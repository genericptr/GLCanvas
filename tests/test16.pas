{
    Copyright (c) 2022 by Ryan Joseph

    GLCanvas Test #16
    
    Testing frame buffer blitting
}
{$mode objfpc}
{$modeswitch multihelpers}

program Test16;
uses
  CThreads, SysUtils, GeometryTypes, VectorMath,
  GLCanvas;

const
  WINDOW_SIZE = 500;
  CELL_SIZE = 8;

var
  texture: TTexture;
  input, output: TFrameBuffer;
begin
  SetupCanvas(WINDOW_SIZE, WINDOW_SIZE);

  // Create the source texture
  texture := TTexture.Create('checkers.png');

  // Create the input buffer and draw the source texture for sampling
  input := TFrameBuffer.Create(texture.Size);
  input.Push;
    ClearBackground;
    DrawTexture(texture, input.Bounds);
  input.Pop;

  // Create the output buffer
  output := TFrameBuffer.Create(WINDOW_SIZE);
  output.Flipped := false;
  output.Push;
    ClearBackground;
  output.Pop;

  while IsRunning do
    begin
      // Blit the input to output
      input.Blit(output, 
                 RectMake(CELL_SIZE * Rand(2), CELL_SIZE * Rand(2), CELL_SIZE, CELL_SIZE), 
                 RectMake(Rand(WINDOW_SIZE), Rand(WINDOW_SIZE), CELL_SIZE, CELL_SIZE));

      // Blir the output texture to screen
      output.Blit(nil, output.Bounds, GetViewPort);

      SetWindowTitle('FPS: '+GetFPS.ToString);
      SwapBuffers;
    end;

  QuitApp;
end.