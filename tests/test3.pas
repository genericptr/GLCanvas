{$mode objfpc}
{$assertions on}

program Test3;
uses
  CThreads, GeometryTypes, GLCanvas, GLPT;

const
  window_size_width = 600;
  window_size_height = 600;

var
  texture: TTexture;
begin
  SetupCanvas(window_size_width, window_size_height);

  texture := TTexture.Create('deer.png');

  while IsRunning do
    begin
      ClearBackground;
      DrawTexture(texture, RectMake(50, 50, texture.GetSize));
      SwapBuffers;
    end;

  QuitApp;
end.