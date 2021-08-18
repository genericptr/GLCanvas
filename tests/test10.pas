{
    Copyright (c) 2021 by Ryan Joseph

    GLCanvas Test #10
    
    Testing frame buffers
}
{$mode objfpc}
{$modeswitch multihelpers}

program Test10;
uses
  CThreads, GeometryTypes, VectorMath,
  GLPT, GLCanvas;

const
  window_size_width = 512;
  window_size_height = 512;
  cell_size = 100;

var
  textures: array[0..3] of TTexture;
  frameBuffer: TFrameBuffer;
  x, y: integer;
begin
  SetupCanvas(window_size_width, window_size_height);

  textures[0] := TTexture.Create('orc.png');
  textures[1] := TTexture.Create('dwarf.png');
  textures[2] := TTexture.Create('human.png');
  textures[3] := TTexture.Create('centaur.png');

  { IMPORTANT: If we don't make the frame buffer the same size as the window then
    we need to push a new projection matrix before drawing. }

  frameBuffer := TFrameBuffer.Create(GetWindowSize);
  frameBuffer.Push;
    FillRect(frameBuffer.Bounds, TColor.SandyBrown);
    for y := 0 to 1 do
    for x := 0 to 1 do
      DrawTexture(textures[x + y * 2], RectMake(x * cell_size, y * cell_size, cell_size, cell_size));
  frameBuffer.Pop;

  while IsRunning do
    begin
      FillRect(GetViewPort, TColor.Red);
      DrawTexture(frameBuffer.Texture, frameBuffer.Bounds);
      SwapBuffers;
    end;

  QuitApp;
end.