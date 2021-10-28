{
    Copyright (c) 2021 by Ryan Joseph

    GLCanvas Test #15
    
    Tests different texture formats

    TODO: make sure textures can use other color formats

    https://community.khronos.org/t/updating-textures-per-frame/75020/3
}
{$mode objfpc}
{$assertions on}

program Test15;
uses
  CThreads, SysUtils, GeometryTypes, VectorMath,
  GLCanvas, GLPT;

const
  window_size_width = 500;
  window_size_height = 500;

type
  TRGBA_U8_PixelMatrix = specialize TFPGMatrix<TImagePixel>;
  TRGBA_F32_PixelMatrix = specialize TFPGMatrix<TColor>;

var
  pix: TRGBA_U8_PixelMatrix;
  texture: TTexture;
begin
  SetupCanvas(window_size_width, window_size_height, nil, [TCanvasOption.VSync]);

  pix := TRGBA_U8_PixelMatrix.Create(100, 100);
  pix.Fill(TImagePixel.Create(255, 0, 0, 255));

  texture := TTexture.Create(pix.width, pix.height, pix.List^, [
    TTextureImage.ClampToEdge,
    TTextureImage.NearestNeighbor, 
    TTextureImage.BGRA,
    TTextureImage.UnsignedByte
  ]);

  while IsRunning do
    begin
      ClearBackground;
      DrawTexture(texture, GetViewPort);
      SwapBuffers;
    end;

  QuitApp;
end.