{$mode objfpc}

unit GLFreeTypeFont;
interface
uses
  GLFreeType, GLCanvas, GeometryTypes, VectorMath;

type
  TGLFreeTypeFont = class (TFreeTypeFont, IFont, ITexture)
    private
      m_textureUnit: TGLTextureUnit;
      m_locked: boolean;
    public
      { ITexture }
      function GetTextureUnit: TGLTextureUnit;
      function GetTexture: TGLTextureID;
      function GetTextureFrame: TTextureFrame;
      procedure Lock(inUnit: TGLTextureUnit);
      procedure Unlock;
      procedure Load;
      procedure Unload;
      function IsLoaded: boolean;
      function IsLocked: boolean;

      { IFont }
      function CharacterRenderFrame(c: char): TFontRenderFrame;
      function LineHeight: integer;
      function SpaceWidth: integer;
      function TabWidth: integer;
      function PreferredTextColor: TVec4;
  end;

implementation

function TGLFreeTypeFont.GetTextureFrame: TTextureFrame;
begin
  result.texture := RectMake(0, 0, 1, 1);
  result.pixel := RectMake(0, 0, TextureWidth, TextureHeight);
end;

function TGLFreeTypeFont.GetTexture: TGLTextureID;
begin
  result := TextureID;
end;

function TGLFreeTypeFont.GetTextureUnit: TGLTextureUnit;
begin
  result := m_textureUnit;
end;

function TGLFreeTypeFont.IsLoaded: boolean;
begin
  result := TextureID > 0;
end;

procedure TGLFreeTypeFont.Lock(inUnit: TGLTextureUnit);
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

function TGLFreeTypeFont.CharacterRenderFrame(c: char): TFontRenderFrame;
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
  // TODO: this must be derived from pixel size
  result := 3;
end;

function TGLFreeTypeFont.TabWidth: integer;
begin
  result := 2;
end;

function TGLFreeTypeFont.PreferredTextColor: TVec4;
begin
  result := RGBA(0, 0, 0, 1);
end;

end.