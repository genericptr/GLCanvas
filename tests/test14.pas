{
    Copyright (c) 2021 by Ryan Joseph

    GLCanvas Test #14
    
    Test updating textures every frame
}
{$mode objfpc}

program Test14;
uses
  SysUtils, GLCanvas;

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
  pix.Fill(TImagePixel.Create(255, 255, 255, 255));

  texture := TTexture.Create(pix.width, pix.height, nil);
  texture.Load;
  
  while IsRunning do
    begin
      ClearBackground;

      pix[Rand(pix.Width), Rand(pix.Height)] := TImagePixel.Create(Rand(255), Rand(255), Rand(255), 255);
      texture.Reload(pix.List^);

      DrawTexture(texture, GetViewPort);

      SetWindowTitle('FPS '+GetFPS.ToString);
      SwapBuffers;
    end;

  QuitApp;
end.