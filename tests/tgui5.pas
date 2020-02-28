{$mode objfpc}
{$modeswitch nestedprocvars}
{$assertions on}

program tgui5;
uses
  CThreads, SysUtils, FreeTypeH,
  VectorMath, GLFreeTypeFont, GLCanvas, GLGUI, GLPT, GL, GeometryTypes;

procedure EventCallback(event: pGLPT_MessageRec);
begin
  if PollWindowEvents(event) then
    exit;
end; 

var
  font: TGLFreeTypeFont;

procedure LoadFreeType;
var
  lib: PFT_Library;
begin
  Assert(FT_Init_FreeType(lib) = 0, 'FT_Init_FreeType');
  font := TGLFreeTypeFont.Create(lib, '/System/Library/Fonts/Avenir.ttc');
  font.Render(36);
  FT_Done_FreeType(lib);
end;

procedure SetupGUI;
var
  window: TWindow;
begin
  // https://learnopengl.com/In-Practice/Text-Rendering
  // https://github.com/graemeg/freepascal/blob/master/packages/fcl-image/src/freetype.pp
  // https://www.sccs.swarthmore.edu/users/03/sven/freetype_tut/
  // https://www.freetype.org/freetype2/docs/tutorial/step1.html#section-3
  LoadFreeType;

  // TODO: how should we do this??
  MainPlatformWindow := GLCanvasState.window;  

  window := TWindow.Create(TWindow.ScreenRect);
  window.SetMoveableByBackground(false);
  window.MakeKeyAndOrderFront;
end;

begin
  SetupCanvas(512, 512, @EventCallback);
  SetupGUI;

  while IsRunning do
    begin
      ClearBackground;
      UpdateWindows;
      SetViewTransform(0, 0, 1);
      FillRect(RectMake(0, 0, 512, 512), RGBA(0.1, 0.1, 1, 0.25));
      DrawText(font, 'Hello World', V2(20, 0));
      SwapBuffers;
    end;

  QuitApp;
end.