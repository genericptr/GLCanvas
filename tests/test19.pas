{
    Copyright (c) 2022 by Ryan Joseph

    GLCanvas Test #19
    
    Testing render buffers
}
{$mode objfpc}
{$modeswitch multihelpers}

// TODO: can't get this working!

program Test19;
uses
  GLCanvas,
  GL, GLext, GLUtils;

const
  window_size_width = 512;
  window_size_height = 512;

const
  world_size_width = 32;
  world_size_height = 32;


var
  texture: TTexture;
  //frameBuffer: TFrameBuffer;
  frameBuffer, 
  renderbuffer: GLuint;
begin
  SetupCanvas(window_size_width, window_size_height);

  texture := TTexture.Create('orc.png');

  // http://www.songho.ca/opengl/gl_fbo.html

  //SetViewTransform(-100,0,1);

  //frameBuffer := TFrameBuffer.Create(256);
  //frameBuffer.Push;
  //      DrawTexture(texture, RectMake(0, 256));
  //frameBuffer.Pop;

  glGenFramebuffers(1, @frameBuffer);
  glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);

  glGenRenderbuffers(1, @renderbuffer);
  glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer);
  glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA, world_size_width, world_size_height);

  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderbuffer);

  glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);
  glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);

      glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
      glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer);
      GLAssert('glBindFramebuffer');
        glViewPort(0, 0, world_size_width, world_size_height);
        //PushProjectionTransform(world_size_width, world_size_height);
        DrawTexture(texture, RectMake(0, 0, world_size_width, world_size_height));
        //PopProjectionTransform;
      glBindFramebuffer(GL_FRAMEBUFFER, 0);
      glBindRenderbuffer(GL_RENDERBUFFER, 0);

  while IsRunning do
    begin
      //FillRect(GetViewPort, TColor.Red);
      //DrawTexture(frameBuffer.Texture, GetViewPort);


      glViewPort(0, 0, window_size_width, window_size_height);

      glBindFramebuffer(GL_READ_FRAMEBUFFER, frameBuffer);
      glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
      glBlitFramebuffer(0, 512-32, world_size_width, world_size_height, // source
                        0, 0, 512, 512, // dest
                        GL_COLOR_BUFFER_BIT, GL_NEAREST);

      SwapBuffers;
    end;

  QuitApp;
end.