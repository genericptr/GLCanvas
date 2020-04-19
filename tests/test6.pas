{$mode objfpc}
{$assertions on}

program Test6;
uses
  // rtl
  CThreads, ExtraTypes, VectorMath,
  GLCanvas, GLPT;

const
  window_size_width = 512;
  window_size_height = 512;

type
  TPixelMatrix = specialize TFPGMatrix<TImagePixel>;

var
  pix: TPixelMatrix;
  texture: TTexture;
  x, y: integer;
begin
  SetupCanvas(window_size_width, window_size_height);

  // TODO: make a TTexture subclass which handles this matrix also
  // then we can include the matrix class in GLCanvas 
  pix := TPixelMatrix.Create(16, 16);

  for y := 0 to 4 do
  for x := 0 to 4 do
    pix[x,y] := RGBA(1,0,0,1);

  texture := TTexture.Create(pix.width, pix.height, pix.data);
  // todo: we need to bind and update the texture now
  // since binding happens before drawing can we add a note
  // to update before drawing so we don't double bind
  texture.Load;

  // reload a part of the texture
  {
    PushTextureInternal(id, 0);
    glTexSubImage2D
    PopTextureInternal;
  }
  texture.Reload(RectMake(0, 0, 4, 4));

  while IsRunning do
    begin
      ClearBackground;
      DrawTexture(texture, GetViewPort);
      SwapBuffers;
    end;

  QuitApp;
end.