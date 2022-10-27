{
    Copyright (c) 2021 by Ryan Joseph

    GLCanvas Test #10
    
    Testing frame buffers
}
{$mode objfpc}
{$modeswitch multihelpers}

program Test10;
uses
  GeometryTypes, VectorMath, GLCanvas;

const
  window_size_width = 512;
  window_size_height = 512;
  cell_size = 512 / 4;

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

  frameBuffer := TFrameBuffer.Create(256);
  frameBuffer.Push;
    FillRect(frameBuffer.Bounds, TColor.SandyBrown);
    for y := 0 to 1 do
    for x := 0 to 1 do
      DrawTexture(textures[x + y * 2], RectMake(x * cell_size, y * cell_size, cell_size, cell_size));
  frameBuffer.Pop;


  while IsRunning do
    begin
      FillRect(GetViewPort, TColor.Red);
      for y := 0 to 1 do
      for x := 0 to 1 do
        DrawTexture(frameBuffer.Texture, RectMake(x * cell_size * 2, y * cell_size * 2, frameBuffer.Width, frameBuffer.Height));
      SwapBuffers;
    end;

  QuitApp;
end.