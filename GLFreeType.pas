{$mode objfpc}
{$modeswitch advancedrecords}
{$assertions on}

unit GLFreeType;
interface
uses
  FreeTypeH, FGL, GL;

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
      TAnsiChar = char;
      TFaceMap = specialize TFPGMap<TAnsiChar, TFreeTypeFace>;
    private
      m_texture: GLuint;
      m_faces: TFaceMap;
      m_face: PFT_Face;
      m_textureWidth,
      m_textureHeight: integer;
      m_charAdvance: integer;
      m_maxLineHeight: integer;
      function GetFace(c: TAnsiChar): TFreeTypeFace;
      procedure AddTexture (c: TAnsiChar; posX, posY: integer); 
    public
      constructor Create(lib: PFT_Library; path: ansistring);
      destructor Destroy; override;
      procedure Render(pixelSize: integer; charset: string = FREETYPE_ANSI_CHARSET; minFilter: GLuint = GL_LINEAR; magFilter: GLuint = GL_LINEAR); 

      function HasGlyph(c: char): boolean;

      property Face[c: TAnsiChar]: TFreeTypeFace read GetFace; default;
      property TextureWidth: integer read m_textureWidth;
      property TextureHeight: integer read m_textureHeight;
      property TextureID: GLuint read m_texture;
      property MaxLineHeight: integer read m_maxLineHeight;
  end;

implementation

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

constructor TFreeTypeFont.Create(lib: PFT_Library; path: ansistring);
var
  err: integer;
begin
  err := FT_New_Face(lib, pchar(path+#0), 0, m_face);
  Assert(err = 0, 'FT_New_Face');
  m_faces := TFaceMap.Create;
end;

function TFreeTypeFont.GetFace(c: TAnsiChar): TFreeTypeFace;
begin
  Assert(m_faces <> nil, 'must render faces first');
  result := m_faces[c];
end;

function TFreeTypeFont.HasGlyph(c: char): boolean;
begin
  result := m_faces.IndexOf(c) > -1;
end;

procedure TFreeTypeFont.AddTexture (c: TAnsiChar; posX, posY: integer); 
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

procedure TFreeTypeFont.Render(pixelSize: integer; charset: string = FREETYPE_ANSI_CHARSET; minFilter: GLuint = GL_LINEAR; magFilter: GLuint = GL_LINEAR); 
var
  bitmap: FT_Bitmap;
  data: PGLubyte;
  value: GLubyte;
  x, y: integer;
  glyph: TAnsiChar;
  err: integer;
  width,
  height,
  canvasX, 
  canvasY, 
  padding: integer;
  offset: integer;
  channels: integer;
  prevTexture: GLint;
begin

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

  glGenTextures(1, @m_texture);
  glGetIntegerv(GL_TEXTURE_BINDING_2D, @prevTexture);

  glBindTexture(GL_TEXTURE_2D, m_texture);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, magFilter);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, minFilter);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);

  glBindTexture(GL_TEXTURE_2D, prevTexture);

  FreeMem(data);
end;

destructor TFreeTypeFont.Destroy;
begin
  FT_Done_Face(m_face);
  m_faces.Free;
  inherited;
end;

end.