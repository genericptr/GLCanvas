
{$ifdef INTERFACE}
type
  TFrameBuffer = class
    private
      m_textureID: GLuint;
      m_width: integer;
      m_height: integer;
      m_options: TTextureImageOptions;
      m_texture: TTexture;
      buffer: GLuint;
      previousViewPort: array[0..3] of GLint;
      function GetBounds: TRect; inline;
      function GetTexture: TTexture; inline;
    public
      { Constructors }
      constructor Create(width, height: integer; options: TTextureImageOptions = DefaultTextureOptions); overload;
      constructor Create(size: TVec2i; options: TTextureImageOptions = DefaultTextureOptions); overload;
      destructor Destroy; override;

      { Methods }
      function IsActive: boolean;
      procedure Push; virtual;
      procedure Pop; virtual;
      procedure Bind;
      procedure Unbind;
      procedure Resize(newWidth, newHeight: integer); virtual;

      { Properties }
      property Width: integer read m_width;
      property Height: integer read m_height;
      property Bounds: TRect read GetBounds;
      property Texture: TTexture read GetTexture;
      property TextureID: GLuint read m_textureID;
  end;
{$endif}

{$ifdef IMPLEMENTATION}

type
  TFrameBufferList = specialize TFPGList<TFrameBuffer>;

var
  FrameBufferStack: TFrameBufferList = nil;

function TFrameBuffer.GetBounds: TRect;
begin
  result := RectMake(0, 0, Width, Height);
end;

function TFrameBuffer.GetTexture: TTexture;
begin
  if m_texture = nil then
    begin
      m_texture := TTexture.Create(TextureID, Width, Height, m_options);
      // we have to flip the texture because the frame buffer origin is bottom-left oriented
      m_texture.SetTextureFrame(RectMake(0, 1, 1, -1));
    end;
  result := m_texture;
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

  // TODO: disabled for now
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
  glGetIntegerv(GL_VIEWPORT, @previousViewPort);
  glViewPort(0, 0, width, height);
end;

procedure TFrameBuffer.Unbind;
begin
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
  GLAssert('glBindFramebuffer '+IntToStr(buffer));
  // restore previous viewport
  glViewPort(previousViewPort[0], previousViewPort[1], previousViewPort[2], previousViewPort[3]);
end;

function TFrameBuffer.IsActive: boolean;
begin
  Assert(FrameBufferStack <> nil, 'empty frame buffer stack.');
  result := FrameBufferStack.Last = self;
end;

procedure TFrameBuffer.Push;
begin
  if FrameBufferStack = nil then
    FrameBufferStack := TFrameBufferList.Create;
  FrameBufferStack.Add(self);
  PushProjectionTransform(Width, Height);
  Bind;
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

constructor TFrameBuffer.Create(width, height: integer; options: TTextureImageOptions);
begin
  self.m_options := options;
  glGenFramebuffers(1, @buffer);
  Resize(width, height);
end;

constructor TFrameBuffer.Create(size: TVec2i; options: TTextureImageOptions);
begin
  Create(size.width, size.height, options);
end;

{$endif}
