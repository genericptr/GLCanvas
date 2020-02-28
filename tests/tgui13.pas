{$mode objfpc}
{$assertions on}
{$modeswitch nestedprocvars}

program tgui13;
uses
  CThreads, SysUtils, 
  GLPT, VectorMath, GeometryTypes, GLCanvas, GLGUI, OS8Theme;

type
  TCustomWindow = class (TWindow)
    procedure Initialize; override;
    procedure MenuClicked(params: TInvocationParams);
  end;

procedure TCustomWindow.MenuClicked(params: TInvocationParams);
var
  menuItem: TMenuItem absolute params;
begin
  menuItem.SetChecked(not menuItem.IsChecked);
end;

procedure TCustomWindow.Initialize;
var
  button: TPopupButton;
begin
  inherited;

  // pull down
  button := TPopupButton.CreatePulldown('Options', V2(50, 100), TControlSize.Small);
  button.SetAction(TInvocation.Create(@MenuClicked));

  button.AddItem('Lorem ipsum dolor sit amet, consectetur.');
  button.AddItem('Cras tempor quam at rutrum vehicula.');
  button.AddItem('Nulla pretium libero interdum sem ultrices.');
  button.AddItem('Fusce scelerisque ipsum a nibh vestibulum.');
  button.AddItem('Suspendisse egestas justo in neque egestas.');
  button.AddItem('In luctus nunc id mi interdum commodo.');
  button.AddItem('Suspendisse sed tortor sed sapien lobortis.');
  button.AddItem('Nam non neque laoreet, egestas dui ut, sagittis.');
  button.AddItem('Nullam eleifend felis efficitur libero.');
  button.AddItem('Proin vestibulum felis sit amet ante congue.');
  AddSubview(button);

  // popup
  button := TPopupButton.Create(V2(50, 70), 80, TControlSize.Small);
  button.AddItem('Red');
  button.AddItem('Green');
  button.AddItem('Blue');
  button.AddItem('Yellow');
  button.AddItem('White');
  button.AddItem('Black');
  button.SelectItemAtIndex(2);

  AddSubview(button);
end;

procedure EventCallback(event: pGLPT_MessageRec);
begin
  if PollWindowEvents(event) then
    exit;
end; 

procedure SetupGUI; 

  procedure MenuClicked(params: TInvocationParams);
  begin
    writeln(TMenuItem(params).GetTitle);
  end;

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