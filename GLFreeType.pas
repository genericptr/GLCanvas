{$mode objfpc}
{$modeswitch advancedrecords}
{$implicitexceptions off}

{$include include/targetos.inc}

{$codepage utf8}

unit GLFreeType;
interface
uses
  {$ifdef API_OPENGL}
  GL, GLext,
  {$endif}
  {$ifdef API_OPENGLES}
  GLES30,
  {$endif}
  CWString, FreeTypeH, FGL;

const
  FREETYPE_ANSI_CHARSET = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!;%:?*()<>_+-=.,/|"''@#$^&{}[]0123456789';

type
  TPoint = record
    x, y: single;
  end;
  TRect = record
    x, y, w, h: single;
  end;
  TFreeTypeFace = record
    private
      function GetBearing: TPoint; inline;
      function GetSize: TPoint; inline;
    public
      glyph: TFT_GlyphSlot;
      textureFrame: TRect;
      property Size: TPoint read GetSize;             // Size of glyph in pixels
      property Bearing: TPoint read GetBearing;       // Offset from baseline to left/top of glyph
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

      procedure GenerateTexture(data: pointer; width, height: integer; minFilter, magFilter: integer); virtual;
    public

      { Methods }
      constructor Create(lib: PFT_Library; path: ansistring); overload;
      constructor Create(path: ansistring); overload;
      class procedure FreeLibrary;

      procedure Render(pixelSize: integer; const charset: TFontString = FREETYPE_ANSI_CHARSET; minFilter: GLuint = GL_LINEAR; magFilter: GLuint = GL_LINEAR); 

      { Accessors }
      function HasGlyph(c: TFontChar): boolean;

      property Face[c: TFontChar]: TFreeTypeFace read GetFace; default;
      property TextureWidth: integer read m_textureWidth;
      property TextureHeight: integer read m_textureHeight;
      property TextureID: integer read m_texture;
      property MaxLineHeight: integer read m_maxLineHeight;
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

function RectMake(x, y, w, h: single): TRect; inline; 
begin
  result.x := x;
  result.y := y;
  result.w := w;
  result.h := h;
end;

function PointMake(x, y: single): TPoint; inline; 
begin
  result.x := x;
  result.y := y;
end;

function TFreeTypeFace.GetBearing: TPoint;
begin
  result.x := glyph.bitmap_left;
  result.y := glyph.bitmap_top;
end;

function TFreeTypeFace.GetSize: TPoint;
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

procedure TFreeTypeFont.GenerateTexture(data: pointer; width, height: integer; minFilter, magFilter: integer); 
begin
  glGenTextures(1, @m_texture);
  glBindTexture(GL_TEXTURE_2D, m_texture);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, magFilter);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, minFilter);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
end;

procedure TFreeTypeFont.Render(pixelSize: integer; const charset: TFontString; minFilter: GLuint; magFilter: GLuint); 
var
  bitmap: FT_Bitmap;
  data: PGLubyte;
  value: GLubyte;
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
  Assert(m_face <> nil, 'freetype face is nil.');
  Assert(TextureID = 0, 'font has already been rendered');

  // https://www.freetype.org/freetype2/docs/tutorial/step1.html
  // https://learnopengl.com/In-Practice/Text-Rendering
  // https://stackoverflow.com/questions/24799090/opengl-freetype-weird-texture
  FT_Set_Pixel_Sizes(m_face, 0, pixelSize);
  
  // TODO: estimate bounds
  width := Pow2(512);
  height := Pow2(512);
  m_textureWidth := width;
  m_textureHeight := height;

  canvasX := 0;
  canvasY := 0;
  channels := 4;
  data := PGLubyte(GetMem(channels * width * height));

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
            value := PGLubyte(bitmap.buffer)[x + y * bitmap.width];
            offset := width * canvasY + (canvasX + x + y * width);

            data[channels * offset + 0] := high(GLubyte);
            data[channels * offset + 1] := high(GLubyte);
            data[channels * offset + 2] := high(GLubyte);
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

  GenerateTexture(data, width, height, minFilter, magFilter);
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