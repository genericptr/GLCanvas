{
    Copyright (c) 2019 by Ryan Joseph

    GLCanvas Test #1
  
    Tests minimal canvas setup & compiles all units
}
{$mode objfpc}

program Test1;
uses
  {$ifdef unix}CThreads,{$endif}
  GLCanvas,
  GLUtils,
  {$ifdef PLATFORM_GLPT}GLPT;{$endif}
  {$ifdef PLATFORM_SDL}SDL;{$endif}

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