{$mode objfpc}
{$assertions on}

program tgui14;
uses
  CThreads, SysUtils, 
  GLPT, VectorMath, GeometryTypes, GLCanvas, GLGUI,
  OS8Theme;

type
  TCustomWindow = class (TWindow)
    procedure Initialize; override;
  end;

procedure TCustomWindow.Initialize;
var
  i: integer;
  group: TRadioGroup;
  radioButton: TRadioButton;
begin
  inherited;

  // TODO: make an option to SizeToFit otherwise average to fill space

  group := TRadioGroup.Create(V2(32, 32), true);
  for i := 0 to 3 do
    group.AddButton('Radio Button '+IntToStr(i + 1));
  AddSubview(group);

  group := TRadioGroup.Create(V2(32, 150), false, 4);
  AddSubview(group);

  //radioButton := TRadioButton.Create('Radio Button', V2(32, 32));
  //AddSubview(radioButton);

  //radioButton := TRadioButton.Create('Radio Button', V2(32, 50), TControlSize.Small);
  //AddSubview(radioButton);
end;

procedure EventCallback(event: pGLPT_MessageRec);
begin
  if PollWindowEvents(event) then
    exit;
end; 

procedure SetupGUI; 
var
  window: TCustomWindow;
begin
  LoadOS8Theme;

  window := TCustomWindow.Create(RectMake(100, 100, 200, 200));
  window.SetMoveableByBackground(true);
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