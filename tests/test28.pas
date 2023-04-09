{
    Copyright (c) 2023 by Ryan Joseph

    GLCanvas Test #28
    
    Tests deleting frame buffers
}
{$mode objfpc}
{$modeswitch multihelpers}

program Test10;
uses
  GLCanvas;

const
  window_size_width = 512;
  window_size_height = 512;
  cell_size = 512 / 4;

var
  frameBuffer: TFrameBuffer;
begin
  SetupCanvas(window_size_width, window_size_height);

  // Set up frame buffer
  frameBuffer := TFrameBuffer.Create(256);
  frameBuffer.Push;
    FillRect(frameBuffer.Bounds, TColor.SandyBrown);
  frameBuffer.Pop;

  while IsRunning do
    begin
      FillRect(GetViewPort, TColor.Red);
      DrawTexture(frameBuffer.Texture, RectMake(100, 100, 100, 100));
      SwapBuffers;
    end;

  QuitApp;
end.