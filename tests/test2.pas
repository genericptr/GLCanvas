{
    Copyright (c) 2019 by Ryan Joseph

    GLCanvas Test #2
    
    Tests drawing shapes
}
{$mode objfpc}
{$assertions on}

program Test2;
uses
  GeometryTypes, VectorMath, GLCanvas;

const
  window_size_width = 600;
  window_size_height = 600;

begin
  SetupCanvas(window_size_width, window_size_height);

  while IsRunning do
    begin
      ClearBackground;
      FillRect(RectMake(50, 50, 100, 100), RGBA(1, 0, 0, 1));
      SwapBuffers;
    end;

  QuitApp;
end.