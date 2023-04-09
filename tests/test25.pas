{
    Copyright (c) 2022 by Ryan Joseph

    GLCanvas Test #25
    
    Tests blitting frame buffers to texture region
}
{$mode objfpc}
{$modeswitch multihelpers}

program Test25;
uses
  GLCanvas;

const
  window_size_width = 512;
  window_size_height = 512;
  cell_size = 512 / 4;

var
  textures: array[0..3] of TTexture;
  output: TTexture;
  frameBuffer: TFrameBuffer;
  x, y: integer;
begin
  SetupCanvas(window_size_width, window_size_height);

  textures[0] := TTexture.Create('orc.png');
  textures[1] := TTexture.Create('dwarf.png');
  textures[2] := TTexture.Create('human.png');
  textures[3] := TTexture.Create('centaur.png');

  // Set up frame buffer
  frameBuffer := TFrameBuffer.Create(256);
  frameBuffer.Push;
    // Fill the entire buffer
    FillRect(GetViewPort, TColor.Blue);
    FlushDrawing;
    // Clip drawing to a sub-region
    PushClipRect(RectMake(0, 0, 100, 100));
    FillRect(frameBuffer.Bounds, TColor.SandyBrown);
    for y := 0 to 1 do
    for x := 0 to 1 do
      DrawTexture(textures[x + y * 2], RectMake(x * cell_size, y * cell_size, cell_size, cell_size));
    FlushDrawing;
    PopClipRect;
  frameBuffer.Pop;

  // Blit the frame buffer to a sub-region of another texture
  output := TTexture.Create(frameBuffer.Size, nil);
  frameBuffer.Blit(output, RectMake(0, 0, frameBuffer.Width / 2, frameBuffer.Height / 2));

  while IsRunning do
    begin
      FillRect(GetViewPort, TColor.Red);
      DrawTexture(output, GetViewPort.FlipY);
      SwapBuffers;
    end;

  QuitApp;
end.