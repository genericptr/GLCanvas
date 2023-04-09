{
    Copyright (c) 2023 by Ryan Joseph

    GLCanvas Test #28
    
    Tests deleting frame buffers
}
{$mode objfpc}
{$modeswitch multihelpers}

program Test28;
uses
  SysUtils, GLCanvas;

const
  window_size_width = 512;
  window_size_height = 512;

var
  frameBuffer: TFrameBuffer;
  i: integer;
begin
  SetupCanvas(window_size_width, window_size_height);

  // create frame buffers and delete them
  for i := 1 to 100 do
    begin
      frameBuffer := TFrameBuffer.Create(256);
      frameBuffer.Push;
        FillRect(frameBuffer.Bounds, TColor.Black);
      frameBuffer.Pop;
      frameBuffer.Free;
    end;

  // create the real frame buffer and ensure the IDs are correct (should be 1)
  frameBuffer := TFrameBuffer.Create(256);
  frameBuffer.Push;
    FillRect(frameBuffer.Bounds, TColor.SandyBrown);
  frameBuffer.Pop;

  Assert(frameBuffer.BufferID = 1, 'Frame buffer ID should be 1 (got '+frameBuffer.BufferID.ToString+')');
  Assert(frameBuffer.TextureID = 1, 'Frame buffer texture should be 1 (got '+frameBuffer.TextureID.ToString+')');

  while IsRunning do
    begin
      FillRect(GetViewPort, TColor.Red);
      DrawTexture(frameBuffer.Texture, RectMake(100, 100, 100, 100));
      SwapBuffers;
    end;

  QuitApp;
end.