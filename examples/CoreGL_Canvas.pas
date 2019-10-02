{$mode objfpc}
{$assertions on}

program CoreGL_Canvas;
uses
  CThreads, SysUtils, GLCanvas, GLPT;

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

var
  nbFrames: integer = 0;
  lastTime: double = 0;

procedure PrintFPS;
var
  currentTime: double;
  fps: string;
begin
  currentTime := GLPT_GetTime;
  inc(nbFrames);
  if currentTime - lastTime >= 1 then
    begin
      fps := format('[FPS: %3.0f]', [nbFrames / (currentTime - lastTime)]);
      writeln(fps);
      nbFrames := 0;
      lastTime := GLPT_GetTime;
    end;
end;

const
  window_size_width = 600;
  window_size_height = 600;

var
  sheet: TTextureSheet;
  font: TBitmapFont;
  i, x, y: integer;
  startTime: longint;
begin
  
  // TODO: make texture switching work in the renderer
  
  // TODO: options - resize changes viewport
  SetupCanvas(window_size_width, window_size_height, @EventCallback);
  // TODO: can we make an "atlas" which is both sheet/pack?
  sheet := TTextureSheet.Create('/Users/ryanjoseph/Documents/metroid/zero.png', SizeMake(16, 16));
  font := TBitmapFont.Create('/Developer/Projects/FPC/NewEngine/Resources/fonts/coders_crux');

  SetViewTransform(0, 0, 1.0);

  while IsRunning do
    begin
      //PrintFPS;
      ClearBackground;
      startTime := TimeSinceNow;

      for i := 0 to 4000 do
        DrawTexture(sheet[
          Rand(0, trunc(sheet.GetTableSize.Width) - 1), 
          Rand(0, trunc(sheet.GetTableSize.Height) - 1)], 
          RectMake(Rand(0, window_size_width), Rand(0, window_size_height), 64, 64));

      // TODO: make an overload that uses the global font (removes first param)
      // and make SetDefaultFont(font) function
      DrawText(font, 'hello world', SizeMake(20, 20), 1.0);
      
      SwapBuffers;
      //writeln('elapsed: ', TimeSinceNow - startTime);
    end;

  QuitApp;
end.