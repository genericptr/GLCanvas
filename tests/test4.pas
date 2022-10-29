{
    Copyright (c) 2019 by Ryan Joseph

    GLCanvas Test #4
    
    Tests FreeType font rendering
}
{$mode objfpc}
{$assertions on}

program Test4;
uses
  SysUtils, VectorMath, GLCanvas;

const
  window_size_width = 600;
  window_size_height = 600;

var
  font: IFont;
begin
  SetupCanvas(window_size_width, window_size_height);
  
  font := CreateFont('Arial.ttf', 50);

  while IsRunning do
    begin
      ClearBackground;
      DrawText(font, 'Hello World', V2(50, 50), RGBA(0.1, 0.1, 1, 1));
      SwapBuffers;
    end;

  QuitApp;
end.