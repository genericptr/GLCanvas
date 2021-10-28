
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
    MouseExit
  );

{$ifdef PLATFORM_NONE}
type
  TKeyCode = integer;
  TScanCode = integer;
  TShiftState = Classes.TShiftState;
{$endif}

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
      { Window }
      function WindowSize: TVec2; virtual; abstract;
      { Properties }
      property RawEvent: TRawEvent read msg;
  end;


{$if defined(PLATFORM_SDL)}
type
  TSDLEvent = class(specialize TAbstractEvent<SDL_Event>)
    public 
      function EventType: TEventType; override;
      function ScanCode: TScancode; override;
      function KeyCode: TKeycode; override;
      function ScrollWheel: TVec2; override;
      function KeyboardModifiers: TShiftState; override;
      function ClickCount: integer; override;
      function MouseModifiers: TShiftState; override;
      function MouseLocation: TVec2i; override;
      function WindowSize: TVec2; override;
  end;
  TEvent = TSDLEvent;
{$endif}

{$if defined(PLATFORM_GLPT)}
type
  TGLPTEvent = class(specialize TAbstractEvent<GLPT_MessageRec>)
    public 
      function EventType: TEventType; override;
      function ScanCode: TScancode; override;
      function KeyCode: TKeycode; override;
      function ScrollWheel: TVec2; override;
      function KeyboardModifiers: TShiftState; override;
      function ClickCount: integer; override;
      function MouseModifiers: TShiftState; override;
      function MouseLocation: TVec2i; override;
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

{$endif}

{$ifdef IMPLEMENTATION}

{*****************************************************************************
 *                                    TSDLEvent
 *****************************************************************************}

{$ifdef PLATFORM_SDL}
function TSDLEvent.EventType: TEventType;
begin
  case msg.type_ of
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
begin
  // TODO: not implemented yet!
  result := [];
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
{$endif}

{*****************************************************************************
 *                                    TGLPTEvent
 *****************************************************************************}

{$ifdef PLATFORM_GLPT}
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

function TGLPTEvent.ScrollWheel: TVec2;
begin
  result := V2(msg.params.mouse.deltaX, msg.params.mouse.deltaY);
end;

function TGLPTEvent.WindowSize: TVec2;
begin
  // TODO: not implemented yet!
  result := 0;
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

{$endif}
