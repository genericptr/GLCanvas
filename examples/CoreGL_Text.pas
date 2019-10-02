{$mode objfpc}
{$assertions on}

program CoreGL_Text;
uses
  GLPT, SysUtils, GLCanvas;

function GetDataFile (name: string): string; inline;
begin
  result := GLPT_GetBasePath+name;
end;

procedure EventCallback(event: pGLPT_MessageRec);
begin
  case event^.mcode of
    GLPT_MESSAGE_KEYPRESS:
      begin
        if event^.params.keyboard.keycode = GLPT_KEY_ESCAPE then
          GLPT_SetWindowShouldClose(event^.win, true);
      end;
  end;
end; 

const
  window_size_width = 600;
  window_size_height = 600;

var
  font: TBitmapFont;
  input: ansistring;
begin
  SetupCanvas(window_size_width, window_size_height, @EventCallback);
  font := TBitmapFont.Create('/Developer/Projects/FPC/NewEngine/Resources/fonts/coders_crux');
  SetViewTransform(0, 0, 1.0);
  input := '>';
  while IsRunning do
    begin
      ClearBackground;
      // TODO: make an overload that uses the global font (removes first param)
      // and make SetDefaultFont(font) function
      DrawText(font, input, 0, RectMake(20, 20, window_size_width - 20 * 2, 10000));
      SwapBuffers;
      write('prompt: ');
      readln(input);
    end;

  QuitApp;
end.