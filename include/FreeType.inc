
{$ifdef INTERFACE}

type
  TGLFreeTypeFont = class (TFreeTypeFont, IFont, ITexture)
    private
      m_textureUnit: integer;
      m_locked: boolean;
    protected
      procedure GenerateTexture(data: pointer; width, height: integer); override;
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
      function LineHeight: integer;
      function SpaceWidth: integer;
      function TabWidth: integer;
      function PreferredTextColor: TVec4;
  end;

{$endif}

{$ifdef IMPLEMENTATION}

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

{$endif}
