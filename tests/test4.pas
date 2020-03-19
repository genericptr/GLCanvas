{$mode objfpc}
{$assertions on}


// compile freetype for ios
// https://stackoverflow.com/questions/6425643/compiling-freetype-for-iphone

program Test4;
uses
  CThreads, FreeTypeH, 
  VectorMath, GLFreeTypeFont, GLCanvas, GLPT;

const
  window_size_width = 600;
  window_size_height = 600;

var
  font: TGLFreeTypeFont;

procedure LoadFreeType;
var
  lib: PFT_Library;
begin
  Assert(FT_Init_FreeType(lib) = 0, 'FT_Init_FreeType');
  font := TGLFreeTypeFont.Create(lib, 'Avenir.ttc');
  font.Render(trunc(36 / 0.5));
  FT_Done_FreeType(lib);
end;

begin
  SetupCanvas(window_size_width, window_size_height);
  LoadFreeType;

  while IsRunning do
    begin
      ClearBackground;
      DrawText(font, 'Hello World', V2(50, 50), RGBA(0.1, 0.1, 1, 1), 0.5);
      SwapBuffers;
    end;

  QuitApp;
end.