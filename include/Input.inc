
{$ifdef INTERFACE}

{$ifdef PLATFORM_SDL}
const
  NUM_SCANCODES = SDL_NUM_SCANCODES;

type
  TKeyCode = SDL.Uint32;
  TScanCode = SDL_Scancode;

{$endif}

{$ifdef PLATFORM_GLPT}
const
  NUM_SCANCODES = GLPT_NUM_SCANCODES;

type
  TKeyCode = GLPT_Keycode;
  TScanCode = GLPT_Scancode;
{$endif}

function GetMouseLocation: TVec2i;
function IsMouseDown: boolean;
function IsLeftMouseDown: boolean;
function IsRightMouseDown: boolean;
function IsMouseOffscreen: boolean;
function IsCommandKeyDown: boolean;
function IsShiftKeyDown: boolean;
function IsOptionKeyDown: boolean;
function IsControlKeyDown: boolean;
function IsKeyDown(key: TScanCode; repeating: boolean = true): boolean;

{$ifdef PLATFORM_SDL}
type
  SDL_Event_Helper = record helper for SDL_Event
    function GetMouseLocation: TVec2i;
  end;
{$endif}

{$ifdef PLATFORM_GLPT}
type
  TGLPT_MessageRec_Helper = record helper for GLPT_MessageRec
    function GetMouseLocation: TVec2i;
  end;

{$endif}

{$ifdef PLATFORM_SDL}
procedure PollSystemInput(event: PSDL_Event);
{$endif}

{$ifdef PLATFORM_GLPT}
procedure PollSystemInput(event: pGLPT_MessageRec);
{$endif}

{$endif}

{$ifdef IMPLEMENTATION}

// https://godotengine.org/article/handling-axis-godot
// https://stackoverflow.com/questions/46044752/godot-keyboard-events
// https://docs.godotengine.org/en/3.1/classes/class_input.html

type
  TKeyCodeMap = specialize TFPGMap<String, TKeyCode>;

type
  TInputAction = class
    key: TKeyCode;
    name: string;
  end;

type
  TKeyDownState = record
    state: boolean;
    dirty: boolean;
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
    public
      actions: TKeyCodeMap;
    public
      constructor Create;
  end;

var
  InputManager: TInputManager;

constructor TInputManager.Create;
var
  i: integer;
begin
  actions := TKeyCodeMap.Create;
  mouseOffscreen := true;

  for i := 0 to NUM_SCANCODES - 1 do
    begin
      keyDown[i].state := false;
      keyDown[i].dirty := true;
    end;
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

// TODO: we need GLPT_GetKeyFromScancode/GLPT_GetScancodeFromKey
// so we can start using real keycodes instead of scancodes
// which will break on different keyboard layouts

function IsKeyDown(key: TScanCode; repeating: boolean): boolean;
begin
  if not repeating then
    begin
      if InputManager.keyDown[key].state and InputManager.keyDown[key].dirty then
        begin
          result := true;
          InputManager.keyDown[key].dirty := false;
        end
      else
        result := false;
    end
  else
    result := InputManager.keyDown[key].state;
end;

{$ifdef PLATFORM_SDL}

procedure PollSystemInput(event: PSDL_Event);
begin
  case event.type_ of
    SDL_MOUSEBUTTONUP:
      begin
        InputManager.leftMouseDown := false;
        InputManager.rightMouseDown := false;
        InputManager.mouseDownLocation := 0;
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
        InputManager.keyDown[event.key.keysym.scancode].state := false;
        InputManager.keyDown[event.key.keysym.scancode].dirty := true;
        //InputManager.shiftState := event^.params.keyboard.shiftstate;
      end;
    SDL_KEYDOWN:
      begin
        InputManager.keyDown[event.key.keysym.scancode].state := true;
        //InputManager.shiftState := event^.params.keyboard.shiftstate;
      end;
  end;
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
        InputManager.mouseDownLocation := 0;
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
    GLPT_MESSAGE_MOUSEMOVE:
      begin
        //InputManager.mouseOffscreen := false;
        InputManager.mouseLocation := CanvasMousePosition(event.GetMouseLocation);
      end;
    GLPT_MESSAGE_KEYRELEASE:
      begin
        // TODO: we need GLPT_GetKeyFromScancode/GLPT_GetScancodeFromKey
        InputManager.keyDown[event^.params.keyboard.scancode].state := false;
        InputManager.keyDown[event^.params.keyboard.scancode].dirty := true;
        InputManager.shiftState := event^.params.keyboard.shiftstate;
      end;
    GLPT_MESSAGE_KEYPRESS:
      begin
        InputManager.keyDown[event^.params.keyboard.scancode].state := true;
        InputManager.shiftState := event^.params.keyboard.shiftstate;
      end;
  end;
end; 

function TGLPT_MessageRec_Helper.GetMouseLocation: TVec2i;
begin
  result := V2i(params.mouse.x, params.mouse.y);
end;
{$endif}

{$endif}
