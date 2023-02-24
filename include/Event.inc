
{$ifdef INTERFACE}

type
  TEventType = (
    None,
    MouseDown,
    MouseUp,
    MouseMoved,
    KeyDown,
    KeyUp,
    Scroll,
    WindowResize,
    MouseEnter,
    MouseExit,
    TouchDown,
    TouchUp,
    TouchMoved,
    Tap,
    Swipe,
    Pinch,
    Pan,
    Rotate,
    LongPress,
    ControllerAdded,
    ControllerRemoved,
    ControllerMotion,
    ControllerButtonDown,
    ControllerButtonUp
  );

{$ifdef PLATFORM_NONE}
type
  TKeyCode = integer;
  TScanCode = integer;
  TShiftState = Classes.TShiftState;
{$endif}

{$ifdef PLATFORM_SDL}
const
  NUM_SCANCODES = SDL_NUM_SCANCODES;

type
  TKeyCode = SDL_Keycode;
  TScanCode = SDL_Scancode;
{$endif}

{$ifdef PLATFORM_GLPT}
const
  NUM_SCANCODES = GLPT_NUM_SCANCODES;

type
  TKeyCode = GLPT_Keycode;
  TScanCode = GLPT_Scancode;
{$endif}

const
  kControllerInvalidInput = -MaxInt;

type
  TControllerAxis = record
    axis: integer;   // axis which was moved
    value: integer;  // value of the axis (-1, 0, 1)
  end;

  TControllerState = record
    public
      index: integer;
      axis: integer;   // axis which was moved
      value: integer;  // value of the axis (-1, 0, 1)
      button: integer; // button pressed/released
      ref: pointer;    // opaque reference to the controller

      procedure Reset;
      function GUIDString: String;
      function Name: String;
  end;

type
  generic TAbstractEvent<T> = class abstract
    public type
      TShiftState = Classes.TShiftState;
      TRawEvent = T;
      PRawEvent = ^TRawEvent;
    private
      msg: TRawEvent;
    public 
      { Constructors }
      constructor Create(constref raw: TRawEvent);
      { General }
      function EventType: TEventType; virtual; abstract;
      { Keyboard }
      function ScanCode: TScancode; virtual; abstract;
      function KeyCode: TKeycode; virtual; abstract;
      function KeyChar: char; virtual;
      function ScrollWheel: TVec2; virtual; abstract;
      function KeyboardModifiers: TShiftState; virtual; abstract;
      { Mouse }
      function ClickCount: integer; virtual; abstract;
      function MouseModifiers: TShiftState; virtual; abstract;
      function MouseLocation: TVec2i; virtual; abstract;
      { Touch }
      function TouchLocation: TVec2i; virtual; abstract;
      function TouchRadius: Float; virtual; abstract;
      function TouchHit(rect: TRect): boolean; virtual; abstract;
      { Controller }
      function ControllerState: TControllerState; virtual; abstract;
      { Window }
      function WindowSize: TVec2; virtual; abstract;
      { Properties }
      property RawEvent: TRawEvent read msg;
  end;


{$if defined(PLATFORM_SDL)}
type
  TSDLEvent = class(specialize TAbstractEvent<SDL_Event>)
    public 
      function Copy: TSDLEvent;
      function EventType: TEventType; override;
      function ScanCode: TScancode; override;
      function KeyCode: TKeycode; override;
      function ScrollWheel: TVec2; override;
      function KeyboardModifiers: TShiftState; override;
      function ClickCount: integer; override;
      function MouseModifiers: TShiftState; override;
      function MouseLocation: TVec2i; override;
      function WindowSize: TVec2; override;
      function ControllerState: TControllerState; override;
  end;
  TEvent = TSDLEvent;
{$endif}

{$if defined(PLATFORM_GLPT)}
type
  TGLPTEvent = class(specialize TAbstractEvent<GLPT_MessageRec>)
    public 
      function Copy: TGLPTEvent;
      function EventType: TEventType; override;
      function ScanCode: TScancode; override;
      function KeyCode: TKeycode; override;
      function ScrollWheel: TVec2; override;
      function KeyboardModifiers: TShiftState; override;
      function ClickCount: integer; override;
      function MouseModifiers: TShiftState; override;
      function MouseLocation: TVec2i; override;
      function TouchLocation: TVec2i; override;
      function TouchRadius: Float; override;
      function TouchHit(rect: TRect): boolean; override;
      function WindowSize: TVec2; override;
  end;
  TEvent = TGLPTEvent;
{$endif}

{$ifdef COCOA_EVENTS}
type
  TCocoaMessage = record
    event: NSEvent;
    view: NSView;
  end;
  TCocoaEvent = class(specialize TAbstractEvent<TCocoaMessage>)
    public 
      function EventType: TEventType; override;
      function ScanCode: TScancode; override;
      function KeyCode: TKeycode; override;
      function KeyChar: char; override;
      function ScrollWheel: TVec2; override;
      function KeyboardModifiers: TShiftState; override;
      function ClickCount: integer; override;
      function MouseModifiers: TShiftState; override;
      function MouseLocation: TVec2i; override;
      function WindowSize: TVec2; override;
  end;
  TEvent = TCocoaEvent;
{$endif}

// redeclare shift state to override GLPT
type
  TShiftState = Classes.TShiftState;
  TTouchMap = specialize TFPGMapObject<SizeUInt, TEvent>;

function GetMouseLocation: TVec2i;
function GetTouches: TTouchMap;
function IsMouseDown: boolean;
function IsLeftMouseDown: boolean;
function IsRightMouseDown: boolean;
function IsMouseOffscreen: boolean;
function IsCommandKeyDown: boolean;
function IsShiftKeyDown: boolean;
function IsOptionKeyDown: boolean;
function IsControlKeyDown: boolean;
function IsKeyDown(key: TScanCode; repeating: boolean = true): boolean; overload;
function IsKeyDown(key: char; repeating: boolean = true): boolean; overload;

function IsControllerConnected(index: integer = 0): boolean;
function IsControllerPressed(button: integer; repeating: boolean = true; index: integer = 0): boolean;
function GetControllerAxis(index: integer = 0): TControllerAxis;
function GetControllerGUID(index: integer = 0): string;
function GetControllerName(index: integer = 0): string;

{$ifdef PLATFORM_SDL}
procedure PollSystemInput(event: PSDL_Event);
{$endif}

{$ifdef PLATFORM_GLPT}
procedure PollSystemInput(event: pGLPT_MessageRec);
{$endif}


{$endif}

{$ifdef IMPLEMENTATION}

type
  TKeyCodeMap = specialize TFPGMap<String, TKeyCode>;

  TInputAction = class
    key: TKeyCode;
    name: string;
  end;

  TKeyDownState = record
    pressed: boolean;
    released: boolean;
  end;
  
  TGameController = record
    buttons: array[0..32] of TKeyDownState;
    guid: array[0..15] of Uint8;
    state: TControllerState;

    function GUIDString: String;
    function Name: String;
    function IsConnected: boolean;
  end;

type
  TInputManager = class
    private
      { keyboard }
      keyDown: array[0..NUM_SCANCODES-1] of TKeyDownState;
      shiftState: TShiftState;

      { mouse }
      leftMouseDown: boolean;
      rightMouseDown: boolean;
      mouseLocation: TVec2i;
      mouseDownLocation: TVec2i;
      mouseOffscreen: boolean;

      { touches }
      touches: TTouchMap;

      { controllers }
      controllers: array[0..32] of TGameController;
    public
      actions: TKeyCodeMap;
    public
      constructor Create;
  end;

var
  InputManager: TInputManager;

{$ifdef PLATFORM_SDL}
type
  SDL_Event_Helper = record helper for SDL_Event
    function GetMouseLocation: TVec2i;
    function GetControllerState: TControllerState;
  end;
{$endif}

{$ifdef PLATFORM_GLPT}
type
  TGLPT_MessageRec_Helper = record helper for GLPT_MessageRec
    function GetMouseLocation: TVec2i;
    function GetTouchLocation: TVec2i;
    function GetGestureLocation: TVec2i;
  end;
{$endif}

{*****************************************************************************
 *                                    TSDLEvent
 *****************************************************************************}

{$ifdef PLATFORM_SDL}
const
  JOYSTICK_DEAD_ZONE = 8000;

function TSDLEvent.Copy: TSDLEvent;
begin
  result := TSDLEvent.Create(RawEvent);
end;

function TSDLEvent.EventType: TEventType;
begin
  case msg.type_ of
    SDL_JOYDEVICEADDED: result := TEventType.ControllerAdded;
    SDL_JOYDEVICEREMOVED: result := TEventType.ControllerRemoved;
    SDL_JOYBUTTONDOWN: result := TEventType.ControllerButtonDown;
    SDL_JOYBUTTONUP: result := TEventType.ControllerButtonUp;
    SDL_JOYAXISMOTION: result := TEventType.ControllerMotion;
    SDL_WINDOW_EVENT:
      begin
        case msg.window.event of
          SDL_WINDOWEVENT_LEAVE: result := TEventType.MouseExit;
          SDL_WINDOWEVENT_ENTER: result := TEventType.MouseEnter;
          SDL_WINDOWEVENT_RESIZED: result := TEventType.WindowResize;
        end;
      end;
    SDL_MOUSEWHEEL: result := TEventType.Scroll;
    SDL_MOUSEBUTTONDOWN: result := TEventType.MouseDown;
    SDL_MOUSEBUTTONUP: result := TEventType.MouseUp;
    SDL_MOUSEMOTION: result := TEventType.MouseMoved;
    SDL_KEYUP: result := TEventType.KeyUp;
    SDL_KEYDOWN: result := TEventType.KeyDown;
    otherwise
      result := TEventType.None;
  end;

end;

function TSDLEvent.ClickCount: integer;
begin
  // TODO: should be in SDL_MouseButtonEvent but our record is missing it??
  // https://wiki.libsdl.org/SDL_MouseButtonEvent
  result := 1;//msg.button
end;

function TSDLEvent.KeyCode: TKeycode;
begin
  result := msg.key.keysym.sym;
end;

function TSDLEvent.ScanCode: TScanCode;
begin
  result := msg.key.keysym.scancode;
end;

function TSDLEvent.KeyboardModifiers: TShiftState;
var
  modState: UInt32;
begin
  modState := SDL_GetModState;
  result := [];

  if modState = (modState or KMOD_LCTRL)  then
    result += [ssCtrl, ssLeft];
  if modState = (modState or KMOD_RCTRL)  then
    result += [ssCtrl, ssRight];

  if modState = (modState or KMOD_LGUI)  then
    result += [ssSuper, ssLeft];
  if modState = (modState or KMOD_RGUI)  then
    result += [ssSuper, ssRight];

  if modState = (modState or KMOD_LALT)  then
    result += [ssAlt, ssLeft];
  if modState = (modState or KMOD_RALT)  then
    result += [ssAlt, ssRight];

  if modState = (modState or KMOD_CAPS)  then
    result += [ssCaps];
end;

function TSDLEvent.MouseModifiers: TShiftState;
begin
  // TODO: not implemented yet!
  result := [];
end;

function TSDLEvent.MouseLocation: TVec2i;
begin
  result := V2(msg.motion.x, msg.motion.y);
end;

function TSDLEvent.ScrollWheel: TVec2;
begin
  result := V2(msg.wheel.x, msg.wheel.y);
end;

function TSDLEvent.WindowSize: TVec2;
begin
  result := V2(msg.window.data1, msg.window.data2)
end;

function TSDLEvent.ControllerState: TControllerState;
begin
  result := RawEvent.GetControllerState;
end;

{$endif}

{*****************************************************************************
 *                             TControllerState
 *****************************************************************************}

function TControllerState.GUIDString: String;
begin
  result := GetControllerGUID(index);
end;

function TControllerState.Name: String;
begin
  result := GetControllerName(index);
end;

procedure TControllerState.Reset;
begin
  index := 0;
  axis := kControllerInvalidInput;
  value := 0;
  button := kControllerInvalidInput;
  ref := nil;
end;

{*****************************************************************************
 *                                    TGLPTEvent
 *****************************************************************************}

{$ifdef PLATFORM_GLPT}
function TGLPTEvent.Copy: TGLPTEvent;
begin
  result := TGLPTEvent.Create(RawEvent);
end;

function TGLPTEvent.EventType: TEventType;
begin
  case msg.mcode of
    GLPT_MESSAGE_MOUSEUP: result := TEventType.MouseUp;
    GLPT_MESSAGE_MOUSEEXIT: result := TEventType.MouseExit;
    GLPT_MESSAGE_MOUSEENTER: result := TEventType.MouseEnter;
    GLPT_MESSAGE_SCROLL: result := TEventType.Scroll;
    GLPT_MESSAGE_MOUSEDOWN: result := TEventType.MouseDown;
    GLPT_MESSAGE_MOUSEMOVE: result := TEventType.MouseMoved;
    GLPT_MESSAGE_KEYRELEASE: result := TEventType.KeyUP;
    GLPT_MESSAGE_KEYPRESS: result := TEventType.KeyDown;
    GLPT_MESSAGE_TOUCH_DOWN: result := TEventType.TouchDown;
    GLPT_MESSAGE_TOUCH_UP: result := TEventType.TouchUp;
    GLPT_MESSAGE_TOUCH_MOTION: result := TEventType.TouchMoved;
    GLPT_MESSAGE_GESTURE_TAP: result := TEventType.Tap;
    GLPT_MESSAGE_GESTURE_SWIPE: result := TEventType.Swipe;
    GLPT_MESSAGE_RESIZE: result := TEventType.WindowResize;
    otherwise
      result := TEventType.None;
  end;
end;

function TGLPTEvent.ClickCount: integer;
begin
  result := msg.params.mouse.clicks;
end;

function TGLPTEvent.KeyCode: TKeycode;
begin
  result := msg.params.keyboard.keycode;
end;

function TGLPTEvent.ScanCode: TScanCode;
begin
  result := msg.params.keyboard.scancode;
end;

function TGLPTEvent.KeyboardModifiers: TShiftState;
begin
  result := TShiftState(msg.params.keyboard.shiftstate);
end;

function TGLPTEvent.MouseModifiers: TShiftState;
begin
  result := TShiftState(msg.params.mouse.shiftstate);
end;

function TGLPTEvent.MouseLocation: TVec2i;
begin
  result := V2i(msg.params.mouse.x, msg.params.mouse.y);
end;

function TGLPTEvent.TouchLocation: TVec2i;
begin
  case EventType of
    TEventType.Tap,
    TEventType.Swipe,
    TEventType.Pinch,
    TEventType.Pan,
    TEventType.Rotate,
    TEventType.LongPress:
      result := V2i(msg.params.gesture.x, msg.params.gesture.y)
    else
      result := V2i(msg.params.touch.x, msg.params.touch.y);
  end;
end;

function TGLPTEvent.TouchRadius: Float;
begin
  result := msg.params.touch.radius;
end;

function TGLPTEvent.TouchHit(rect: TRect): boolean;
  function CircleIntersectsRect(origin: TVec2; radius: TScalar; constref rect: TRect): boolean; 
  var
    distX, distY: TScalar;
    dx, dy: TScalar;
  begin
    distX := Abs(origin.x - rect.origin.x - rect.size.width / 2);
    distY := Abs(origin.y - rect.origin.y - rect.size.height / 2);
    
    if (distX > (rect.size.width / 2 + radius)) then
      exit(false);
    
    if (distY > (rect.size.height / 2 + radius)) then
      exit(false);
      
    if (distX <= (rect.size.width / 2)) then
      exit(true);
    
    if (distY <= (rect.size.height / 2)) then
      exit(true); 
    
    dx := distX - rect.size.width / 2;
    dy := distY - rect.size.height / 2;
    result := (dx * dx + dy * dy <= (radius * radius));
  end;
begin
  result := CircleIntersectsRect(TouchLocation, TouchRadius, rect);
end;

function TGLPTEvent.ScrollWheel: TVec2;
begin
  result := V2(msg.params.mouse.deltaX, msg.params.mouse.deltaY);
end;

function TGLPTEvent.WindowSize: TVec2;
begin
  result := V2(msg.params.rect.width, msg.params.rect.height);
end;
{$endif}

{*****************************************************************************
 *                               TCocoaEvent
 *****************************************************************************}

{$ifdef COCOA_EVENTS}
function TCocoaEvent.EventType: TEventType;
begin
  case RawEvent.event.type_ of
    NSLeftMouseDown, NSRightMouseDown: result := TEventType.MouseDown;
    NSLeftMouseUp, NSRightMouseUp: result := TEventType.MouseUp;
    NSMouseMoved, NSLeftMouseDragged, NSRightMouseDragged: result := TEventType.MouseMoved;
    NSMouseEntered: result := TEventType.MouseEnter;
    NSMouseExited: result := TEventType.MouseExit;
    NSScrollWheel: result := TEventType.Scroll;
    NSKeyDown: result := TEventType.KeyDown;
    NSKeyUp: result := TEventType.KeyUp;
    otherwise
      Assert(false, 'Invalid event type '+IntToStr(RawEvent.event.type_));
  end;
end;

function TCocoaEvent.ScanCode: TScancode;
begin
  result := RawEvent.event.keyCode;
end;

function TCocoaEvent.KeyChar: char;
begin
  result := char(RawEvent.event.charactersIgnoringModifiers.characterAtIndex(0));
end;

function TCocoaEvent.KeyCode: TKeycode;
begin
  //keymap := @GLPT_default_keymap;
  //params.keyboard.scancode := darwin_scancode_table[event.keycode];
  //params.keyboard.keycode := keymap^[params.keyboard.scancode];
  //params.keyboard.shiftstate := Cocoa_GetKeyboardShiftState;
  result := ord(KeyChar);
end;

function TCocoaEvent.ScrollWheel: TVec2;
begin
  result := V2(RawEvent.event.deltaX, RawEvent.event.deltaY);
end;

function TCocoaEvent.KeyboardModifiers: TShiftState;
begin
  // TODO: not implemented yet!
  result := []; { Cocoa_GetKeyboardShiftState }
end;

function TCocoaEvent.ClickCount: integer;
begin
  result := RawEvent.event.clickCount;
end;

function TCocoaEvent.MouseModifiers: TShiftState;
begin
  // TODO: not implemented yet!
  result := [];
end;

function TCocoaEvent.MouseLocation: TVec2i;
begin
  result := V2i(
    trunc(RawEvent.event.locationInWindow.x), 
    trunc(RawEvent.view.frame.size.height - RawEvent.event.locationInWindow.y)
    );
end;

function TCocoaEvent.WindowSize: TVec2;
begin
  result := V2i(trunc(RawEvent.event.window.frame.size.width), trunc(RawEvent.event.window.frame.size.height));
end;
{$endif}

{*****************************************************************************
 *                             TAbstractEvent
 *****************************************************************************}

function TAbstractEvent.KeyChar: char;
begin
  result := Chr(KeyCode);
end;

constructor TAbstractEvent.Create(constref raw: TRawEvent); 
begin
  msg := raw;
end;

{*****************************************************************************
 *                                 Input
 *****************************************************************************}

// https://godotengine.org/article/handling-axis-godot
// https://stackoverflow.com/questions/46044752/godot-keyboard-events
// https://docs.godotengine.org/en/3.1/classes/class_input.html

constructor TInputManager.Create;
var
  i: integer;
begin
  actions := TKeyCodeMap.Create;
  touches := TTouchMap.Create;

  mouseOffscreen := true;

  for i := 0 to high(keyDown) do
    begin
      keyDown[i].pressed := false;
      keyDown[i].released := true;
    end;

  for i := 0 to high(controllers) do
    controllers[i].state.Reset;
end;

{ Actions }

function IsActionPressed(action: string): boolean;
begin
end;

function IsActionJustPressed(action: string): boolean;
begin
end;

function IsActionReleased(action: string): boolean;
begin
end;

function IsActionJustReleased(action: string): boolean;
begin
end;

function GetActionForce(key: string): single;
begin
end;

{ Keyboard & Mouse Events }

function GetMouseLocation: TVec2i;
begin
  result := InputManager.mouseLocation;
end;

function GetTouches: TTouchMap;
begin
  result := InputManager.touches;
end;

function IsMouseDown: boolean;
begin
  result := InputManager.leftMouseDown or InputManager.rightMouseDown;
end;

function IsLeftMouseDown: boolean;
begin
  result := InputManager.leftMouseDown;
end;

function IsRightMouseDown: boolean;
begin
  result := InputManager.rightMouseDown;
end;

function IsMouseOffscreen: boolean;
begin
  result := InputManager.mouseOffscreen;
end;

function IsCommandKeyDown: boolean;
begin
  result := ssSuper in InputManager.shiftState;
end;

function IsShiftKeyDown: boolean;
begin
  result := ssShift in InputManager.shiftState;
end;

function IsOptionKeyDown: boolean;
begin
  result := ssAlt in InputManager.shiftState;
end;

function IsControlKeyDown: boolean;
begin
  result := ssCtrl in InputManager.shiftState;
end;

function IsKeyDown(key: TScanCode; repeating: boolean): boolean;
begin
  if not repeating then
    begin
      if InputManager.keyDown[key].pressed and InputManager.keyDown[key].released then
        begin
          result := true;
          InputManager.keyDown[key].released := false;
        end
      else
        result := false;
    end
  else
    result := InputManager.keyDown[key].pressed;
end;

function IsKeyDown(key: char; repeating: boolean): boolean;
begin
  {$ifdef PLATFORM_GLPT}
  result := IsKeyDown(GLPT_GetScancodeFromKey(Ord(key)), repeating);
  {$endif}

  {$ifdef PLATFORM_SDL}
  result := IsKeyDown(SDL_GetScancodeFromKey(Ord(key)), repeating);
  {$endif}
end;

function IsControllerConnected(index: integer): boolean;
begin
  Assert((index >= 0) and (index < high(InputManager.controllers)), 'Controller index '+index.ToString+' out of range');

  result := InputManager.controllers[index].IsConnected;
end;

function IsControllerPressed(button: integer; repeating: boolean; index: integer): boolean;
begin
  Assert((index >= 0) and (index < high(InputManager.controllers)), 'Controller index '+index.ToString+' out of range');
  Assert((button >= 0) and (button < high(InputManager.controllers[index].buttons)), 'Button '+button.ToString+' out of range');

  result := InputManager.controllers[index].buttons[button].pressed;
end;

function GetControllerAxis(index: integer): TControllerAxis;
begin
  Assert((index >= 0) and (index < high(InputManager.controllers)), 'Controller index '+index.ToString+' out of range');

  result.axis := InputManager.controllers[index].state.axis;
  result.value := InputManager.controllers[index].state.value;
end;

function GetControllerGUID(index: integer): string;
begin
  Assert((index >= 0) and (index < high(InputManager.controllers)), 'Controller index '+index.ToString+' out of range');

  result := InputManager.controllers[index].GUIDString;
end;

function GetControllerName(index: integer): string;
begin
  Assert((index >= 0) and (index < high(InputManager.controllers)), 'Controller index '+index.ToString+' out of range');

  result := InputManager.controllers[index].Name;
end;

{*****************************************************************************
 *                             TControllerState
 *****************************************************************************}

function TGameController.Name: String;
begin
  result := SDL_JoystickName(state.ref);
end;

function TGameController.IsConnected: boolean;
begin
  result := assigned(state.ref) and SDL_JoystickGetAttached(state.ref);
end;

function TGameController.GUIDString: String;
const
  GUIDStringLength = 33;
begin
  SDL_JoystickGetGUIDString(
      SDL_JoystickGetGUID(state.ref),
      @result,
      GUIDStringLength
  );
  
  SetLength(result, GUIDStringLength);
end;

{$ifdef PLATFORM_SDL}

generic function IfThenElse<T>(condition: boolean; constref _if: T; constref _else: T): T; inline;
begin
  if condition then
    result := _if
  else
    result := _else;
end;

procedure PollSystemInput(event: PSDL_Event);
var
  joystick: PSDL_Joystick;
begin
  case event.type_ of
    SDL_MOUSEBUTTONUP:
      begin
        InputManager.leftMouseDown := false;
        InputManager.rightMouseDown := false;
        InputManager.mouseDownLocation := -1;
      end;
    SDL_WINDOW_EVENT:
      begin
        case event.window.event of
          SDL_WINDOWEVENT_LEAVE:
            InputManager.mouseOffscreen := true;
          SDL_WINDOWEVENT_ENTER:
            begin
              InputManager.mouseOffscreen := false;
              InputManager.mouseLocation := CanvasMousePosition(event.GetMouseLocation);
            end;
        end;
      end;
    SDL_MOUSEWHEEL:
      begin
        InputManager.mouseLocation := CanvasMousePosition(event.GetMouseLocation);
      end;
    SDL_MOUSEBUTTONDOWN:
      begin
        InputManager.mouseDownLocation := InputManager.mouseLocation;
        InputManager.leftMouseDown := event.button.button = SDL_BUTTON_LEFT;
        InputManager.rightMouseDown := event.button.button = SDL_BUTTON_RIGHT;
        //InputManager.shiftState := event^.params.mouse.shiftstate;
      end;
    SDL_MOUSEMOTION:
      begin
        //InputManager.mouseOffscreen := false;
        InputManager.mouseLocation := CanvasMousePosition(event.GetMouseLocation);
      end;
    SDL_KEYUP:
      begin
        InputManager.keyDown[event.key.keysym.scancode].pressed := false;
        InputManager.keyDown[event.key.keysym.scancode].released := true;
        //InputManager.shiftState := event^.params.keyboard.shiftstate;
      end;
    SDL_KEYDOWN:
      begin
        InputManager.keyDown[event.key.keysym.scancode].pressed := true;
        //InputManager.shiftState := event^.params.keyboard.shiftstate;
      end;
    SDL_JOYAXISMOTION:
      begin
        with InputManager.controllers[event.jaxis.which] do
          begin
            state := event.GetControllerState;
            guid := SDL_JoystickGetGUID(state.ref).data;
            //writeln('axis: ', event.jaxis.axis, ' = ', state.value);
          end;
      end;
    SDL_JOYHATMOTION:
      ;
    SDL_JOYBUTTONDOWN:
      begin
        //writeln('down ', event.jbutton.button);
        with InputManager.controllers[event.jbutton.which] do
          begin
            //state := event.GetControllerState;
            buttons[event.jbutton.button].pressed := true;//IfThenElse(jbutton.state = SDL_PRESSED, true, false);
            guid := SDL_JoystickGetGUID(state.ref).data;
          end;
        // jbutton.state = SDL_PRESSED or SDL_RELEASED
        //InputManager.controllerButtonDown[event.jbutton.which, event.jbutton.button].pressed := false;
      end;
    SDL_JOYBUTTONUP:
      begin
        with InputManager.controllers[event.jbutton.which] do
          begin
            //state := event.GetControllerState;
            buttons[event.jbutton.button].pressed := false;
            buttons[event.jbutton.button].released := true;
            guid := SDL_JoystickGetGUID(state.ref).data;
          end;
      end;
    SDL_JOYDEVICEADDED:
      begin
        joystick := SDL_JoystickOpen(event.jdevice.which);

        InputManager.controllers[SDL_JoystickInstanceID(joystick)].state.ref := joystick;

        writeln('SDL_JoystickName: ', SDL_JoystickName(joystick));
        writeln('SDL_JoystickInstanceID: ', SDL_JoystickInstanceID(joystick));
        writeln('SDL_JoystickGetAttached: ', SDL_JoystickGetAttached(joystick));
        writeln('SDL_JoystickNumButtons: ', SDL_JoystickNumButtons(joystick));
        writeln('SDL_JoystickNumHats: ', SDL_JoystickNumHats(joystick));
        writeln('SDL_JoystickNumAxes: ', SDL_JoystickNumAxes(joystick));
        writeln('SDL_IsGameController: ', SDL_IsGameController(event.jdevice.which));
      end;
    SDL_JOYDEVICEREMOVED:
      begin
        SDL_JoystickClose(InputManager.controllers[event.jdevice.which].state.ref);
        InputManager.controllers[event.jdevice.which].state.ref := nil;
        writeln('device removed');
      end;
  end;
end;

function SDL_Event_Helper.GetControllerState: TControllerState;
begin  
  if (type_ = SDL_JOYBUTTONDOWN) or (type_ = SDL_JOYBUTTONUP) then
    result.index := self.jbutton.which
  else
    result.index := self.jaxis.which;

  result.ref := InputManager.controllers[result.index].state.ref;

  result.button := self.jbutton.button;
  result.axis := self.jaxis.axis;

  if self.jaxis.value < -JOYSTICK_DEAD_ZONE then
    result.value := -1
  else if self.jaxis.value > JOYSTICK_DEAD_ZONE then
    result.value := 1
  else
    result.value := 0;
end;

function SDL_Event_Helper.GetMouseLocation: TVec2i;
begin
  result := V2(motion.x, motion.y);
end;
{$endif}


{$ifdef PLATFORM_GLPT}
procedure PollSystemInput(event: pGLPT_MessageRec);
begin
  case event^.mcode of
    GLPT_MESSAGE_MOUSEUP:
      begin
        InputManager.leftMouseDown := false;
        InputManager.rightMouseDown := false;
        InputManager.mouseDownLocation := -1;
      end;
    GLPT_MESSAGE_MOUSEEXIT:
      InputManager.mouseOffscreen := true;
    GLPT_MESSAGE_MOUSEENTER:
      begin
        InputManager.mouseOffscreen := false;
        InputManager.mouseLocation := CanvasMousePosition(event.GetMouseLocation);
        InputManager.shiftState := event^.params.mouse.shiftstate;
      end;
    GLPT_MESSAGE_SCROLL:
      begin
        InputManager.mouseLocation := CanvasMousePosition(event.GetMouseLocation);
      end;
    GLPT_MESSAGE_MOUSEDOWN:
      begin
        InputManager.mouseDownLocation := InputManager.mouseLocation;
        InputManager.leftMouseDown := event^.params.mouse.buttons = GLPT_MOUSE_BUTTON_LEFT;
        InputManager.rightMouseDown := event^.params.mouse.buttons = GLPT_MOUSE_BUTTON_RIGHT;
        InputManager.shiftState := event^.params.mouse.shiftstate;
      end;
    GLPT_MESSAGE_TOUCH_DOWN:
      begin
        InputManager.touches.Add(event.params.touch.id, TEvent.Create(event^));
        //InputManager.mouseLocation := CanvasMousePosition(event.GetTouchLocation);
        // TODO: computed property which checks touches map
      end;
    GLPT_MESSAGE_TOUCH_MOTION:
      begin
        if InputManager.touches.IndexOf(event.params.touch.id) > -1 then
          InputManager.touches.Remove(event.params.touch.id);
        InputManager.touches.Add(event.params.touch.id, TEvent.Create(event^));

        //InputManager.mouseLocation := CanvasMousePosition(event.GetTouchLocation);
      end;
    GLPT_MESSAGE_TOUCH_UP:
      begin
        if InputManager.touches.IndexOf(event.params.touch.id) > -1 then
          InputManager.touches.Remove(event.params.touch.id);

        //InputManager.mouseLocation := -1;
      end;
    GLPT_MESSAGE_KEYRELEASE:
      begin
        // TODO: we need GLPT_GetKeyFromScancode/GLPT_GetScancodeFromKey
        InputManager.keyDown[event^.params.keyboard.scancode].pressed := false;
        InputManager.keyDown[event^.params.keyboard.scancode].released := true;
        InputManager.shiftState := event^.params.keyboard.shiftstate;
      end;
    GLPT_MESSAGE_KEYPRESS:
      begin
        InputManager.keyDown[event^.params.keyboard.scancode].pressed := true;
        InputManager.shiftState := event^.params.keyboard.shiftstate;
      end;
  end;
end; 

function TGLPT_MessageRec_Helper.GetMouseLocation: TVec2i;
begin
  result := V2i(params.mouse.x, params.mouse.y);
end;

function TGLPT_MessageRec_Helper.GetTouchLocation: TVec2i;
begin
  result := V2i(params.touch.x, params.touch.y);
end;

function TGLPT_MessageRec_Helper.GetGestureLocation: TVec2i;
begin
  result := V2i(params.gesture.x, params.gesture.y);
end;
{$endif}

{$endif}
