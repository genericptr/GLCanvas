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
  if not IsFocused then
    FillRect(GetBounds, RGBA(0.1, 0.1, 1, 0.5))
  else
    FillRect(GetBounds, RGBA(0.1, 1, 0.1, 0.5));
  inherited;
end;

// TODO: move to GLGUI
type
  TTextField = class (TControl)
    private
      m_text: TTextView;
      m_borderWidth: integer;
      m_font: TBitmapFont;
      procedure SetBorderWidth(newValue: integer);
      procedure SetFont(newValue: TBitmapFont);
      procedure AdjustFrame;
    private
      textFrame: TRect;
    protected
      procedure HandleWillAddToParent(view: TView); override;
      procedure HandleViewFrameChanged (notification: TNotification);
      procedure HandleViewFocusChanged (notification: TNotification);
      procedure HandleKeyDown (event: TEvent); override;
    public
      procedure Draw; override;
      property BorderWidth: integer read m_borderWidth write SetBorderWidth; 
      property TextFont: TBitmapFont read m_font write SetFont; 
  end;

procedure TTextField.AdjustFrame;
begin
  textFrame := GetBounds.Inset(BorderWidth, BorderWidth);
  m_text.SetFrame(textFrame);
end;

procedure TTextField.SetBorderWidth(newValue: integer);
begin
  m_borderWidth := newValue;
  if m_text <> nil then
    AdjustFrame;
end;

procedure TTextField.SetFont(newValue: TBitmapFont);
begin
  m_font := newValue;
  if m_text <> nil then
    AdjustFrame;
end;

procedure TTextField.HandleViewFocusChanged (notification: TNotification);
begin
  GiveFocus;
end;

procedure TTextField.HandleViewFrameChanged (notification: TNotification);
var
  newFrame,
  parentFrame: TRect;
  rightMargin: single;
begin
  textFrame := GetBounds.Inset(BorderWidth, BorderWidth);

  parentFrame := m_text.ConvertRectTo(m_text.GetBounds, self);
  rightMargin := GetBounds.width - 2;

  newFrame := m_text.GetFrame;
  if parentFrame.Width > rightMargin then
    newFrame.origin.x := trunc(rightMargin - newFrame.Width)
  else
    newFrame.origin.x := textFrame.MinX;
  m_text.SetFrame(newFrame);  
end;

procedure TTextField.HandleKeyDown (event: TEvent);
begin
  case event.KeyCode of
    GLPT_SCANCODE_TAB:
      GetWindow.AdvanceFocus;
    GLPT_SCANCODE_RETURN:
      begin
        InvokeAction;
        event.Accept(self);
        exit;
      end;
    otherwise
      inherited HandleKeyDown(event);
  end;  
end;

// TODO: changing TTextField to TView makes internal error
procedure TTextField.HandleWillAddToParent (view: TView);
begin
  inherited HandleWillAddToParent(view);

  // TODO: border width 8 is buggy
  BorderWidth := 8;
  SetCanAcceptFocus(true);

  textFrame := GetBounds.Inset(BorderWidth, BorderWidth);

  m_text := TTextView.Create(textFrame);
  m_text.SetEditable(true);
  m_text.SetWidthTracksContainer(true);
  m_text.SetStringValue(GetStringValue);
  m_text.SetFont(TextFont);
  m_text.SetPostsFrameChangedNotifications(true);
  AddSubview(m_text);

  TNotificationCenter.DefaultCenter.ObserveNotification(kNotificationFocusChanged, @self.HandleViewFocusChanged, pointer(m_text));
  TNotificationCenter.DefaultCenter.ObserveNotification(kNotificationFrameChanged, @self.HandleViewFrameChanged, pointer(m_text));
end;

procedure TTextField.Draw;
begin   
  if not IsFocused then
    FillRect(GetBounds, RGBA(0.1, 0.1, 1, 0.5))
  else
    FillRect(GetBounds, RGBA(0.1, 1, 0.1, 0.5));

  FlushDrawing;
  PushClipRect(textFrame);
  inherited;
  PopClipRect;
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
  textField: TTextField;
begin
  inherited;

  // TODO: command/option delete need to work properly

  // TODO: focus is per WINDOW so which window is focused? expand the example

  textField := TTextField.Create(RectMake(100, 50, 120, 22));
  textField.SetStringValue('Hello World');
  textField.TextFont := font;
  AddSubview(textField);

  textField := TTextField.Create(RectMake(100, 100, 120, 22));
  textField.SetStringValue('Hello World');
  textField.TextFont := font;
  AddSubview(textField);

  textView := TCustomTextView.Create(RectMake(250, 50, 120, 120));
  textView.SetEditable(true);
  textView.SetWidthTracksContainer(false);
  // TODO: line endings on a single line don't work
  textView.SetStringValue('1'+LineEnding+'2'+LineEnding+'3');
  textView.SetFont(font);
  textView.SetPostsFrameChangedNotifications(true);
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