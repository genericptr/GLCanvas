{$mode objfpc}
{$assertions on}


// compile freetype for ios
// https://stackoverflow.com/questions/6425643/compiling-freetype-for-iphone

program Test4;
uses
  CThreads, 
  VectorMath, GLFreeTypeFont, GLCanvas, GLPT;

const
  window_size_width = 600;
  window_size_height = 600;


procedure LoadFreeType;
var
  font: TGLFreeTypeFont;
begin
  Chdir(GLPT_GetBasePath+'/tests');
  font := TGLFreeTypeFont.Create('Avenir.ttc');
  font.Render(trunc(36 / 0.5));
  { make this the system font }
  SetActiveFont(font);
  { call this once we're done using loading fonts }
  TGLFreeTypeFont.FreeLibrary;
end;

begin
  SetupCanvas(window_size_width, window_size_height);
  LoadFreeType;

  while IsRunning do
    begin
      ClearBackground;
      DrawText('Hello World', V2(50, 50), RGBA(0.1, 0.1, 1, 1), 0.5);
      SwapBuffers;
    end;

  QuitApp;
end.