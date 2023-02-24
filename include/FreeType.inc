
{$ifdef INTERFACE}

type
  
  { TFreeTypeFace }

  TFreeTypeFace = record
    private type
      TFTPoint = record
        x, y: single;
      end;
      TFTRect = record
        x, y, w, h: single;
      end;
    private
      function GetBearing: TFTPoint; inline;
      function GetSize: TFTPoint; inline;
    public
      glyph: TFT_GlyphSlot;
      textureFrame: TFTRect;
      property Size: TFTPoint read GetSize;           // Size of glyph in pixels
      property Bearing: TFTPoint read GetBearing;     // Offset from baseline to left/top of glyph
      property Advance: FT_Pos read glyph.advance.x;  // Offset to advance to next glyph
  end;

  { TFreeTypeFont }

  TFreeTypeFont = class abstract
    private const
      kFreeTypeANSIChars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!;%:?*()<>_+-=.,/|"''@#$^&{}[]0123456789';
    private type
      TFontChar = UnicodeChar;
      TFontString = UnicodeString;
      TFaceMap = specialize TFPGMap<TFontChar, TFreeTypeFace>;
    private
      m_faces: TFaceMap;
      m_face: PFT_Face;
      m_textureWidth,
      m_textureHeight: integer;
      m_maxLineHeight: integer;
      function GetFace(c: TFontChar): TFreeTypeFace;
      procedure AddTexture(c: TFontChar; posX, posY: integer); 
    protected
      m_texture: integer;

      procedure GenerateTexture(data: pointer; width, height: integer); virtual; abstract;
      function GetMaximumTextureSize: integer; virtual; abstract;
    public
      { Class Methods }
      class procedure FreeLibrary;

      { Constructors }
      constructor Create(lib: PFT_Library; path: ansistring); overload;
      constructor Create(path: ansistring); overload;
      destructor Destroy; override;

      { Methods }
      procedure Render(pixelSize: integer; const charset: TFontString = kFreeTypeANSIChars); 

      function HasGlyph(c: TFontChar): boolean;
      function LineHeight: integer; virtual; abstract;
      function SpaceWidth: integer; virtual; abstract;
      function TabWidth: integer; virtual; abstract;

      { Properties }
      property Face[c: TFontChar]: TFreeTypeFace read GetFace; default;
      property TextureWidth: integer read m_textureWidth;
      property TextureHeight: integer read m_textureHeight;
      property TextureID: integer read m_texture;
      property MaxLineHeight: integer read m_maxLineHeight;
      property MaximumTextureSize: integer read GetMaximumTextureSize;
  end;

  { TGLFreeTypeFont }

  TGLFreeTypeFont = class (TFreeTypeFont, IFont, ITexture)
    private
      m_textureUnit: integer;
      m_locked: boolean;
    protected
      procedure GenerateTexture(data: pointer; width, height: integer); override;
      function GetMaximumTextureSize: integer; override;
    public
      { ITexture }
      function GetTextureUnit: integer;
      function GetTexture: integer;
      function GetFrame: TTextureFrame;
      procedure Lock(inUnit: integer);
      procedure Unlock;
      procedure Load;
      procedure Unload;
      function IsLoaded: boolean;
      function IsLocked: boolean;

      { IFont }
      function CharacterRenderFrame(c: TFontChar): TFontRenderFrame;
      function LineHeight: integer; override;
      function SpaceWidth: integer; override;
      function TabWidth: integer; override;
      function PreferredTextColor: TVec4;
  end;

{$endif}

{$ifdef IMPLEMENTATION}

var
  SharedLibrary: PFT_Library = nil;

function Pow2(a: integer): integer; inline;
var
  rval: integer = 1;
begin
  while rval < a do
    rval := rval shl 1;
  result := rval;
end;

{*****************************************************************************
 *                               TFreeTypeFont
 *****************************************************************************}

function TFreeTypeFace.GetBearing: TFTPoint;
begin
  result.x := glyph.bitmap_left;
  result.y := glyph.bitmap_top;
end;

function TFreeTypeFace.GetSize: TFTPoint;
begin
  result.x := glyph.bitmap.width;
  result.y := glyph.bitmap.rows;
end;

class procedure TFreeTypeFont.FreeLibrary;
begin
  Assert(SharedLibrary <> nil, 'No shared library was loaded.');
  FT_Done_FreeType(SharedLibrary);
  SharedLibrary := nil;
end;

function TFreeTypeFont.GetFace(c: TFontChar): TFreeTypeFace;
begin
  Assert(m_faces <> nil, 'must render faces first');
  result := m_faces[c];
end;

function TFreeTypeFont.HasGlyph(c: TFontChar): boolean;
begin
  result := m_faces.IndexOf(c) > -1;
end;

procedure TFreeTypeFont.AddTexture(c: TFontChar; posX, posY: integer); 
var
  f: TFreeTypeFace;
begin
  f.textureFrame.x := posX / TextureWidth;
  f.textureFrame.y := posY / TextureHeight;
  f.textureFrame.w := m_face^.glyph^.bitmap.width / TextureWidth;
  f.textureFrame.h := m_face^.glyph^.bitmap.rows / TextureHeight;

  f.glyph := m_face^.glyph^;
  m_faces.Add(c, f);
end;

procedure TFreeTypeFont.Render(pixelSize: integer; const charset: TFontString); 
var
  bitmap: FT_Bitmap;
  data: PUInt8;
  value: UInt8;
  x, y: integer;
  glyph: TFontChar;
  err: integer;
  width,
  height,
  canvasX, 
  canvasY, 
  padding: integer;
  offset: integer;
  channels: integer;
begin
  Assert(m_face <> nil, 'Freetype face is nil.');
  Assert(TextureID = 0, 'Font has already been rendered');

  // https://www.freetype.org/freetype2/docs/tutorial/step1.html
  // https://learnopengl.com/In-Practice/Text-Rendering
  // https://stackoverflow.com/questions/24799090/opengl-freetype-weird-texture
  FT_Set_Pixel_Sizes(m_face, 0, pixelSize);
  
  
  // Find a square power of two sized box to fix the glyphs
  width := Pow2(Round(Sqrt(m_face^.size^.metrics.x_ppem * m_face^.size^.metrics.y_ppem * Length(charset))));
  height := width;
  
  Assert((width <= MaximumTextureSize) and (height <= MaximumTextureSize), 'Font size exceeds maximum texture size.');

  m_textureWidth := width;
  m_textureHeight := height;

  canvasX := 0;
  canvasY := 0;
  channels := 4;
  data := PUInt8(GetMem(channels * width * height));

  m_maxLineHeight := m_face^.size^.metrics.y_ppem;
  padding := 1;
  
  for glyph in charset do
    begin
      err := FT_Load_Char(m_face, ord(glyph), FT_LOAD_RENDER);
      Assert(err = 0, 'FT_Load_Char');
      bitmap := m_face^.glyph^.bitmap;

      for y := 0 to bitmap.rows - 1 do
        for x := 0 to bitmap.width - 1 do
          begin
            value := PUInt8(bitmap.buffer)[x + y * bitmap.width];
            offset := width * canvasY + (canvasX + x + y * width);

            Assert(offset <= width * height, 'Allocate texture size is too small ('+width.ToString+'x'+height.ToString+')');

            data[channels * offset + 0] := high(UInt8);
            data[channels * offset + 1] := high(UInt8);
            data[channels * offset + 2] := high(UInt8);
            data[channels * offset + 3] := value;
          end;

      AddTexture(glyph, canvasX, canvasY);

      canvasX += bitmap.width + padding;
      if canvasX + bitmap.width + padding > width then
        begin
          canvasX := 0;
          canvasY += m_maxLineHeight;
        end;
    end;

  GenerateTexture(data, width, height);
  FreeMem(data);
end;

destructor TFreeTypeFont.Destroy;
begin
  FT_Done_Face(m_face);
  m_faces.Free;
  inherited;
end;

constructor TFreeTypeFont.Create(path: ansistring);
begin
  if SharedLibrary = nil then
    Assert(FT_Init_FreeType(SharedLibrary) = 0, 'FT_Init_FreeType');
  Create(SharedLibrary, path);
end;

constructor TFreeTypeFont.Create(lib: PFT_Library; path: ansistring);
var
  err: integer;
begin
  Assert(lib <> nil, 'FreeType library can''t be nil');
  err := FT_New_Face(lib, pchar(path+#0), 0, m_face);
  Assert(err = 0, 'FT_New_Face');
  m_faces := TFaceMap.Create;
end;

{*****************************************************************************
 *                               TGLFreeTypeFont
 *****************************************************************************}

function TGLFreeTypeFont.GetMaximumTextureSize: integer;
begin
  result := GLCanvas.GetMaximumTextureSize;
end;

procedure TGLFreeTypeFont.GenerateTexture(data: pointer; width, height: integer);
const
  TextureOptions = [TTextureImage.RGBA,  
                    TTextureImage.UnsignedByte,
                    TTextureImage.NearestNeighbor
                    ];
begin
  GLCanvas.GenerateTexture(Longint(m_texture));
  BindTexture2D(textureID);
  LoadTexture2D(width, height, data, TextureOptions);
  RestoreLastBoundTexture;
end;

function TGLFreeTypeFont.GetFrame: TTextureFrame;
begin
  result.texture := RectMake(0, 0, 1, 1);
  result.pixel := RectMake(0, 0, TextureWidth, TextureHeight);
end;

function TGLFreeTypeFont.GetTexture: integer;
begin
  result := TextureID;
end;

function TGLFreeTypeFont.GetTextureUnit: integer;
begin
  result := m_textureUnit;
end;

function TGLFreeTypeFont.IsLoaded: boolean;
begin
  result := TextureID > 0;
end;

procedure TGLFreeTypeFont.Lock(inUnit: integer);
begin
  Assert(not IsLocked, 'Texture is already locked');
  if not IsLoaded then
    Load;
  ChangeTextureUnit(IFont(self), inUnit);
  m_textureUnit := inUnit;
  m_locked := true;
  writeln('bound and locked texture ', TextureID, ' to unit ', m_textureUnit);
end;

procedure TGLFreeTypeFont.Unlock;
begin
  Assert(IsLocked, 'Texture is already unlocked');
  m_locked := false;
  ClearTextureUnit(m_textureUnit);
end;

procedure TGLFreeTypeFont.Load;
begin  
  Assert(false, 'loading not supported for free type fonts');
end;

procedure TGLFreeTypeFont.Unload;
begin
  Assert(false, 'loading not supported for free type fonts');
end;

function TGLFreeTypeFont.IsLocked: boolean;
begin
  result := m_locked;
end;

function TGLFreeTypeFont.CharacterRenderFrame(c: TFontChar): TFontRenderFrame;
var
  f: TFreeTypeFace;
begin
  f := face[c];

  result.textureFrame := RectMake(f.textureFrame.x, f.textureFrame.y, f.textureFrame.w, f.textureFrame.h);
  result.faceSize := V2(f.size.x, f.size.y);
  result.advance := f.Advance shr 6;
  result.bearing.y := trunc(MaxLineHeight - f.bearing.y);
  result.bearing.x := f.bearing.x;
end;

function TGLFreeTypeFont.LineHeight: integer;
begin
  result := MaxLineHeight;
end;

function TGLFreeTypeFont.SpaceWidth: integer;
begin
  result := Round(MaxLineHeight / 1.5);
end;

function TGLFreeTypeFont.TabWidth: integer;
begin
  result := SpaceWidth * 2;
end;

function TGLFreeTypeFont.PreferredTextColor: TVec4;
begin
  result := RGBA(0, 0, 0, 1);
end;

{$endif}
