{
    Copyright (c) 2021 by Ryan Joseph

    GLCanvas Test #8
    
    Testing bitmap image class
}
{$mode objfpc}

program Test8;
uses
  CThreads, GeometryTypes, VectorMath,
  GLCanvas, GLPT;

const
  window_size_width = 512;
  window_size_height = 512;

var
  img,
  tile: TPNGImage;
  texture: TTexture;
  x, y, i: integer;
begin
  SetupCanvas(window_size_width, window_size_height);

  img := TPNGImage.Create('orc.png');

  // fill transparent with color
  for i := 0 to img.Count - 1 do
    if img.data[i].a = 0 then
      img.data[i] := TColor.PeachPuff;

  // blit other texture
  tile := TPNGImage.Create('16x16.png');
  //img.Blit(tile, TBlendMode.Multiply, 2, 2);
  // TODO: wraps! constrain to width
  img.Blit(tile, TBlendMode.ColorDodge, 18, 2);
  tile.Free;

  {
    1) blit to dest TRects
    2) copy to rect
    3) load tga
    4) don't copy/retain TImage input for TTexture.Create
    5) Blit with tinting/opacity

    😡 other tests:

    - loading/unloading/freeing (texture manager implementation?)
    - texture composite
    - rendering to frame buffers

  }

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