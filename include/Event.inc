
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

type
  TEvent = class
    {$ifdef PLATFORM_SDL}
    private type
      TKeyCode = SDL.Uint32;
      TScanCode = SDL_Scancode;
      TRawEvent = SDL_Event;
    {$endif}
    {$ifdef PLATFORM_GLPT}
    private type
      TKeyCode = GLPT_Keycode;
      TScanCode = GLPT_Scancode;
      TRawEvent = GLPT_MessageRec;
    {$endif}
    private
      msg: TRawEvent;
    public 
      constructor Create(constref raw: TRawEvent);
      { General }
      function EventType: TEventType;
      { Keyboard }
      function ScanCode: TScancode;
      function KeyCode: TKeycode;
      function KeyChar: char;
      function ScrollWheel: TVec2;
      function KeyboardModifiers: TShiftState;
      { Mouse }
      function ClickCount: integer;
      function MouseModifiers: TShiftState;
      { Window }
      function WindowSize: TVec2;
  end;

{$endif}

{$ifdef IMPLEMENTATION}

function TEvent.EventType: TEventType;
begin
  result := TEventType.None;

  {$ifdef PLATFORM_SDL}
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
  end;
  {$endif}

  {$ifdef PLATFORM_GLPT}
  case msg.mcode of
    GLPT_MESSAGE_MOUSEUP: result := TEventType.MouseUp;
    GLPT_MESSAGE_MOUSEEXIT: result := TEventType.MouseExit;
    GLPT_MESSAGE_MOUSEENTER: result := TEventType.MouseEnter;
    GLPT_MESSAGE_SCROLL: result := TEventType.Scroll;
    GLPT_MESSAGE_MOUSEDOWN: result := TEventType.MouseDown;
    GLPT_MESSAGE_MOUSEMOVE: result := TEventType.MouseMoved;
    GLPT_MESSAGE_KEYRELEASE: result := TEventType.KeyUP;
    GLPT_MESSAGE_KEYPRESS: result := TEventType.KeyDown;
  end;
  {$endif}
end;

function TEvent.ClickCount: integer;
begin
  {$ifdef PLATFORM_GLPT}
  result := msg.params.mouse.clicks;
  {$endif}

  {$ifdef PLATFORM_SDL}
  // TODO: should be in SDL_MouseButtonEvent but our record is missing it??
  // https://wiki.libsdl.org/SDL_MouseButtonEvent
  result := 1;//msg.button
  {$endif}
end;

function TEvent.KeyCode: TKeycode;
begin
  {$ifdef PLATFORM_GLPT}
  result := msg.params.keyboard.keycode;
  {$endif}

  {$ifdef PLATFORM_SDL}
  result := msg.key.keysym.sym;
  {$endif}
end;

function TEvent.KeyChar: char;
begin
  result := Chr(KeyCode);
end;

function TEvent.ScanCode: TScanCode;
begin
  {$ifdef PLATFORM_GLPT}
  result := msg.params.keyboard.scancode;
  {$endif}

  {$ifdef PLATFORM_SDL}
  result := msg.key.keysym.scancode;
  {$endif}
end;

function TEvent.KeyboardModifiers: TShiftState;
begin
  {$ifdef PLATFORM_GLPT}
  result := msg.params.keyboard.shiftstate;
  {$endif}

  {$ifdef PLATFORM_SDL}
  result := [];
  {$endif}
end;

function TEvent.MouseModifiers: TShiftState;
begin
  {$ifdef PLATFORM_GLPT}
  result := msg.params.mouse.shiftstate;
  {$endif}

  {$ifdef PLATFORM_SDL}
  result := [];
  {$endif}
end;

function TEvent.ScrollWheel: TVec2;
begin
  {$ifdef PLATFORM_GLPT}
  result := V2(msg.params.mouse.deltaX, msg.params.mouse.deltaY);
  {$endif}

  {$ifdef PLATFORM_SDL}
  result := V2(msg.wheel.x, msg.wheel.y);
  {$endif}
end;

function TEvent.WindowSize: TVec2;
begin
  {$ifdef PLATFORM_SDL}
  result := V2(msg.window.data1, msg.window.data2)
  {$endif}
end;

constructor TEvent.Create(constref raw: TRawEvent); 
begin
  msg := raw;
end;

{$endif}
