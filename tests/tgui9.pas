{$mode objfpc}
{$assertions on}

program tgui9;
uses
  CThreads, FreeTypeH, GLFreeType, GLFreeTypeFont, SysUtils, VectorMath, GeometryTypes,
  GLCanvas, GLGUI, GLPT, GL;

procedure EventCallback(event: pGLPT_MessageRec);
begin
  if PollWindowEvents(event) then
    exit;
end; 

var
  font: TGLFreeTypeFont;
  buttonImage: TTextureSheet;

type
  TCustomCheckBox = class (TCheckBox)
    procedure Draw; override;
  end;

procedure TCustomCheckBox.Draw;
begin
  //StrokeRect(GetBounds, RGBA(0, 1));

  Draw9PartImage(buttonImage, GetButtonFrame);

  if IsPressed then
    FillRect(GetButtonFrame, RGBA(0.1, 0.1, 1, 0.2));
  //if IsChecked then
  //  FillOval(GetButtonFrame.Inset(4, 4), RGBA(1, 0, 0, 0.85));

  if IsChecked then
    DrawText(font, '*', GetButtonFrame.Inset(4, 4).origin, RGBA(0));
   
  inherited;
end;

procedure LoadFreeType;
var
  lib: PFT_Library;
begin
  Assert(FT_Init_FreeType(lib) = 0, 'FT_Init_FreeType');
  font := TGLFreeTypeFont.Create(lib, '/System/Library/Fonts/Geneva.dfont');
  // TODO: √ doesn't work? outside of ansi range?
  font.Render(12, FREETYPE_ANSI_CHARSET + '√');
  FT_Done_FreeType(lib);
end;

procedure SetupGUI;
var
  window: TWindow;
  i: integer;
begin
  LoadFreeType;

  buttonImage := TTextureSheet.Create('square_button_small.png', 3);

  // TODO: how should we do this??
  MainPlatformWindow := GLCanvasState.window;  

  window := TWindow.Create(TWindow.ScreenRect);
  window.SetMoveableByBackground(false);
  window.MakeKeyAndOrderFront;

  for i := 0 to 3 do
    begin
      window.AddSubview(
        TCustomCheckBox.Create(RectMake(50, 50 + i * 20, 16, 16), 'My Button'+IntToStr(i), font)
      );
    end;
end;

begin
  SetupCanvas(480, 480, @EventCallback);
  SetupGUI;

  while IsRunning do
    begin
      ClearBackground;
      UpdateWindows;
      SwapBuffers;
    end;

  QuitApp;
end.