
{$ifdef INTERFACE}
type
  TFrameBuffer = class
    private
      m_textureID: GLuint;
      m_depthTextureID: GLuint;
      m_width: integer;
      m_height: integer;
      m_options: TTextureImageOptions;
      m_texture: TTexture;
      m_flipped: boolean;
      buffer: GLuint;
      previousViewPort: TRect;
      enableDepthBuffer: boolean;

      function GetBounds: TRect; inline;
      function GetSize: TVec2; inline;
      function GetTexture: TTexture; inline;
      procedure SetFlipped(newValue: boolean); 
    public
      { Constructors }
      constructor Create(width, height: integer; depthBuffer: boolean = false; options: TTextureImageOptions = DefaultTextureOptions); overload;
      constructor Create(size: TVec2i; depthBuffer: boolean = false; options: TTextureImageOptions = DefaultTextureOptions); overload;
      destructor Destroy; override;

      { Methods }
      function IsActive: boolean;
      function IsBound: boolean;
      function PixelAt(x, y: integer): TColor;

      procedure Push(_clear: Boolean = false); virtual;
      procedure Pop; virtual;
      procedure Bind;
      procedure Unbind;
      procedure Blit(destBuffer: TFrameBuffer; sourceRect, destRect: TRecti); overload;
      procedure Blit(destTexture: TTexture; sourceRect: TRecti; destOffset: TVec2i); overload;
      procedure Blit(destTexture: TTexture; rect: TRecti); overload;
      procedure Resize(newWidth, newHeight: integer); virtual;
      procedure Clear;

      { Properties }
      property Width: integer read m_width;
      property Height: integer read m_height;
      property Size: TVec2 read GetSize;
      property Bounds: TRect read GetBounds;
      property Texture: TTexture read GetTexture;
      property TextureID: GLuint read m_textureID;
      property TextureOptions: TTextureImageOptions read m_options;
      property Flipped: boolean read m_flipped write SetFlipped;
  end;
{$endif}

{$ifdef IMPLEMENTATION}

type
  TFrameBufferList = specialize TFPGList<TFrameBuffer>;

var
  FrameBufferStack: TFrameBufferList = nil;

procedure TFrameBuffer.SetFlipped(newValue: boolean); 
begin
  if m_texture <> nil then
    if newValue then
      m_texture.SetTextureFrame(RectMake(0, 1, 1, -1))
    else
      m_texture.SetTextureFrame(RectMake(0, 0, 1, 1));

  m_flipped := newValue;
end;

function TFrameBuffer.GetBounds: TRect;
begin
  result := RectMake(0, 0, Width, Height);
end;

function TFrameBuffer.GetSize: TVec2;
begin
  result := V2(Width, Height);
end;

function TFrameBuffer.GetTexture: TTexture;
begin
  if m_texture = nil then
    begin
      m_texture := TTexture.Create(TextureID, Width, Height, m_options);
      // we have to flip the texture because the frame buffer origin is bottom-left oriented
      if flipped then
        m_texture.SetTextureFrame(RectMake(0, 1, 1, -1))
      else
        m_texture.SetTextureFrame(RectMake(0, 0, 1, 1));
    end;
  result := m_texture;
end;

procedure TFrameBuffer.Clear;
var
  flags: GLbitfield;
begin
  flags := GL_COLOR_BUFFER_BIT;

  if enableDepthBuffer then
    flags += GL_DEPTH_BUFFER_BIT;
  
  glClear(flags);
end;

procedure TFrameBuffer.Resize(newWidth, newHeight: integer);
var
  prevTexture,
  prevFBO: GLint;
begin
  if (width = newWidth) and (height = newHeight) then
    exit;

  m_width := newWidth;
  m_height := newHeight;

  // TODO: disabled for now since we can't figure it out
  Assert(TextureID = 0, 'frame buffer already allocated.');
  //if texture > 0 then
  //  begin
  //    glActiveTexture(GL_TEXTURE0 + 0);
  //    glBindTexture(GL_TEXTURE_2D, texture);
  //    LoadTexture2D(width, height, pixelFormat);
  //    glBindTexture(GL_TEXTURE_2D, 0);
  //    exit;
  //  end;

  glGenTextures(1, @m_textureID);
  glGetIntegerv(GL_TEXTURE_BINDING_2D, @prevTexture);

  glBindTexture(GL_TEXTURE_2D, TextureID);
  LoadTexture2D(Width, Height, nil, m_options);

  glGetIntegerv(GL_FRAMEBUFFER_BINDING, @prevFBO);
  glBindFramebuffer(GL_FRAMEBUFFER, buffer);
  GLAssert('glBindFramebuffer '+IntToStr(buffer));
  glFrameBufferTexture2D(GL_FRAMEBUFFER,
                        GL_COLOR_ATTACHMENT0,
                        GL_TEXTURE_2D,
                        TextureID,
                        0);
  
  if enableDepthBuffer then
    begin
      glGenTextures(1, @m_depthTextureID);
      glBindTexture(GL_TEXTURE_2D, m_depthTextureID);
      glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT, width, height, 0, GL_DEPTH_COMPONENT, GL_FLOAT, nil);
      glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, m_depthTextureID, 0);
    end;

  Assert(glCheckFramebufferStatus(GL_FRAMEBUFFER) = GL_FRAMEBUFFER_COMPLETE, 'glFramebufferTexture2D failed with error $'+HexStr(glCheckFramebufferStatus(GL_FRAMEBUFFER), 4));

  glFrameBufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, TextureID, 0);
  GLAssert('glFrameBufferTexture2D '+IntToStr(buffer));

  // restore previous bindings
  glBindTexture(GL_TEXTURE_2D, prevTexture);
  glBindFramebuffer(GL_FRAMEBUFFER, prevFBO);
end;

procedure TFrameBuffer.Bind;
begin
  glBindFramebuffer(GL_FRAMEBUFFER, buffer);
  GLAssert('glBindFramebuffer '+IntToStr(buffer));
  // reset viewport to frame buffer size
  previousViewPort := GetViewPort;
  SetViewPort(Bounds);
end;

procedure TFrameBuffer.Unbind;
begin
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
  GLAssert('glBindFramebuffer '+IntToStr(buffer));
  // restore previous viewport
  SetViewPort(previousViewPort);
end;

{ Copies part of the frame buffer to a target texture }
procedure TFrameBuffer.Blit(destTexture: TTexture; sourceRect: TRecti; destOffset: TVec2i);
begin
  Assert((sourceRect.x >= 0) and (sourceRect.y >= 0), 'Source origin is negative '+sourceRect.ToStr);
  Assert((sourceRect.Width <= Width) and (sourceRect.Height <= Height), 'Source size exceeds frame buffer size '+sourceRect.ToStr);

  destTexture.LoadIfNeeded;
  BindTexture2D(destTexture.TextureID, 1);

  glBindFramebuffer(GL_READ_FRAMEBUFFER, self.buffer);
  CopyTexture2D(sourceRect, RectMake(destOffset.x, destOffset.y, destTexture.Size));
  glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);

  RestoreLastBoundTexture;
end;

procedure TFrameBuffer.Blit(destTexture: TTexture; rect: TRecti);
begin
  Blit(destTexture, rect, rect.origin);
end;

{ Copies part of the frame buffer to target frame buffer }
procedure TFrameBuffer.Blit(destBuffer: TFrameBuffer; sourceRect, destRect: TRecti);
begin
  glBindFramebuffer(GL_READ_FRAMEBUFFER, self.buffer);

  // use the application created frame buffer if none is specified
  if destBuffer <> nil then
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, destBuffer.buffer)
  else
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);

  glBlitFramebuffer(sourceRect.MinX,
                    sourceRect.MinY,
                    sourceRect.MaxX,
                    sourceRect.MaxY,
                    destRect.MinX,
                    destRect.MinY,
                    destRect.MaxX,
                    destRect.MaxY,
                    GL_COLOR_BUFFER_BIT,
                    GL_NEAREST);

  glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);
  glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
end;

function TFrameBuffer.IsActive: boolean;
begin
  Assert(FrameBufferStack <> nil, 'empty frame buffer stack.');
  result := FrameBufferStack.Last = self;
end;

function TFrameBuffer.IsBound: boolean;
var
  id: GLUint;
begin
  glGetIntegerv(GL_FRAMEBUFFER_BINDING, @id);
  result := buffer = id;
end;

function TFrameBuffer.PixelAt(x, y: integer): TColor;
var
  pixel: array[0..3] of GLubyte;
begin
  Assert(IsBound, 'Frame buffer must be bound before inspecting pixels');

  // flip-y
  y := Height - y;
  glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

  case TextureOptions.Format of
    GL_UNSIGNED_BYTE:
      begin
        glReadPixels(x, y, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, @pixel);
        result := RGBA(pixel[0]/255,pixel[1]/255,pixel[2]/255,pixel[3]/255);
      end;
    GL_FLOAT:
      glReadPixels(x, y, 1, 1, GL_RGBA, GL_FLOAT, @result);
  end;
end;

procedure TFrameBuffer.Push(_clear: Boolean);
begin
  FlushDrawing;
  if FrameBufferStack = nil then
    FrameBufferStack := TFrameBufferList.Create;
  FrameBufferStack.Add(self);
  PushProjectionTransform(Width, Height);
  Bind;
  if _clear then
    Clear;
end;

procedure TFrameBuffer.Pop;
begin
  Assert((FrameBufferStack <> nil) and (FrameBufferStack.Count > 0), 'empty frame buffer stack.');
  FlushDrawing;
  FrameBufferStack.Last.Unbind;
  FrameBufferStack.Delete(FrameBufferStack.Count - 1);
  PopProjectionTransform;
end;

destructor TFrameBuffer.Destroy;
begin
  glDeleteFramebuffers(1, @buffer);
  Texture.Free;
end;

constructor TFrameBuffer.Create(width, height: integer; depthBuffer: boolean; options: TTextureImageOptions);
begin
  Assert((width > 0) and (height > 0), 'Frame buffer size must be greater than zero.');
  self.m_options := options;
  enableDepthBuffer := depthBuffer;
  Flipped := true;
  glGenFramebuffers(1, @buffer);
  Resize(width, height);
end;

constructor TFrameBuffer.Create(size: TVec2i; depthBuffer: boolean; options: TTextureImageOptions);
begin
  Create(size.width, size.height, depthBuffer, options);
end;

{$endif}
