{
    Copyright (c) 2021 by Ryan Joseph

    GLCanvas Test #9
    
    Testing texture manager
}
{$mode objfpc}

program Test9;
uses
  GLCanvas;

const
  window_size_width = 512;
  window_size_height = 512;

var
  textures: array[0..3] of TTexture;
  currentTexture: integer;

procedure EventCallback(event: TEvent);
begin
  case event.EventType of
    TEventType.KeyDown:
      case event.KeyCode of
        KEY_SPACE:
          begin
            currentTexture += 1;
            if currentTexture > high(textures) then
              currentTexture := 0;
          end;
      end;
  end;
end;

begin
  SetupCanvas(window_size_width, window_size_height, @EventCallback);
  SetWindowTitle('Press space key to cycle...');

  currentTexture := 0;
  textures[0] := TTexture.Create('orc.png');
  textures[1] := TTexture.Create('dwarf.png');
  textures[2] := TTexture.Create('human.png');
  textures[3] := TTexture.Create('centaur.png');

  { TODO: if we try to create too many textures you need to unload others
    we need a way to know how many textures are created and a master
    table which we can unload others from. this isn't part of the API yet. }

  while IsRunning do
    begin
      ClearBackground;
      DrawTexture(textures[currentTexture], GetViewPort);
      SwapBuffers;
    end;

  QuitApp;
end.