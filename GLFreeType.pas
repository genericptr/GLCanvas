{$mode objfpc}
{$modeswitch advancedrecords}
{$implicitexceptions off}

{$include include/targetos.inc}

{$codepage utf8}

unit GLFreeType;
interface
uses
  {$ifdef DARWIN}
  CWString,
  {$endif}
  SysUtils, CTypes, FreeTypeH, FGL;

const
  FREETYPE_ANSI_CHARSET = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!;%:?*()<>_+-=.,/|"''@#$^&{}[]0123456789';

type
  TFTPoint = record
    x, y: single;
  end;
  TFTRect = record
    x, y, w, h: single;
  end;
  TFreeTypeFace = record
    private
      function GetBearing: TFTPoint; inline;
      function GetSize: TFTPoint; inline;
    public
      glyph: TFT_GlyphSlot;
      textureFrame: TFTRect;
      property Size: TFTPoint read GetSize;             // Size of glyph in pixels
      property Bearing: TFTPoint read GetBearing;       // Offset from baseline to left/top of glyph
      property Advance: FT_Pos read glyph.advance.x;  // Offset to advance to next glyph
  end;

type
  TFreeTypeFont = class
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

      { Methods }
      procedure Render(pixelSize: integer; const charset: TFontString = FREETYPE_ANSI_CHARSET); 

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
    public
      destructor Destroy; override;
  end;

implementation

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

function RectMake(x, y, w, h: single): TFTRect; inline; 
begin
  result.x := x;
  result.y := y;
  result.w := w;
  result.h := h;
end;

function PointMake(x, y: single): TFTPoint; inline; 
begin
  result.x := x;
  result.y := y;
end;

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

end.