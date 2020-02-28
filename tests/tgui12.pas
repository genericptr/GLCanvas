{$mode objfpc}
{$assertions on}

program tgui12;
uses
  CThreads, SysUtils, 
  GLPT, VectorMath, GeometryTypes, GLCanvas, GLGUI,
  OS8Theme;

type
  TCustomPopover = class (TPopover)
    procedure Initialize; override;
  end;

procedure TCustomPopover.Initialize;
var
  button: TButton;
begin
  inherited;

  button := TButton.Create('Close', V2(0, 0));
  button.SetAction(TInvocation.Create(@PerformClose));
  button.LayoutIfNeeded;
  button.SetLocation(V2(GetWidth - (button.GetWidth + 10), GetHeight - (button.GetHeight + 10)));

  AddSubview(button);
end;

type
  TCustomWindow = class (TWindow, IWindowDelegate)
    popover: TCustomPopover;
    showButton: TButton;
    edgeCheckbox: TCheckBox;
    positionButton: TPopupButton;
    procedure HandleWindowWillClose (window: GLGUI.TWindow);
    procedure ShowPopover(params: TInvocationParams);
    procedure Initialize; override;
  end;

procedure TCustomWindow.HandleWindowWillClose (window: GLGUI.TWindow);
begin
  writeln('popover will close');
  popover := nil;
end;

procedure TCustomWindow.ShowPopover(params: TInvocationParams);
begin
  if (popover <> nil) and (popover.behavior = TPopoverBehavior.ApplicationDefined) then
    begin
      popover.Close;
      popover := nil;
      exit;
    end;

  Assert(popover = nil, 'popover is already open');

  popover := TCustomPopover.Create(self, V2(140, 140));
  if edgeCheckbox.IsChecked then
    popover.behavior := TPopoverBehavior.Transient
  else
    popover.behavior := TPopoverBehavior.ApplicationDefined;

  popover.Show(showButton.GetBounds, showButton, TRectEdge(positionButton.IndexOfSelectedItem));
end;

procedure TCustomWindow.Initialize;
begin
  inherited;

  showButton := TButton.Create('Show Popover', V2(50, 100));
  showButton.SetAction(TInvocation.Create(@ShowPopover));
  AddSubview(showButton);

  edgeCheckbox := TCheckBox.Create('Transient', V2(32, 32));
  AddSubview(edgeCheckbox);

  positionButton := TPopupButton.Create(V2(50, 70), 80, TControlSize.Regular);
  positionButton.AddItem('Left');
  positionButton.AddItem('Top');
  positionButton.AddItem('Right');
  positionButton.AddItem('Bottom');
  positionButton.SelectItemAtIndex(2);
  AddSubview(positionButton);
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