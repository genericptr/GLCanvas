{$mode objfpc}
{$modeswitch nestedprocvars}

program tgui4;
uses
  CThreads, SysUtils, FreeTypeH, 
  VectorMath, GeometryTypes, GLCanvas, GLFreeTypeFont, GLGUI, 
  GLPT;

{define FREETYPE_FONT}
{$assertions on}

var
  {$ifdef FREETYPE_FONT}
  font: TGLFreeTypeFont;
  {$else}
  font: TBitmapFont;
  {$endif}
  icon: TTexture;
  buttonFrame: TTextureSheet;

type
  TCustomButton = class (TButton)
    procedure Draw; override;
  end;

procedure TCustomButton.Draw;
begin
  Draw9PartImage(buttonFrame, GetBounds);
  if not IsEnabled then
    FillRect(GetBounds, RGBA(0.7, 0.7, 0.7, 0.2))
  else if IsPressed then
    FillRect(GetBounds, RGBA(0.1, 0.1, 1, 0.2));
  inherited;
end;

procedure EventCallback(event: pGLPT_MessageRec);
begin
  if PollWindowEvents(event) then
    exit;
end; 

{$ifdef FREETYPE_FONT}
procedure LoadFreeType;
var
  lib: PFT_Library;
begin
  Assert(FT_Init_FreeType(lib) = 0, 'FT_Init_FreeType');
  font := TGLFreeTypeFont.Create(lib, '/System/Library/Fonts/Geneva.dfont');
  font.Render(12);
  FT_Done_FreeType(lib);
end;
{$endif}

procedure SetupGUI;

  procedure ClickedButton(button: pointer);
  begin
    writeln('clicked button ', HexStr(TCustomButton(button)));
  end;

var
  window: TWindow;
  button: TButton;
begin
  {$ifdef FREETYPE_FONT}
  LoadFreeType;
  {$else}
  font := TBitmapFont.Create('coders_crux');
  {$endif}

  icon := TTexture.Create('AlertStopIcon.png');
  buttonFrame := TTextureSheet.Create('button.png', V2(8, 8));

  // TODO: how should we do this??
  MainPlatformWindow := GLCanvasState.window;  

  window := TWindow.Create(TWindow.ScreenRect);
  window.SetMoveableByBackground(false);

  // no icons
  button := TCustomButton.Create(RectMake(200, 50, 80, 24));
  button.SetFont(font);
  button.SetResizeByWidth(true);
  button.SetTitle('Hello World');
  button.SetAction(TInvocation.Create(@ClickedButton));
  window.AddSubview(button);

  button := TCustomButton.Create(RectMake(200, button.GetFrame.MaxY + 10, 120, 40));
  button.SetFont(font);
  button.SetResizeByWidth(false);
  button.SetTitle('Hello World');
  button.SetAction(TInvocation.Create(@ClickedButton));
  window.AddSubview(button);

  button := TCustomButton.Create(RectMake(200, button.GetFrame.MaxY + 10, 120, 28));
  button.SetFont(font);
  button.SetResizeByWidth(false);
  button.SetTitle('Hello World');
  button.SetAction(TInvocation.Create(@ClickedButton));
  window.AddSubview(button);

  // icons
  button := TCustomButton.Create(RectMake(50, 50, 80, 24));
  button.SetFont(font);
  button.SetResizeByWidth(true);
  button.SetTitle('Hello World');
  button.SetImage(icon);
  button.SetAction(TInvocation.Create(@ClickedButton));
  window.AddSubview(button);

  button := TCustomButton.Create(RectMake(50, button.GetFrame.MaxY + 10, 120, 40));
  button.SetFont(font);
  button.SetResizeByWidth(false);
  button.SetTitle('Hello World');
  button.SetImage(icon);
  button.SetAction(TInvocation.Create(@ClickedButton));
  window.AddSubview(button);

  button := TCustomButton.Create(RectMake(50, button.GetFrame.MaxY + 10, 120, 28));
  button.SetFont(font);
  button.SetResizeByWidth(false);
  button.SetTitle('Hello World');
  button.SetImage(icon);
  button.SetAction(TInvocation.Create(@ClickedButton));
  window.AddSubview(button);

  window.MakeKeyAndOrderFront;
end;

begin
  SetupCanvas(512, 512, @EventCallback);
  SetupGUI;

  while IsRunning do
    begin
      ClearBackground;
      DrawTexture(font, 10, 10);
      UpdateWindows;
      SwapBuffers;
    end;

  QuitApp;
end.