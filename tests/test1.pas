{
    Copyright (c) 2019 by Ryan Joseph

    GLCanvas Test #1
  
    Tests minimal canvas setup & compiles all units
}
{$mode objfpc}
{$assertions on}

program Test1;
uses
  // rtl
  CThreads, 
  // GLCanvas
  GLCanvas, 
  GLVertexBuffer, 
  GLUtils, 
  GLShader, 
  GLGUI, 
  GLFreeTypeFont, 
  GLFreeType, 
  GLFrameBuffer,
  // glcanvas extras
  VectorMath, GeometryTypes,
  // GLPT
  GLPT;

const
  window_size_width = 600;
  window_size_height = 600;

begin
  SetupCanvas(window_size_width, window_size_height);

  while IsRunning do
    begin
      ClearBackground;
      { Do drawing here... }
      SwapBuffers;
    end;

  QuitApp;
end.