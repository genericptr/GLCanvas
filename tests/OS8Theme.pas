{$mode objfpc}
{$modeswitch advancedrecords}
{$assertions on}
{$scopedenums on}

unit OS8Theme;
interface
uses
  SysUtils, FreeTypeH,
  GLFreeType, VectorMath, GeometryTypes, GLFreeTypeFont, GLCanvas, GLGUI;

type
  TControlSize = (Mini, Small, Regular); 

const
  TDefaultControlSize = TControlSize.Regular;

type
  TOS8Menu = class (TMenu)
    procedure Draw; override;
  end;

type
  TOS8Button = class (TButton)
    public
      constructor Create(title: string; position: TVec2; controlSize: TControlSize = TDefaultControlSize);
      function GetTitleFrame: TRect; override;
      function GetContainerFrame: TRect; override;
      procedure Draw; override;
    private
      controlSize: TControlSize;
  end;

type
  TOS8PopupButton = class (TPopupButton)
    public
      constructor CreatePulldown(title: string; position: TVec2; controlSize: TControlSize = TDefaultControlSize);
      constructor Create(position: TVec2; width: integer; controlSize: TControlSize = TDefaultControlSize);

      class function MenuClass: TMenuClass; override;
      procedure Draw; override;
      function GetTitleFrame: TRect; override;
      function GetContainerFrame: TRect; override;
      function GetMinimumMenuWidth: integer; override;
    private
      controlSize: TControlSize;
      function PopupFrame: TTextureArray; inline;
  end;

type
  TOS8CheckBox = class (TCheckBox)
    constructor Create(title: string; position: TVec2; controlSize: TControlSize = TDefaultControlSize);
    function GetTitleFrame: TRect; override;
    function GetButtonFrame: TRect; override;
    procedure Draw; override;
  end;

type
  TOS8RadioButton = class (TRadioButton)
    constructor Create(title: string; position: TVec2; controlSize: TControlSize = TDefaultControlSize);
    function GetTitleFrame: TRect; override;
    procedure Draw; override;
  end;

type
  TOS8RadioGroup = class (TRadioGroup)
    procedure AddButton(title: string); override;
    procedure Draw; override;
  end;

type
  TOS8WindowFlags = (Bordered, Titled, Resizable);
  TOS8Window = class (TWindow)
    private
      m_bordered: boolean;
    public
      constructor Create; overload;
      procedure Draw; override;
      procedure Initialize; override;
      function ShouldMoveByBackground(event: TEvent): boolean; override;
      property Bordered: boolean read m_bordered write m_bordered;
  end;

type
  TOS8Scroller = class (TScroller)
    function GetHandleFrame: TRect; override;
    procedure DrawHandle(rect: TRect); override;
    procedure DrawTrack(rect: TRect); override;
  end;

type
  TOS8Popover = class (TPopover)
    procedure Draw; override;
  end;

type
  TButton = TOS8Button;
  TWindow = TOS8Window;
  TPopover = TOS8Popover;
  TCheckBox = TOS8CheckBox;
  TRadioButton = TOS8RadioButton;
  TRadioGroup = TOS8RadioGroup;
  TPopupButton = TOS8PopupButton;
  TScroller = TOS8Scroller;

procedure LoadOS8Theme; 
function FontForControlSize(controlSize: TControlSize): IFont;

implementation

type
  TFontSize = (Mini, Small, Regular);

type
  TWindowFrame = class
    texture: TTexture;
    titleBar: array of TTexture;
    middle: array of TTexture;
    bottom: array of TTexture;
    titleBarHeight: integer;
    constructor Create(name: string);
    destructor Destroy; override;
    procedure Draw(frame: TRect);
  end;

type
  TOS8Theme = record
    public
      popupFrame: array[TControlSize] of TTextureArray;
      menuFrame: TTextureSheet;
      popoverFrame: TTextureSheet;
      windowFrame: TWindowFrame;
      buttonFrame: TTextureSheet;
      checkbox: array[TControlState] of TTexture;
      radioButton: array[TControlState] of TTexture;
      sliderTrack: TTextureSheet;
      sliderThumb: TTexture;
  end;

var
  theme: TOS8Theme;
  font: array[TFontSize] of TGLFreeTypeFont;

//#########################################################
// THEME
//#########################################################

procedure DrawCheck(frame: TRect);
begin
  FillOval(RectCenter(RectMake(0,0,4,4), frame), RGBA(0, 0, 0, 0.9));
end;

function FontForControlSize(controlSize: TControlSize): IFont;
begin
  case controlSize of
    TControlSize.Small:
      result := font[TFontSize.Small];
    TControlSize.Regular:
      result := font[TFontSize.Regular];
    TControlSize.Mini:
      result := font[TFontSize.Mini];
    otherwise
      result := nil;
  end;

  Assert(result <> nil, 'Invalid control size for font.');
end;

//#########################################################
// WINDOW FRAME
//#########################################################

procedure TWindowFrame.Draw(frame: TRect); 
begin
  Draw3PartImage(titleBar, RectMake(0, 0, frame.Width, titleBarHeight));
  Draw3PartImage(middle, RectMake(0, titleBarHeight, frame.Width, frame.Height - (titleBarHeight * 2)));
  Draw3PartImage(bottom, RectMake(0, frame.Height - titleBarHeight, frame.Width, titleBarHeight));
end;

destructor TWindowFrame.Destroy;
begin
  texture.Free;
  inherited;
end;

constructor TWindowFrame.Create(name: string);
begin
  texture := TTexture.Create(name);

  titleBarHeight := 13;

  titleBar := [
    texture.Splice(RectMake(0, 0, titleBarHeight, titleBarHeight)),
    texture.Splice(RectMake(titleBarHeight, 0, 32 - (titleBarHeight * 2), titleBarHeight)),
    texture.Splice(RectMake(titleBarHeight + (32 - (titleBarHeight * 2)), 0, titleBarHeight, titleBarHeight))
  ];

  middle := [
    texture.Splice(RectMake(0, titleBarHeight, titleBarHeight, 32 - (titleBarHeight * 2))),
    texture.Splice(RectMake(titleBarHeight, titleBarHeight, 32 - (titleBarHeight * 2), 32 - (titleBarHeight * 2))),
    texture.Splice(RectMake(titleBarHeight + (32 - (titleBarHeight * 2)), titleBarHeight, titleBarHeight, 32 - (titleBarHeight * 2)))
  ];

  bottom := [
    texture.Splice(RectMake(0, 32 - titleBarHeight, titleBarHeight, titleBarHeight)),
    texture.Splice(RectMake(titleBarHeight, 32 - titleBarHeight, 32 - (titleBarHeight * 2), titleBarHeight)),
    texture.Splice(RectMake(titleBarHeight + (32 - (titleBarHeight * 2)), 32 - titleBarHeight, titleBarHeight, titleBarHeight))
  ];
end;

//#########################################################
// CHECKBOX
//#########################################################

constructor TOS8CheckBox.Create(title: string; position: TVec2; controlSize: TControlSize = TDefaultControlSize);
begin
  inherited Create(RectMake(position, 0, 12));
  SetFont(FontForControlSize(controlSize));
  SetTitle(title);
end;

function TOS8CheckBox.GetButtonFrame: TRect; 
begin
  result := RectMake(0, 0, theme.checkbox[GetControlState].GetSize);
end;

function TOS8CheckBox.GetTitleFrame: TRect;
begin
  result := inherited GetTitleFrame;
  result.origin.x += 4;
end;

procedure TOS8CheckBox.Draw;
var
  texture: TTexture;
  tint: TVec4;
begin
  texture := theme.checkbox[GetControlState];
  if IsPressed then
    tint := RGBA(0.7, 1)
  else
    tint := RGBA(1, 1);
  DrawTexture(texture, GetButtonFrame, texture.GetTextureFrame.Texture, tint);

  inherited;
end;

//#########################################################
// RADIO BUTTON
//#########################################################

constructor TOS8RadioButton.Create(title: string; position: TVec2; controlSize: TControlSize = TDefaultControlSize);
begin
  inherited Create(RectMake(position, 12, 12));
  SetFont(FontForControlSize(controlSize));
  SetTitle(title);
end;

function TOS8RadioButton.GetTitleFrame: TRect;
begin
  result := inherited GetTitleFrame;
  result.origin.x += 4;
  result.origin.y -= 2;
end;

procedure TOS8RadioButton.Draw;
var
  texture: TTexture;
  tint: TVec4;
begin
  //FillRect(GetBounds, RGBA(1,0,0,1));

  texture := theme.radioButton[GetControlState];
  if IsPressed then
    tint := RGBA(0.7, 1)
  else
    tint := RGBA(1, 1);
  DrawTexture(texture, GetButtonFrame, texture.GetTextureFrame.Texture, tint);

  inherited;
end;

//#########################################################
// RADIO GROUP
//#########################################################
procedure TOS8RadioGroup.Draw;
begin
  FillRect(GetBounds, RGBA(1,0,0,1));

  inherited;
end;

procedure TOS8RadioGroup.AddButton(title: string);
var
  button: TOS8RadioButton;
begin
  button := TOS8RadioButton.Create(title, V2(0, 0), TDefaultControlSize);
  AddSubview(button);
end;

//#########################################################
// BUTTON
//#########################################################


// TODO: make a button frame enum -- round/square

constructor TOS8Button.Create(title: string; position: TVec2; controlSize: TControlSize = TDefaultControlSize);
begin
  self.controlSize := controlSize;
  inherited Create(RectMake(position, 0, 20));
  SetFont(FontForControlSize(controlSize));
  SetResizeByWidth(true);
  SetTitle(title);
end;

function TOS8Button.GetTitleFrame: TRect;
begin
  result := inherited GetTitleFrame;
  result.origin.y -= 1;
end;

function TOS8Button.GetContainerFrame: TRect;
begin
  result := inherited GetContainerFrame;

  case controlSize of
    TControlSize.Small:
      result.size.y := 16;
    TControlSize.Regular:
      result.size.y := 20;
    TControlSize.Mini:
      result.size.y := 15;
  end;

  result.size.x += 8;
end;

procedure TOS8Button.Draw;
begin
  Draw9PartImage(theme.buttonFrame, GetBounds);
  if not IsEnabled then
    FillRect(GetBounds, RGBA(0.7, 0.7, 0.7, 0.2))
  else if IsPressed then
    FillRect(GetBounds, RGBA(0.1, 0.1, 1, 0.2));
  inherited;
end;

//#########################################################
// MENU
//#########################################################

procedure TOS8Menu.Draw;
begin
  Draw9PartImage(theme.menuFrame, GetBounds);

  inherited;
end;

//#########################################################
// POPUP BUTTON
//#########################################################

constructor TOS8PopupButton.CreatePulldown(title: string; position: TVec2; controlSize: TControlSize = TDefaultControlSize);
begin
  self.controlSize := controlSize;
  inherited Create(RectMake(position, 0, PopupFrame[0].GetHeight));
  SetFont(FontForControlSize(controlSize));
  SetResizeByWidth(true);
  SetTitle(title);
  SetPullsdown(true);
end;

constructor TOS8PopupButton.Create(position: TVec2; width: integer; controlSize: TControlSize = TDefaultControlSize);
begin
  self.controlSize := controlSize;
  inherited Create(RectMake(position, width, PopupFrame[0].GetHeight));
  SetFont(FontForControlSize(controlSize));
end;

function TOS8PopupButton.PopupFrame: TTextureArray;
begin
  result := theme.popupFrame[controlSize];
end;

class function TOS8PopupButton.MenuClass: TMenuClass;
begin
  result := TOS8Menu;
end;

function TOS8PopupButton.GetMinimumMenuWidth: integer;
begin
  result := inherited;
  // remove arrow button width
  result -= 18;
end;

function TOS8PopupButton.GetTitleFrame: TRect;
begin
  result := inherited;
  result.x := 6;
end;

function TOS8PopupButton.GetContainerFrame: TRect;
begin
  result := inherited;
  if resizeByWidth then
    result.size.x += PopupFrame[2].GetWidth + 4; 
  result.size.height := PopupFrame[0].GetHeight; 
end;

procedure TOS8PopupButton.Draw;
begin
  Draw3PartImage(PopupFrame, GetBounds);
  if not IsEnabled then
    FillRect(GetBounds, RGBA(0.7, 0.7, 0.7, 0.2))
  else if IsPressed then
    FillRect(GetBounds, RGBA(0.1, 0.1, 0.1, 0.2));
  inherited;
end;

//#########################################################
// SCROLLER
//#########################################################

function TOS8Scroller.GetHandleFrame: TRect;
begin
  result := inherited;
  result.size := theme.sliderThumb.GetSize;
end;

procedure TOS8Scroller.DrawHandle(rect: TRect);
begin
  DrawTexture(theme.sliderThumb, rect);
  if IsDragging then
    FillRect(rect, RGBA(0, 0, 1, 0.3));
end;

procedure TOS8Scroller.DrawTrack(rect: TRect);
begin
  Draw9PartImage(theme.sliderTrack, rect);
end;

//#########################################################
// WINDOW
//#########################################################
function TOS8Window.ShouldMoveByBackground(event: TEvent): boolean;
begin
  if Bordered then
    result := RectMake(0, 0, GetWidth, theme.windowFrame.titleBarHeight).ContainsPoint(event.Location(self))
  else
    result := true;
end;

procedure TOS8Window.Draw;
begin  
  if Bordered then
    theme.windowFrame.Draw(GetBounds);
  inherited
  ;
end;

procedure TOS8Window.Initialize;
begin
  inherited;
  Bordered := true;
end;

constructor TOS8Window.Create;
begin
  inherited Create;
  Bordered := false;
end;

//#########################################################
// POPOVER
//#########################################################

procedure TOS8Popover.Draw;
begin
  Draw9PartImage(theme.popoverFrame, GetBounds);

  inherited;
end;

procedure LoadFreeType;
const
  kCharset = FREETYPE_ANSI_CHARSET + '√';
  kSystemSmallFont = '/System/Library/Fonts/Geneva.dfont';
  kSystemRegularFont = '/Users/ryanjoseph/Library/Fonts/charcoal.ttf';
var
  lib: PFT_Library;
begin
  Assert(FT_Init_FreeType(lib) = 0, 'FT_Init_FreeType');

  font[TFontSize.Mini] := TGLFreeTypeFont.Create(lib, kSystemSmallFont);
  font[TFontSize.Mini].Render(9, kCharset);
  
  font[TFontSize.Small] := TGLFreeTypeFont.Create(lib, kSystemSmallFont);
  font[TFontSize.Small].Render(10, kCharset);

  font[TFontSize.Regular] := TGLFreeTypeFont.Create(lib, kSystemRegularFont);
  font[TFontSize.Regular].Render(13, kCharset);

  FT_Done_FreeType(lib);
end;

procedure LoadOS8Theme; 
var
  texture: TTexture;
begin
  with theme do
    begin
      checkbox[TControlState.Off] := TTexture.Create('checkbox_off.png');
      checkbox[TControlState.On] := TTexture.Create('checkbox_on.png');

      radioButton[TControlState.Off] := TTexture.Create('radio_off.png');
      radioButton[TControlState.On] := TTexture.Create('radio_on.png');

      buttonFrame := TTextureSheet.Create('button.png', 8);

      menuFrame := TTextureSheet.Create('WDEF_7.png', 8);
      popoverFrame := TTextureSheet.Create('WDEF_6.png', 8);
      // TODO: make modal/utility frames - this is modal
      windowFrame := TWindowFrame.Create('WDEF_4.png');

      sliderTrack := TTextureSheet.Create('scroller_track.png', V2(4, 4));
      sliderThumb := TTexture.Create('scroller_thumb.png');

      texture := TTexture.Create('popup_small.png');
      popupFrame[TControlSize.Small] := [
        texture.Splice(RectMake(0, 0, 3, 16)),
        texture.Splice(RectMake(3, 0, 5, 16)),
        texture.Splice(RectMake(8, 0, 19, 16))
      ];

      texture := TTexture.Create('popup_regular.png');
      popupFrame[TControlSize.Regular] := [
        texture.Splice(RectMake(0, 0, 4, 20)),
        texture.Splice(RectMake(4, 0, 4, 20)),
        texture.Splice(RectMake(8, 0, 22, 20))
      ];
    end;
  LoadFreeType;
end;

end.