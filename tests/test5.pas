{
    Copyright (c) 2023 by Ryan Joseph

    GLCanvas Test #5
    
    Test reading pixels from textures
}
{$mode objfpc}

program Test5;
uses
  SysUtils, GLCanvas;

const
  window_size_width = 500;
  window_size_height = 500;

procedure EventCallback(event: TEvent);
begin
end;

var
  frameBuffer: TFrameBuffer;
  texture: TTexture;
begin
  SetupCanvas(window_size_width, window_size_height, @EventCallback);

  texture := TTexture.Create('checkers.png');

  // TODO: we have a flaw where we rely on the image data from loading from file
  // so if the texture is modified we need to use glGetTexImage
  // https://registry.khronos.org/OpenGL-Refpages/gl4/html/glGetTexImage.xhtml
  // https://registry.khronos.org/OpenGL-Refpages/gl4/html/glTexSubImage2D.xhtml
  {
    image := texture.CopyPixels;

    void glGetTexImage( GLenum target,
      GLint level,
      GLenum format,
      GLenum type,
      void * pixels);
  }
  while IsRunning do
    begin
      ClearBackground;
      SwapBuffers;
    end;

  QuitApp;
end.