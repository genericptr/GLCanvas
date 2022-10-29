{
    Copyright (c) 2022 by Ryan Joseph

    GLCanvas Test #20
    
    Test image slicing/saving
}
{$mode objfpc}

program Test20;
uses
  GLCanvas;

var
  pngImage: TPNGImage;
  cell: TPNGImage;
  rgbImage: TImage3b;
begin
  pngImage := TPNGImage.Create('deer.png');
  
  // copy part of image and save to disk
  cell := TPNGImage(pngImage.Copy(0, 0, pngImage.Width div 2, pngImage.Height div 2));
  cell.SaveToFile('cell.png', TFileFormat.PNG);
  cell.Free;

  // create a bitmap from raw data and save to disk
  rgbImage := TImage3b.Create(32, 32);
  with rgbImage do
    begin
      Fill([255, 0, 0]);
      // TODO: Save to file is producing garbled output now
      SaveToFile('rgb.jpg', TFileFormat.JPEG);
      SaveToFile('rgb.png', TFileFormat.PNG);
      Free;
    end;
end.