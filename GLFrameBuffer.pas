{$mode objfpc}
{$assertions on}

unit GLFrameBuffer;
interface
uses
  GL, GLExt;

type
  TFrameBuffer = class
    public
      texture: GLuint;
      width, height: integer;
    public
      constructor Create (_width, _height: integer; format: GLenum);
      procedure Bind;
      procedure Unbind;
      procedure Resize (newWidth, newHeight: integer); overload;
      destructor Destroy; override;
    private
      buffer: GLuint;
      pixelFormat: GLenum;
  end;  


implementation
uses
  GLUtils, SysUtils;

procedure LoadTexture2D (width, height: GLsizei; format: GLenum; data: pointer = nil);
begin
  case format of
    GL_RGB:
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, data);
    GL_RGBA:
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
  end;

  GLAssert('glTexImage2D failed');

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
end;

procedure TFrameBuffer.Resize (newWidth, newHeight: integer);
begin
  if (width = newWidth) and (height = newHeight) then
    exit;

  width := newWidth;
  height := newHeight;

  // TODO: disabled for now
  Assert(texture = 0, 'frame buffer already allocated.');
  //if texture > 0 then
  //  begin
  //    glActiveTexture(GL_TEXTURE0 + 0);
  //    glBindTexture(GL_TEXTURE_2D, texture);
  //    LoadTexture2D(width, height, pixelFormat);
  //    glBindTexture(GL_TEXTURE_2D, 0);
  //    exit;
  //  end;

  // TODO: are we overwritting other textures?
  glGenTextures(1, @texture);
  writeln('frame buffer texture ', texture);
  glActiveTexture(GL_TEXTURE0 + 0);
  glBindTexture(GL_TEXTURE_2D, texture);
  LoadTexture2D(width, height, pixelFormat);

  glBindFramebuffer(GL_FRAMEBUFFER, buffer);
  GLAssert('glBindFramebuffer '+IntToStr(buffer));
  glFrameBufferTexture2D(GL_FRAMEBUFFER,
                        GL_COLOR_ATTACHMENT0,
                        GL_TEXTURE_2D,
                        texture,
                        0);
  Assert(glCheckFramebufferStatus(GL_FRAMEBUFFER) = GL_FRAMEBUFFER_COMPLETE, 'glFramebufferTexture2D failed with error $'+HexStr(glCheckFramebufferStatus(GL_FRAMEBUFFER), 4));

  glFrameBufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);
  GLAssert('glFrameBufferTexture2D '+IntToStr(buffer));

  glBindTexture(GL_TEXTURE_2D, 0);

  Unbind;
end;

procedure TFrameBuffer.Bind;
begin
  glBindFramebuffer(GL_FRAMEBUFFER, buffer);
  GLAssert('glBindFramebuffer '+IntToStr(buffer));
end;

procedure TFrameBuffer.Unbind;
begin
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
  GLAssert('glBindFramebuffer '+IntToStr(buffer));
end;

destructor TFrameBuffer.Destroy;
begin
  glDeleteFramebuffers(1, @buffer);
  glDeleteTextures(1, @texture);
end;

constructor TFrameBuffer.Create (_width, _height: integer; format: GLenum);
begin
  pixelFormat := format;
  glGenFramebuffers(1, @buffer);
  Resize(_width, _height);
end;  

end.