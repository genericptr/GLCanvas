
{$ifdef INTERFACE}

function GetMouseLocation: TVec2i;
function IsMouseDown: boolean;
function IsCommandKeyDown: boolean;
function IsShiftKeyDown: boolean;
function IsOptionKeyDown: boolean;
function IsControlKeyDown: boolean;
function IsKeyDown(key: GLPT_Scancode): boolean;
procedure PollSystemInput(event: pGLPT_MessageRec);

{$endif}

{$ifdef IMPLEMENTATION}

// https://godotengine.org/article/handling-axis-godot
// https://stackoverflow.com/questions/46044752/godot-keyboard-events
// https://docs.godotengine.org/en/3.1/classes/class_input.html

type
  TKeyCodeMap = specialize TFPGMap<String, GLPT_Keycode>;

type
  TInputAction = class
    key: GLPT_Keycode;
    name: string;

    //procedure AddKey();
    // TODO: how do we get the device id's in advance?
    //GLPT_MESSAGE_CONTROLLER_HAT = 300;
    //GLPT_MESSAGE_CONTROLLER_AXIS = 301;
    //GLPT_MESSAGE_CONTROLLER_BUTTON = 302;
    //GLPT_MESSAGE_CONTROLLER_ADDED = 303;
    //GLPT_MESSAGE_CONTROLLER_REMOVED = 304;
  end;

type
  TInputManager = class
    private
      { keyboard }
      keyDown: array[0..GLPT_NUM_SCANCODES-1] of boolean;
      shiftState: TShiftState;

      { mouse }
      leftMouseDown: boolean;
      rightMouseDown: boolean;
      mouseLocation: TVec2i;
      mouseDownLocation: TVec2i;
    public
      actions: TKeyCodeMap;
    public
      constructor Create;
  end;

var
  InputManager: TInputManager;

constructor TInputManager.Create;
begin
  actions := TKeyCodeMap.Create;
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
  result := InputManager.leftMouseDown or InputManager.leftMouseDown;
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

function IsKeyDown(key: GLPT_Scancode): boolean;
begin
  result := InputManager.keyDown[key];
end;

procedure PollSystemInput(event: pGLPT_MessageRec);
begin
  case event^.mcode of
    GLPT_MESSAGE_MOUSEUP:
      begin
        InputManager.leftMouseDown := false;
        InputManager.rightMouseDown := false;
        InputManager.mouseDownLocation := 0;
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
        InputManager.mouseLocation := V2i(event^.params.mouse.x, event^.params.mouse.y);
      end;
    GLPT_MESSAGE_KEYRELEASE:
      begin
        // TODO: we need GLPT_GetKeyFromScancode/GLPT_GetScancodeFromKey
        InputManager.keyDown[event^.params.keyboard.scancode] := false;
        InputManager.shiftState := event^.params.keyboard.shiftstate;
      end;
    GLPT_MESSAGE_KEYPRESS:
      begin
        InputManager.keyDown[event^.params.keyboard.scancode] := true;
        InputManager.shiftState := event^.params.keyboard.shiftstate;
      end;
  end;
end; 


{$endif}
