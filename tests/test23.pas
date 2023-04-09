{
    Copyright (c) 2023 by Ryan Joseph

    GLCanvas Test #23
    
    Tests image rotations
}
{$mode objfpc}
{$modeswitch implicitfunctionspecialization}

program Test23;
uses
  SysUtils, GLCanvas;

const
  window_margin = 0;
  window_size_width = 500;
  window_size_height = 500;
  segments = 320 / 160;

var
  image: TPNGImage;
  texture: TTexture;
  angle: Float = 0;

procedure RotateTexture;
var
  newImage: TPNGImage.TFormat;
begin
  newImage := image.Rotate(angle);
  texture.Reload(newImage.data);
  newImage.Free;
end;

procedure EventCallback(event: TEvent);
begin
  case event.EventType of
    TEventType.KeyDown:
      case event.KeyCode of
        KEY_LEFT:
          begin
            angle -= segments;
            RotateTexture;
          end;
        KEY_RIGHT:
          begin
            angle += segments;
            RotateTexture;
          end;
      end;
  end;
end;

begin
  SetupCanvas(window_size_width + window_margin * 2, window_size_height + window_margin * 2, @EventCallback);

  SetWindowTitle('Use left/right arrows keys to rotate image');

  image := TPNGImage.Create('16x16.png');
  texture := TTexture.Create(image);

  while IsRunning do
    begin
      ClearBackground;
      DrawTexture(texture, RectMake(100, 100, 256, 256));
      SwapBuffers;
    end;

  QuitApp;
end.