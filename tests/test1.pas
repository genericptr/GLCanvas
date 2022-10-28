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
  {$ifdef unix}CThreads,{$endif}
  // GLCanvas
  GLCanvas, 
  GLVertexBuffer, 
  GLUtils, 
  GLShader, 
  GLUI, 
  GLFreeType, 
  // GLCanvas extras
  VectorMath, GeometryTypes,
  // Platform units
  {$ifdef PLATFORM_GLPT}GLPT;{$endif}
  {$ifdef PLATFORM_SDL}SDL;{$endif}

const
  window_size_width = 600;
  window_size_height = 600;

begin
  writeln('Starting...');
  SetupCanvas(window_size_width, window_size_height);

  while IsRunning do
    begin
      ClearBackground;
      { Do drawing here... }
      SwapBuffers;
    end;

  QuitApp;
end.