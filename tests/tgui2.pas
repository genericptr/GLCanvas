{$mode objfpc}

program tgui2;
uses
  CThreads, SysUtils, VectorMath, GeometryTypes, GLCanvas, GLGUI, GLPT;

var
  font: TBitmapFont;

type
  TCustomTextView = class (TTextView)
    procedure Draw; override;
  end;

procedure TCustomTextView.Draw;
begin   
  FillRect(GetBounds, RGBA(0.1, 0.1, 1, 0.5));
  inherited;
end;

type
  TCustomWindow = class (TWindow)
    procedure Initialize; override;
  end;

var
  window: TCustomWindow;

procedure TCustomWindow.Initialize;
var
  textView: TTextView;
begin
  inherited;

  textView := TCustomTextView.Create(RectMake(100, 100, 120, 32));
  textView.SetWidthTracksContainer(false);
  textView.SetStringValue('TTextView');
  textView.SetFont(font);
  AddSubview(textView);

  textView := TCustomTextView.Create(RectMake(100, 140, 120, 32));
  textView.SetTextAlignment(kAlignmentCenter);
  textView.SetWidthTracksContainer(false);
  textView.SetStringValue('TTextView');
  textView.SetFont(font);
  AddSubview(textView);

  textView := TCustomTextView.Create(RectMake(100, 180, 120, 32));
  textView.SetWidthTracksContainer(true);
  textView.SetStringValue('TTextView');
  textView.SetFont(font);
  AddSubview(textView);

  textView := TCustomTextView.Create(RectMake(240, 100, 120, 120));
  textView.SetWidthTracksContainer(false);
  textView.SetStringValue('Incidunt vel voluptas dolore ut sit. Sapiente animi asperiores dolor et molestiae voluptatem voluptates. Omnis eos error facilis iure aliquam.');
  textView.SetFont(font);
  AddSubview(textView);

  textView := TCustomTextView.Create(RectMake(240, 240, 120, 50));
  textView.SetWidthTracksContainer(false);
  textView.SetEnableClipping(true);
  textView.SetStringValue('Incidunt vel voluptas dolore ut sit. Sapiente animi asperiores dolor et molestiae voluptatem voluptates. Omnis eos error facilis iure aliquam.');
  textView.SetFont(font);
  AddSubview(textView);
end;

procedure EventCallback(event: pGLPT_MessageRec);
begin
  if PollWindowEvents(event) then
    exit;
end; 

procedure SetupGUI; 
begin
  font := TBitmapFont.Create(GLPT_GetBasePath+'/coders_crux');

  // TODO: how should we do this??
  MainPlatformWindow := GLCanvasState.window;  
  window := TCustomWindow.Create(TWindow.ScreenRect);
  window.SetMoveableByBackground(false);
  window.MakeKeyAndOrderFront;
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