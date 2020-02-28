{$mode objfpc}

program tgui1;
uses
  CThreads, SysUtils, VectorMath, GeometryTypes, GLCanvas, GLGUI, GLPT;

type
  TCustomWindow = class (TWindow)
    title: string;
    backgroundColor: TColor;

    procedure HandleKeyDown (event: TEvent); override;
    procedure Draw; override;
  end;

procedure TCustomWindow.HandleKeyDown (event: TEvent);
begin
  writeln(title, ' got ', event.KeyboardCharacter);
  inherited HandleKeyDown(event);
end;

procedure TCustomWindow.Draw;
begin
  FillRect(GetBounds, backgroundColor);
  if IsKey then
    StrokeRect(GetBounds, RGBA(0, 0, 0, 0.85), 4);
end;

var
  window: array[0..2] of TCustomWindow;

procedure EventCallback(event: pGLPT_MessageRec);
begin
  if PollWindowEvents(event) then
    exit;
end; 

procedure SetupGUI; 
begin
  window[0] := TCustomWindow.Create(RectMake(20, 20, 200, 120));
  window[0].title := 'Red Bro';
  window[0].backgroundColor := RGBA(1, 0, 0, 0.95);
  window[0].SetMoveableByBackground(true);
  window[0].MakeKeyAndOrderFront;

  window[1] := TCustomWindow.Create(RectMake(200, 300, 200, 120));
  window[1].title := 'Blue Stud';
  window[1].backgroundColor := RGBA(0, 0, 1, 0.95);
  window[1].SetMoveableByBackground(true);
  window[1].MakeKeyAndOrderFront;

  window[2] := TCustomWindow.Create(RectMake(420, 20, 180, 300));
  window[2].title := 'Green Guy';
  window[2].backgroundColor := RGBA(0, 1, 0, 0.95);
  window[2].SetWindowLevel(kWindowLevelUtility);
  window[2].MakeKeyAndOrderFront;
end;

begin
  SetupCanvas(640, 480, @EventCallback);
  SetupGUI;

  while IsRunning do
    begin
      ClearBackground;
      UpdateWindows;
      SwapBuffers;
    end;

  QuitApp;
end.