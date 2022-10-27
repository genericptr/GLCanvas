{
    Copyright (c) 2021 by Ryan Joseph

    GLCanvas Test #12
    
    Testing image composite textures
}
{$mode objfpc}

program Test12;
uses
  GeometryTypes, VectorMath,
  GLCanvas, GLPT;

const
  window_size_width = 512;
  window_size_height = 512;
  cell_size = 64;

var
  output: TImage4b;
  img: array[0..3] of TPNGImage;
  texture: TTexture;
  x, y: integer;
begin
  SetupCanvas(window_size_width, window_size_height);

  output := TImage4b.Create(cell_size * 2, cell_size * 2);

  img[0] := TPNGImage.Create('orc.png');
  img[1] := TPNGImage.Create('dwarf.png');
  img[2] := TPNGImage.Create('human.png');
  img[3] := TPNGImage.Create('centaur.png');

  for y := 0 to 1 do
  for x := 0 to 1 do
    output.Blit(img[x + y * 2], x * cell_size, y * cell_size);

  texture := TTexture.Create(output);

  output.Free;
  img[0].Free;
  img[1].Free;
  img[2].Free;
  img[3].Free;

  while IsRunning do
    begin
      ClearBackground;
      DrawTexture(texture, GetViewPort);
      SwapBuffers;
    end;

  QuitApp;
end.