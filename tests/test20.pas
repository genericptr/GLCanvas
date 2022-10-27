{
    Copyright (c) 2022 by Ryan Joseph

    GLCanvas Test #20
    
    Test image slicing/saving
}
{$mode objfpc}

program Test20;
uses
  GeometryTypes, VectorMath, GLCanvas;

var
  pngImage: TPNGImage;
  cell: TPNGImage;
  rgbImage: TImage3b;
begin
  pngImage := TPNGImage.Create('/Users/ryanjoseph/Desktop/Projects/Games/Platformer/resources/tiles.png');
  
  cell := TPNGImage(pngImage.Copy(1, 1, 16, 16));
  cell.SaveToFile('/Users/ryanjoseph/Desktop/cell.png', TFileFormat.PNG);
  cell.Free;

  rgbImage := TImage3b.Create(10, 10);
  rgbImage.Fill([255, 0, 0]);
  rgbImage.SaveToFile('/Users/ryanjoseph/Desktop/rgb.jpg', TFileFormat.JPEG);
  rgbImage.Free;
end.