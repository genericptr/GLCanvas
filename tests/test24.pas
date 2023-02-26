{
    Copyright (c) 2023 by Ryan Joseph

    GLCanvas Test #24
    
    Test blitting frame buffer regions into textures
}
{$mode objfpc}
{$modeswitch implicitfunctionspecialization}

program Test24;
uses
  SysUtils, Classes, GLCanvas;

const
  window_size_width = 500;
  window_size_height = 500;

var
  sourceRect: TRect;
  destOffset: TVec2;
  target: TTexture;
  frameBuffer: TFrameBuffer;

procedure UpdateBlit;
var
  image: TImage;
begin
  // TODO: how can we clear the target texture?
  image := TImage.Create(target.Width, target.height);
  image.Fill(TColor.White);

  target.LoadIfNeeded;
  target.Reload(image.Data);

  image.Free;
  
  frameBuffer.Blit(target, sourceRect, destOffset);
end;

procedure EventCallback(event: TEvent);
begin
  case event.EventType of
    TEventType.KeyDown:
      case event.KeyCode of
        KEY_LEFT:
          begin
            // TODO: should have IsShiftDown modifier
            if ssAlt in event.KeyboardModifiers then
              destOffset.x -= 1
            else
              sourceRect.origin.x -= 1;
            UpdateBlit;
          end;
        KEY_RIGHT:
          begin
            if ssAlt in event.KeyboardModifiers then
              destOffset.x += 1
            else
              sourceRect.origin.x += 1;
            UpdateBlit;
          end;
        KEY_UP:
          begin
            if ssAlt in event.KeyboardModifiers then
              destOffset.y -= 1
            else
              sourceRect.origin.y -= 1;
            UpdateBlit;
          end;
        KEY_DOWN:
          begin
            if ssAlt in event.KeyboardModifiers then
              destOffset.y += 1
            else
              sourceRect.origin.y += 1;
            UpdateBlit;
          end;
      end;
  end;
end;

var
  image: TTexture;
  rect: TRect;
begin
  SetupCanvas(window_size_width, window_size_height, @EventCallback);

  image := TTexture.Create('checkers.png');

  frameBuffer := TFrameBuffer.Create(64);
  frameBuffer.Push;
    DrawTexture(image, frameBuffer.Bounds);
  frameBuffer.Pop;

  // Create the target texture
  target := TTexture.Create(frameBuffer.Size, nil);
  // TODO: flipped texture property for DrawTexture calls
  //target.Flipped := true;

  destOffset := V2(16, 16);
  sourceRect := RectMake(0, 0, 32, 32);
  UpdateBlit;

  SetWindowTitle('Use arrow keys to move blitting area');

  while IsRunning do
    begin
      ClearBackground;
      
      // Dest
      rect := RectMake(100, 100, target.Size);
      DrawTexture(target, rect, RectMake(0,1,1,-1));
      StrokeRect(rect, TColor.Black);
      StrokeRect(RectMake(rect.origin + destOffset, sourceRect.size), TColor.Black);

      // Source
      rect := RectMake(300, 100, frameBuffer.Size);
      DrawTexture(frameBuffer.Texture, rect);
      StrokeRect(rect, TColor.Black);
      StrokeRect(RectMake(rect.origin + sourceRect.origin, sourceRect.size), TColor.Black);
      SwapBuffers;
    end;

  QuitApp;
end.