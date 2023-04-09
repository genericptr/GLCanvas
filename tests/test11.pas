{
    Copyright (c) 2021 by Ryan Joseph

    GLCanvas Test #11
    
    Tests blending modes
}
{$mode objfpc}

program Test11;
uses
  GLCanvas;

const
  window_size_width = 512;
  window_size_height = 512;

var
  textures: array[0..3] of TTexture;
begin
  SetupCanvas(window_size_width, window_size_height);

  textures[0] := TTexture.Create('orc.png');
  textures[1] := TTexture.Create('dwarf.png');
  textures[2] := TTexture.Create('human.png');
  textures[3] := TTexture.Create('centaur.png');

  while IsRunning do
    begin
      ClearBackground;

      PushBlendMode(TBlendingFactor.ONE, TBlendingFactor.ONE_MINUS_DST_COLOR);
        DrawTexture(textures[0], GetViewPort);
        DrawTexture(textures[1], GetViewPort);
        DrawTexture(textures[2], GetViewPort);
        DrawTexture(textures[3], GetViewPort);
        FlushDrawing;
      PopBlendMode;

      SwapBuffers;
    end;

  QuitApp;
end.