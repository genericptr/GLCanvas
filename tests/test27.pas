{
    Copyright (c) 2023 by Ryan Joseph

    GLCanvas Test #27
    
    Tests slicing textures
}
{$mode objfpc}

program Test27;
uses
  GLCanvas;

const
  window_size_width = 512;
  window_size_height = 512;

var
  texture: TTexture;
  slice: array[0..1] of TTexture;
begin
  SetupCanvas(window_size_width, window_size_height);

  texture := CreateTexture('centaur.png');

  // Slice main texture horizontally
  slice[0] := texture.Slice(RectMake(0, 0, texture.Width / 2, texture.Height));

  // Slice sub texture vertically
  slice[1] := slice[0].Slice(RectMake(0, 0, slice[0].Width, slice[0].Height / 2));

  SetViewTransform(0, 0, 3);

  while IsRunning do
    begin
      DrawTexture(texture, RectMake(0, 0, texture.Size));
      DrawTexture(slice[0], RectMake(50, 50, slice[0].Size));
      DrawTexture(slice[1], RectMake(100, 50, slice[1].Size));
      SwapBuffers;
    end;

  // Slices are owned the main texture so we only need to free once
  texture.Free;

  QuitApp;
end.