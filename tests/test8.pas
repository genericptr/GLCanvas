{
    Copyright (c) 2021 by Ryan Joseph

    GLCanvas Test #8
    
    Tests bitmap image class
}
{$mode objfpc}

program Test8;
uses
  GLCanvas;

const
  window_size_width = 512;
  window_size_height = 512;

var
  img,
  tile: TPNGImage;
  texture: TTexture;
  i: integer;
begin
  SetupCanvas(window_size_width, window_size_height);

  img := TPNGImage.Create('orc.png');

  // fill transparent with color
  for i := 0 to img.Count - 1 do
    if img.data[i].a = 0 then
      img.data[i] := TColor.PeachPuff;

  // blit other texture
  tile := TPNGImage.Create('16x16.png');
  // TODO: blitting wraps around! constrain to size
  // TODO: use source/dest rects instead of offsets
  img.Blit(tile, 8, 8, TBlendMode.ColorDodge);
  tile.Free;

  // TODO: blend with color directly
  //img.Blend(RectMake(0,0,16,16), RGBA(1, 0, 0, 1), TBlendMode.Multiply);

  texture := TTexture.Create(img);

  img.Free;

  while IsRunning do
    begin
      ClearBackground;
      DrawTexture(texture, GetViewPort);
      SwapBuffers;
    end;

  QuitApp;
end.