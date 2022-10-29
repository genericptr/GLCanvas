{
    Copyright (c) 2022 by Ryan Joseph

    GLCanvas Test #18
    
    Testing static vertex buffers
}
{$mode objfpc}

program test18;
uses
  GLCanvas;

var
  buffer: array[0..1] of TDefaultVertexBuffer;
begin
  SetupCanvas(480, 480);

  { TODO: draw to the buffer using a texture at a specific unit so we can 
    guarantee it won't change between draw calls }

  buffer[0] := CreateVertexBuffer(true);
  PushVertexBuffer(buffer[0]);
  StrokeRect(RectMake(0, 0, 100, 100), RGBA(1, 0, 0, 1));
  PopVertexBuffer;

  buffer[1] := CreateVertexBuffer(true);
  PushVertexBuffer(buffer[1]);
  StrokeRect(RectMake(100, 100, 100, 100), RGBA(0, 0, 1, 1));
  PopVertexBuffer;

  while IsRunning do
    begin
      ClearBackground;
      DrawBuffer(buffer[0]);
      DrawBuffer(buffer[1]);
      SwapBuffers;
    end;

  QuitApp;
end.