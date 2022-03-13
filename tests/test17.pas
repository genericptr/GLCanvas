{
    Copyright (c) 2022 by Ryan Joseph

    GLCanvas Test #17
    
    Testing texture compositing
}
{$mode objfpc}
{$modeswitch arrayoperators}

program test17;
uses
  CThreads, SysUtils, VectorMath, GeometryTypes,
  GLCanvas;

var
  texture: TTextureComposite;
  images: array of TImage = nil;
  image: TImage;
  i, j: integer;
begin
  SetupCanvas(480, 480);

  // TODO: make a bunch of random sized TImage's and use those for composite

  // create composite texture using images
  j := 0;
  for i := 0 to 32 do
    begin
      if j = 4 then
        begin
          case Rand(4) of
            0: image := TPNGImage.Create('centaur.png');
            1: image := TPNGImage.Create('dwarf.png');
            2: image := TPNGImage.Create('human.png');
            3: image := TPNGImage.Create('orc.png');
          end;
          j := 0;
        end
      else
        begin
          image := TImage.Create(Rand(32, 128), Rand(32, 128));
          image.Fill(TImage.TPixel.Create(Rand(255),Rand(255),Rand(255),255));
        end;

      images += [image];
      inc(j);
    end;

  //texture := TTextureComposite.Create(128, ['centaur.png', 'dwarf.png', 'human.png', 'orc.png']);
  texture := TTextureComposite.Create(480, images);

  while IsRunning do
    begin
      ClearBackground;
      DrawTexture(texture, RectMake(0, GetWindowSize));
      SwapBuffers;
    end;

  QuitApp;
end.