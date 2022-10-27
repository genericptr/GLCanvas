{
    Copyright (c) 2019 by Ryan Joseph

    GLCanvas Test #6
    
    Tests loading textures from memory

    TODO: this example is deprecated in favor of TImage
}
{$mode objfpc}
{$assertions on}

program Test6;
uses
  GeometryTypes, VectorMath,
  GLCanvas, GLPT;

const
  window_size_width = 512;
  window_size_height = 512;

type
  TRGBA_U8_PixelMatrix = specialize TFPGMatrix<TImagePixel>;
  TRGBA_F32_PixelMatrix = specialize TFPGMatrix<TColor>;

var
  pix: TRGBA_U8_PixelMatrix;
  texture: TTexture;
  x, y: integer;
begin
  SetupCanvas(window_size_width, window_size_height);

  pix := TRGBA_U8_PixelMatrix.Create(16, 16);
  pix.Fill(TImagePixel.Create(255, 0, 0, 255));

  // make a random texture
  RandSeed := 100;
  for y := 0 to pix.height - 1 do
  for x := 0 to pix.width - 1 do
    begin
      if Rand(100) < 50 then
        continue;
      pix[x,y] := TImagePixel.Create(0, 255, 0, 255);
    end;

  texture := TTexture.Create(pix.width, pix.height, pix.List^);

  // reload a part of the texture
  {
    PushTextureInternal(id, 0);
    glTexSubImage2D
    PopTextureInternal;
  }
  //texture.Reload(RectMake(0, 0, 4, 4));

  while IsRunning do
    begin
      ClearBackground;
      DrawTexture(texture, GetViewPort);
      SwapBuffers;
    end;

  QuitApp;
end.