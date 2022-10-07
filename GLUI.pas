{$mode objfpc}
{$modeswitch advancedrecords}
{$modeswitch multihelpers}
{$modeswitch nestedprocvars}
{$modeswitch arrayoperators}
{$modeswitch autoderef}

{$include include/targetos.inc}

{$interfaces corba}
{$implicitexceptions off}
{$scopedenums on}

{define GLGUI_DEBUG}
{define BUFFERED_RENDERING}

unit GLUI;
interface
uses
  {$ifdef API_OPENGL}
  GL, GLext,
  {$endif}
  {$ifdef API_OPENGLES}
  GLES30,
  {$endif}
  SysUtils, FGL, TypInfo, Classes,
  {$if defined(PLATFORM_GLPT)}
  GLPT, GLPT_Threads, 
  {$elseif defined(PLATFORM_SDL)}
  SDL,
  {$endif}
  GLCanvas,
  GeometryTypes, VectorMath;

type
  TVariantList = specialize TFPGList<Variant>;
  TVariantMap = specialize TFPGMap<String, Variant>;
  TObjectList = specialize TFPGObjectList<TObject>;
  TPoint = TVec2i;

{$define INTERFACE}
{$include include/Invocation.inc}
{$include include/NotificationCenter.inc}
{$include include/Timer.inc}
{$undef INTERFACE}

type
  TEvent = class(GLCanvas.TEvent)
    private
      m_accepted: boolean;
      m_inputSender: TObject;
      acceptedObject: TObject;
    public
      { Methods }
      function ScrollWheel: TVec2; override;
      function Location(system: TObject = nil): TPoint;
      procedure Accept(obj: TObject = nil);
      procedure Reject;
      { Properties }
      property IsAccepted: boolean read m_accepted;
      property InputSender: TObject read m_inputSender;
  end;
  TEventList = specialize TFPGObjectList<TEvent>;

type
  TDragOperation = (
    None,
    Generic,
    Copy,
    Move,
    Delete
  );

type
  TDraggingItem = class
  end;
  TDraggingItems = specialize TFPGList<TDraggingItem>;

type
  IDelegate = interface ['IDelegate']
  end;

type
  IDelegation = interface
    procedure SetDelegate(newValue: TObject);
    function GetDelegate: TObject;
  end;

type
  ICoordinateConversion = interface (IDelegate) ['ISpriteCoordinateConversion']
    
    // return the parent coordinate system(canvas, layer or sprite)
    function GetParentCoordinateSystem: TObject;
    
    { point: A point specifying a location in the coordinate system of the caller.
      system: The system into whose coordinate system "point" is to be converted.
      result: The point converted to the coordinate system of "system". }
    function ConvertPointTo(point: TPoint; system: TObject): TPoint;
    
    { point: A point specifying a location in the coordinate system of "system".
      system: The system with "point" in its coordinate system.
      result: The point converted to the coordinate system of the caller. }
    function ConvertPointFrom(point: TPoint; system: TObject): TPoint;
    
    function ConvertRectTo(rect: TRect; system: TObject): TRect;
    function ConvertRectFrom(rect: TRect; system: TObject): TRect;
  end;

const
  kNotificationWindowWillOpen = 'TWindow.WillOpen';
  kNotificationWindowWillClose = 'TWindow.WillClose';
  kNotificationWindowDidOpen = 'TWindow.DidOpen';
  kNotificationWindowDidClose = 'TWindow.DidClose';

const
  kNotificationFrameChanged = 'TView.FrameChanged';
  kNotificationFocusChanged = 'TView.FocusChanged';

const
  kNotificationScreenWillResize = 'TScreen.WillResize';
  kNotificationScreenDidResize = 'TScreen.DidResize';

type
  TAutoresizingOption = ( MinXMargin,
                          WidthSizable,
                          MaxXMargin,
                          MinYMargin,
                          HeightSizable,
                          MaxYMargin
                          );  
  TAutoresizingOptions = set of TAutoresizingOption;  

const
  TAutoresizingStretchToFill = [TAutoresizingOption.MinXMargin, TAutoresizingOption.MinYMargin, 
                                TAutoresizingOption.MaxXMargin, TAutoresizingOption.MaxYMargin, 
                                TAutoresizingOption.WidthSizable, TAutoresizingOption.HeightSizable];

type
  TWindowOption = ( Modal,
                    MoveableByBackground
                    );

  TWindowOptions = set of TWindowOption;

type
  TWindowLevel = (
    Normal = 0,
    Utility = 1,
    Menu = 2,
    Drag = 3
  ); 

type
  TWindow = class;
  TView = class;
  TControl = class;
  TDraggingSession = class;

  TViewList = specialize TFPGList<TView>;
  TViewClass = class of TView;

  TWindowList = specialize TFPGList<TWindow>;
  TWindowClass = class of TWindow;
  TWindowArray = array of TWindow;

  IDraggingSource = interface;

  { TResponder }

  TResponder = class
    protected
      procedure HandleCommand(command: string); virtual;
      procedure HandleKeyEquivalent(event: TEvent); virtual;
    public
      procedure DefaultHandlerStr(var message); override;
  end;

  { TApplication }

  TApplication = class(TResponder)
    private
      locked: boolean;
      list: array[TWindowLevel] of TWindowList;
      pendingClose: TWindowList;
      function GetWindow(level: TWindowLevel; index: integer): TWindow;
      property Get[level: TWindowLevel; index: integer]: TWindow read GetWindow; default;
    private
      procedure Add(window: TWindow);
      procedure Remove(window: TWindow);
      procedure MoveToFront(window: TWindow);
      procedure ResizeScreen(event: TEvent);
      function PollEvent(event: TEvent): boolean;
    protected
      procedure HandleKeyEquivalent(event: TEvent); override;
      procedure HandleCommand(command: string); override;
    public
      { Static }
      class function FirstResponder: TObject;

      { Methods }
      function PollEvent(constref event: TEvent.TRawEvent): boolean;

      procedure Update;
      function FrontWindow: TWindow;
      function AvailableWindows: TWindowArray;
      function FindWindow(window: TWindow): boolean;
      function FindWindowOfClass(ofClass: TWindowClass): TWindow;
      function FrontWindowOfAnyLevel: TWindow;
      function FrontWindowOfLevel(level: TWindowLevel): TWindow;

      procedure AfterConstruction; override;
  end;

  { TView }

  TView = class (TResponder, ICoordinateConversion)
    private
      function GetSubviews: TViewList; inline;
    public
      
      { Class Methods }
      class function StyleName: string; virtual;

      { Constructors }
      constructor Create; overload;
      constructor Create(_frame: TRect); overload;
      
      { Accessors }
      procedure SetFrame(newValue: TRect);
      procedure SetBounds(newValue: TRect); 
      procedure SetSize(width, height: TScalar); overload;
      procedure SetSize(newValue: TVec2); overload;
      procedure SetWidth(newValue: TScalar);
      procedure SetHeight(newValue: TScalar);
      procedure SetLocation(x, y: TScalar); overload;
      procedure SetLocation(where: TPoint); overload;
      procedure SetLeftEdge(offset: TScalar);
      procedure SetTopEdge(offset: TScalar);
      procedure SetRightEdge(offset: TScalar);
      procedure SetBottomEdge(offset: TScalar);
      procedure SetBackgroundColor(newValue: TColor);
      procedure SetAutoresizingOptions(newValue: TAutoresizingOptions);
      procedure SetCanAcceptFocus(newValue: boolean);
      procedure SetPostsFrameChangedNotifications(newValue: boolean);
      procedure SetTag(newValue: integer);
      procedure SetEnableClipping(newValue: boolean);

      function GetWindow: TWindow;
      function GetAutoresizingOptions: TAutoresizingOptions;
      function GetWidth: TScalar; inline;
      function GetHeight: TScalar; inline;
      function GetSize: TVec2; inline;
      function GetLocation: TPoint;
      function GetFrame: TRect; virtual;
      function GetBounds: TRect; inline;
      function GetParent: TView; inline;
      function GetTag: integer; inline;

      function IsOpaque: boolean; virtual;

      { Properties }
      property Window: TWindow read GetWindow;
      property Subviews: TViewList read GetSubviews;
      property Frame: TRect read GetFrame write SetFrame;
      property Bounds: TRect read GetBounds write SetBounds;
      property Tag: integer read GetTag;

      { Managing Subviews }
      procedure AddSubview(view: TView);
      procedure AddSubviews(views: array of TView);
      procedure InsertSubview(view: TView; index: integer);
      procedure RemoveSubview(view: TView);
      procedure RemoveSubviews;
      procedure RemoveFromParent;

      function FindParent(ofClass: TViewClass): TView;
      function FindSubview(withTag: integer): TView;  
      function GetChildIndex: integer;

      { Controls }
      // TODO: remove these to helpers so we can decouple TControl from TView
      function FindValue(identifier: string): variant;
      function FindControl(identifier: string): TControl;

      { Keyboard }
      procedure SendKeyDown(event: TEvent);
      function IsFocused(global: boolean = false): boolean;
      procedure GiveFocus;
      procedure AdvanceFocus; virtual;

      { Methods }
      function IsMember(viewClass: TViewClass): boolean; inline;
      destructor Destroy; override;
      procedure ChangeAutoresizingOptions(newValue: TAutoresizingOptions; add: boolean);

      { Layout }
      procedure LayoutIfNeeded;
      procedure NeedsLayoutSubviews;
      procedure LayoutSubviews; virtual;

      { Visibility }
      function IsVisible: boolean;
      function IsHidden: boolean;
      procedure SetVisible(newValue: boolean);
      procedure SetHidden(newValue: boolean);

      { ICoordinateConversion }
      function ConvertPointTo(point: TPoint; system: TObject): TPoint;
      function ConvertPointFrom(point: TPoint; system: TObject): TPoint;
      function ConvertRectTo(rect: TRect; system: TObject): TRect;
      function ConvertRectFrom(rect: TRect; system: TObject): TRect;
      function GetParentCoordinateSystem: TObject; virtual;

      { Geometry }
      function ContainsPoint(point: TPoint): boolean;
      function ContainsRect(rect: TRect): boolean;
      function IntersectsRect(rect: TRect): boolean;
      function InputHit(event: TEvent): boolean;

    protected
      procedure Initialize; virtual;
      procedure Draw; virtual;
      procedure DrawDebugWidgets; virtual;
      procedure Update; virtual;
      procedure AutoResize; virtual;
      function ShouldDrawSubview(view: TView): boolean; virtual;
      function IsSubviewClipping(view: TView): boolean; inline;

      procedure PushClipRect(rect: TRect);
      function GetClipRect: TRect; virtual;

      { View Handlers }
      procedure HandleFrameDidChange(previousFrame: TRect); virtual;
      procedure HandleFrameWillChange(var newFrame: TRect); virtual;
      procedure HandleWillRemoveFromParent(view: TView); virtual;
      procedure HandleDidRemoveFromParent(view: TView); virtual;
      procedure HandleWillAddToParent(view: TView); virtual;
      procedure HandleWillAddToWindow(win: TWindow); virtual;
      procedure HandleDidAddToParent(view: TView); virtual;
      procedure HandleVisibilityChanged(visible: boolean); virtual;
      procedure HandleSubviewsChanged; virtual;
      procedure HandleWillAddSubview(view: TView); virtual;
      procedure HandleWillRemoveSubview(view: TView); virtual;
      procedure HandleWillBecomeFocused; virtual;
      procedure HandleDidBecomeFocused; virtual;
      procedure HandleWillResignFocus; virtual;

      { Keyboard Events }
      procedure HandleKeyDown(event: TEvent); virtual;
      procedure HandleKeyEquivalent(event: TEvent); override;

      { Generic Input Events }
      procedure HandleInputPress(event: TEvent); virtual;
      procedure HandleInputStarted(event: TEvent); virtual;
      procedure HandleInputEnded(event: TEvent); virtual;
      procedure HandleInputDragged(event: TEvent); virtual;

      { Mouse Events }
      procedure HandleMouseUp(event: TEvent); virtual;
      procedure HandleMouseDown(event: TEvent); virtual;
      procedure HandleMouseMoved(event: TEvent); virtual;
      procedure HandleMouseEntered(event: TEvent); virtual;
      procedure HandleMouseExited(event: TEvent); virtual;
      procedure HandleMouseDragged(event: TEvent); virtual;
      procedure HandleMouseWheelScroll(event: TEvent); virtual;
      procedure HandleContextualClick(event: TEvent); virtual;
      function AcceptsMouseMovedEvents: boolean; virtual;
      
      { Properties }
      property ClipRect: TRect read GetClipRect;

    private type
      TInitialState = record
        margin: TAABB;
        relativeSize: TVec2;
        relativeMid: TVec2;
      end;
    private
      parentWindow: TWindow;
      backgroundColor: TColor;
      autoresizingOptions: TAutoresizingOptions;
      m_subviews: TViewList;
      m_parent: TView;
      m_tag: integer;
      m_frame: TRect;
      renderOrigin: TVec2;
      initialState: TInitialState;

      // TODO: make an enum we can use once properties are established
      m_visible: boolean;
      enableClipping: boolean;
      canAcceptFocus: boolean;
      wantsFocus: boolean;
      settingVisible: boolean;
      postsFrameChangedNotifications: boolean;
      didAutoResize: boolean;
      postingFrameChangeNotification: boolean;
      m_needsLayoutSubviews: boolean;
      m_needsDisplay: boolean;

      procedure SetParent(newValue: TView);
      procedure SetNeedsDisplay(newValue: boolean);
      function GetResolution: TScalar;
      procedure DisplayNeedsUpdate;
      procedure PostFrameChangedNotification;
      procedure ReliquishFocus;
      procedure DrawInternal(parentOrigin: TVec2);
      procedure LayoutRoot;
      procedure InternalLayoutSubviews;
      procedure SubviewsAreClipping(var clipping: boolean; deep: boolean = true);
      procedure TestMouseTracking(event: TEvent);
      procedure TestDragTracking(event: TEvent);
    public
      property NeedsDisplay: boolean read m_needsDisplay write SetNeedsDisplay;
  end;

  { TScreen }

  TScreen = class(TView)
    private
      { This is the rectangle defining the portion of the screen in 
        which it is currently safe to draw your application content. }
      function GetVisibleFrame: TRect;
    public
      class function MainScreen: TScreen;
      property VisibleFrame: TRect read GetVisibleFrame;
  end;

  IWindowDelegate = interface (IDelegate) ['IWindowDelegate']
    function HandleWindowShouldClose(window: TWindow): boolean;
    procedure HandleWindowWillClose(window: TWindow);
  end;

  TWindow = class (TView, IDelegation)
    public

      { Class Methods }
      class function ScreenRect: TRect;
      class function KeyWindow: TWindow;
      class function MouseLocation: TPoint;
      class function FindWindow(ofClass: TWindowClass): TWindow;
      class function FindWindowAtMouse: TWindow;
      class function IsFrontWindowBlockingInput(event: TEvent = nil): boolean;
      class function DoesFrontWindowHaveKeyboardFocus: boolean;

      { Constructors }
      constructor Create; overload;

      { Accessors }
      procedure SetContentSize(newValue: TVec2);
      procedure SetContentView(newValue: TView);
      procedure SetMoveableByBackground(newValue: boolean);
      procedure SetWindowLevel(newValue: TWindowLevel);

      function GetContentSize: TVec2; virtual;
      function GetContentFrame: TRect; virtual;
      function GetFocusedView: TView;
      function GetParentCoordinateSystem: TObject; override;

      function IsFront: boolean;
      function IsModal: boolean;
      function IsFloating: boolean;
      function IsKey: boolean;

      { Properties }
      property ContentSize: TVec2 read GetContentSize;
      property ContentFrame: TRect read GetContentFrame;

      { IDelegation }
      procedure SetDelegate(newValue: TObject);
      function GetDelegate: TObject;

      { Methods }
      function IsOpen: boolean;
      procedure MakeKey; 
      procedure MakeKeyAndOrderFront;
      procedure Close;
      procedure OrderFront;
      procedure Center;
      procedure SendDefaultAction;
      procedure AdvanceFocus; override;
      function ShouldConstrainToSafeArea: boolean;

      destructor Destroy; override;

    protected
      procedure Initialize; override;
      procedure SetModal(newValue: boolean);
      procedure PerformClose(params: TInvocationParams);

      function ShouldMoveByBackground(event: TEvent): boolean; virtual;
      function ShouldResize(event: TEvent): boolean; virtual;
      function ShouldClose: boolean; virtual;

      procedure HandleFrameWillChange(var newFrame: TRect); override;
      procedure HandleFrameDidChange(previousFrame: TRect); override;
      
      { Notifications }
      procedure HandleWillClose; virtual;
      procedure HandleDidAddToScreen; virtual;
      procedure HandleWillResignKeyWindow; virtual;
      procedure HandleWillBecomeKeyWindow; virtual;
      procedure HandleDidBecomeKeyWindow; virtual;
      procedure HandleWillResignFrontWindow; virtual;
      procedure HandleDidResignFrontWindow; virtual;
      procedure HandleWillBecomeFrontWindow; virtual;
      procedure HandleDidBecomeFrontWindow; virtual;
      procedure HandleScreenDidResize; virtual;

      { Events }
      procedure HandleInputStarted(event: TEvent); override;
      procedure HandleInputDragged(event: TEvent); override;
      procedure HandleInputEnded(event: TEvent); override;
      
      { Mouse Events }
      function AcceptsMouseMovedEvents: boolean; override;
      function AcceptsKeyboardEvents: boolean; virtual;
      procedure HandleMouseMoved(event: TEvent); override;
      procedure HandleKeyEquivalent(event: TEvent); override;

      { IKeyboardEventDelegate }
      procedure HandleKeyDown(event: TEvent); override;
      
      { Layout }
      function GetFrameForContentFrame(_contentFrame: TRect): TRect; virtual;

    private
      windowLevel: TWindowLevel;
      modal: boolean;
      moveableByBackground: boolean;
      freeWhenClosed: boolean;
      wantsCenter: boolean;
      delegate: TObject;
      pressOrigin: TPoint;
      dragOrigin: TPoint;
      resizeOrigin: TPoint;
      resizeOriginalSize: TVec2;
      focusedView: TView;
      mouseInsideView: TView;
      defaultButton: TView;
      frameBuffer: TFrameBuffer;
      tempBuffer: TFrameBuffer;
      dirtyRect: TRect;

      function GetWindowLevel: TWindowLevel;
      procedure HandleDefaultAction(var msg); message 'DefaultAction';
      procedure FindSubviewForMouseEvent(event: TEvent; parent: TView; var outView: TView);
      procedure SetFocusedView(newValue: TView);
      procedure ProcessKeyDown(super: TView; event: TEvent);
      function PollEvent(event: TEvent): boolean;
      procedure FinalizeClose;
      function ShouldAllowEnabling: boolean;
      procedure Render;
  end;

  { TDraggingSession }

  TDraggingSession = class(TWindow)
    private
      source: IDraggingSource;
      m_operation: TDragOperation;
      offset: TVec2;
      items: TDraggingItems;
      dragImage: TTexture;
      dragTarget: TView;
    protected
      procedure HandleInputDragged(event: TEvent); override;
      procedure HandleInputEnded(event: TEvent); override;
      procedure TrackDrag(view: TView; event: TEvent);
    public
      class function IsDragging: boolean;
      constructor Create(dragEvent: TEvent; _offset: TVec2; _source: IDraggingSource);
      destructor Destroy; override;
      procedure Draw; override;
      procedure SetImage(size: TVec2; image: TTexture);
      property Operation: TDragOperation read m_operation;
  end;

  { IDraggingDestination }

  IDraggingDestination = interface (IDelegate) ['IDraggingDestination']
    function HandleDraggingEntered(session: TDraggingSession): TDragOperation;
    function HandleDraggingUpdated(session: TDraggingSession): TDragOperation;
    procedure HandleDraggingExited(session: TDraggingSession);
    function HandlePerformDragOperation(session: TDraggingSession): boolean;
  end;

  { IDraggingSourceDelegate }

  IDraggingSource = interface (IDelegate)
    procedure HandleDraggingSessionWillBeginAtPoint(session: TDraggingSession; screenPoint: TPoint);
    procedure HandleDraggingSessionMovedToPoint(session: TDraggingSession; screenPoint: TPoint);
    procedure HandleDraggingSessionEndedAtPoint(session: TDraggingSession; screenPoint: TPoint; operation: TDragOperation);
  end;

type
  TPopoverBehavior = (ApplicationDefined,     { Your application assumes responsibility for closing the popover. }
                      Transient,              { The system will close the popover when the user interacts with a user interface element outside the popover. }
                      Semitransient);         { The system will close the popover when the user interacts 
                                                with user interface elements in the window containing the popover's positioning view. }

  TPopover = class (TWindow)
    public
      behavior: TPopoverBehavior;
    public
      constructor Create(inDelegate: TWindow; inContentSize: TVec2i);
      procedure Show(positioningRect: TRect; positioningView: TView; preferredEdge: TRectEdge);
      procedure SetBehavior(newValue: TPopoverBehavior);
      destructor Destroy; override;
    protected
      procedure Update; override;
      procedure Initialize; override;
      procedure HandleInputStarted(event: TEvent); override;
      procedure HandleInputDragged(event: TEvent); override;
      procedure HandleWillResignFrontWindow; override;
      procedure HandleCloseEvent(event: TEvent); virtual;
      procedure HandlePositioningFrameWillChange(var newFrame: TRect); virtual;
    private
      positioningRect: TRect;
      positioningView: TView;
      preferredEdge: TRectEdge;
      positioningEdgeMargin: integer;
      procedure UpdatePosition;
      procedure HandleWindowWillOpen(notification: TNotification);
  end;

type
  TControlState = (Off, On, Mixed);

  TControlKeyEquivalent = record
    keycode: TKeyCode;
    modifiers: TShiftState;
  end;

  TControlBinding = record
    prop: string;
    controller: TObject;
    procedure Apply(control: TControl);
  end;

  TControl = class (TView)
    private
      binding: TControlBinding;
    public
      { Accessors }
      procedure SetStringValue(newValue: string); virtual; overload;
      procedure SetEnabled(newValue: boolean);
      procedure SetControlState(newValue: TControlState);
      procedure SetAction(newValue: TInvocation); overload;
      procedure SetAction(newValue: string); overload;
      procedure SetKeyEquivalent(keycode: TKeycode; modifiers: TShiftState = []); virtual;
      procedure SetIdentifier(newValue: string);
      procedure SetBinding(prop: string; controller: TObject);
      procedure SetController(controller: TObject);

      function GetValue: variant;
      function GetStringValue: string;
      function GetFloatValue: single;
      function GetDoubleValue: double;
      function GetIntegerValue: integer;
      function GetLongValue: longint;
      function GetBoolValue: boolean;
      function GetAction: TInvocation;

      function GetControlState: TControlState;

      function IsEnabled: boolean;
      function HasActions: boolean;

      { Properties }
      property StringValue: string read GetStringValue;
      property FloatValue: single read GetFloatValue;
      property DoubleValue: double read GetDoubleValue;
      property IntegerValue: integer read GetIntegerValue;
      property LongValue: longint read GetLongValue;
      property BoolValue: boolean read GetBoolValue;

      property BindingName: string read binding.prop;

      { Methods }
      procedure AddAction(newValue: TInvocation);
      procedure InsertAction(index: integer; newValue: TInvocation);
      procedure InvokeAction;
      procedure SizeToFit; virtual;
      procedure Bind;
      destructor Destroy; override;

    protected
      procedure Initialize; override;
      procedure HandleValueChanged; virtual;
      procedure HandleStateChanged; virtual;
      procedure HandleActivityChanged; virtual;
      procedure HandleKeyEquivalent(event: TEvent); override;
    private
      m_value: variant;
      m_actions: TInvocationList;
      m_enabled: boolean;
      controlFont: IFont;
      state: TControlState;
      keyEquivalent: TControlKeyEquivalent;
      identifier: ansistring;

      function GetActions: TInvocationList;
      property Actions: TInvocationList read GetActions;

      procedure SetIdentifierFromTitle(newValue: string);
      procedure SetValue(newValue: variant; alwaysNotify: boolean = false);
      procedure SetStringValue(newValue: string; alwaysNotify: boolean); overload;
  end;

type
  TImageViewOption = (ScaleToFit, 
                      ScaleProportionately, 
                      Center
                      );

  TImageViewOptions = set of TImageViewOption;

type
  TImageView = class (TControl)
    private
      m_frontImage: TTexture;
      backgroundImage: TTexture;
      options: TImageViewOptions;
    protected
      procedure Draw; override;
    public

      { Constructors }
      constructor Create(inFrame: TRect; image: TTexture); overload;

      { Methods }
      procedure SetImage(newValue: TTexture); overload;
      procedure SetOptions(newValue: TImageViewOptions);
      procedure SetBackgroundImage(newValue: TTexture);

      { Properties }
      property Image: TTexture read m_frontImage;
  end;

type
  PLineLayout = ^TLineLayout;
  TLineLayout = record
    {
      TODO: keep the parent node (which is above us)
      so we when line wrapping is implemented we can find
      the literal line number which preceeds the line and
      use that determine the line number of the current line (and lines below)
      a concept of dirty flags needs to be added also so that
      when lines are removed we know to track the parent and recalculate
    }
    offset: LongInt;
    line: integer;
    columns: integer;
    prev: PLineLayout;
    next: PLineLayout;
    class operator = (left: TLineLayout; right: TLineLayout): boolean;
  end;

type
  TTextStorage = class
    // text storage will be used for style runs
    m_text: pchar;
    length: integer;

    //function FindCharacterAtPoint(point: TVec2i): LongInt;
    //function FindPointAtLocation(location: LongInt): TVec2i;
    //function FindWordAtPoint(point: TVec2i): TTextRange;
    //function FindLineAtPoint(point: TVec2i): TTextRange;
  end;

type
  TLayoutManager = class
    private type
      TLineList = specialize TFPGList<TLineLayout>;
    private
      lines: TLineList;
      // TODO: this needs to be a pointer with a range
      text: TFontString;
      //range: TTextRange;
      //where: TVec2;
      color: TColor;
      scale: float;
      textAlignment: TTextAlignment;
      wrap: TTextWrapping;
      // TODO: make this another record for an overload
      //testPoint: TVec2;
      //testOffset: TTextOffset;
      //hitPoint: TVec2;
      //hitOffset: TTextOffset;
      //textSize: TVec2;
      function GetLineHeight: integer; inline;
      procedure DrawLine(origin: TVec2; line: TLineLayout);
      procedure DrawGutter(origin: TVec2; startLine, endLine: integer; out gutterWidth: integer);
    public
      cursor: TTextRange;
      font: IFont;

      constructor Create;
      procedure SetText(const newText: ansistring);
      procedure Draw(origin: TVec2; visibleRect: TRect);

      property LineHeight: integer read GetLineHeight;
  end;

type
  TTextViewOption = (
      WidthTracksContainer,
      HeightTracksContainer,
      WidthTracksView,
      Editable
    );
  TTextViewOptions = set of TTextViewOption;
  TTextViewString = UnicodeString;

  TTextViewSelectionMode = (
      Character,
      Word,
      Line
    );

type
  TTextView = class (TView)
    private
      m_text: TTextViewString;
      textFont: IFont;
      textColor: TColor;
      textAlignment: TTextAlignment;
      cursor: TTextRange;
      options: TTextViewOptions;
      selMode: TTextViewSelectionMode;
      maximumWidth: integer;
      dragStart: longint;
      dirty: boolean;
    protected
      procedure Initialize; override;
      procedure Draw; override;

      { Methods }
      procedure TextLayoutChanged;

      { Events }
      procedure HandleFrameDidChange(previousFrame: TRect); override;
      procedure HandleKeyDown(event: TEvent); override;
      procedure HandleInputStarted(event: TEvent); override;
      procedure HandleInputDragged(event: TEvent); override;
      procedure HandleInputEnded(event: TEvent); override;
      procedure HandleKeyEquivalent(event: TEvent); override;

      { Handlers }
      function HandleWillInsertText(var newText: TTextViewString): boolean; virtual;
      function HandleWillDelete: boolean; virtual;

      { Rendering }
      function GetTextFrame: TRect; virtual;
      function GetTextLayout: TTextLayoutOptions;
      
    public

      { Constructors }
      constructor Create(inFrame: TRect; text: string; inWidthTracksContainer: boolean = true; inFont: IFont = nil); overload;

      { Accessors }
      procedure SetText(newValue: TTextViewString);
      procedure SetFont(newValue: IFont);
      procedure SetWidthTracksContainer(newValue: boolean);
      procedure SetHeightTracksContainer(newValue: boolean);
      procedure SetWidthTracksView(newValue: boolean);
      procedure SetMaximumWidth(newValue: integer);
      procedure SetTextAlignment(newValue: TTextAlignment);
      procedure SetEditable(newValue: boolean);
      procedure SetTextColor(newValue: TColor);

      function GetFont: IFont; inline;
      function GetTextSize: TVec2; inline;

      function IsEditable: boolean; inline;
      function IsSelectable: boolean; inline;
      function IsReadyToLayout: boolean; inline;

      { Methods }
      procedure LayoutSubviews; override;
      procedure InsertText(location, length: TTextOffset; newText: TTextViewString); overload;
      procedure InsertText(newText: TTextViewString); overload;
      procedure DeleteText(location, length: TTextOffset);

      procedure ToggleOption(newValue: boolean; option: TTextViewOption);
      procedure MoveCursor(location: TTextOffset; grow: boolean = false); 
      procedure SelectRange(location, length: TTextOffset);

      { Text Storage }
      function FindCharacterAtPoint(point: TVec2i): LongInt;
      function FindPointAtLocation(location: LongInt): TVec2i;
      function FindWordAtPoint(point: TVec2i): TTextRange;
      function FindLineAtPoint(point: TVec2i): TTextRange;

      { Properties }
      property Text: TTextViewString read m_text write SetText;
      property TextFrame: TRect read GetTextFrame;
      property TextLayout: TTextLayoutOptions read GetTextLayout;
  end;

type
  TTextField = class (TControl)
    private
      m_text: TTextView;
      m_borderWidth: integer;
      // TODO: TControl already has "controlFont" so we probably added this by accident
      m_font: IFont;
      m_labelView: TTextView;
      procedure SetBorderWidth(newValue: integer);
      procedure SetFont(newValue: IFont);
      procedure SetLabelString(newValue: string);
      procedure AdjustFrame;

      property LabelView: TTextView read m_labelView;
    private
      textFrame: TRect;
    protected
      procedure HandleWillAddToParent(view: TView); override;
      procedure HandleViewFrameChanged(notification: TNotification);
      procedure HandleViewFocusChanged(notification: TNotification);
      procedure HandleInputStarted(event: TEvent); override;
      procedure HandleKeyDown (event: TEvent); override;
    public
      procedure Draw; override;
      property BorderWidth: integer read m_borderWidth write SetBorderWidth; 
      property TextFont: IFont read m_font write SetFont; 
      property LabelString: string write SetLabelString;
  end;

type
  TButtonImagePosition = (Left, Center, Right);

type
  TButton = class (TControl)
    public
      constructor Create(_frame: TRect; _title: string; _font: IFont = nil; _action: TInvocation = nil); overload;

      procedure SetTitle(newValue: string);
      procedure SetFont(newValue: IFont);
      procedure SetMaximumWidth(newValue: integer);
      procedure SetResizeByWidth(newValue: boolean);
      procedure SetImage(newValue: TTexture);
      procedure SetImagePosition(newValue: TButtonImagePosition);
      procedure SetSound(newValue: string);
      procedure SetDefault(newValue: boolean);
      procedure SetEnableContentClipping(newValue: boolean);

      function GetImage: TTexture;
      function GetImagePosition: TButtonImagePosition;
      function GetTitle: string; inline;

      function IsPressed: boolean;
      function IsTracking: boolean;

    protected
      resizeByWidth: boolean;
      pressed: boolean; 
      tracking: boolean;
      textView: TTextView;
      imageView: TImageView;

      procedure Initialize; override;
      procedure Draw; override;
      procedure LayoutSubviews; override;

      function GetTitleFrame: TRect; virtual;
      function GetContainerFrame: TRect; virtual;

      procedure HandleValueChanged; override;
      procedure HandleStateChanged; override;
      procedure HandleWillAddToWindow(win: TWindow); override;

      { Handlers }
      procedure HandlePressed; virtual;
      procedure HandleAction virtual;

      { Events }
      procedure HandleInputEnded(event: TEvent); override;
      procedure HandleInputStarted(event: TEvent); override;
      procedure HandleInputDragged(event: TEvent); override;

    private
      imagePosition: TButtonImagePosition;
      sound: string;
      wantsDefault: boolean;
      enableContentClipping: boolean;

      procedure DepressButton;
      procedure RecalculateText;
  end;

type
  TCheckBox = class (TButton)
    public
      procedure SetChecked(newValue: boolean); overload;
      function IsChecked: boolean;
    protected
      procedure Initialize; override;
      procedure HandlePressed; override;
      function GetButtonFrame: TRect; virtual;
      function GetTitleFrame: TRect; override;
      function GetContainerFrame: TRect; override;
  end;

type
  TRadioGroup = class;

  TRadioButton = class (TCheckBox)
    private
      function GetRadioGroup: TRadioGroup;
    protected
      property RadioGroup: TRadioGroup read GetRadioGroup;
      procedure HandlePressed; override;
  end;
  TRadioButtonClass = class of TRadioButton;

  TRadioGroup = class (TView)
    public
      class function ButtonClass: TRadioButtonClass; virtual;
      constructor Create(position: TVec2; vertical: boolean; count: integer = 0);
      procedure AddButton(title: string); virtual;
      function SelectedButton: TRadioButton;
      function IndexOfSelectedButton: integer;
    protected
      procedure Initialize; override;
      procedure LayoutSubviews; override;
    private
      buttonMargin: integer;
      vertical: boolean;
      resizeByWidth: boolean;
  end;

type
  TSlider = class (TControl)
    private type
      TSliderValue = integer;
    public

      { Constructors }
      constructor Create(current, min, max: TSliderValue; _frame: TRect); overload;
      constructor Create(propName: string; controller: TObject; current, min, max: TSliderValue; _frame: TRect); overload;

      { Accessors }
      procedure SetValue(newValue: TSliderValue);
      procedure SetInterval(newValue: integer);
      procedure SetTickMarks(newValue: integer);
      procedure SetTitle(newValue: string);
      procedure SetTitleFont(newValue: IFont);
      procedure SetShowValueWhileDragging(newValue: boolean);
      procedure SetLiveUpdate(newValue: boolean);

      function GetValue: TSliderValue;
      function GetMinValue: TSliderValue;
      function GetMaxValue: TSliderValue;

      function IsVertical: boolean;
      function IsDragging: boolean;

      procedure LayoutSubviews; override;

      { Properties }
      property Value: TSliderValue read GetValue;
      property MinValue: TSliderValue read GetMinValue;
      property MaxValue: TSliderValue read GetMaxValue;

    protected
      range: TRangeInt;
      // TODO: TControl has a "controlFont" which we should use instead
      labelFont: IFont;

      procedure Initialize; override;
      procedure Draw; override;
      procedure DrawHandle(rect: TRect); virtual;
      procedure DrawTrack(rect: TRect); virtual;

      procedure HandleInputStarted(event: TEvent); override;
      procedure HandleInputDragged(event: TEvent); override;
      procedure HandleInputEnded(event: TEvent); override;
      procedure HandleValueChanged; override;
      procedure HandleStateChanged; override;

      function GetTrackSize: TVec2;
      function GetTrackFrame: TRect; virtual;
      function GetHandleFrame: TRect; virtual;
      function GetTitleFrame: TRect; virtual;

      function ClosestTickMarkToValue(inValue: TSliderValue): integer;
      function ValueAtRelativePosition(percent: single): TSliderValue;
      function RectOfTickMarkAtIndex(index: integer): TRect;
    private
      handleFrame: TRect;
      dragOrigin: TPoint;
      interval: integer;
      dragging: boolean;
      tickMarks: integer;
      liveUpdate: boolean;
      tickMarkFrames: array[0..32] of TRect;
      textView: TTextView;
      showValueWhileDragging: boolean;
      startValue: variant;
  end;


type
  TScrollView = class;

  TScroller = class (TSlider)
    protected
      procedure HandleWillAddToParent(sprite: TView); override;
      procedure HandleFrameDidChange(previousFrame: TRect); override;
      procedure HandleValueChanged; override;
      function GetTrackFrame: TRect; override;
      procedure Initialize; override;
    private
      upButton: TButton;
      downButton: TButton;
      scrollView: TScrollView;
  end;

  TScrollView = class (TControl)
    public
      scrollButtonAmount: integer;
      verticalScrollerOffset: TPoint;
      horizontalScrollerOffset: TPoint;
      contentInset: TPoint;
      contentViewOrigin: TPoint;
    public
      procedure SetContentSize(newValue: TVec2);
      procedure SetContentView(newValue: TView);
      procedure SetHorizontalScroller(newValue: TScroller);
      procedure SetVerticalScroller(newValue: TScroller);
      procedure SetScrollingLimit(newValue: TScalar);
      
      function GetVisibleRect: TRect;
      function GetVerticalScroller: TScroller;
      function GetHorizontalScroller: TScroller;
      function GetContentView: TView;

      function IsVerticalScrollerVisible: boolean;
      function IsHorizontalScrollerVisible: boolean;

      destructor Destroy; override;
      procedure LayoutSubviews; override;

    protected
      procedure Initialize; override;
      
      procedure HandleMouseWheelScroll(event: TEvent); override;
      procedure HandleInputStarted(event: TEvent); override;
      procedure HandleInputEnded(event: TEvent); override;
      procedure HandleInputDragged(event: TEvent); override;
      procedure Draw; override;
      procedure Update; override;

      function GetHorizontalScrollerFrame: TRect; virtual;
      function GetVerticalScrollerFrame: TRect; virtual;
      function GetClipRect: TRect; override;

      procedure HandleContentViewFrameChanged(notification: TNotification);

    private
      scrollOrigin: TPoint; 
      scrollingLimit: TScalar;
      contentView: TView;
      contentSize: TVec2;
      horizontalScroller: TScroller;
      verticalScroller: TScroller;
      scrollVelocity: TVec2;
      scrollAcceleration: TScalar;

      enableScrollingInertia: boolean;
      enableContentClipping: boolean;
      enableDragScrolling: boolean;
      dragScrolling: boolean;
      dragScrollingOrigin: TPoint;
      dragScrollingDown: TPoint;
      swipeTimer: TTimer;
      
      procedure ScrollUp(var msg); message 'ScrollUp';
      procedure ScrollDown(var msg); message 'ScrollDown';

      procedure HandleSwipeTimer(timer: TTimer);

      function GetScrollableFrame: TRect; 
      function InsertRectForScrollers(rect: TRect): TRect; inline;
      procedure UpdateContentSize;
      procedure Scroll(direction: TPoint);
      procedure SetScrollOrigin(where: TPoint; axisX, axisY: boolean);
  end;

type
  IScrollingContent = interface (IDelegate) ['IScrollingContent']
    procedure HandleScrollingContentChanged(scrollView: TScrollView);
  end;


type 
  TCellState = (Selected, 
                Hovered
                );

type
  TCell = class (TControl)  
    private type
      TCellStates = set of TCellState;
    public
      selectionState: TCellStates;
    public
      procedure SetSelectable(newValue: boolean);
      procedure SetObjectValue(newValue: pointer); virtual;
      procedure SetFont(newValue: IFont); virtual;

      function GetObjectValue: pointer;
      function IsSelectable: boolean;

      destructor Destroy; override;
    protected
      procedure Initialize; override;
    private
      selectable: boolean;
      objectValue: pointer;
      rowIndex: integer;
      font: IFont;
      next: TCell;
  end;
  TCellList = specialize TFPGList<TCell>;
  TCellClass = class of TCell;

type
  TTextAndImageCell = class (TCell)
    private
      imageTitleMargin: TScalar;
    protected
      textView: TTextView;
      imageView: TImageView;
      procedure Initialize; override;
      function GetTextView: TTextView;
      function GetTextFrame: TRect; virtual;
      function GetImageFrame: TRect; virtual;
    public
      procedure SetStringValue(newValue: string); override;
      procedure SetObjectValue(newValue: pointer); override;
      procedure SetFont(newValue: IFont); override;
      procedure SetTextColor(newValue: TColor);
      procedure SetImageTitleMargin(newValue: TScalar);
      
      procedure SetImageValue(newValue: TTexture); overload;
            
      function GetImageValue: TTexture;
      function GetStringValue: string;
      function GetFont: IFont;

      function IsImageVisible: boolean;

      procedure SizeToFit; override;
      procedure LayoutSubviews; override;

      { Properties }
      property TextFrame: TRect read GetTextFrame;
      property ImageFrame: TRect read GetImageFrame;
  end;

type
  TSectionCell = class (TTextAndImageCell)
    public
      class function Height: integer;
      class function Section(title: string): TSectionCell; overload;
      class function Section(title: string; _font: IFont): TSectionCell; overload;
    protected
      procedure Initialize; override;
  end;
  
type
  TTableViewSelection = (None,
                         Single,
                         Multiple
                          );

type
  TCellView = class (TControl, IDelegation)
    private type
      TRowList = specialize TFPGList<Integer>;
    public

      { Cells }
      procedure SetCells(newValue: TCellList);
      procedure AddCells(newValue: TCellList);
      procedure AddCell(cell: TCell);
      procedure RemoveCells(newValue: TCellList);
      procedure RemoveAllCells;

      function GetCells: TCellList;

      { Selection }
      function FindCellWithObjectValue(obj: pointer): TCell;
      procedure SelectCell(cell: TCell; extendSelection: boolean = false; notifyDelegate: boolean = true); overload;
      procedure ClearSelection(notifyDelegate: boolean = true);
      procedure SelectionChanged; virtual;
      procedure RemoveSelection(cell: TCell); overload;
      function GetSelection: TRowList;
      procedure SetSelectionType(newValue: TTableViewSelection);
      procedure SetEnableDragSelection(newValue: boolean);

      { IDelegation }
      procedure SetDelegate(newValue: TObject);
      function GetDelegate: TObject;

      destructor Destroy; override;

    protected
      procedure Initialize; override;
      procedure HandleInputDragged(event: TEvent); override;
      procedure HandleInputStarted(event: TEvent); override;
      procedure HandleInputEnded(event: TEvent); override;
      procedure ArrangeCells; virtual;
    private
      cells: TCellList;
      selection: TRowList;
      selectionType: TTableViewSelection;
      _delegate: TObject;
      enableDragSelection: boolean;
      tracking: boolean;
      pivotRow: integer;
  end;

type
  TTableColumnHeader = class (TView)
  end;

type
  TTableColumn = record
    title: string;
    id: integer;
    width: integer;
    class operator = (left: TTableColumn; right: TTableColumn): boolean;
  end;
  PTableColumn = ^TTableColumn;
  TTableColumnList = specialize TFPGList<TTableColumn>;

type
  TTableView = class;
  
  ITableViewDataSource = interface (IDelegate) ['ITableViewDataSource']
    function TableViewValueForRow(tableView: TTableView; column: TTableColumn; row: integer): pointer;
    function TableViewNumberOfRows(tableView: TTableView): integer;
  end;

  ITableViewCellDelegate = interface (IDelegate) ['ITableViewCellDelegate']
    procedure TableViewPrepareCell(tableView: TTableView; column: TTableColumn; cell: TCell);
  end;

  TTableView = class (TCellView)
    private
      m_dataSource: TObject;
      m_columns: TTableColumnList;
      m_cellDelegate: boolean;
      arrangingCells: boolean;
      cellsNeedArranging: boolean;
      lastColumnTracksWidth: boolean;
      cellSpacing: integer;
      cellHeight: integer;
      cellFont: IFont;
      cellClass: TCellClass;
      totalHeight: TScalar;

      function ColumnAtIndex(index: integer): PTableColumn; inline;
      function GetColumns: TTableColumnList; inline;
      property Columns: TTableColumnList read GetColumns;
      procedure ReloadCellsFromDataSource(dataSource: ITableViewDataSource; firstRow, maxRows: integer);
      procedure ScrollUp;
      procedure ScrollDown;
      function HeightForCell(cell: TCell): integer; inline;
    protected
      procedure Initialize; override;
      procedure Draw; override;
      procedure ArrangeCells; override;
      function ShouldDrawSubview(view: TView): boolean; override;

      procedure HandleDrawSelection(rect: TRect); virtual;
      procedure HandleFrameDidChange(previousFrame: TRect); override;
      procedure HandleDidAddToParent(sprite: TView); override;
      procedure HandleKeyDown(event: TEvent); override;
    public
      procedure SetCellSpacing(newValue: integer);
      procedure SetCellHeight(newValue: integer);
      procedure SetCellFont(newValue: IFont);
      procedure SetCellClass(newValue: TCellClass);
      procedure InsertCells(newValue: TCellList; index: integer);
      function GetCell(index: integer): TCell;
      procedure SetDataSource(newValue: TObject; cellDelegate: boolean = false);
      procedure SetLastColumnTracksWidth(newValue: boolean);

      function GetCellHeight: integer;
      function GetCellSpacing: integer;
      function GetVisibleRange: TRangeInt;
      
      procedure AddColumn(column: TTableColumn); overload;
      procedure AddColumn(id: integer; title: string); overload;
      procedure Reload;
      procedure SizeLastColumnToFit;

      destructor Destroy; override;

      { Properties }
      property VisibleRange: TRangeInt read GetVisibleRange;
  end;

type
  TImageAndTextCellDataSource = class(ITableViewDataSource)
    private type
      TDataList = specialize TFPGList<ITableViewCellDelegate>;
    private
      data: TDataList;
    public
      constructor Create;
      destructor Destroy; override;
      procedure Add(item: ITableViewCellDelegate); inline;
      function TableViewValueForRow(tableView: TTableView; column: TTableColumn; row: integer): pointer;
      function TableViewNumberOfRows(tableView: TTableView): integer;
  end;

type
  ICellViewDelegate = interface (IDelegate) ['ICellViewDelegate']
    procedure HandleSelectionChanged(cellView: TCellView);
    function HandleShouldSelectCell(cellView: TCellView; cell: TCell): boolean;
  end;

type
  ITableViewDelegate = interface (ICellViewDelegate) ['ITableViewDelegate']
  end;
  

type
  TBarItem = class (TControl)
    private
      cellPadding: integer;

      function GetCell: TCell; inline;
    public

      { Constructors }
      constructor Create(_view: TView); overload;
      constructor Create(width: integer); overload;

      { Methods }
      procedure SetView(newValue: TView);
      procedure LayoutSubviews; override;
      procedure Initialize; override;

      { Properties }
      property Cell: TCell read GetCell;
  end;
  TBarItemList = specialize TFPGList<TBarItem>;
  
type
  TItemBar = class (TControl)
    public
      function GetItems: TBarItemList;
      procedure SetItems(newValue: TBarItemList);
      procedure SetItemMargin(newValue: integer);
      procedure AddItem(item: TBarItem);
      procedure RemoveAllItems;
      procedure SetResizeByWidth(newValue: boolean);
      procedure SetEnableContentClipping(newValue: boolean);

      procedure Draw; override;
      destructor Destroy; override;
    protected
      procedure Initialize; override;
      procedure LayoutSubviews; override;
      procedure HandleDidAddItem(item: TBarItem); virtual;
    private
      items: TBarItemList;
      itemOffset: TScalar;
      itemMargin: TScalar;
      resizeByWidth: boolean;
      enableContentClipping: boolean;
  end;

type
  IItemBarDelegate = interface (IDelegate) ['IItemBarDelegate']
    procedure HandleItemBarItemsChanged(itemBar: TItemBar);
  end;  

type
  TTabView = class;
  
  TTabViewItem = class (TBarItem)
    public
      constructor Create(title: string; _pane: TView);
      function GetPane: TView;
      function IsSelected: boolean;
      destructor Destroy; override;
    protected
      procedure Initialize; override;
    private
      pane: TView;
      button: TButton;
      tabView: TTabView;
  end;
  TTabViewItemClass = class of TTabViewItem;  
  TTabViewList = specialize TFPGList<TTabViewItem>;

  TTabBar = class (TItemBar)      
  end;

  ITabViewDelegate = interface (IDelegate) ['ITabViewDelegate']
    function HandleTabViewShouldSelectItem(tabView: TTabView; tabViewItem: TTabViewItem): boolean;
    procedure HandleTabViewWillSelectItem(tabView: TTabView; tabViewItem: TTabViewItem);
    procedure HandleTabViewDidSelectItem(tabView: TTabView; tabViewItem: TTabViewItem);
  end;

  TTabView = class (TView, IDelegation)
    public
    
      { Accessors }
      procedure SetTabHeight(newValue: integer);
      function GetItem(index: integer): TTabViewItem;
      function GetSelectedItem: TTabViewItem;
      
      { Methods }
      procedure AddItem(item: TTabViewItem);
      procedure SelectItem(params: TInvocationParams); overload;
      procedure SelectItem(index: integer); overload;
      
      { IDelegation }
      procedure SetDelegate(newValue: TObject);
      function GetDelegate: TObject;
      
      destructor Destroy; override;     

    protected
      procedure Initialize; override;
      procedure LayoutSubviews; override;
    private
      tabBar: TTabBar;
      selectedItem: TTabViewItem;
      tabHeight: integer;
      delegate: TObject;
  end;

type
  TMenu = class;

  TMenuBarItem = class (TBarItem)
    private
      m_menu: TMenu;
      procedure OpenMenu;
    protected
      procedure HandleInputStarted(event: TEvent); override;
      procedure HandleMouseEntered(event: TEvent); override;
      procedure HandleKeyEquivalent(event: TEvent); override;
    public
      constructor Create(_view: TView; _menu: TMenu);
      property Menu: TMenu read m_menu;
  end;
  TMenuBarItemClass = class of TMenuBarItem;
  TMenuBarItemList = specialize TFPGList<TMenuBarItem>;

  TMenuBar = class (TWindow)
    private
      itemBar: TItemBar;

      function GetItems: TMenuBarItemList;
    protected
      procedure HandleWillAddToParent(view: TView); override;
      procedure HandleScreenDidResize; override;
    public

      { Static }
      class function MainMenu: TMenuBar;
      class function MenuBarHeight: integer; virtual;
      class function ItemMargin: integer; virtual;
      class function MenuBarItemClass: TMenuBarItemClass; virtual;

      { Constructors }
      constructor Create;

      { Methods }
      procedure AddMenu(menu: TMenu);
      function IndexOfMenu(menu: TMenu): integer;
      function HasOpenMenus: boolean;

      { Properties }
      property Items: TMenuBarItemList read GetItems;
  end;

  TMenuItem = class (TControl)
    private
      checked: boolean;
      cell: TTextAndImageCell;
      keyEquivalentCell: TTextAndImageCell;
      m_submenu: TMenu;

      function GetMenu: TMenu;
      function PopupSubmenu(sender: TMenu): TMenu;
      procedure SetKeyEquivalentCellValue(value: string);
      procedure SetSubmenu(newValue: TMenu);

      { Properties }
      property Menu: TMenu read GetMenu;

    protected
      procedure Initialize; override;
      procedure Draw; override;
      procedure HandleInputEnded(event: TEvent); override;

      { Appearance }
      procedure SetHilighted(newValue: boolean);
    public
    
      { Constructors }
      constructor Create(_title: string; _action: TInvocation); overload;
      
      { Accessors }
      procedure SetChecked(newValue: boolean);
      procedure SetFont(newValue: IFont);
      procedure SetImage(newValue: TTexture);
      procedure SetKeyEquivalent(keycode: TKeyCode; modifiers: TShiftState); override;

      function GetTextSize: TVec2i;
      function GetItemIndex: integer;
      function GetTitle: string;
      function IsChecked: boolean;
      function IsSelected: boolean;
      function IsSubmenuOpen: boolean;

      { Properties }
      property Title: string read GetTitle;
      property ItemIndex: integer read GetItemIndex;
      property Submenu: TMenu read m_submenu write SetSubmenu;

      { Methods }
      procedure SizeToFit; override;
      procedure LayoutSubviews; override;
  end;
  TMenuItemClass = class of TMenuItem;
  TMenuItemList = specialize TFPGList<TMenuItem>;

  TSeperatorMenuItem = class (TMenuItem)
  end;

  IMenuDelegate = interface ['IMenuDelegate']
    procedure HandleMenuWillSelectItem(menu: TMenu; item: TMenuItem);
  end;

  IMenuItemValidation = interface ['IMenuItemValidation']
    function HandleValidateMenuItem(item: TMenuItem): boolean;
  end;

  TMenu = class (TPopover)
    private
      font: IFont;
      margin: TVec2i;
      itemHeight: integer;
      minimumWidth: integer;
      popupOrigin: TVec2i;
      m_selectedItem: TMenuItem;
      m_items: TMenuItemList;
      m_menuBarItem: TMenuBarItem;
      m_title: string;
      parentMenu: TMenu;
      childMenu: TMenu;

      procedure ValidateMenuItems;
      function GetSelectedItem: TMenuItem;
      procedure SetSelectedItem(newValue: TMenuItem);
    protected
      procedure Initialize; override;
      procedure HandleWillClose; override;
      procedure HandleCloseEvent(event: TEvent); override;
      function AcceptsMouseMovedEvents: boolean; override;
      procedure TrackSelection(event: TEvent);
      function GetItemFrame(item: TMenuItem): TRect; virtual;

      { Handlers }
      procedure HandleKeyDown(event: TEvent); override;
      procedure HandleMouseMoved(event: TEvent); override;
      procedure HandleMouseDragged(event: TEvent); override;
      procedure HandleSelectionWillChange(newItem: TMenuItem); virtual;
      procedure HandleSelectionDidChange; virtual;

      { Properties }
      property SelectedItem: TMenuItem read GetSelectedItem write SetSelectedItem;
    public

      { Constructors }
      constructor Create(_title: string = '');
      destructor Destroy; override; 

      { Methods }
      procedure SetFont(newValue: IFont);

      procedure AddItem(item: TMenuItem); overload;
      function AddItem(title: string; action: TInvocation): TMenuItem; overload;
      function AddItem(title: string; action: TInvocation; keycode: TKeyCode; modifiers: TShiftState = []): TMenuItem; overload;
      function AddItem(title: string; method: string; keycode: TKeyCode; modifiers: TShiftState = []): TMenuItem; overload;

      procedure InsertItem(index: integer; item: TMenuItem);
      procedure RemoveItem(item: TMenuItem); overload;
      procedure RemoveItem(index: integer); overload;

      procedure LayoutSubviews; override;
      procedure CloseAll;

      { Finding Items }
      function IndexOfItem(item: TMenuItem): integer;
      function IndexOfItemWithTitle(_title: string): integer;
      function IndexOfItemWithTag(_tag: integer): integer;

      function ItemWithTitle(_title: string): TMenuItem;
      function ItemWithTag(_tag: integer): TMenuItem;

      { Opening }
      procedure Popup(where: TPoint); overload;
      procedure Popup(parentView: TView); overload;
      procedure Popup(_positioningRect: TRect; _positioningView: TView; edge: TRectEdge);

      { Drawing }
      procedure DrawSelection(rect: TRect); virtual;

      { Properties }
      property Title: string read m_title;
      property MenuBarItem: TMenuBarItem read m_menuBarItem;
      property Items: TMenuItemList read m_items;
  end;
  TMenuClass = class of TMenu;

{ TPopupButton }

type
  TPopupButton = class (TButton, IWindowDelegate, IMenuDelegate)
    public
      class function MenuClass: TMenuClass; virtual;
      class function MenuItemClass: TMenuItemClass; virtual;

      procedure SetPullsdown(newValue: boolean);

      function AddItem(title: string): TMenuItem;
      function InsertItem(index: integer; title: string): TMenuItem;

      procedure SelectItem(item: TMenuItem);
      procedure SelectItemAtIndex(index: integer);
      procedure SelectItemWithTag(_tag: integer);
      procedure SelectItemWithTitle(title: string);

      function TitleOfSelectedItem: string;
      function IndexOfSelectedItem: integer;
      function SelectedTag: integer;
    protected
      procedure Initialize; override;
      procedure LayoutSubviews; override;
      procedure HandlePressed; override;
      procedure HandleInputStarted(event: TEvent); override;
      procedure HandleInputEnded(event: TEvent); override;
      procedure HandleInputDragged(event: TEvent); override;

      procedure HandleWillSelectItem; virtual;
      procedure HandleDidSelectItem; virtual;

      function GetMinimumMenuWidth: integer; virtual;
      function GetCheckmarkImage: TTexture; virtual;

    private
      procedure HandleWindowWillClose(win: TWindow);
      function HandleWindowShouldClose(win: TWindow): boolean;
      procedure HandleMenuWillSelectItem(menu: TMenu; item: TMenuItem);
    private
      menu: TMenu;
      m_selectedItem: TMenuItem;
      pullsdown: boolean;
      procedure SetSelectedItem(newValue: TMenuItem);
      procedure Popup;

      { Properties }
      property SelectedItem: TMenuItem read m_selectedItem write SetSelectedItem;
      property CheckmarkImage: TTexture read GetCheckmarkImage;
  end;

{ TMatrixView }

type
  TMatrixView = class (TCellView)
    public
      
      { Accessors }
      procedure SetCellSize(newValue: TVec2);
      procedure SetCellMargin(newValue: TScalar);
      procedure SetColumns(newValue: integer);
      procedure SetResizeToFit(newValue: boolean);

      function GetCellSize: TVec2;
      function GetCellMargin: TScalar;
      function GetColumns: integer;
      
      { Methods } 
      function SizeForGrid(grid: TVec2): TVec2;
      procedure ArrangeCells; override;
      function GetCellSizeForLayout(maxWidth: TScalar): TVec2;

    protected
      procedure Initialize; override;
      procedure HandleFrameWillChange(var newFrame: TRect); override;
      procedure HandleDidAddToParent(sprite: TView); override;
      
    private
      cellSize: TVec2;
      cellMargin: TScalar;
      columns: integer;
      arrangingCells: boolean;
      totalHeight: TScalar;
      resizeToFit: boolean;
  end;

{ TStackView }
type
  TStackViewOrientation = (Vertical, Horizontal);
  TStackView = class(TView)
    private
      m_orientation: TStackViewOrientation;
      m_cellSpacing: integer;
      m_centerSubviews: boolean;
      procedure SetOrientation(newValue: TStackViewOrientation);
      procedure SetCellSpacing(newValue: integer);
      procedure SetCenterSubviews(newValue: boolean);
    public
      { Methods }
      constructor Create(_frame: TRect; orientation: TStackViewOrientation = TStackViewOrientation.Vertical; cellSpacing: integer = 0; centerSubviews: boolean = false); overload;
      procedure LayoutSubviews; override;
      { Properties }
      property Orientation: TStackViewOrientation read m_orientation write SetOrientation;
      property CellSpacing: integer read m_cellSpacing write SetCellSpacing;
      property CenterSubviews: boolean read m_centerSubviews write SetCenterSubviews;
  end;

{ TStatusBar }

type
  TStatusBar = class (TControl)
    public
      procedure SetCurrentValue(newValue: TScalar);
      procedure SetMaximumValue(newValue: TScalar);
      procedure SetMinimumValue(newValue: TScalar);
    private
      currentValue: TScalar;
      maximumValue: TScalar;
      minimumValue: TScalar;
  end;

{ TNavigationBar }

type
  TNavigationBar = class (TView)
    public
      procedure SetTitle(newValue: string);
    protected
      procedure Initialize; override;
      procedure HandleDidAddToParent(sprite: TView); override;
      procedure HandleFrameDidChange(previousFrame: TRect); override;
    private
      backButton: TButton;
      titleView: TTextView;
  end;

{ TNavigationView }

type
  TNavigationView = class (TView)
    public
      { Accessors }
      procedure SetTitle(newValue: string);
      
      { Methods }
      procedure PushPage(page: TView);
      procedure GoBack(params: TInvocationParams);

      destructor Destroy; override;

    protected
      procedure Initialize; override;
      procedure HandleFrameDidChange(previousFrame: TRect); override;
      
    private
      pages: TViewList;
      navigationBar: TNavigationBar;
      
      procedure UpdateContents;
      procedure PopPage(page: TView);
  end;

procedure Draw3PartImage(parts: TTextureArray; frame: TRect; vertical: boolean = false); 
procedure Draw9PartImage(parts: TTextureSheet; frame: TRect); 

var
  PlatformScreenScale: Float;
  MainScreen: TScreen = nil;
  SharedApp: TApplication = nil;

implementation
uses
  StrUtils, Math;

type
  TWindowCursor = record
    mouseDown: boolean;   
    hover: TView;
    inputStarted: TView;
  end; 

var
  KeyWindow: TWindow;
  ScreenMouseLocation: TPoint;
  SubpixelAccuracyEnabled: boolean = false;
  SharedCursor: TWindowCursor;
  MainMenuBar: TMenuBar = nil;
  CurrentEvent: TEvent = nil;
  PendingEvents: TEventList;

{$define IMPLEMENTATION}
{$include include/Invocation.inc}
{$include include/NotificationCenter.inc}
{$include include/Timer.inc}
{$undef IMPLEMENTATION}

const
  kNormalPressDelay = 0.2;
  kLongPressDelay = 0.75;

type
  TScrollViewHelper = class helper for TView
    function EnclosingScrollView: TScrollView;
  end;

function TScrollViewHelper.EnclosingScrollView: TScrollView;
begin
  result := FindParent(TScrollView) as TScrollView;
end;

function MainPlatformWindow: pointer; inline;
begin
  result := CanvasState.window;
end;

function GetClipboardText: UnicodeString;
begin
  {$if defined(PLATFORM_SDL)}
  result := SDL_GetClipboardText;
  {$elseif defined(PLATFORM_GLPT)}
  result := GLPT_GetClipboardText;
  {$endif}
end;

procedure SetClipboardText(text: UnicodeString);
begin
  {$if defined(PLATFORM_SDL)}
  text += #0;
  SDL_SetClipboardText(@text[1]);
  {$elseif defined(PLATFORM_GLPT)}
  GLPT_SetClipboardText(text);
  {$endif}
end;

{ DRAWING }

procedure Draw3PartImage(parts: TTextureArray; frame: TRect; vertical: boolean = false); 
var
 rect: TRect;
begin
 Assert(Length(parts) = 3, 'invalid 3-part texture');

 if vertical then
   begin
     rect := RectMake(frame.MinX, frame.MinY, parts[0].GetWidth, parts[0].GetHeight);
     DrawTexture(parts[0], rect);

     rect.origin.y += parts[0].GetHeight;
     rect.size.height := frame.Height - (parts[0].GetHeight + parts[2].GetHeight);
     DrawTexture(parts[1], rect);

     rect.origin.y := rect.MaxY;
     rect.size.height := parts[2].GetHeight;
     DrawTexture(parts[2], rect);
   end
 else
   begin
     rect := RectMake(frame.MinX, frame.MinY, parts[0].GetWidth, frame.Height);
     DrawTexture(parts[0], rect);

     rect.origin.x += parts[0].GetWidth;
     rect.size.width := frame.Width - (parts[0].GetWidth + parts[2].GetWidth);
     DrawTexture(parts[1], rect);

     rect.origin.x := rect.MaxX;
     rect.size.width := parts[2].GetWidth;
     DrawTexture(parts[2], rect);
   end;
end;

procedure Draw9PartImage(parts: TTextureSheet; frame: TRect); 
var
 texture: TTexture;
 rect: TRect;
 cornerSize: float;
begin
 cornerSize := parts[0].GetSize.Max;

 // corners
 texture := parts[0];
 rect.size := V2(cornerSize, cornerSize);
 rect.origin := V2(frame.MinX, frame.MinY);
 DrawTexture(texture, rect);

 texture := parts[2];
 rect.size := V2(cornerSize, cornerSize);
 rect.origin := V2(frame.MaxX - cornerSize, frame.MinY);
 DrawTexture(texture, rect);

 texture := parts[8];
 rect.size := V2(cornerSize, cornerSize);
 rect.origin := V2(frame.MaxX - cornerSize, frame.MaxY - cornerSize);
 DrawTexture(texture, rect);

 texture := parts[6];
 rect.size := V2(cornerSize, cornerSize);
 rect.origin := V2(frame.MinX, frame.MaxY - cornerSize);
 DrawTexture(texture, rect);

 // middles
 texture := parts[1];
 rect.size := V2(frame.Width - (cornerSize * 2), cornerSize);
 rect.origin := V2(frame.MinX + cornerSize, frame.MinY);
 DrawTexture(texture, rect);

 texture := parts[7];
 rect.size := V2(frame.Width - (cornerSize * 2), cornerSize);
 rect.origin := V2(frame.MinX + cornerSize, frame.MaxY - cornerSize);
 DrawTexture(texture, rect);

 texture := parts[3];
 rect.size := V2(cornerSize, frame.Height - (cornerSize * 2));
 rect.origin := V2(frame.MinX, frame.MinY + cornerSize);
 DrawTexture(texture, rect);

 texture := parts[5];
 rect.size := V2(cornerSize, frame.Height - (cornerSize * 2));
 rect.origin := V2(frame.MaxX - cornerSize, frame.MinY + cornerSize);
 DrawTexture(texture, rect);

 // center
 texture := parts[4];
 rect.size := V2(frame.Width - (cornerSize * 2), frame.Height - (cornerSize * 2));
 rect.origin := V2(frame.MinX + cornerSize, frame.MinY + cornerSize);
 DrawTexture(texture, rect);
end;

{ DRAGGING SESSION }

var
  SharedDraggingSession: TDraggingSession = nil;

procedure TDraggingSession.TrackDrag(view: TView; event: TEvent);
var
  destination: IDraggingDestination;
begin
  if dragTarget = nil then
    begin
      if not Supports(view, IDraggingDestination, destination) then
        exit;
      m_operation := destination.HandleDraggingEntered(self);
      if operation <> TDragOperation.None then
        begin
          dragTarget := view;
          event.Accept(self);
        end;
    end
  else if dragTarget = view then
    begin
      if not Supports(view, IDraggingDestination, destination) then
        exit;
      event.Accept(self);
      m_operation := destination.HandleDraggingUpdated(self);
    end
  else if (dragTarget <> nil) and (dragTarget <> view) and not dragTarget.InputHit(event) then
    begin
      if not Supports(dragTarget, IDraggingDestination, destination) then
        exit;
      event.Accept(self);
      destination.HandleDraggingExited(self);
      dragTarget := nil;
    end;
end;

class function TDraggingSession.IsDragging: boolean;
begin
  result := SharedDraggingSession <> nil;
end;

procedure TDraggingSession.HandleInputEnded(event: TEvent);
var
  destination: IDraggingDestination;
begin
  writeln('ended drag');
  if source <> nil then
    source.HandleDraggingSessionEndedAtPoint(self, frame.origin, operation);
  
  if assigned(dragTarget) and (operation <> TDragOperation.None) and Supports(dragTarget, IDraggingDestination, destination) then
    begin
      if destination.HandlePerformDragOperation(self) then
        begin
          // TODO: if we don't accept then snap back
        end;
      dragTarget := nil;
    end;

  event.Accept(self);
  Close;
end;

procedure TDraggingSession.HandleInputDragged(event: TEvent);
begin
  SetLocation(event.Location(nil) - offset);
  if source <> nil then
    source.HandleDraggingSessionMovedToPoint(self, frame.origin);
  event.Accept(self);
end;

procedure TDraggingSession.Draw;
begin
  //FillRect(Bounds, RGBA(1,0,0,0.5));
  DrawTexture(dragImage, Bounds, RGBA(1, 0.5));
  inherited;
end;

procedure TDraggingSession.SetImage(size: TVec2; image: TTexture);
begin
  dragImage := image;
  SetContentSize(size);
end;

constructor TDraggingSession.Create(dragEvent: TEvent; _offset: TVec2; _source: IDraggingSource);
begin
  SharedDraggingSession := self;
  Initialize;

  source := _source;
  offset := _offset;
  items := TDraggingItems.Create;
  windowLevel := TWindowLevel.Drag;
  freeWhenClosed := true;
  SetContentSize(V2(32, 32));

  SetLocation(dragEvent.Location(nil) - offset);
  OrderFront;

  if source <> nil then
    source.HandleDraggingSessionWillBeginAtPoint(self, frame.origin);
end;

destructor TDraggingSession.Destroy;
begin
  items.Free;
  SharedDraggingSession := nil;
  inherited;
end;

{ APPLICATION }

function TApplication.FrontWindowOfAnyLevel: TWindow;
var
  level: TWindowLevel;
  window: TWindow;
begin
  result := nil;
  for level in TWindowLevel do
    begin
      window := GetWindow(level, 0);
      if assigned(window) then
        exit(window);
    end;
end;

function TApplication.FrontWindowOfLevel(level: TWindowLevel): TWindow;
begin
  if list[level].Count > 0 then
    result := list[level][0]
  else
    result := nil;
end;

{ Returns the frontmost normal window (not including utilty/overlay windows)}
function TApplication.FrontWindow: TWindow;
begin
  if list[TWindowLevel.Normal].Count > 0 then
    result := list[TWindowLevel.Normal][0]
  else
    result := nil;
end;

function TApplication.FindWindowOfClass(ofClass: TWindowClass): TWindow;
var
  level: TWindowLevel;
  index: integer;
  window: TWindow;
begin
  result := nil;
  for level in TWindowLevel do
    for index := 0 to list[level].Count - 1 do
      begin
        window := GetWindow(level, index);
        if window.IsMember(ofClass) then
          exit(window);
      end;
end;

function TApplication.FindWindow(window: TWindow): boolean;
var
  level: TWindowLevel;
  index: integer;
begin
  result := false;
  for level in TWindowLevel do
    for index := 0 to list[level].Count - 1 do
      if GetWindow(level, index) = window then
        exit(true);
end;

function TApplication.AvailableWindows: TWindowArray;
var
  level: TWindowLevel;
  window: integer;
begin
  result := nil;
  for level in TWindowLevel do
    for window := list[level].Count - 1 downto 0 do
      result += [GetWindow(level, window)];
end;

procedure TApplication.Update;
var
  level: TWindowLevel;
  index: integer;
  window: TWindow;
begin
  locked := true;
  for level in TWindowLevel do
    for index := list[level].Count - 1 downto 0 do
      begin
        window := self[level, index];
        if window.IsHidden then
          continue;

        window.LayoutRoot;
        window.Update;
        window.Render;
      end;
  locked := false;

  ProcessTimersForLoop;
end;

procedure TApplication.ResizeScreen(event: TEvent);
begin
  PostNotification(kNotificationScreenWillResize);
  ResizeCanvas(event.WindowSize);
  MainScreen.SetSize(event.WindowSize);
end;

function TApplication.PollEvent(constref event: TEvent.TRawEvent): boolean;
begin
  FreeAndNil(CurrentEvent);

  result := PollEvent(TEvent.Create(event));

  while PendingEvents.Count > 0 do
    begin
      PollEvent(PendingEvents.Last);
      PendingEvents.Delete(PendingEvents.Count - 1);
    end;
end;

function TApplication.PollEvent(event: TEvent): boolean;
var
  window: TWindow;
  level: integer;
  didResize: boolean;
label
  Finished;
begin
  CurrentEvent := event;

  locked := true;
  didResize := false;
  result := false;

  // handle application level events outside main loop
  case event.EventType of
    TEventType.KeyDown:
      begin
        // get key combinations and propogate through "HandleKeyEquivalent(event)/HandleKeyEquivalent"
        // also see NSMenuItemValidation to enabling menu items based
        HandleKeyEquivalent(event);
        if event.IsAccepted then
          goto Finished;
      end;
    TEventType.WindowResize:
      begin
        ResizeScreen(event);
        didResize := true;
      end;
  end;

  // handle other events in the window list
  for level := ord(high(TWindowLevel)) downto 0 do
    for window in list[TWindowLevel(level)] do
      if not window.IsHidden and window.PollEvent(event) then
        begin
          result := true;
          goto Finished;
        end
      else
        begin
          // the event may been accepted so clear it manually for next pass
          event.m_accepted := false;
        end;

  Finished:
  locked := false;
  
  if didResize then
    PostNotification(kNotificationScreenDidResize);

  // clear the pending window list
  for window in pendingClose do
    Remove(window);
  pendingClose.Clear;
end;

procedure TApplication.Add(window: TWindow);
begin
  if locked then
    begin
      writeln('🔥 warning trying to create new window while manifest is locked');
      //HALT(-1);
    end;
  list[window.GetWindowLevel].Add(window);
end;

procedure TApplication.Remove(window: TWindow);
var
  level: TWindowLevel;
  i: integer;
  win: TWindow;
begin
  if locked then
    begin
      pendingClose.Add(window);
      exit;
    end;

  if KeyWindow = window then
    KeyWindow := nil;

  level := window.GetWindowLevel;
  list[level].Remove(window);
  
  // restore the key window
  if KeyWindow = nil then
    begin
      //search down from current level
      for i := integer(level) downto 0 do
        begin
          win := GetWindow(TWindowLevel(i), 0);
          if assigned(win) then
            begin
              win.MakeKey;
              break;
            end;
        end;
      win := FrontWindowOfLevel(level);
      if win <> nil then
        win.MakeKey;
    end;

  window.FinalizeClose;
end;

function TApplication.GetWindow(level: TWindowLevel; index: integer): TWindow;
begin
  if index < list[level].Count then
    result := list[level].Get(index)
  else
    result := nil;
end;

procedure TApplication.MoveToFront(window: TWindow);
var
  level: TWindowLevel;
begin
  level := window.GetWindowLevel;
  list[level].Move(list[level].IndexOf(window), 0);
end;

procedure TApplication.HandleKeyEquivalent(event: TEvent);
var
  level: integer;
  window: TWindow;
begin
  //for level := kWindowLevels - 1 downto 0 do
  for level := ord(high(TWindowLevel)) downto 0 do
    for window in list[TWindowLevel(level)] do
      if not window.IsHidden then
        begin
          window.HandleKeyEquivalent(event);
          if event.IsAccepted then
            exit;
        end;
end;

procedure TApplication.HandleCommand(command: string);
begin
  if command = 'closeWindow:' then
    begin
      if FrontWindow <> nil then
        FrontWindow.Close;
    end;
end;

procedure TApplication.AfterConstruction;
var
  level: TWindowLevel;
begin
  Assert(SharedApp = nil, 'only one app is allowed!');
  SharedApp := self;
  pendingClose := TWindowList.Create;
  for level in TWindowLevel do
    list[level] := TWindowList.Create;
end;

class function TApplication.FirstResponder: TObject;
begin
  // TODO: front window + focused view and bubble up from there
  result := SharedApp;
end;

{ EVENT }

function TEvent.ScrollWheel: TVec2;
begin
  result := inherited * PlatformScreenScale;
end;

function TEvent.Location(system: TObject = nil): TPoint;
begin
  result := CanvasMousePosition(MouseLocation);

  // scale location from screen scale
  result.x := trunc(result.x / PlatformScreenScale);
  result.y := trunc(result.y / PlatformScreenScale);

  if system <> nil then
    result := TView(system).ConvertPointFrom(result, MainScreen);
end;

procedure TEvent.Reject;
begin
  m_accepted := false;
  acceptedObject := nil;
end;

procedure TEvent.Accept(obj: TObject = nil);
begin
  m_accepted := true;
  acceptedObject := obj;
end;

{ VIEW }

function TView.InputHit(event: TEvent): boolean;
begin
  result := GetBounds.Contains(event.Location(self));
end;

function TView.ContainsPoint(point: TPoint): boolean;
begin
  result := GetBounds.Contains(point);
end;

function TView.ContainsRect(rect: TRect): boolean;
begin
  result := GetBounds.Contains(rect);
end;

function TView.IntersectsRect(rect: TRect): boolean;
begin
  result := GetBounds.Intersects(rect);
end;

function TView.GetParentCoordinateSystem: TObject;
begin
  result := GetParent;
end;

function TView.ConvertPointTo(point: TPoint; system: TObject): TPoint;
begin
  result := ConvertRectTo(RectMake(point.x, point.y, 0, 0), system).origin;
end;

function TView.ConvertPointFrom(point: TPoint; system: TObject): TPoint;
begin
  result := ConvertRectFrom(RectMake(point.x, point.y, 0, 0), system).origin;
end;

function TView.ConvertRectTo(rect: TRect; system: TObject): TRect;
var
  delegate: ICoordinateConversion;
begin   
  if system = nil then
    system := MainScreen;

  if system = self then
    exit(rect)
  else
    result := RectMake(-maxInt, -maxInt, 0, 0);

  if Supports(system, ICoordinateConversion, delegate) then
    if delegate.GetParentCoordinateSystem <> GetParentCoordinateSystem then
      begin
        result.origin.x := rect.origin.x + GetLocation.x;
        result.origin.y := rect.origin.y + GetLocation.y;
        result.size := rect.size;

        if Supports(GetParentCoordinateSystem, ICoordinateConversion, delegate) then
          result := delegate.ConvertRectTo(result, system);
      end;
end;

function TView.ConvertRectFrom(rect: TRect; system: TObject): TRect;
var
  delegate: ICoordinateConversion;
begin
  if system = nil then
    system := MainScreen;

  if system = self then
    exit(rect)
  else
    result := RectMake(-maxInt, -maxInt, 0, 0);

  if Supports(system, ICoordinateConversion, delegate) then
    if delegate.GetParentCoordinateSystem <> GetParentCoordinateSystem then
      begin
        result.origin.x := rect.origin.x - GetLocation.x;
        result.origin.y := rect.origin.y - GetLocation.y;
        result.size := rect.size;

        if Supports(GetParentCoordinateSystem, ICoordinateConversion, delegate) then
          result := delegate.ConvertRectFrom(result, system);
      end;
end;

function TView.GetResolution: TScalar;
begin
  result := 1.0;
end;

procedure TView.Update;
var
  child: TView;
begin   
  if assigned(subviews) then
    for child in subviews do
      child.Update;
end;

function TView.IsMember(viewClass: TViewClass): boolean;
begin
  result := InheritsFrom(viewClass);
end;

procedure TView.GiveFocus;
begin
  if GetWindow <> nil then
    GetWindow.SetFocusedView(self)
  else
    wantsFocus := true;
end;

procedure TView.AdvanceFocus;
begin
end;

function TView.IsFocused(global: boolean = false): boolean;
begin
  if GetWindow <> nil then
    begin
      if global then
        result := GetWindow.IsFront and(GetWindow.GetFocusedView = self)
      else 
        result := GetWindow.GetFocusedView = self;
    end
  else
    result := false;
end;

procedure TView.SendKeyDown(event: TEvent);
begin
  HandleKeyDown(event);
end;

procedure TView.InsertSubview(view: TView; index: integer);
begin
  if subviews.IndexOf(view) = -1 then
    begin
      view.HandleWillAddToParent(self);
      HandleWillAddSubview(view);
      subviews.Insert(index, view);
      view.SetParent(self);
      view.HandleDidAddToParent(self);
      HandleSubviewsChanged;
    end;
  DisplayNeedsUpdate;
  LayoutSubviews;
end;

procedure TView.AddSubview(view: TView);
begin
  InsertSubview(view, subviews.Count);
end;

procedure TView.AddSubviews(views: array of TView);
var
  view: TView;
begin
  for view in views do
    InsertSubview(view, subviews.Count);
end;

procedure TView.RemoveSubview(view: TView);
begin
  if subviews.IndexOf(view) <> -1 then
    begin
      view.HandleWillRemoveFromParent(self);
      HandleWillRemoveSubview(view);
      view.SetParent(nil);
      view.HandleDidRemoveFromParent(self);
      subviews.Remove(view);
      HandleSubviewsChanged;
    end;
  DisplayNeedsUpdate;
  LayoutSubviews;
end;

procedure TView.RemoveSubviews;
var
  view: TView;
begin
  while subviews.Count > 0 do
    begin
      view := subviews[0];
      view.HandleWillRemoveFromParent(self);
      HandleWillRemoveSubview(view);
      view.SetParent(nil);
      view.HandleDidRemoveFromParent(self);
      subviews.Remove(view);
    end;
end;

procedure TView.RemoveFromParent;
begin
  if m_parent <> nil then
    m_parent.RemoveSubview(self);
end;

procedure TView.NeedsLayoutSubviews;
begin
  m_needsLayoutSubviews := true;
end;

procedure TView.LayoutIfNeeded;
begin
  if m_needsLayoutSubviews then
    begin
      LayoutSubviews;
      m_needsLayoutSubviews := false;
    end;
end;

procedure TView.InternalLayoutSubviews;
var
  oldSize: TVec2;
begin
  oldSize := GetSize;

  // it's important to layout first so view can set
  // their size before autoresize is called
  LayoutSubviews;
  
  // call autoresize outside of the layout method
  // so that subviews can not override this behavior
  if (GetParent <> nil) and (GetAutoresizingOptions <> []) then
    begin
      AutoResize;
      
      // we need to follow after AutoResize because subviews may have changed
      if GetSize <> oldSize then
        LayoutSubviews;
    end;
end;

procedure TView.LayoutSubviews;
var
  child: TView;
begin
  //NeedsDisplay := true;

  for child in subviews do
    begin
      child.InternalLayoutSubviews;
      child.m_needsLayoutSubviews := false;
    end;
  m_needsLayoutSubviews := false;
end;

{ Private layout method which is always called from the window. }
procedure TView.LayoutRoot;
var
  child: TView;
begin
  LayoutIfNeeded;
  for child in subviews do
    begin
      child.LayoutIfNeeded;
      child.LayoutRoot;
    end;
end;

procedure TView.SetNeedsDisplay(newValue: boolean);
var
  view: TView;
begin
  {$ifndef BUFFERED_RENDERING}
  exit;
  {$endif}

  if newValue and not NeedsDisplay then
    begin
      // look up the view hierarchy to find non-opaue views need to be redrawn also
      view := self;
      while (view <> nil) and not view.IsOpaque and (GetParent <> nil) do
        begin
          view.m_needsDisplay := true;
          view := view.GetParent;
        end;
      // TODO: during on draw cycle multiple views may redraw so we need to union these
      window.dirtyRect := window.dirtyRect.Union(ConvertRectFrom(frame, self));
      //writeln(classname, ' -> ', window.dirtyRect.tostr);
    end
  else if not newValue and NeedsDisplay then
    begin
      m_needsDisplay := false;
      if subviews <> nil then
        for view in subviews do
          if view.NeedsDisplay then
            view.NeedsDisplay := false;
    end;
end;

function TView.FindParent(ofClass: TViewClass): TView;
var
  view: TView;
begin
  view := GetParent;
  while view <> nil do
    begin
      if view.IsMember(ofClass) then
        exit(view);
      view := view.GetParent;
    end;
  result := nil;
end;

function TView.FindValue(identifier: string): variant;
var
  found: TControl = nil;
begin
  found := FindControl(identifier);
  if found <> nil then
    result := found.GetValue
  else
    result := false;
end;

function TView.FindControl(identifier: string): TControl;

  procedure FindControlInternal(root: TView; var ioView);
  var
    child: TView;
    view: TView absolute ioView;
  begin
    if root.subviews <> nil then
      for child in root.subviews do
        if (child is TControl) and 
           (TControl(child).identifier = identifier) then
          begin
            view := child;
            break;
          end
        else if child.subviews.Count > 0 then
          begin
            FindControlInternal(child, ioView);
            if view <> nil then
              break;
          end;
  end;

begin
  result := nil;
  FindControlInternal(self, result);
end;

function TView.FindSubview(withTag: integer): TView;

  procedure FindSubviewInternal(root: TView; var ioView);
  var
    child: TView;
    view: TView absolute ioView;
  begin
    if root.subviews <> nil then
      for child in root.subviews do
        if child.GetTag = withTag then
          begin
            view := child;
            break;
          end
        else if child.subviews.Count > 0 then
          begin
            FindSubviewInternal(child, ioView);
            if view <> nil then
              break;
          end;
  end;

begin
  result := nil;
  FindSubviewInternal(self, result);
end;

{ Get the index of the view in it's parent subviews
  Returns -1 if the view has no parent }
function TView.GetChildIndex: integer;
var
  i: integer;
begin
  if GetParent = nil then
    exit(-1);

  if GetParent.Subviews.Count = 0 then
    exit(-1);

  for i := 0 to GetParent.Subviews.Count - 1 do
    if GetParent.Subviews[i] = self then
      exit(i);

  result := -1;
end;

procedure TView.ChangeAutoresizingOptions(newValue: TAutoresizingOptions; add: boolean);
begin
  if add then
    autoresizingOptions += newValue
  else
    autoresizingOptions -= newValue;
end;

function TView.IsVisible: boolean;
begin
  result := m_visible;
end;

function TView.IsHidden: boolean;
begin
  result := not IsVisible;
end;

procedure TView.SetVisible(newValue: boolean);
begin
  if IsVisible <> newValue then
    begin
      m_visible := newValue;
      if not settingVisible then
        begin
          settingVisible := true;
          HandleVisibilityChanged(newValue);
          settingVisible := false;
        end;
    end;
end;

procedure TView.SetHidden(newValue: boolean);
begin
  SetVisible(not newValue);
end;

procedure TView.SetPostsFrameChangedNotifications(newValue: boolean);
begin
  postsFrameChangedNotifications := newValue;
end;

procedure TView.SetTag(newValue: integer);
begin
  m_tag := newValue;
end;

procedure TView.SetEnableClipping(newValue: boolean);
begin
  enableClipping := newValue;
end;

procedure TView.SetCanAcceptFocus(newValue: boolean);
begin
  canAcceptFocus := newValue;
end;

procedure TView.SetAutoresizingOptions(newValue: TAutoresizingOptions);
begin
  autoresizingOptions := newValue;
end;

procedure TView.SetBackgroundColor(newValue: TColor);
begin
  backgroundColor := newValue;
end;

procedure TView.SetSize(newValue: TVec2);
var
  newFrame: TRect;
begin
  newValue := V2(trunc(newValue.x), trunc(newValue.y));

  if GetFrame.size <> newValue then
    begin
      newFrame := GetFrame;
      newFrame.size := newValue;
  
      SetFrame(newFrame);
    end;
end;

procedure TView.SetSize(width, height: TScalar);
begin
  SetSize(V2(width, height));
end;

procedure TView.SetWidth(newValue: TScalar);
begin
  SetSize(V2(newValue, GetHeight));
end;

procedure TView.SetHeight(newValue: TScalar);
begin
  SetSize(V2(GetWidth, newValue));
end;

procedure TView.PostFrameChangedNotification;
begin
  postingFrameChangeNotification := true;
  PostNotification(kNotificationFrameChanged, self);
  postingFrameChangeNotification := false;
end;

procedure TView.DisplayNeedsUpdate;
begin
end;

procedure TView.SetFrame(newValue: TRect);
var
  savedFrame: TRect;
begin
  if not SubpixelAccuracyEnabled then
    newValue := Trunc(newValue);
    
  if m_frame <> newValue then
    begin
      HandleFrameWillChange(newValue);
      
      savedFrame := m_frame;
      m_frame := newValue;
      DisplayNeedsUpdate;
      if GetParent <> nil then
        LayoutSubviews
      else
        NeedsLayoutSubviews;

      HandleFrameDidChange(savedFrame);
            
      if assigned(GetWindow) and postsFrameChangedNotifications and not postingFrameChangeNotification then
        PostFrameChangedNotification;
    end;
end;

procedure TView.SetBounds(newValue: TRect);
begin
  SetSize(newValue.size);
end;

procedure TView.SetLocation(where: TPoint);
var
  newFrame: TRect;
begin
  if GetLocation <> where then
    begin
      newFrame.origin := where;
      newFrame.size := m_frame.size;
      SetFrame(newFrame);
    end;
end;

procedure TView.SetLeftEdge(offset: TScalar);
var
  newLocation: TPoint;
begin
  newLocation := GetLocation;
  newLocation.x := trunc(offset);
  SetLocation(newLocation);
end;

procedure TView.SetTopEdge(offset: TScalar);
var
  newLocation: TPoint;
begin
  newLocation := GetLocation;
  newLocation.y := trunc(offset);
  SetLocation(newLocation);
end;

procedure TView.SetRightEdge(offset: TScalar);
var
  newLocation: TPoint;
begin
  LayoutIfNeeded;
  newLocation := GetLocation;
  newLocation.x := trunc(offset - GetWidth);
  SetLocation(newLocation);
end;

procedure TView.SetBottomEdge(offset: TScalar);
var
  newLocation: TPoint;
begin
  LayoutIfNeeded;
  newLocation := GetLocation;
  newLocation.y := trunc(offset - GetHeight);
  SetLocation(newLocation);
end;

procedure TView.SetLocation(x, y: TScalar);
begin
  SetLocation(V2(x, y));
end;

procedure TView.SetParent(newValue: TView);
begin
  m_parent := newValue;
end;

function TView.GetAutoresizingOptions: TAutoresizingOptions;
begin
  result := autoresizingOptions;
end;

function TView.GetBounds: TRect;
begin
  result.origin := V2(0, 0);
  result.size := GetFrame.size;
end;

function TView.GetParent: TView;
begin
  result := m_parent;
end;

function TView.GetSubviews: TViewList;
begin
  if m_subviews = nil then
    m_subviews := TViewList.Create;
  result := m_subviews;
end;

function TView.IsOpaque: boolean;
begin
  { The default value of this property is false to reflect the fact that 
    views do no drawing by default. Subclasses can override this property 
    and return true to indicate that the view completely covers its frame 
    rectangle with opaque content. Doing so can improve performance during 
    drawing operations by eliminating the need to render content behind the view. }

  result := false;
end;

function TView.GetTag: longint;
begin
  result := m_tag;
end;

function TView.GetFrame: TRect;
begin
  result := m_frame;
end;

function TView.GetWidth: TScalar;
begin
  result := GetSize.width;
end;

function TView.GetHeight: TScalar;
begin
  result := GetSize.height;
end;

function TView.GetSize: TVec2;
begin
  result := GetFrame.size;
end;

function TView.GetLocation: TPoint;
begin
  result := GetFrame.origin;
end;

function TView.GetWindow: TWindow;
var
  parent: TView;
begin   
  if parentWindow = nil then
    begin
      parent := self;
      while parent <> nil do
        begin
          if parent.IsMember(TWindow) then
            begin
              parentWindow := TWindow(parent);
              break;
            end;
          parent := TView(parent.GetParent);
        end;
    end;
  result := parentWindow;
end;

procedure TView.AutoResize;
var
  newFrame,
  resizedFrame,
  enclosingFrame: TRect;
begin
  newFrame := GetFrame;
  resizedFrame := newFrame;
  enclosingFrame := GetParent.GetFrame;
  
  if not didAutoResize then
    begin
      initialState.margin.left := newFrame.MinX;
      initialState.margin.top := newFrame.MinY;
      initialState.margin.right := enclosingFrame.Width - newFrame.MaxX;
      initialState.margin.bottom := enclosingFrame.Height - newFrame.MaxY;

      initialState.relativeMid.x := (newFrame.MidX) / enclosingFrame.Width;
      initialState.relativeMid.y := (newFrame.MidY) / enclosingFrame.Height;
      //writeln(ClassName, ': ', initialState.relativeMid.tostr, ' from ', newFrame.tostr, ' of ', enclosingFrame.tostr);

      initialState.relativeSize.x := newFrame.Width / enclosingFrame.Width;
      initialState.relativeSize.y := newFrame.Height / enclosingFrame.Height;

      didAutoResize := true;
    end;

  // relative origins
  if not (TAutoresizingOption.MinXMargin in GetAutoresizingOptions) and 
    not (TAutoresizingOption.MaxXMargin in GetAutoresizingOptions) then
    resizedFrame.origin.x := (initialState.relativeMid.x * enclosingFrame.Width) - (newFrame.Width / 2);
  
  if not (TAutoresizingOption.MinYMargin in GetAutoresizingOptions) and 
    not (TAutoresizingOption.MaxYMargin in GetAutoresizingOptions) then
    resizedFrame.origin.y := (initialState.relativeMid.y * enclosingFrame.Height) - (newFrame.Height / 2);

  // x margins
  if TAutoresizingOption.MinXMargin in GetAutoresizingOptions then
    resizedFrame.origin.x := initialState.margin.left
  else if(TAutoresizingOption.MaxXMargin in GetAutoresizingOptions) and
          not (TAutoresizingOption.WidthSizable in GetAutoresizingOptions) then
    resizedFrame.origin.x := enclosingFrame.width - initialState.margin.right - newFrame.width;

  // y margins
  if TAutoresizingOption.MinYMargin in GetAutoresizingOptions then
    resizedFrame.origin.y := initialState.margin.top
  else if(TAutoresizingOption.MaxYMargin in GetAutoresizingOptions ) and
          not (TAutoresizingOption.HeightSizable in GetAutoresizingOptions) then
    resizedFrame.origin.y := enclosingFrame.height - initialState.margin.bottom - newFrame.height;

  // width
  if TAutoresizingOption.WidthSizable in GetAutoresizingOptions then
    begin
      if TAutoresizingOption.MaxXMargin in GetAutoresizingOptions then
        resizedFrame.size.x := (enclosingFrame.Width - resizedFrame.MinX) - initialState.margin.right
      else
        resizedFrame.size.x := initialState.relativeSize.x * enclosingFrame.Width;
    end;
  
  // height
  if TAutoresizingOption.HeightSizable in GetAutoresizingOptions then
    begin
      if TAutoresizingOption.MaxYMargin in GetAutoresizingOptions then
        resizedFrame.size.y := (enclosingFrame.Height - resizedFrame.MinY) - initialState.margin.bottom
      else
        resizedFrame.size.y := initialState.relativeSize.y * enclosingFrame.Height;
    end;
    
  SetFrame(resizedFrame);
end;

procedure TView.ReliquishFocus;
var
  child: TView;
begin

  // has focus, remove it
  if IsFocused then
    begin
      GetWindow.SetFocusedView(nil);
      exit;
    end;
  
  // search children
  if assigned(subviews) then
    for child in subviews do
      child.ReliquishFocus;
end;

procedure TView.HandleSubviewsChanged;
begin
end;

procedure TView.HandleWillBecomeFocused;
begin
end;

procedure TView.HandleDidBecomeFocused;
begin
end;

procedure TView.HandleWillResignFocus;
begin
end;

procedure TView.HandleWillAddSubview(view: TView);
begin
end;

procedure TView.HandleWillRemoveSubview(view: TView);
begin
end;

procedure TView.HandleFrameDidChange(previousFrame: TRect);
begin
end;

procedure TView.HandleFrameWillChange(var newFrame: TRect);
begin
end;

procedure TView.HandleWillRemoveFromParent(view: TView);
begin   
  ReliquishFocus;
end;

procedure TView.HandleDidRemoveFromParent(view: TView);
begin
end;

procedure TView.HandleWillAddToParent(view: TView);
begin
  if view.IsMember(TWindow) then
    HandleWillAddToWindow(TWindow(view));
end;

procedure TView.HandleWillAddToWindow(win: TWindow);
begin
end;

procedure TView.HandleDidAddToParent(view: TView);
begin 
  if wantsFocus then
    begin
      GiveFocus;
      wantsFocus := false;
    end;

  NeedsLayoutSubviews;
end;

procedure TView.HandleVisibilityChanged(visible: boolean);
begin
end;

procedure TView.HandleKeyDown(event: TEvent);
var
  child: TView;
begin 
  for child in subviews do
    begin
      child.HandleKeyDown(event);
      if event.IsAccepted then
        exit;
    end;
end;

procedure TView.HandleKeyEquivalent(event: TEvent);
var
  child: TView;
begin
  for child in subviews do
    begin
      child.HandleKeyEquivalent(event);
      if event.IsAccepted then
        break;
    end;
end;

procedure TView.HandleInputPress(event: TEvent);
var
  child: TView;
begin
  for child in subviews do
    begin
      child.HandleInputPress(event);
      if event.IsAccepted then
        exit;
    end;
end;

procedure TView.HandleInputEnded(event: TEvent);
var
  child: TView;
begin
  for child in subviews do
    begin
      child.HandleInputEnded(event);
      if event.IsAccepted then
        exit;
    end;
end;

procedure TView.HandleInputStarted(event: TEvent);
var
  child: TView;
begin
  if InputHit(event) then
    begin
      if CanAcceptFocus then
        GiveFocus;
      
      for child in subviews do
        begin
          child.HandleInputStarted(event);
          if event.IsAccepted then
            exit;
        end;
    end;
end;

procedure TView.HandleInputDragged(event: TEvent);
var
  child: TView;
begin
  for child in subviews do
    begin
      child.HandleInputDragged(event);
      if event.IsAccepted then
        exit;
    end;
end;

procedure TView.HandleMouseUp(event: TEvent);
var
  child: TView;
begin 
  for child in subviews do
    begin
      child.HandleMouseUp(event);
      if event.IsAccepted then
        exit;
    end;
end;

procedure TView.HandleMouseDown(event: TEvent);
var
  child: TView;
begin
  if InputHit(event) then
    begin
      if GetWindow <> SharedApp.FrontWindow then
        exit;
      
      for child in subviews do
        begin
          child.HandleMouseDown(event);
          if event.IsAccepted then
            exit;
        end;
    end;
end;

{ HandleMouseMoved is called when the mouse is moving within the view. To receive this event you must:
  1) Override AcceptsMouseMovedEvents and return true.
  2) Accept the event by overriding HandleMouseEntered. }

procedure TView.HandleMouseMoved(event: TEvent);
begin
end;

function TView.AcceptsMouseMovedEvents: boolean;
begin
  if GetWindow <> nil then
    result := GetWindow.AcceptsMouseMovedEvents
  else
    result := false;
end;

procedure TView.TestDragTracking(event: TEvent);
var
  child: TView;
begin 
  if InputHit(event) then
    begin
      for child in subviews do
        begin
          child.TestDragTracking(event);
          if event.IsAccepted then
            exit;
        end;
      SharedDraggingSession.TrackDrag(self, event);
      if event.IsAccepted then
        exit;
    end;
end;

procedure TView.TestMouseTracking(event: TEvent);
var
  child: TView;
begin 
  if InputHit(event) then
    begin
      for child in subviews do
        begin
          child.TestMouseTracking(event);
          if event.IsAccepted then
            exit;
        end;

      // mouse tracking
      if SharedCursor.hover <> self then
        begin
          HandleMouseEntered(event);
          if event.IsAccepted then
            begin
              if assigned(SharedCursor.hover) then
                SharedCursor.hover.HandleMouseExited(event);
              SharedCursor.hover := self;
            end;
        end;
    end;
end;

procedure TView.HandleMouseEntered(event: TEvent);
begin 
end;

procedure TView.HandleMouseExited(event: TEvent);
begin
end;

procedure TView.HandleMouseDragged(event: TEvent);
var
  child: TView;
begin
  for child in subviews do
    begin
      child.HandleMouseDragged(event);
      if event.IsAccepted then
        exit;
    end;
end;

procedure TView.HandleMouseWheelScroll(event: TEvent);
var
  child: TView;
begin
  for child in subviews do
    begin
      child.HandleMouseWheelScroll(event);
      if event.IsAccepted then
        exit;
    end;
end;

procedure TView.HandleContextualClick(event: TEvent);
begin
end;

procedure TView.Initialize;
begin 
  m_visible := true;
  m_needsDisplay := true;
  SetAutoresizingOptions([TAutoresizingOption.MinXMargin, TAutoresizingOption.MinYMargin]);
end;

function TView.GetClipRect: TRect; 
begin
  result := GetBounds;
end;

procedure TView.PushClipRect(rect: TRect);
begin
  rect := ConvertRectTo(rect, MainScreen);
  rect *= PlatformScreenScale;

  rect := RectFlipY(rect, GetViewPort);
  GLCanvas.PushClipRect(rect);
end;

procedure TView.SubviewsAreClipping(var clipping: boolean; deep: boolean = true);
var
  child: TView;
begin
  for child in subviews do
    begin
      if IsSubviewClipping(child) then
        begin
          clipping := true;
          break;
        end;
      if deep then
        begin
          child.SubviewsAreClipping(clipping, deep);
          if clipping then
            break;
        end;
    end;
end;

function TView.IsSubviewClipping(view: TView): boolean;
begin
  result := not GetBounds.Contains(view.GetFrame);
end;

function TView.ShouldDrawSubview(view: TView): boolean;
begin
  result := not IsHidden;
end;

procedure TView.DrawInternal(parentOrigin: TVec2);

  function ShouldDraw: boolean; inline;
  begin
    //writeln('hit: ', {ConvertRectFrom(window.dirtyRect, Window).tostr}frame.Intersects(window.dirtyRect));
    //if not frame.Intersects(window.dirtyRect) then
    //  exit(false);
    if assigned(GetParent) then
      result := GetParent.ShouldDrawSubview(self)
    else
      result := not IsHidden;
  end;

var
  child: TView;
begin
  renderOrigin := GetFrame.origin * PlatformScreenScale + parentOrigin;

  {$ifdef BUFFERED_RENDERING}
  if IsMember(TWindow) then
    renderOrigin := 0;
  {$endif}

  FlushDrawing;

  if not IsHidden then
    begin
      // TODO: why do we push the transform ShowDraw is false??
      if ShouldDraw then
        begin
          PushViewTransform(renderOrigin.x, renderOrigin.y, PlatformScreenScale);

          if enableClipping then
            PushClipRect(GetClipRect);
          //if ShouldDraw then
            Draw;
          FlushDrawing;
          if enableClipping then
            PopClipRect;

          // draw outside of clip rect
          {$ifdef GLGUI_DEBUG}
          DrawDebugWidgets;
          FlushDrawing;
          {$endif}

          PopViewTransform;
        end;
    end
  else
    begin
      if assigned(subviews) then
        for child in subviews do
          child.DrawInternal(renderOrigin);
    end;
end;

procedure TView.DrawDebugWidgets;
begin
  StrokeRect(GetBounds, RGBA(0, 0, 1, 1));
end;

procedure TView.Draw;
var
  child: TView;
begin
  if assigned(subviews) then
    for child in subviews do
      child.DrawInternal(renderOrigin);
end;

constructor TView.Create;
begin
  Initialize;
end;

constructor TView.Create(_frame: TRect);
begin
  SetFrame(_frame);
  Initialize;
end;

class function TView.StyleName: string;
begin
  result := 'System';
end;

destructor TView.Destroy;
begin
  writeln('free ', classname);
  inherited;
end;

{ TResponder }

procedure TResponder.HandleKeyEquivalent(event: TEvent);
begin
end;

procedure TResponder.HandleCommand(command: string);
begin
end;

procedure TResponder.DefaultHandlerStr(var message);
var
  callback: TInvocationCallbackDispatch absolute message;
begin
  writeln('default: ', callback.method);
  {
    we should re-send the message using the dispatch system!
  }
  HandleCommand(callback.method);
end;

{ SCREEN }

function TScreen.GetVisibleFrame: TRect;
begin
  result := GetViewPort;
  if TMenuBar.MainMenu <> nil then
    begin
      result.origin.y += TMenuBar.MainMenu.Frame.Height;
      result.size.y -= TMenuBar.MainMenu.Frame.Height;
    end;
end;

class function TScreen.MainScreen: TScreen;
begin
  result := GLUI.MainScreen;
end;

{ WINDOW }

function TWindow.GetDelegate: TObject;
begin
  result := delegate;
end;

function TWindow.GetParentCoordinateSystem: TObject;
begin
  result := MainScreen;
end;

function TWindow.GetContentFrame: TRect;
begin
  result := RectMake(0, 0, GetWidth, GetHeight);
end;

function TWindow.GetFocusedView: TView;
begin
  result := focusedView;
end;

function TWindow.GetContentSize: TVec2;
begin
  result := GetContentFrame.size;
end;

procedure TWindow.SetFocusedView(newValue: TView);
begin
  if focusedView <> nil then
    focusedView.HandleWillResignFocus;
  newValue.HandleWillBecomeFocused;
  focusedView := newValue;
  newValue.HandleDidBecomeFocused;
  PostNotification(kNotificationFocusChanged, newValue);
end;

procedure TWindow.SetContentSize(newValue: TVec2);
var
  newFrame: TRect;
begin
  newFrame := GetFrameForContentFrame(RectMake(0, newValue));
  SetSize(newFrame.size);
end;

procedure TWindow.SetContentView(newValue: TView);
begin
  newValue.SetAutoresizingOptions(TAutoresizingStretchToFill);
  newValue.SetFrame(GetContentFrame);
  AddSubview(newValue);
end;

procedure TWindow.SetDelegate(newValue: TObject);
begin
  delegate := newValue;
end;

procedure TWindow.SetMoveableByBackground(newValue: boolean);
begin
  moveableByBackground := newValue;
end;

procedure TWindow.SetWindowLevel(newValue: TWindowLevel);
begin
  windowLevel := newValue;
end;

procedure TWindow.SetModal(newValue: boolean);    
begin
  modal := newValue;
end;

function TWindow.GetWindowLevel: TWindowLevel;
begin
  result := windowLevel;
end;

procedure TWindow.PerformClose(params: TInvocationParams);
begin
  // TODO: ask delegate to close
  Close;
end;

procedure TWindow.AdvanceFocus;

  procedure _AdvanceFocus(topLevel: boolean; startIndex: integer; root: TView; var found: TView);
  var
    view: TView;
    i: integer;
  begin
    for i := startIndex to root.subviews.Count - 1 do
      begin
        view := root.subviews[i];

        // Give focus to the view
        if view.canAcceptFocus and not view.IsFocused then
          begin
            view.GiveFocus;
            found := view;
            break;
          end;

        // recurse in to subviews
        if view.subviews.Count > 0 then
          begin
            _AdvanceFocus(false, 0, view, found);
            if found <> nil then
              break;
          end;
      end;

    // go up if we've reached the top of the hierarchy
    if topLevel and (found = nil) then
      _AdvanceFocus(false, root.GetChildIndex, root.GetParent, found);
  end;

var
  target: TView = nil;
begin
  if focusedView = nil then
    _AdvanceFocus(true, 0, self, target)
  else
    _AdvanceFocus(true, focusedView.GetChildIndex, focusedView.GetParent, target);
end;


procedure TWindow.Center;
begin 
  wantsCenter := false;
  SetLocation(RectCenter(GetBounds, ScreenRect).origin);
end;

procedure TWindow.MakeKey; 
begin
  if KeyWindow = self then
    exit;
  if assigned(KeyWindow) then
    KeyWindow.HandleWillResignKeyWindow;
  HandleWillbecomeKeyWindow;
  GLUI.KeyWindow := self;
  HandleDidbecomeKeyWindow;
  OrderFront;
end;

procedure TWindow.MakeKeyAndOrderFront; 
begin
  if KeyWindow = self then
    exit;
  MakeKey;
  OrderFront;
end;

procedure TWindow.OrderFront;
var
  win: TWindow;
begin
  
  if not SharedApp.FindWindow(self) then
    HandleDidAddToScreen;

  // already ordered front
  if not IsFloating and IsFront then
    begin
      SetHidden(false);
      exit;
    end;
      
  if not IsFloating then
    begin
      win := SharedApp.FrontWindow;
      if win <> nil then
        win.HandleWillResignFrontWindow;

      SetHidden(false);

      if win <> nil then
        win.HandleDidResignFrontWindow;

      HandleWillBecomeFrontWindow;
      SharedApp.MoveToFront(self);
      HandleDidBecomeFrontWindow;
    end;

  if assigned(CurrentEvent) then
    TestMouseTracking(CurrentEvent);
end;

function TWindow.IsFront: boolean;
begin
  result := SharedApp.FrontWindow = self;
end;

function TWindow.IsKey: boolean;
begin
  result := KeyWindow = self;
end;

function TWindow.IsModal: boolean;
begin
  result := modal;
end;

function TWindow.IsFloating: boolean;
begin
  result := windowLevel > TWindowLevel.Normal;
end;

procedure TWindow.HandleWillResignKeyWindow;
begin
end;

procedure TWindow.HandleWillBecomeKeyWindow;
begin
end;

procedure TWindow.HandleDidBecomeKeyWindow;
begin
end;

procedure TWindow.HandleDidResignFrontWindow;
begin
end;

procedure TWindow.HandleWillResignFrontWindow;
begin
end;

procedure TWindow.HandleWillBecomeFrontWindow;
begin
end;

procedure TWindow.HandleDidBecomeFrontWindow;
begin
end;

procedure TWindow.HandleScreenDidResize;
begin
end;

procedure TWindow.HandleWillClose;
var
  windowDelegate: IWindowDelegate;
begin
  if Supports(delegate, IWindowDelegate, windowDelegate) then
    windowDelegate.HandleWindowWillClose(self);
end;

function TWindow.AcceptsKeyboardEvents: boolean;
begin
  result := false;
end;

function TWindow.AcceptsMouseMovedEvents: boolean;
begin
  if IsModal then
    result := IsFront
  else if IsFloating then
    result := false
  else
    result := true;
end;

procedure TWindow.Render; 
begin
  {$ifdef BUFFERED_RENDERING}
  if frameBuffer = nil then
    begin
      writeln('CREATE BUFFER: ',frame.size.tostr);
      frameBuffer := TFrameBuffer.Create(frame.size);
      frameBuffer.Flipped := false;
      dirtyRect := Bounds;
    end;

  if tempBuffer = nil then
    tempBuffer := TFrameBuffer.Create(frame.size);

  if NeedsDisplay then
    begin
      tempBuffer.Push;
      ClearBackground;
      PushViewTransform(0, 0, PlatformScreenScale);

      {
        1) does subview intersect dirty rect?
        2) after drawing is complete blit temp buffer to final buffer at the dirty rect
      }
      writeln('-- draw window ', dirtyRect.tostr);
      DrawInternal(0);
      writeln('-- done ');

      PopViewTransform;
      tempBuffer.Pop;
      NeedsDisplay := false;
    end;

    tempBuffer.Blit(frameBuffer, dirtyRect, dirtyRect);
    dirtyRect := TRect.Infinite;

    DrawTexture(frameBuffer.Texture, frame);
    FlushDrawing;
  {$else}
  PushViewTransform(0, 0, PlatformScreenScale);
  DrawInternal(0);
  PopViewTransform;
  {$endif}
end;

procedure TWindow.Initialize;
begin
  inherited Initialize;
  
  freeWhenClosed := false;
  dragOrigin := -1;
  resizeOrigin := -1;
end;

destructor TWindow.Destroy;
begin
  FreeAndNil(frameBuffer);
  FreeAndNil(tempBuffer);
  delegate := nil;
  inherited;
end;

{ Fullscreen constructor }
constructor TWindow.Create;
begin
  Initialize;
  SetMoveableByBackground(false);
  SetAutoresizingOptions(TAutoresizingStretchToFill);
  SetFrame(TWindow.ScreenRect);
end;

{ Returns the size of a fullscreen window }
class function TWindow.ScreenRect: TRect;
begin
  result.origin := 0;
  result.size := TVec2(GetWindowSize) / PlatformScreenScale;
end;

function TWindow.ShouldMoveByBackground(event: TEvent): boolean;
begin
  result := moveableByBackground and IsKey;
end;

function TWindow.ShouldResize(event: TEvent): boolean;
begin
  result := false;
end;

function TWindow.ShouldClose: boolean;
var
  windowDelegate: IWindowDelegate;
begin
  if Supports(delegate, IWindowDelegate, windowDelegate) then
    result := windowDelegate.HandleWindowShouldClose(self)
  else
    result := true;
end;

function TWindow.GetFrameForContentFrame(_contentFrame: TRect): TRect;
begin
  result := _contentFrame;
end;

// alternate method to send default action by invocation
procedure TWindow.HandleDefaultAction(var msg);
begin
  SendDefaultAction;
end;

procedure TWindow.FindSubviewForMouseEvent(event: TEvent; parent: TView; var outView: TView);
var
  child: TView;
begin
  for child in parent.subviews do
    if child.IsMember(TView) and 
       child.InputHit(event) then
      begin
        outView := child;
        child.HandleMouseEntered(event);
        if event.IsAccepted then
          exit;
        if child.subviews.Count > 0 then
          begin
            FindSubviewForMouseEvent(event, child, outView);
            if event.IsAccepted then
              exit;
          end;
      end;
end;

procedure TWindow.HandleKeyEquivalent(event: TEvent);
begin
  // pass to focused view first
  if focusedView <> nil then
    begin
      focusedView.HandleKeyEquivalent(event);
      if event.IsAccepted then
        exit;
    end;
  inherited HandleKeyEquivalent(event);
end;

procedure TWindow.HandleMouseMoved(event: TEvent);
var
  child: TView;
  outView: TView;
begin
  if not AcceptsMouseMovedEvents then
    exit;
  
  // block events that are from a window behind the front window
  if (self <> SharedApp.FrontWindow) and 
    (assigned(SharedApp.FrontWindow) and SharedApp.FrontWindow.InputHit(event)) then
    exit;

  if (mouseInsideView <> nil) and 
     (mouseInsideView.GetParent = nil) then
    begin
      mouseInsideView := nil;
    end;

  if (mouseInsideView <> nil) and 
     not mouseInsideView.InputHit(event) then
    begin
      mouseInsideView.HandleMouseExited(event);
      mouseInsideView := nil;
    end;
  
  if mouseInsideView = nil then
    begin
      outView := nil;
      if InputHit(event) then
        FindSubviewForMouseEvent(event, self, outView);

      // if the event was accepted then set view
      if (outView <> nil) and event.IsAccepted then
        mouseInsideView := outView;
    end;
  
  if mouseInsideView <> nil then
    mouseInsideView.HandleMouseMoved(event);

  // consume the mouse moved event if we're inside the window frame
  if InputHit(event) then
    event.Accept(self);
end;

procedure TWindow.ProcessKeyDown(super: TView; event: TEvent);
var
  child: TView;
  control: TControl;
begin
  for child in super.subviews do
    begin
      if child.IsMember(TControl) then 
        begin
          control := child as TControl;
          if (control.keyEquivalent.keycode = event.KeyCode) and 
            (control.keyEquivalent.modifiers = event.KeyboardModifiers) then
            begin
              control.InvokeAction;
              event.Accept(self);
              break;
            end;
        end;
      ProcessKeyDown(child, event);
      if event.IsAccepted then
        break;
    end;
end;

procedure TWindow.HandleKeyDown(event: TEvent);
begin
  
  // handle default button action
  if (event.KeyCode = KEY_RETURN) and
     (defaultButton <> nil) then
    begin
      TButton(defaultButton).InvokeAction;
      event.Accept(self);
      exit;
    end;
  
  // process keydown for all children
  ProcessKeyDown(self, event);
  if event.IsAccepted then
    exit;

  // pass on to focused view
  if focusedView <> nil then
    focusedView.HandleKeyDown(event);
end;

procedure TWindow.HandleInputEnded(event: TEvent);
var
  where: TPoint;
begin
  inherited HandleInputEnded(event);
  
  // if the press origin is the same then post
  // a pseudo event for the press
  where := event.Location;
  if pressOrigin = where then
    HandleInputPress(event);
    
  pressOrigin := -1;
  dragOrigin := -1;
  resizeOrigin := -1;
end;

procedure TWindow.HandleInputDragged(event: TEvent);
var
  where, newPos: TPoint;
begin 
  pressOrigin := V2(-1, -1);

  if not event.IsAccepted and (dragOrigin <> -1) then
    begin
      where := event.Location(self);
      newPos := GetLocation + V2(where.x - dragOrigin.x, where.y - dragOrigin.y);
      SetLocation(newPos);
      event.Accept(self);
    end
  else if not event.IsAccepted and (resizeOrigin <> -1) then
    begin
      where := event.Location(self);
      newPos := resizeOriginalSize + V2(where.x - resizeOrigin.x, where.y - resizeOrigin.y);
      SetContentSize(newPos);
      //GetBounds.show;
      // we need to force resize windows
      LayoutSubviews;
      event.Accept(self);
    end;
    
  inherited HandleInputDragged(event);
end;

procedure TWindow.HandleInputStarted(event: TEvent);
var
  front: TWindow;
begin   
  pressOrigin := event.Location;
  front := SharedApp.FrontWindow;

  // block clicks outside the window if the front window is modal
  if not InputHit(event) and (front <> nil) and front.IsModal then
    begin
      event.Accept(self);
      exit;
    end;

  // bring the window to front and let the event
  // pass through so it can be dragged
  if InputHit(event) and 
     not IsFront and 
     (front <> nil) and 
     not front.IsModal then
    MakeKeyAndOrderFront;
      
  inherited HandleInputStarted(event);

  // resize window
  if InputHit(event) and not event.IsAccepted then
    begin
      if ShouldResize(event) then
        begin
          resizeOrigin := event.Location(self);
          resizeOriginalSize := GetContentSize;
          event.Accept(self);
          exit;
        end;
    end;

  // drag window by background
  if InputHit(event) and not event.IsAccepted then
    begin
      if ShouldMoveByBackground(event) then
        dragOrigin := event.Location(self);
      event.Accept(self);
      exit;
    end;
end;

procedure TWindow.HandleDidAddToScreen;
begin
  PostNotification(kNotificationWindowWillOpen, self);
        
  SharedApp.Add(self);
  
  if wantsCenter then
    Center; 
  
  PostNotification(kNotificationWindowDidOpen, self);
end;

procedure TWindow.HandleFrameWillChange(var newFrame: TRect);
begin
  // keep windows in visible screen frame (except the menu bar)
  if ShouldConstrainToSafeArea then
    begin
      if newFrame.origin.y < MainScreen.VisibleFrame.MinY then
        newFrame.origin.y := MainScreen.VisibleFrame.MinY;
    end;
end;

procedure TWindow.HandleFrameDidChange(previousFrame: TRect);
begin
  wantsCenter := false;
  inherited HandleFrameDidChange(previousFrame);
end;

function TWindow.ShouldConstrainToSafeArea: boolean;
begin
  result := not InheritsFrom(TMenuBar) and not (windowLevel = TWindowLevel.Drag);
end;

function TWindow.IsOpen: boolean;
begin
  result := SharedApp.FindWindow(self);
end;

procedure TWindow.Close;
begin 
  if ShouldClose then
    begin
      PostNotification(kNotificationWindowWillClose, self);
      HandleWillClose;
      SharedApp.Remove(self);
    end;
end;

procedure TWindow.SendDefaultAction;
begin
  if defaultButton <> nil then
    TButton(defaultButton).InvokeAction;
end;

function TWindow.ShouldAllowEnabling: boolean;
begin
  result := IsFront or IsFloating;
end;

procedure TWindow.FinalizeClose; 
begin
  PostNotification(kNotificationWindowDidClose, self);

  // free the window now that's it's safe
  if freeWhenClosed then
    Free;
end;

function TWindow.PollEvent(event: TEvent): boolean;
begin
  // if the window is modal then we need to block other events
  result := IsModal;
  ScreenMouseLocation := event.Location;

  case event.EventType of
    TEventType.WindowResize:
      HandleScreenDidResize;
    TEventType.MouseDown:
      if SharedCursor.inputStarted = nil then
        begin
          // Assert(SharedCursor.inputStarted = nil, 'mouse up wasn''t processed');

          SharedCursor.mouseDown := true;
          HandleMouseDown(event);
          if event.IsAccepted then
            exit(true);

          HandleInputStarted(event);
          if event.IsAccepted then
            begin
              SharedCursor.inputStarted := event.acceptedObject as TView;
              exit(true);
            end;
        end;
    TEventType.MouseUp:
      begin
        event.m_inputSender := SharedCursor.inputStarted;

        SharedCursor.inputStarted := nil;
        SharedCursor.mouseDown := false;
        HandleMouseUp(event);
        if event.IsAccepted then
          exit(true);

        HandleInputEnded(event);
        if event.IsAccepted then
          exit(true);
      end;
    TEventType.MouseMoved:
      begin
        { don't accpet the mouse moved event during dragging sessions
          the reason for this is so that the event falls through and
          can can be processed on any windows below }
        if SharedDraggingSession <> nil then
          begin
            result := false;
            if SharedDraggingSession <> self then
              begin
                TestDragTracking(event);
                if event.IsAccepted then
                  exit(true);
              end;
          end;

        if SharedCursor.mouseDown then
          begin
            event.m_inputSender := SharedCursor.inputStarted;

            HandleMouseDragged(event);
            if event.IsAccepted then
              exit;
          
            HandleInputDragged(event);
            if event.IsAccepted then
              exit;
          end
        else if AcceptsMouseMovedEvents then
          begin
            HandleMouseMoved(event);
            if event.IsAccepted then
              exit;
          end;

        TestMouseTracking(event);

        // mouse went outside of hover target
        if assigned(SharedCursor.hover) and not SharedCursor.hover.InputHit(event) then
          begin
            SharedCursor.hover.HandleMouseExited(event);
            SharedCursor.hover := nil;
          end;

        // mouse went outside of drag target
        //if assigned(SharedCursor.dragTarget) and not SharedCursor.dragTarget.InputHit(event) then
        //  begin
        //    SharedCursor.dragTarget.HandleMouseExited(event);
        //    SharedCursor.dragTarget := nil;
        //  end;
      end;
    TEventType.Scroll:
      begin
        HandleMouseWheelScroll(event);
        if event.IsAccepted then
          exit(true);
      end;
    TEventType.KeyDown:
      begin
        if assigned(KeyWindow) then
          KeyWindow.HandleKeyDown(event);
        exit(true);
      end;
   end;
end;

class function TWindow.MouseLocation: TPoint;
begin
  result := ScreenMouseLocation;
end;

class function TWindow.FindWindow(ofClass: TWindowClass): TWindow;
var
  win: TWindow;
begin
  result := nil;
  for win in SharedApp.AvailableWindows do
    if win.IsMember(ofClass) then
      exit(win);
end;

class function TWindow.FindWindowAtMouse: TWindow;
var
  win: TWindow;
begin
  result := nil;
  for win in SharedApp.AvailableWindows do
    if win.GetFrame.Contains(TWindow.MouseLocation) then
      exit(win);
end;

class function TWindow.IsFrontWindowBlockingInput(event: TEvent = nil): boolean;
var
  win: TWindow;
begin
  win := SharedApp.FrontWindow;
  if win <> nil then
    begin
      result := not win.IsFloating;
      if event <> nil then
        result := win.InputHit(event);
    end
  else
    result := false;
end;

class function TWindow.DoesFrontWindowHaveKeyboardFocus: boolean;
var
  win: TWindow;
begin
  win := SharedApp.FrontWindow;
  if win <> nil then
    result := win.focusedView <> nil
  else
    result := false;
end;

class function TWindow.KeyWindow: TWindow;
begin
  result := GLUI.KeyWindow;
end;

{ POPOVER }

constructor TPopover.Create(inDelegate: TWindow; inContentSize: TVec2i);
begin
  SetContentSize(inContentSize);
  SetDelegate(inDelegate);
  Initialize;
end;

procedure TPopover.HandlePositioningFrameWillChange(var newFrame: TRect);
begin
end;

procedure TPopover.UpdatePosition;
var
  rect, newFrame: TRect;
begin
  if positioningView <> nil then
    rect := positioningView.ConvertRectTo(positioningRect, nil)
  else
    rect := positioningRect;
    
  case preferredEdge of
    TRectEdge.MinX:
      begin
        newFrame := GetFrame;
        newFrame.origin.x := rect.origin.x - (self.GetWidth + positioningEdgeMargin);
        newFrame.origin.y := rect.origin.y + (rect.height / 2 - self.GetHeight / 2);
        HandlePositioningFrameWillChange(newFrame);
        SetFrame(newFrame);
      end;
    TRectEdge.MaxX:
      begin
        newFrame := GetFrame;
        newFrame.origin.x := rect.MaxX + positioningEdgeMargin;
        newFrame.origin.y := rect.origin.y + (rect.height / 2 - self.GetHeight / 2);
        HandlePositioningFrameWillChange(newFrame);
        SetFrame(newFrame);
      end;
    TRectEdge.MinY:
      begin
        newFrame := GetFrame;
        newFrame.origin.x := rect.origin.x + (rect.width / 2 - self.GetWidth / 2);
        newFrame.origin.y := rect.origin.y - (self.GetHeight + positioningEdgeMargin);
        HandlePositioningFrameWillChange(newFrame);
        SetFrame(newFrame);
      end;
    TRectEdge.MaxY:
      begin
        newFrame := GetFrame;
        newFrame.origin.x := rect.origin.x + (rect.width / 2 - self.GetWidth / 2);
        newFrame.origin.y := rect.maxY + positioningEdgeMargin;
        HandlePositioningFrameWillChange(newFrame);
        SetFrame(newFrame);
      end;
    TRectEdge.Any:
      begin
        newFrame := rect;
        HandlePositioningFrameWillChange(newFrame);
        SetLocation(newFrame.origin);
      end;
    otherwise
      Assert(false, 'Invalid popover edge.');
  end;

  //writeln('popover frame: ', getframe.tostr);
end;

procedure TPopover.Update;
begin
  inherited;

  UpdatePosition;
end;

procedure TPopover.SetBehavior(newValue: TPopoverBehavior);
begin
  behavior := newValue;
end;

procedure TPopover.Show(positioningRect: TRect; positioningView: TView; preferredEdge: TRectEdge); 
begin
  self.positioningRect := positioningRect;
  self.positioningView := positioningView;
  self.preferredEdge := preferredEdge;

  UpdatePosition;
  MakeKeyAndOrderFront;
end;

procedure TPopover.Initialize;
begin
  inherited;
  
  positioningEdgeMargin := 8;
  freeWhenClosed := true;
  behavior := TPopoverBehavior.ApplicationDefined;
  windowLevel := TWindowLevel.Utility;
  ObserveNotification(kNotificationWindowWillOpen, @self.HandleWindowWillOpen, pointer(self));
end;

procedure TPopover.HandleCloseEvent(event: TEvent);
begin
  Close;
end;

procedure TPopover.HandleInputStarted(event: TEvent);
begin 
  if (behavior <> TPopoverBehavior.ApplicationDefined) and not InputHit(event) then
    begin
      HandleCloseEvent(event);
      exit;
    end;
      
  inherited HandleInputStarted(event);
end;

procedure TPopover.HandleInputDragged(event: TEvent);
begin 
  // TODO: why do we need this?
  //if (behavior <> TPopoverBehavior.ApplicationDefined) and not InputHit(event) then
  //  begin
  //    HandleCloseEvent(event);
  //    exit;
  //  end;
      
  inherited HandleInputDragged(event);
end;

procedure TPopover.HandleWillResignFrontWindow;
begin
  if behavior <> TPopoverBehavior.ApplicationDefined then
    Close;
end;

procedure TPopover.HandleWindowWillOpen(notification: TNotification);
begin
  if (behavior <> TPopoverBehavior.ApplicationDefined) and (notification.GetObject <> pointer(self)) then
    Close;
end;

destructor TPopover.Destroy;
begin
  TNotificationCenter.DefaultCenter.RemoveEveryObserver(self);
  
  inherited;
end;

{ TAB VIEW ITEM }

function TTabViewItem.IsSelected: boolean;
begin
  result := tabView.GetSelectedItem = self;
end;

function TTabViewItem.GetPane: TView;
begin
  result := pane;
end;

procedure TTabViewItem.Initialize;
begin
  inherited;  
  SetHeight(13);
end;

destructor TTabViewItem.Destroy;
begin
  pane := nil;
  
  inherited;
end;

constructor TTabViewItem.Create(title: string; _pane: TView);
begin
  pane := _pane;
  Initialize;

  // TODO: height-only constructor?
  button := TButton.Create(RectMake(0, 0, 0, 16), title, GetActiveFont);
  button.SetResizeByWidth(true);
  button.LayoutSubviews;
  SetView(button);
end;

{ TAB VIEW }

function TTabView.GetDelegate: TObject;
begin
  result := delegate;
end;

function TTabView.GetItem(index: integer): TTabViewItem;
begin
  result := tabBar.items[index] as TTabViewItem;
end;

function TTabView.GetSelectedItem: TTabViewItem;
begin
  result := selectedItem;
end;

procedure TTabView.SetDelegate(newValue: TObject);
begin
  delegate := newValue;
end;

procedure TTabView.SetTabHeight(newValue: integer);
begin
  tabHeight := newValue;
  NeedsLayoutSubviews;
end;

procedure TTabView.SelectItem(index: integer);
begin
  SelectItem(GetItem(index));
end;

procedure TTabView.SelectItem(params: TInvocationParams);
var
  del: ITabViewDelegate;
  item: TTabViewItem absolute params;
begin
  writeln('select item ', item.classname);

  // the delgete rejected selection
  if Supports(delegate, ITabViewDelegate, del) then
    if not del.HandleTabViewShouldSelectItem(self, item) then
      exit;
  
  // the item is already selected
  if selectedItem = item then
    exit;
  
  if Supports(delegate, ITabViewDelegate, del) then
    del.HandleTabViewWillSelectItem(self, item);
    
  if selectedItem <> nil then
    begin
      RemoveSubview(selectedItem.GetPane);
      selectedItem := nil;
    end;
    
  if item <> nil then
    begin
      item.GetPane.SetFrame(RectMake(0, tabHeight, GetWidth, GetHeight - tabHeight));
      AddSubview(item.GetPane);
      selectedItem := item;
    end;

  if Supports(delegate, ITabViewDelegate, del) then
    del.HandleTabViewDidSelectItem(self, item);
end;

procedure TTabView.AddItem(item: TTabViewItem); 
begin
  item.tabView := self;
  item.button.SetAction(TInvocation.Create(@self.SelectItem, item));
  tabBar.AddItem(item);
end;

procedure TTabView.LayoutSubviews;
var
  newFrame: TRect;
begin
  newFrame.origin := 0;
  newFrame.size := V2(GetWidth, tabHeight);
  tabBar.SetFrame(newFrame);
  inherited;
end;

procedure TTabView.Initialize;
begin
  inherited;

  tabBar := TTabBar.Create;
  AddSubview(tabBar);
  SetTabHeight(16);
end;

destructor TTabView.Destroy;
begin
  delegate := nil;
  inherited;
end;

{ STATUS BAR }

procedure TStatusBar.SetCurrentValue(newValue: TScalar);
begin
  
end;

procedure TStatusBar.SetMaximumValue(newValue: TScalar);
begin
  
end;

procedure TStatusBar.SetMinimumValue(newValue: TScalar);
begin
  
end;

{ MATRIX VIEW }

function TMatrixView.GetColumns: integer;
begin
  result := columns;
end;

function TMatrixView.GetCellSize: TVec2;
begin
  result := cellSize;
end;

function TMatrixView.GetCellMargin: TScalar;
begin
  result := cellMargin;
end;

procedure TMatrixView.SetCellSize(newValue: TVec2);
begin
  cellSize := newValue;
end;

procedure TMatrixView.SetCellMargin(newValue: TScalar);
begin
  cellMargin := newValue;
end;

procedure TMatrixView.SetColumns(newValue: integer);      
begin
  columns := newValue;
end;

procedure TMatrixView.SetResizeToFit(newValue: boolean);
begin
  resizeToFit := newValue;
end;

procedure TMatrixView.HandleFrameWillChange(var newFrame: TRect);
begin
  inherited HandleFrameWillChange(newFrame);
  // todo: move to LayoutSubviews
  if not arrangingCells then
    ArrangeCells;
end;

procedure TMatrixView.HandleDidAddToParent(sprite: TView);
begin
  inherited HandleDidAddToParent(sprite);
  
  ArrangeCells;
end;

function TMatrixView.GetCellSizeForLayout(maxWidth: TScalar): TVec2;
var
  s: TScalar;
begin
  s := (maxWidth / GetColumns) - GetCellMargin;
  result := V2(s, s);
end;

function TMatrixView.SizeForGrid(grid: TVec2): TVec2;
begin
  result := V2((cellSize.width + cellMargin) * grid.width, (cellSize.height + cellMargin) * grid.height);
  result.x -= cellMargin;
  result.y -= cellMargin;
end;

procedure TMatrixView.ArrangeCells;
var
  cellFrame: TRect;
  cell: TView;
  count: integer = 0;
  i: integer;
  boundingRect: TRect;
begin
  if cells = nil then
    exit;
  
  if cells.Count = 0 then
    exit;
    
  cellFrame := RectMake(0, 0, cellSize.width, cellSize.height);
  boundingRect := RectMake(0, 0, 0, 0);
  
  while count < cells.Count do
    begin
      cellFrame.origin.x := 0;
      
      for i := 0 to columns - 1 do
        begin
          cell := cells[count];
          if cell = nil then
            continue;

          cell.SetFrame(cellFrame);
          boundingRect := boundingRect.Union(cellFrame);
          
          if cell.GetParent = nil then
            AddSubview(cell);
          cellFrame.origin.x += cellFrame.size.width + cellMargin;
          count += 1;
          if count = cells.Count then
            break;
        end;
      
      // increment row
      cellFrame.origin.x -= cellFrame.size.width + cellMargin;
      cellFrame.origin.y += cellFrame.size.height + cellMargin;
    end;
  
  // calculate total height
  if cells.Count > columns then
    totalHeight := (cells.Count / columns) * (cellSize.height + cellMargin) - cellMargin
  else
    totalHeight := cellSize.height;
  
  // resize view to fit all cells
  if resizeToFit then
    begin
      arrangingCells := true;
      SetFrame(RectMake(GetLocation, boundingRect.size));
      arrangingCells := false;
    end;
end;

procedure TMatrixView.Initialize;
begin
  inherited Initialize;
  
  SetCellSize(V2(32, 32));
  SetCellMargin(4);
  SetColumns(3);
end;

{ TStackView }

procedure TStackView.SetOrientation(newValue: TStackViewOrientation);
begin
  m_orientation := newValue;
  NeedsLayoutSubviews;
end;

procedure TStackView.SetCellSpacing(newValue: integer);
begin
  m_cellSpacing := newValue;
  NeedsLayoutSubviews;
end;

procedure TStackView.SetCenterSubviews(newValue: boolean);
begin
  m_centerSubviews := newValue;
  NeedsLayoutSubviews;
end;

procedure TStackView.LayoutSubviews;
var
  view: TView;
  position, yPos: Float;
begin 
  inherited;

  position := 0;
  for view in Subviews do
    begin
      if CenterSubviews then
        yPos := frame.MidX - view.frame.width / 2
      else
        yPos := 0;
      view.SetLocation(V2(yPos, position));

      position += view.GetHeight + CellSpacing;
    end;
end;

constructor TStackView.Create(_frame: TRect; orientation: TStackViewOrientation; cellSpacing: integer; centerSubviews: boolean);
begin
  inherited Create(_frame);
  self.Orientation := orientation;
  self.CellSpacing := cellSpacing;
  self.CenterSubviews := centerSubviews;
end;

{ MENU ITEM }

function TMenuItem.PopupSubmenu(sender: TMenu): TMenu;
var
  screenPoint: TVec2;
begin
  Assert(submenu <> nil, 'must have submenu to popup.');

  screenPoint := ConvertPointTo(V2(bounds.maxX, bounds.minY), nil);
  submenu.parentMenu := sender;
  submenu.Popup(screenPoint);

  result := submenu;
end;

function TMenuItem.GetMenu: TMenu;
begin
  result := TMenu(GetParent);
end;

procedure TMenuItem.SetHilighted(newValue: boolean);
var
  color: TColor;
begin
  if newValue then
    color := TColor.White
  else
    color := TColor.Black;

  cell.SetTextColor(color);
  if keyEquivalentCell <> nil then
    keyEquivalentCell.SetTextColor(color);
end;

procedure TMenuItem.SetImage(newValue: TTexture);
begin
  cell.SetImageValue(newValue);
end;

procedure TMenuItem.SetFont(newValue: IFont);
begin
  cell.SetFont(newValue);
  if keyEquivalentCell <> nil then
    keyEquivalentCell.SetFont(newValue);
end;

procedure TMenuItem.SetChecked(newValue: boolean);
begin
  checked := newValue;
end;

function TMenuItem.IsChecked: boolean;
begin
  result := checked;
end;

function TMenuItem.IsSubmenuOpen: boolean;
begin
  if submenu <> nil then
    result := submenu.IsOpen
  else
    result := false;
end;

function TMenuItem.IsSelected: boolean;
begin
  if menu <> nil then
    result := menu.GetSelectedItem = self
  else
    result := false;
end;

function TMenuItem.GetTitle: string;
begin
  result := cell.GetStringValue;
end;

function TMenuItem.GetTextSize: TVec2i;
begin
  result := cell.textView.GetTextSize;
end;

function TMenuItem.GetItemIndex: integer;
begin
  if menu = nil then
    exit(-1);
  result := menu.IndexOfItem(self);
end;

procedure TMenuItem.HandleInputEnded(event: TEvent);
var
  delegate: IMenuDelegate;
begin 
  if InputHit(event) and IsEnabled and (menu.popupOrigin <> TWindow.MouseLocation) then
    begin
      if Supports(menu.GetDelegate, IMenuDelegate, delegate) then
        delegate.HandleMenuWillSelectItem(Menu, self);
      InvokeAction;
      event.Accept(self);
      menu.CloseAll;
    end;
  
  inherited HandleInputEnded(event);
end;

procedure TMenuItem.Draw;
begin
  if IsSelected then
    menu.DrawSelection(GetBounds);
  inherited;
end;

procedure TMenuItem.SizeToFit;
var
  newFrame: TRect;
begin
  if menu <> nil then
    begin
      cell.SizeToFit;

      if keyEquivalentCell <> nil then
        keyEquivalentCell.SizeToFit;

      // resize menu item to fit cell
      newFrame := GetFrame;
      newFrame.size.width := cell.GetWidth + menu.margin.x * 2;
      if keyEquivalentCell <> nil then
        newFrame.size.x += keyEquivalentCell.frame.width + { use margin to separate items } menu.margin.x;
      newFrame.size.height := cell.GetHeight;
      SetFrame(newFrame);
    end;
end;

procedure TMenuItem.LayoutSubviews;
var
  newFrame: TRect;
begin 
  inherited;

  if menu <> nil then
    begin
      newFrame := cell.GetFrame;
      newFrame.origin.x := menu.margin.x;
      newFrame.size.y := GetHeight;
      cell.SetFrame(newFrame);

      if keyEquivalentCell <> nil then
        begin
          newFrame := keyEquivalentCell.GetFrame;
          newFrame.origin.x := bounds.maxX - (newFrame.width + menu.margin.x);
          newFrame.size.y := GetHeight;
          keyEquivalentCell.SetFrame(newFrame);
        end;
    end;
end;

procedure TMenuItem.SetSubmenu(newValue: TMenu);
begin
  SetKeyEquivalentCellValue('>');
  m_submenu := newValue;
end;

procedure TMenuItem.SetKeyEquivalentCellValue(value: string);
begin
  if keyEquivalentCell = nil then
    begin
      keyEquivalentCell := TTextAndImageCell.Create;
      AddSubview(keyEquivalentCell);
    end;

  keyEquivalentCell.SetStringValue(value);
end;

procedure TMenuItem.SetKeyEquivalent(keycode: TKeyCode; modifiers: TShiftState);
var
  codeName: string;
begin
  inherited SetKeyEquivalent(keycode, modifiers);

  codeName := UpperCase(TFontChar(keycode));
  if modifiers <> [] then
    codeName := '- '+codeName;
  SetKeyEquivalentCellValue(codeName);
end;

procedure TMenuItem.Initialize;
begin
  inherited;

  cell := TTextAndImageCell.Create;
  cell.SetImageTitleMargin(4);
  AddSubview(cell);
end;

constructor TMenuItem.Create(_title: string; _action: TInvocation);
begin
  Initialize;
  cell.SetStringValue(_title);
  if _action <> nil then
    SetAction(_action);
end;

{ MENU }

constructor TMenu.Create(_title: string = '');
begin
  m_title := _title;
  SetDelegate(self);
  Initialize;
end;

procedure TMenu.SetFont(newValue: IFont);
begin
  font := newValue;
  NeedsLayoutSubviews;
end;

procedure TMenu.AddItem(item: TMenuItem);
begin
  items.Add(item);
  NeedsLayoutSubviews;
end;

function TMenu.AddItem(title: string; action: TInvocation): TMenuItem;
begin
  result := TMenuItem.Create(title, action);
  AddItem(result);
end;

function TMenu.AddItem(title: string; action: TInvocation; keycode: TKeyCode; modifiers: TShiftState = []): TMenuItem;
begin
  result := AddItem(title, action);
  result.SetKeyEquivalent(keycode, modifiers);
end;

function TMenu.AddItem(title: string; method: string; keycode: TKeyCode; modifiers: TShiftState = []): TMenuItem;
begin
  result := AddItem(title, TInvocation.Create(TApplication.FirstResponder, method), keycode, modifiers);
end;

procedure TMenu.InsertItem(index: integer; item: TMenuItem);
begin
  items.Insert(index, item);
  NeedsLayoutSubviews;
end;

procedure TMenu.RemoveItem(item: TMenuItem);
begin
  items.Remove(item);
  NeedsLayoutSubviews;
end;

procedure TMenu.RemoveItem(index: integer);
begin
  items.Delete(index);
  NeedsLayoutSubviews;
end;

procedure TMenu.ValidateMenuItems;
var
  item: TMenuItem;
  target: TObject;
  validation: IMenuItemValidation;
  valid: boolean;
begin
  // TODO: make an option "autoenablesItems"
  for item in items do
    if item.HasActions and item.Actions[0].HasTarget then
      begin
        target := item.Actions[0].Target;
        if (target <> nil) and Supports(target, validation) then
          begin
            valid := validation.HandleValidateMenuItem(item);
            item.SetEnabled(valid);
          end;
      end;
end;

procedure TMenu.Popup(_positioningRect: TRect; _positioningView: TView; edge: TRectEdge);

  // TODO: make an app level method for this
  {$ifdef PLATFORM_GLPT}
  procedure SimulateMouseEvent(where: TVec2i);
  var
    params: GLPT_MessageParams;
    msg: GLPT_MessageRec;
  begin
    params := Default(GLPT_MessageParams);
    params.mouse.x := where.x;
    params.mouse.y := where.y;
    params.mouse.timestamp := GetTime;

    msg := Default(GLPT_MessageRec);
    msg.win := MainPlatformWindow;
    msg.mcode := GLPT_MESSAGE_MOUSEMOVE;
    msg.params := params;

    PendingEvents.Add(TEvent.Create(msg));
    //SharedApp.PollEvents(@msg);
    //TApplication.Active.PostEvent(event);
  end;
  {$endif}

var
  menu: TMenu;
begin

  // there is already a window open!
  menu := TMenu(SharedApp.FindWindowOfClass(TMenu));
  if (menu <> nil) and (parentMenu <> menu) then
    menu.Close;

  LayoutSubviews;
  ValidateMenuItems;
  Show(_positioningRect, _positioningView, edge);
  UpdatePosition;

  popupOrigin := TWindow.MouseLocation;

  // TODO: simulate a mouse moved event to select item under the mouse
  // broken for now for some reason...
  //SimulateMouseEvent(popupOrigin);
end;

procedure TMenu.Popup(where: TPoint);
begin
  Popup(RectMake(where, 0, 0), nil, TRectEdge.Any);
end;

procedure TMenu.Popup(parentView: TView);
begin
  Assert(parentView <> nil, 'parent view must not be nil');
  Popup(parentView.GetBounds, parentView, TRectEdge.MaxY);
end;

{ Closes all open menus up the chain }
procedure TMenu.CloseAll;
begin
  writeln('close all ', title);
  Close;
  if parentMenu <> nil then
    parentMenu.CloseAll;
end;

procedure TMenu.HandleWillClose;
begin
  writeln('will close ', title);

  inherited;

  { restore the parent menu key
    and clear the parents reference to us }
  if parentMenu <> nil then
    begin
      parentMenu.MakeKey;
      parentMenu.childMenu := nil;
    end;

  if childMenu <> nil then
    begin
      childMenu.Close;
      childMenu := nil;
    end;

  // make sure the menu doesn't retain its selection
  selectedItem := nil;
end;

procedure TMenu.HandleCloseEvent(event: TEvent);
begin
  Close;
  event.Accept(self);
end;

function TMenu.AcceptsMouseMovedEvents: boolean;
begin
  result := IsOpen;
end;

function TMenu.GetItemFrame(item: TMenuItem): TRect;
begin
  if itemHeight = 0 then
    result := RectMake(0, margin.y, 0, item.GetTextSize.Height + 4)
  else
    result := RectMake(0, margin.y, 0, itemHeight);
end;

function TMenu.GetSelectedItem: TMenuItem;
begin
  result := m_selectedItem;
end;

function TMenu.IndexOfItem(item: TMenuItem): integer;
var
  i: integer;
begin
  result := -1;
  for i := 0 to items.Count - 1 do
    if items[i] = item then
      exit(i);
end;

function TMenu.IndexOfItemWithTitle(_title: string): integer;
var
  i: integer;
begin
  result := -1;
  for i := 0 to items.Count - 1 do
    if items[i].Title = _title then
      exit(i);
end;

function TMenu.IndexOfItemWithTag(_tag: integer): integer;
var
  i: integer;
begin
  result := -1;
  for i := 0 to items.Count - 1 do
    if items[i].Tag = _tag then
      exit(i);
end;

function TMenu.ItemWithTitle(_title: string): TMenuItem;
var
  i: integer;
begin
  result := nil;
  for i := 0 to items.Count - 1 do
    if items[i].Title = _title then
      exit(items[i]);
end;

function TMenu.ItemWithTag(_tag: integer): TMenuItem;
var
  i: integer;
begin
  result := nil;
  for i := 0 to items.Count - 1 do
    if items[i].Tag = _tag then
      exit(items[i]);
end;

procedure TMenu.DrawSelection(rect: TRect); 
begin
  FillRect(rect, RGBA(0, 0, 0.7, 0.4));
end;

procedure TMenu.SetSelectedItem(newValue: TMenuItem); 
begin
  HandleSelectionWillChange(newValue);
  //if (m_selectedItem <> nil) and (m_selectedItem <> newValue) then
  //  m_selectedItem.SetHilighted(false);
  m_selectedItem := newValue;
  //if m_selectedItem <> nil then
  //  m_selectedItem.SetHilighted(true);
  HandleSelectionDidChange;
end;

procedure TMenu.HandleSelectionWillChange(newItem: TMenuItem);
begin
  if (m_selectedItem <> nil) and (m_selectedItem <> newItem) then
    m_selectedItem.SetHilighted(false);
end;

procedure TMenu.HandleSelectionDidChange;
begin
  if m_selectedItem <> nil then
    m_selectedItem.SetHilighted(true);
end;

procedure TMenu.TrackSelection(event: TEvent);
var
  item: TMenuItem;
begin 
  if IsOpen then
    begin
      // remove selection outside of menu
      if not InputHit(event) then
        begin
          // if there is a selected item with an open submenu
          // then don't deselect the item
          if (selectedItem <> nil) and not selectedItem.IsSubmenuOpen then
            selectedItem := nil;
          exit;
        end;
      for item in items do
        begin
          if item.InputHit(event) then
            begin
              selectedItem := item;
              event.Accept(item);
              // popup the submenu for the item
              if item.submenu <> nil then
                childMenu := item.PopupSubmenu(self)
              else if childMenu <> nil then
                begin
                  childMenu.Close;
                  childMenu := nil;
                end;
              exit;
            end
        end;
    end;
end;

procedure TMenu.HandleMouseDragged(event: TEvent);
begin 
  TrackSelection(event);
  if not event.IsAccepted then
    inherited HandleMouseDragged(event);
end;

procedure TMenu.HandleMouseMoved(event: TEvent);
begin 
  TrackSelection(event);
  if not event.IsAccepted then
    inherited HandleMouseMoved(event);
end;

procedure TMenu.HandleKeyDown(event: TEvent);
var
  index: integer;
  item: TMenuItem;
begin
  //writeln(event.KeyCode);
  case event.KeyCode of
    KEY_ESCAPE:
      begin
        writeln('close menu!');
        Close;
        event.Accept(self);
      end;
    KEY_RETURN:
      begin
        if selectedItem <> nil then
          begin
            selectedItem.InvokeAction;
            InvokeAfterDelay(0.0, @self.CloseAll);
          end;
        event.Accept(self);
      end;
    KEY_LEFT:
      begin
        // if the menu has a parent then close us
        if parentMenu <> nil then
          begin
            Close;
            event.Accept(self);
            exit;
          end
        else
          begin
            index := MainMenuBar.IndexOfMenu(self);
            index -= 1;
            if index >= 0 then
              writeln(index);
            MainMenuBar.Items[index].OpenMenu;
            event.Accept(self);
          end;
      end;
    KEY_RIGHT:
      begin
        if (selectedItem <> nil) and (selectedItem.submenu <> nil) then
          begin
            Assert(childMenu = nil, 'submenu already open');
            childMenu := selectedItem.PopupSubmenu(self);
            childMenu.SetSelectedItem(childMenu.Items[0]);
            event.Accept(self);
          end
        else
          begin
            index := MainMenuBar.IndexOfMenu(self);
            index += 1;
            if index < MainMenuBar.itemBar.Items.Count then
              writeln(index);

            MainMenuBar.Items[index].OpenMenu;
            event.Accept(self);
          end;
      end;
    KEY_UP:
      begin
        item := GetSelectedItem;
        if item = nil then
          selectedItem := items[0]
        else
          begin
            index := items.IndexOf(item) - 1;
            if index >= 0 then
              selectedItem := items[index];
          end;
        event.Accept(self);
      end;
    KEY_DOWN:
      begin
        writeln('down');
        item := GetSelectedItem;
        if item = nil then
          selectedItem := items[0]
        else
          begin
            index := items.IndexOf(item) + 1;
            if index < items.Count then
              selectedItem := items[index];
          end;
        event.Accept(self);
      end;
  end;
end;

procedure TMenu.LayoutSubviews;
var
  item: TMenuItem;
  widestItem: integer = 0;
  hasRightColumn: boolean = false;
  itemFrame: TRect;
begin 
  inherited;

  // calculate widest item width
  for item in items do
    begin
      if item.GetParent = nil then
        AddSubview(item);

      Assert(font <> nil, 'Menu must set font before LayoutSubviews.');
      item.SetFont(font);

      item.SizeToFit;
      
      if item.cell.IsImageVisible then
        hasRightColumn := true;

      if widestItem < item.GetWidth then
        widestItem := trunc(item.GetWidth);
    end;

  if widestItem < minimumWidth then
    widestItem := minimumWidth;

  // resize all items to fit largest width
  itemFrame := GetItemFrame(item);
  itemFrame.size.width := widestItem;

  for item in items do
    begin     
      // if the menu has a right accessory column then
      // make sure all items are showing their image view
      if hasRightColumn and not item.cell.IsImageVisible then
        item.SetImage(nil);
      item.SetFrame(itemFrame);
      itemFrame.origin.y += itemFrame.height;
    end;
  
  // resize menu to fit all items
  SetSize(itemFrame.Width, (itemFrame.MaxY - itemFrame.Height) + margin.y);
end;

procedure TMenu.Initialize;
begin
  inherited;
  
  itemHeight := 0;
  margin := V2(8, 8);
  minimumWidth := 0;
  m_items := TMenuItemList.Create;
  freeWhenClosed := false;
  windowLevel := TWindowLevel.Menu;
  positioningEdgeMargin := 0;

  SetBackgroundColor(RGBA(1.0, 0.75));
end;

destructor TMenu.Destroy;
begin
  items.Free;
  font := nil;
  inherited;
end;

{ MENUBAR ITEM }

procedure TMenuBarItem.OpenMenu;
begin
  if not menu.IsOpen then
    begin
      menu.SetBehavior(TPopoverBehavior.Transient);
      menu.Popup(self);
    end;
end;

procedure TMenuBarItem.HandleKeyEquivalent(event: TEvent);
var
  item: TMenuItem;
begin
  inherited HandleKeyEquivalent(event);
  if event.IsAccepted then
    exit;

  for item in menu.Items do
    begin
      item.HandleKeyEquivalent(event);
      if event.IsAccepted then
        break;
    end;
end;

procedure TMenuBarItem.HandleMouseEntered(event: TEvent);
begin
  if InputHit(event) and IsEnabled and not menu.IsOpen and MainMenuBar.HasOpenMenus then
    begin
      writeln('over ', menu.title);
      OpenMenu;
    end;
end;

procedure TMenuBarItem.HandleInputStarted(event: TEvent);
begin 
  if InputHit(event) and IsEnabled then
    begin
      if menu.IsOpen then
        menu.Close;
      OpenMenu;
      HandleStateChanged;
      event.Accept(self);
    end
  else
    inherited HandleInputStarted(event);
end;

constructor TMenuBarItem.Create(_view: TView; _menu: TMenu);
begin
  inherited Create(_view);

  m_menu := _menu;
  m_menu.m_menuBarItem := self;
end;

{ MENUBAR }

type
  TMenuBarItemCell = class(TTextAndImageCell)
  end;

function TMenuBar.GetItems: TMenuBarItemList;
begin
  result := TMenuBarItemList(itemBar.items);
end;

procedure TMenuBar.HandleWillAddToParent(view: TView);
begin
  Assert(false, 'menubar should not be managed manually.');
end;

procedure TMenuBar.HandleScreenDidResize;
begin
  SetFrame(RectMake(0, 0, TWindow.ScreenRect.Size.Width, MenuBarHeight));
end;

function TMenuBar.HasOpenMenus: boolean;
var
  item: TMenuBarItem;
begin
  result := false;
  for item in Items do
    if item.menu.IsOpen then
      exit(true);
end;

function TMenuBar.IndexOfMenu(menu: TMenu): integer;
var
  i: integer;
begin
  result := -1;
  for i := 0 to itemBar.Items.Count - 1 do
     if TMenuBarItem(itemBar.Items[i]).Menu = menu then
      exit(i);
end;

procedure TMenuBar.AddMenu(menu: TMenu);
var
  cell: TMenuBarItemCell;
  item: TMenuBarItem;
begin
  cell := TMenuBarItemCell.Create(RectMake(0, 0, 0, frame.height));
  cell.SetStringValue(menu.title);
  cell.SetFont(menu.font);
  cell.SizeToFit;

  item := MenuBarItemClass.Create(cell, menu);

  itemBar.AddItem(item);
end;

class function TMenuBar.MenuBarItemClass: TMenuBarItemClass;
begin
  result := TMenuBarItem;
end;

class function TMenuBar.MainMenu: TMenuBar;
begin
  result := MainMenuBar;
end;

class function TMenuBar.MenuBarHeight: integer;
begin
  result := 20;
end;

class function TMenuBar.ItemMargin: integer;
begin
  result := 0;
end;

constructor TMenuBar.Create;
var
  rect: TRect;
begin
  Assert(MainMenuBar = nil, 'Menu bar already exists!');

  inherited;

  //SetAutoresizingOptions([TAutoresizingOption.MinXMargin, TAutoresizingOption.MaxXMargin, TAutoresizingOption.WidthSizable]);
  windowLevel := TWindowLevel.Menu;

  SetFrame(RectMake(0, 0, TWindow.ScreenRect.Size.Width, MenuBarHeight));
  
  rect := Bounds;
  rect.origin.x += ItemMargin;
  rect.size.x -= ItemMargin;

  itemBar := TItemBar.Create(rect);
  itemBar.SetAutoresizingOptions(TAutoresizingStretchToFill);
  AddSubview(itemBar);

  OrderFront;
  MainMenuBar := self;
end;


{ BAR ITEM }

function TBarItem.GetCell: TCell;
begin
  result := TCell(Subviews[0]);
end;

procedure TBarItem.LayoutSubviews;
var
  newFrame: TRect;
begin
  inherited;

  newFrame := cell.Frame;
  newFrame.origin.x += cellPadding;
  newFrame.origin.y := frame.MidY - newFrame.Height / 2;
  cell.SetFrame(newFrame);

  newFrame := Frame;
  newFrame.size.x := cell.frame.width + (cellPadding * 2);
  SetFrame(newFrame);
end;

procedure TBarItem.SetView(newValue: TView);
begin
  Assert(newValue is TCell, 'bar item must be subclass of TCell');
  //newValue.SetAutoresizingOptions(TAutoresizingStretchToFill);
  newValue.SetAutoresizingOptions([TAutoresizingOption.MinXMargin, TAutoresizingOption.MinYMargin]);
  SetWidth(newValue.GetWidth);
  AddSubview(newValue);
end;

procedure TBarItem.Initialize;
begin
  inherited;

  cellPadding := 3;
end;

constructor TBarItem.Create(_view: TView);
begin
  Initialize;
  SetView(_view);
end;

constructor TBarItem.Create(width: integer);
begin
  Initialize;
  SetFrame(RectMake(0, 0, width, 0));
end;

{ ITEM BAR }

function TItemBar.GetItems: TBarItemList;
begin
  result := items;
end;

procedure TItemBar.SetItemMargin(newValue: integer);
begin
  itemMargin := newValue;
  NeedsLayoutSubviews;
end;

procedure TItemBar.SetItems(newValue: TBarItemList);
begin
  items := newValue;
  NeedsLayoutSubviews;
end;

procedure TItemBar.AddItem(item: TBarItem);
begin
  items.Add(item);
  NeedsLayoutSubviews;
end;

procedure TItemBar.RemoveAllItems;
begin
  // TODO: this doesn't remove from parent also.
  //items.Clear;
  NeedsLayoutSubviews;
end;

procedure TItemBar.SetResizeByWidth(newValue: boolean);
begin
  resizeByWidth := newValue;
  NeedsLayoutSubviews;
end;

procedure TItemBar.SetEnableContentClipping(newValue: boolean);
begin
  enableContentClipping := newValue;
end;

procedure TItemBar.Draw;
var
  child: TView;
begin
  //FillRect(GetBounds, RGBA(0,0,0,0.25));
  if assigned(subviews) then
    for child in subviews do
      begin
        if enableContentClipping then
          PushClipRect(GetClipRect);
        child.DrawInternal(renderOrigin);
        if enableContentClipping then
          PopClipRect;
      end
end;

procedure TItemBar.HandleDidAddItem(item: TBarItem);
begin
end;

procedure TItemBar.LayoutSubviews;
var
  item: TBarItem;
  rect: TRect;
  totalWidth: TScalar;
begin
  rect.origin.x := itemOffset;
  rect.origin.y := 0;
  rect.size.height := GetHeight;
  totalWidth := 0;
  
  for item in items do
    begin
      if item.GetParent = nil then
        begin
          AddSubview(item);
          HandleDidAddItem(item);
        end;

      rect.size.width := item.GetWidth;
      //writeln('item ', rect.tostr, ' cell: ', item.Subviews[0].frame.tostr);
      item.SetFrame(rect);
      
      rect.origin.x += rect.Width + itemMargin;
      totalWidth += rect.Width + itemMargin;
    end;
  
  totalWidth -= itemMargin;
  
  if resizeByWidth then
    begin
      rect := GetFrame;
      rect.size.width := totalWidth;
      SetFrame(rect);
    end;
end;

procedure TItemBar.Initialize;
begin
  inherited Initialize;

  itemMargin := 4;
  itemOffset := 0;
  items := TBarItemList.Create;

  SetEnableContentClipping(true);
end;

destructor TItemBar.Destroy;
begin
  items.Free;
end;


{ CELL }

procedure TCell.SetObjectValue(newValue: pointer);
begin
  objectValue := newValue;
end;

procedure TCell.SetFont(newValue: IFont);
begin
  font := newValue;
end;

procedure TCell.SetSelectable(newValue: boolean);
begin
  selectable := newValue;
end;

function TCell.GetObjectValue: pointer;
begin
  result := objectValue;
end;

function TCell.IsSelectable: boolean;
begin
  result := selectable;
end;

destructor TCell.Destroy;
begin
  objectValue := nil;
  inherited;
end;

procedure TCell.Initialize;
begin
  inherited;
  
  SetSelectable(true);
  SetAutoresizingOptions([]);
end;

{ SECTION CELL }

class function TSectionCell.Height: integer;
begin
  result := 16;
end;

class function TSectionCell.Section(title: string): TSectionCell;
begin
  result := Section(title, nil);
end;

class function TSectionCell.Section(title: string; _font: IFont): TSectionCell;
begin
  result := TSectionCell.Create;
  if _font <> nil then
    result.SetFont(_font);
  result.SetStringValue(title);
end;

procedure TSectionCell.Initialize;
begin
  inherited Initialize;
  
  SetSelectable(false);
  SetBackgroundColor(RGBA(0, 0.25));
  //SetFont(IFont.SystemFont);
  SetHeight(TSectionCell.Height);
end;

{ TEXT AND IMAGE CELL }

procedure TTextAndImageCell.SetStringValue(newValue: string);
begin
  inherited SetStringValue(newValue);
  textView.SetText(newValue);
end;

procedure TTextAndImageCell.SetObjectValue(newValue: pointer);
begin
  inherited SetObjectValue(newValue);
  SetStringValue(ansistring(newValue));
end;

procedure TTextAndImageCell.SetFont(newValue: IFont);
begin
  inherited SetFont(newValue);
  textView.SetFont(newValue);
  NeedsLayoutSubviews;
end;

procedure TTextAndImageCell.SetTextColor(newValue: TColor);
begin
  textView.SetTextColor(newValue);
end;

procedure TTextAndImageCell.SetImageValue(newValue: TTexture);
begin
  if not assigned(imageView) then
    begin
      imageView := TImageView.Create;
      imageView.SetOptions([TImageViewOption.ScaleProportionately]);
      AddSubview(imageView);
    end;
  imageView.SetImage(newValue);
  NeedsLayoutSubviews;
end;

procedure TTextAndImageCell.SetImageTitleMargin(newValue: TScalar);
begin
  imageTitleMargin := newValue;
  NeedsLayoutSubviews;
end;

function TTextAndImageCell.IsImageVisible: boolean;
begin
  result := assigned(imageView);
end;

function TTextAndImageCell.GetImageValue: TTexture;
begin
  result := TTexture(imageView.Image);
end;

function TTextAndImageCell.GetStringValue: string;
begin
  result := textView.Text;
end;

function TTextAndImageCell.GetFont: IFont;
begin
  result := textView.GetFont;
end;

function TTextAndImageCell.GetTextView: TTextView;
begin
  result := textView;
end;

function TTextAndImageCell.GetTextFrame: TRect;
var
  newFrame: TRect;
  imageSize: TVec2;
begin
  imageSize := ImageFrame.Size;

  newFrame := GetBounds;
  newFrame.origin.x += imageSize.width;
  if assigned(textView) and assigned(imageView) then
    newFrame.origin.x += imageTitleMargin;
  newFrame.size.x -= imageSize.height;
  newFrame.size.height := textView.GetTextSize.height;
  if GetBounds.size.height > newFrame.size.height then
    result := RectCenterY(newFrame, GetBounds)
  else
    result := newFrame;

end;

function TTextAndImageCell.GetImageFrame: TRect;
begin
  if assigned(imageView) then
    begin
      result := RectMake(0, 0, GetHeight, GetHeight);
      result := RectCenterY(result, GetBounds);
    end
  else
    result := RectMake(0, 0, 0, 0);
end;

procedure TTextAndImageCell.SizeToFit;
var
  newFrame: TRect;
begin
  newFrame.origin := GetLocation;
  newFrame.size := 0;

  if assigned(textView) and textView.IsReadyToLayout then
    begin
      newFrame.size.x += textView.GetTextSize.Width;
      newFrame.size.height := textView.GetTextSize.Height;
    end;
  
  if assigned(imageView) then
    begin
      newFrame.size.x += GetImageFrame.width;
      if assigned(textView) then
        newFrame.size.x += imageTitleMargin;
    end;

  //writeln('size to fit: ', newFrame.tostr);
  SetFrame(newFrame);
end;

procedure TTextAndImageCell.LayoutSubviews;
var
  clipping: boolean;
begin

  if assigned(textView) and textView.IsReadyToLayout then
    textView.SetFrame(GetTextFrame);
  
  if assigned(imageView) then
    imageView.SetFrame(GetImageFrame);

  // TODO: we need this for OTHER views in the cell but we don't want to re-do the
  // text and image view...
  //inherited;

  // dynamically enable clipping for subviews if the
  // cell is in view
  clipping := false;
  SubviewsAreClipping(clipping);
  SetEnableClipping(clipping);
end;

procedure TTextAndImageCell.Initialize;
begin
  inherited Initialize;

  imageTitleMargin := 0;
  
  textView := TTextView.Create;
  textView.SetWidthTracksContainer(true);
  AddSubview(textView); 
end;

{ SCROLLER }

procedure TScroller.Initialize;
begin
  inherited;
  range := TRangeInt.Create(0, 100);
end;

procedure TScroller.HandleWillAddToParent(sprite: TView);
begin
  inherited;

  {
  upButton := TButton.Create;
  // TODO: add messages invocations if we actually need them. not sure why we're using them here...
  //upButton.SetAction('ScrollUp', scrollView);
  AddSubview(upButton);

  downButton := TButton.Create;
  //downButton.SetAction('ScrollDown', scrollView);
  AddSubview(downButton);
  }

  //upButton.SetFrame(RectMake(GetBounds.origin + scrollerParts.upButtonOffset, scrollerParts.upButtonNormal.GetSize));
  //downButton.SetFrame(RectMake(V2(0, GetHeight - scrollerParts.downButtonNormal.GetHeight) + scrollerParts.downButtonOffset, scrollerParts.downButtonNormal.GetSize));
end;

procedure TScroller.HandleFrameDidChange(previousFrame: TRect);
begin
  inherited;

  if GetParent <> nil then
    begin
      //upButton.SetFrame(RectMake(GetBounds.origin + scrollerParts.upButtonOffset, scrollerParts.upButtonNormal.GetSize));
      //downButton.SetFrame(RectMake(V2(0, GetHeight - scrollerParts.downButtonNormal.GetHeight) + scrollerParts.downButtonOffset, scrollerParts.downButtonNormal.GetSize));
    end;
end;

procedure TScroller.HandleValueChanged;
var
  total, 
  percent: float;
begin
  inherited;

  if scrollView <> nil then
    if IsVertical then
      begin
        total := scrollView.GetScrollableFrame.Height;
        percent := GetValue / range.Total;
        scrollView.SetScrollOrigin(V2(0, total * percent), false, true);
      end
    else
      begin
        total := scrollView.GetScrollableFrame.Width;
        percent := GetValue / range.Total;
        scrollView.SetScrollOrigin(V2(total * percent, 0), true, false);
      end;
end;

function TScroller.GetTrackFrame: TRect; 
begin
  result := inherited;
  //if IsVertical then
  //  result := RectMake(0, {scrollerParts.upButtonNormal.GetHeight}20, GetWidth, GetHeight - ({scrollerParts.upButtonNormal.GetHeight}20 * 2))
  //else
  //  result := RectMake(0, 0, GetWidth, GetHeight);
end;

{ SLIDER }

constructor TSlider.Create(current, min, max: TSliderValue; _frame: TRect);
begin
  range := TRangeInt.Create(min, max);
  SetFrame(_frame);
  SetValue(current);
  Initialize;
end;

{ Create slider with property binding }
constructor TSlider.Create(propName: string; controller: TObject; current, min, max: TSliderValue; _frame: TRect);
begin
  Create(current, min, max, _frame);
  SetBinding(propName, controller);
end;

procedure TSlider.SetValue(newValue: TSliderValue);
begin
  m_value := interval * Ceil(newValue / interval);
end;

procedure TSlider.SetInterval(newValue: integer);
begin
  Assert(newValue > 0, 'interval must be greater than 0.');
  interval := newValue;
end;

procedure TSlider.SetTickMarks(newValue: integer);
begin
  tickMarks := newValue;
end;

procedure TSlider.SetShowValueWhileDragging(newValue: boolean);
begin
  showValueWhileDragging := newValue;
end;

procedure TSlider.SetLiveUpdate(newValue: boolean);
begin
  liveUpdate := newValue;
end;

procedure TSlider.SetTitleFont(newValue: IFont);
begin
  labelFont := newValue;
  if textView <> nil then
    textView.SetFont(labelFont);
end;

procedure TSlider.SetTitle(newValue: string);
begin
  if textView = nil then
    begin
      textView := TTextView.Create;
      textView.SetWidthTracksContainer(true);
      textView.SetFont(labelFont);
      textView.SetAutoresizingOptions([]);
      AddSubview(textView);
    end;

  textView.SetText(newValue);
  NeedsLayoutSubviews;
  SetIdentifierFromTitle(newValue);
end;

function TSlider.GetValue: TSliderValue;
begin
  result := GetIntegerValue;
end;

function TSlider.GetMinValue: TSliderValue;
begin
  result := range.min;
end;

function TSlider.GetMaxValue: TSliderValue;
begin
  result := range.max;
end;

function TSlider.IsVertical: boolean;
begin
  result := GetHeight > GetWidth;
end;

function TSlider.IsDragging: boolean;
begin
  result := dragging;
end;

function TSlider.GetTrackFrame: TRect; 
begin
  result := GetBounds;
end;

function TSlider.GetHandleFrame: TRect; 
begin
  if IsVertical then
    result := RectMake(0, 0, GetWidth, 12)
  else
    result := RectMake(0, 0, 12, GetHeight);
end;

function TSlider.GetTrackSize: TVec2; 
begin
  result.height := (GetTrackFrame.Height - GetHandleFrame.Height);
  result.width := (GetTrackFrame.Width - GetHandleFrame.Width);
end;

procedure TSlider.DrawHandle(rect: TRect);
begin
  FillRect(rect, RGBA(0, 0, 1, 0.3));
end;

procedure TSlider.DrawTrack(rect: TRect);
begin
  FillRect(rect, RGBA(0, 0, 0, 0.3));
end;

function TSlider.ClosestTickMarkToValue(inValue: TSliderValue): integer;
begin
  result := Ceil(GetValue / interval);
end;

function TSlider.RectOfTickMarkAtIndex(index: integer): TRect;
begin
  result := tickMarkFrames[index];
end;

function TSlider.ValueAtRelativePosition(percent: single): TSliderValue;
begin
  percent := Clamp(percent, 0, 1);
  result := range.ValueOfPercent(percent);//PercentOfRange(range, percent);
  result := interval * Ceil(result / interval);
end;

function TSlider.GetTitleFrame: TRect;
begin
  result := textView.GetBounds;
  result.origin.y -= textView.GetHeight + 2;
end;

procedure TSlider.LayoutSubviews; 
begin

  if textView <> nil then
    begin
      textView.LayoutSubviews;
      textView.SetFrame(GetTitleFrame);
    end;

  inherited;
end;

procedure TSlider.Draw;
var
  percent: float;
  rect: TRect;
  i: integer;
begin
  inherited;

  // track
  DrawTrack(GetTrackFrame);

  // tick marks
  if tickMarks > 1 then
    begin
      if IsVertical then
        begin
        end
      else
        begin
          rect := RectMake(0, 0, GetWidth / tickMarks, GetHeight);
          for i := 0 to tickMarks - 1 do
            begin
              FillRect(rect.Inset(8, 0), RGBA(1,0,0,0.2));
              tickMarkFrames[i] := rect;
              rect.origin.x += rect.width;
            end;
        end;
    end;

  // handle
  percent := GetValue / range.Total;
  if IsVertical then
    begin
      handleFrame := RectMake(0, GetTrackFrame.MinY + (percent * GetTrackSize.height), GetHandleFrame.Width, GetHandleFrame.Height);
      handleFrame := RectCenterX(handleFrame, GetBounds);
      if tickMarks > 1 then
        begin
          handleFrame := RectCenterY(handleFrame, tickMarkFrames[ClosestTickMarkToValue(GetValue)]);
        end
      else
        handleFrame.origin += GetHandleFrame.origin;
    end
  else
    begin
      handleFrame := RectMake(percent * GetTrackSize.width, 0, GetHandleFrame.Width, GetHandleFrame.Height);
      handleFrame := RectCenterY(handleFrame, GetBounds);
      if tickMarks > 1 then
        begin
          handleFrame := RectCenterX(handleFrame, tickMarkFrames[ClosestTickMarkToValue(GetValue)]);
          //handleFrame.origin := tickMarkFrames[ClosestTickMarkToValue(currentValue)].origin;
          //handleFrame.origin += GetHandleFrame.origin;
        end
      else
        handleFrame.origin += GetHandleFrame.origin;
    end;
  DrawHandle(handleFrame);


  // show value label
  // TODO: make this a tooltip window
  if IsDragging and showValueWhileDragging then
    begin
      rect := handleFrame.Inset(-4, 0);
      rect.origin.y -= rect.size.height;
      FillRect(rect, RGBA(244/255,240/255,156/255,0.90));
      DrawText(labelFont, GetStringValue, TTextAlignment.Center, rect, RGBA(0, 1));
    end;
end;

procedure TSlider.HandleValueChanged; 
begin
  inherited;

  InvokeAction;
  NeedsDisplay := true;
end;

procedure TSlider.HandleStateChanged; 
begin
  inherited;

  NeedsDisplay := true;
end;

procedure TSlider.HandleInputStarted(event: TEvent);
var
  where: TPoint;
  oldValue: variant;
begin
  inherited;

  if event.IsAccepted then
    exit;


  //if InputHit(event) then
  //  begin
  //    where := (event.Location(self) - GetTrackFrame.origin);
  //    if IsVertical then
  //      currentValue := ValueAtRelativePosition(where.y / GetTrackSize.height)
  //    else
  //      currentValue := ValueAtRelativePosition(where.x / GetTrackSize.width);
  //    if liveUpdate then
  //      HandleValueChanged;
  //    event.Accept;
  //    dragging :=true;

  //    if handleFrame.ContainsPoint(event.Location(self)) then
  //      dragOrigin := event.Location(self) - handleFrame.origin;
  //  end;
  startValue := m_value;

  if handleFrame.Contains(event.Location(self)) then
    begin
      dragOrigin := event.Location(self) - handleFrame.origin;
      event.Accept;
      dragging := true;
    end
  else if InputHit(event) then
    begin
      where := (event.Location(self) - GetTrackFrame.origin);
      oldValue := m_value;
      if IsVertical then
        m_value := ValueAtRelativePosition(where.y / GetTrackSize.height)
      else
        m_value := ValueAtRelativePosition(where.x / GetTrackSize.width);
      // notify the value changed
      if liveUpdate and (oldValue <> m_value) then
        HandleValueChanged;
      event.Accept;
      dragging := true;
    end;

  //writeln('input started at ', GetValue);
end;

procedure TSlider.HandleInputDragged(event: TEvent);
var
  where: TPoint;
  oldValue: variant;
begin
  inherited HandleInputDragged(event);

  if IsDragging then
    begin
      where := (event.Location(self) - GetTrackFrame.origin) - dragOrigin;
      oldValue := m_value;
      if IsVertical then
        m_value := ValueAtRelativePosition(where.y / GetTrackSize.height)
      else
        m_value := ValueAtRelativePosition(where.x / GetTrackSize.width);
      if liveUpdate and (oldValue <> m_value) then
        HandleValueChanged;
      event.Accept;
    end;
end;

procedure TSlider.HandleInputEnded(event: TEvent);
begin
  inherited HandleInputEnded(event);

  if dragging then
    begin

      // snap to interval
      if interval > 1 then
        SetValue(GetValue);

      //writeln('new value: ', GetValue, ' tick=', ClosestTickMarkToValue(GetValue)+1);
      if not liveUpdate and (m_value <> startValue) then
        HandleValueChanged;

      dragging := false;
    end;
end;

procedure TSlider.Initialize; 
begin
  inherited;

  tickMarks := 0;
  interval := 1;
  liveUpdate := false;
end;

{ SCROLL VIEW }

procedure TScrollView.SetScrollingLimit(newValue: TScalar);
begin
  scrollingLimit := newValue;
end;

procedure TScrollView.SetContentSize(newValue: TVec2);
begin
  contentSize := newValue;
end;

function TScrollView.GetContentView: TView;
begin
  result := contentView;
end;

procedure TScrollView.SetContentView(newValue: TView);
begin
  if contentView <> nil then
    begin
      contentView.RemoveFromParent;
      contentView := nil;
    end;
      
  contentView := newValue;

  if contentView <> nil then    
    begin
      contentViewOrigin := contentView.GetFrame.origin;
      contentView.SetPostsFrameChangedNotifications(true);
      AddSubview(contentView);

      // force a layout of subviews so the scrollview
      // knows the content views real size
      contentView.LayoutSubviews;
    end;
end;

procedure TScrollView.SetHorizontalScroller(newValue: TScroller);
begin
  if horizontalScroller <> nil then
    begin
      horizontalScroller.RemoveFromParent;
      horizontalScroller := nil
    end;
  
  horizontalScroller := newValue;
  
  if horizontalScroller <> nil then
    begin
      horizontalScroller.scrollView := self;
      AddSubview(horizontalScroller);
    end;
end;

procedure TScrollView.SetVerticalScroller(newValue: TScroller);
begin
  if verticalScroller <> nil then
    begin
      verticalScroller.RemoveFromParent;
      verticalScroller := nil;
    end;
  
  verticalScroller := newValue;

  if verticalScroller <> nil then
    begin
      verticalScroller.scrollView := self;
      AddSubview(verticalScroller);
    end;  
end;

function TScrollView.GetVerticalScroller: TScroller;
begin
  result := verticalScroller;
end;

function TScrollView.GetHorizontalScroller: TScroller;
begin
  result := horizontalScroller;
end;

function TScrollView.IsVerticalScrollerVisible: boolean;
begin
  result := assigned(verticalScroller) and not verticalScroller.IsHidden;
end;

function TScrollView.IsHorizontalScrollerVisible: boolean;
begin
  result := assigned(horizontalScroller) and not horizontalScroller.IsHidden;
end;

function TScrollView.GetVisibleRect: TRect;
begin
  result := RectMake(scrollOrigin.x, scrollOrigin.y, contentSize.width - GetWidth, contentSize.height - GetHeight);
end;

function TScrollView.GetHorizontalScrollerFrame: TRect;
var
  rect: TRect;
begin
  rect.size.width := GetWidth;
  if IsVerticalScrollerVisible then
    rect.size.x -= verticalScroller.GetHandleFrame.Width;
  rect.size.height := horizontalScroller.GetHandleFrame.Height;
  rect.origin.x := 0;
  rect.origin.y := GetBounds.MaxY - rect.Height;
  rect := RectMake(rect.origin + horizontalScrollerOffset, rect.size);
  result := rect;
end;

function TScrollView.GetVerticalScrollerFrame: TRect;
var
  rect: TRect;
begin
  rect.size.width := verticalScroller.GetHandleFrame.Width;
  rect.size.height := GetHeight;
  if IsHorizontalScrollerVisible then
    rect.size.y -= verticalScroller.GetHandleFrame.Width;
  rect.origin.x := GetBounds.MaxX - rect.Width;
  rect.origin.y := 0;
  rect := RectMake(rect.origin + verticalScrollerOffset, rect.size);
  result := rect;
end;

procedure TScrollView.LayoutSubviews;
var
  newFrame: TRect;
  tableView: TTableView;
  delegate: IScrollingContent;
begin
  
  if assigned(verticalScroller) then
    verticalScroller.SetFrame(GetVerticalScrollerFrame);

  if assigned(horizontalScroller) then
    horizontalScroller.SetFrame(GetHorizontalScrollerFrame);
      
  // adjust content view to fit scrollable area
  if contentView <> nil then
    begin
      UpdateContentSize;
        
      newFrame := contentView.GetFrame;
      // TODO: why isn't this LayoutSubviews?

      tableView := TTableView(contentView);
      if tableView.IsMember(TTableView) and 
         tableView.lastColumnTracksWidth then
          begin
            // todo: resize the actual column widths also
            newFrame.size.width := GetClipRect.Width;
            contentView.SetFrame(newFrame);
            tableView.SizeLastColumnToFit;
          end
        else
          begin
            contentView.SetFrame(newFrame);
          end;

      if Supports(contentView, IScrollingContent, delegate) then
        delegate.HandleScrollingContentChanged(self);
    end;

  // hide the scroller if the visible rect is fully visible
  if verticalScroller <> nil then
    verticalScroller.SetHidden(GetVisibleRect.size.height <= 0);

  if horizontalScroller <> nil then
    horizontalScroller.SetHidden(GetVisibleRect.size.width <= 0);
end;

const
  kIntialAcceleration = 0.25;
  kFriction = 0.01;

procedure TScrollView.Update;
begin
  inherited Update;

  // apply scrolling intertia
  if enableScrollingInertia and(scrollVelocity <> V2(0, 0)) then
    begin
      Scroll(scrollVelocity);
      if scrollVelocity.y < 0 then
        begin
          scrollVelocity.y += scrollAcceleration;
          if scrollVelocity.y > 0 then
            scrollVelocity.y := 0;
          scrollAcceleration -= kFriction;
          if scrollAcceleration < 0 then
            begin
              scrollAcceleration := 0;
              scrollVelocity.y := 0;
            end;
        end
      else if scrollVelocity.y > 0 then
        begin
          scrollVelocity.y -= scrollAcceleration;
          if scrollVelocity.y < 0 then
            scrollVelocity.y := 0;
          scrollAcceleration -= kFriction;
          if scrollAcceleration < 0 then
            begin
              scrollAcceleration := 0;
              scrollVelocity.y := 0;
            end;
        end;
    end;
end;

procedure TScrollView.Draw;
var
  child: TView;
begin
  FillRect(GetBounds, RGBA(0,0,0,0.1));

  if assigned(subviews) then
    for child in subviews do
      if child = contentView then
        begin
          if enableContentClipping then
            PushClipRect(GetClipRect);
          child.DrawInternal(renderOrigin);
          if enableContentClipping then
            PopClipRect;
        end
      else
        child.DrawInternal(renderOrigin);
end;

function TScrollView.InsertRectForScrollers(rect: TRect): TRect;
begin
  if IsVerticalScrollerVisible then
    rect.size.x -= verticalScroller.GetWidth;

  if IsHorizontalScrollerVisible then
    rect.size.y -= horizontalScroller.GetHeight;

  result := rect;
end;

function TScrollView.GetClipRect: TRect; 
begin
  result := InsertRectForScrollers(GetBounds);
end;

function TScrollView.GetScrollableFrame: TRect; 
var
  size: TVec2;
begin
  size := GetBounds.size - contentSize;
  result := RectMake(0, 0, size.width, size.height);
  result := InsertRectForScrollers(result);
end;

procedure TScrollView.Scroll(direction: TPoint);
var
  amount,
  newOrigin: TVec2;
begin
  // TODO: horizontal scrolling is available yet

  // content is smaller than view height
  if contentSize.height < GetHeight then
    begin
      scrollOrigin.y := 0;
      exit;
    end;
  
  if scrollingLimit > 0 then
    begin
      if (direction.y < 0) and (direction.y > -scrollingLimit) then
        amount.y := -scrollingLimit;

      if (direction.y > 0) and (direction.y < scrollingLimit) then
        amount.y := scrollingLimit;
    end
  else
    amount := direction;
    
  newOrigin := scrollOrigin;
  newOrigin.y += Trunc(amount.y);

  // top limit
  if newOrigin.y > GetScrollableFrame.MinY then
    newOrigin.y := GetScrollableFrame.MinY;
  
  // bottom limit
  if newOrigin.y < GetScrollableFrame.MaxY then
    newOrigin.y := GetScrollableFrame.MaxY;

  SetScrollOrigin(newOrigin, false, true);
end;

procedure TScrollView.SetScrollOrigin(where: TPoint; axisX, axisY: boolean);
var
  delegate: IScrollingContent;
  rect: TRect;
begin
  //scrollOrigin := where;
  if axisX then
    scrollOrigin.x := where.x;
  if axisY then
    scrollOrigin.y := where.y;

  // scroll content view
  if contentView <> nil then
    begin
      rect := contentView.GetFrame;
      rect.origin := contentViewOrigin + scrollOrigin;
      contentView.SetFrame(rect);
    end;
  
  // update scrollers
  if assigned(verticalScroller) and axisY then
    verticalScroller.SetValue(verticalScroller.range.ValueOfPercent(scrollOrigin.y / GetScrollableFrame.Height));
  
  if assigned(horizontalScroller) and axisX then
    horizontalScroller.SetValue(horizontalScroller.range.ValueOfPercent(scrollOrigin.x / GetScrollableFrame.Width));

  if Supports(contentView, IScrollingContent, delegate) then
    delegate.HandleScrollingContentChanged(self);
end;

procedure TScrollView.HandleInputStarted(event: TEvent);
begin
  inherited HandleInputStarted(event);

  if InputHit(event) and enableDragScrolling then
    begin
      dragScrollingDown := event.Location(self);
      dragScrollingOrigin := scrollOrigin;
      // TODO: we need to make an option for this for touch only
      dragScrolling := false;
      event.Accept(self);
    end;
end;

procedure TScrollView.HandleInputEnded(event: TEvent);
begin
  inherited HandleInputEnded(event);
  
  if swipeTimer <> nil then
    begin
      writeln('swipe');
      //swipeTimer.Invalidate;
      //swipeTimer := nil;
    end;
    
  dragScrolling := false;
end;

procedure TScrollView.ScrollUp(var msg);
begin
  Scroll(V2(0, scrollButtonAmount));
end;

procedure TScrollView.ScrollDown(var msg);
begin
  Scroll(V2(0, -scrollButtonAmount));
end;

procedure TScrollView.HandleSwipeTimer(timer: TTimer);
begin
  swipeTimer := nil;
end;

procedure TScrollView.HandleInputDragged(event: TEvent);
var
  where: TPoint;
  vertical: boolean = true;
  percent: TScalar;
begin
  inherited HandleInputDragged(event);

  if dragScrolling and InputHit(event) then
    begin
      where := event.Location(self);
      
      //if swipeTimer = nil then
      //  swipeTimer := InvokeMethodAfterDelay(0.25, @TScrollView.HandleSwipeTimer);
      
      if vertical then
        begin
          percent := (dragScrollingDown.y - where.y) / GetHeight;
          //writeln('% ', percent:1:1);
          scrollOrigin.y := trunc(dragScrollingOrigin.y - GetHeight * percent);
          
          // top limit
          if scrollOrigin.y > 0 then
            scrollOrigin.y := 0;

          // bottom limit
          if scrollOrigin.y < GetHeight - contentSize.height then
            scrollOrigin.y := trunc(GetHeight - contentSize.height);
          
          //writeln('scroll to ', tstr(scrollOrigin));
        end
      else
        begin
        end;

      event.Accept(self);
    end;
end;

procedure TScrollView.HandleMouseWheelScroll(event: TEvent);
begin
  if InputHit(event) then
    begin

      // content is smaller than view height
      if contentSize.height < GetHeight then
        begin
          scrollOrigin.y := 0;
          exit;
        end;
      
      // swipe with velocity
      if (Abs(event.ScrollWheel.y) > 14) or (Abs(event.ScrollWheel.x) > 14) then
        begin
          scrollVelocity := event.ScrollWheel;
          scrollAcceleration := kIntialAcceleration;
          Scroll(scrollVelocity); 
        end
      else
        begin
          scrollVelocity := V2(0, 0);
          scrollAcceleration := 0;
          Scroll(event.ScrollWheel);  
        end;

      event.Accept(self);
    end;
end;

procedure TScrollView.UpdateContentSize;
begin
  // TODO: this is a hack, no? maybe we need an interface
  // to call
  if contentView.IsMember(TTextView) then
    begin
      TTextView(contentView).SetMaximumWidth(Trunc(GetWidth));
      TTextView(contentView).SetWidthTracksContainer(true);
      SetContentSize(contentView.GetSize);
    end
  else
    SetContentSize(contentView.GetSize);
end;

procedure TScrollView.HandleContentViewFrameChanged(notification: TNotification);
begin
  if notification.GetObject = pointer(contentView) then
    UpdateContentSize;
end;

destructor TScrollView.Destroy;
begin
  TNotificationCenter.DefaultCenter.RemoveEveryObserver(self);
  
  inherited;
end;

procedure TScrollView.Initialize;
begin
  inherited Initialize;
  
  scrollingLimit := 0;
  scrollButtonAmount := 20;
  enableContentClipping := true;

  ObserveNotification(kNotificationFrameChanged, @self.HandleContentViewFrameChanged);
end;

{ CELL VIEW }

procedure TCellView.SetDelegate(newValue: TObject);
begin
  _delegate := newValue;
end;

function TCellView.GetDelegate: TObject;
begin
  result := _delegate;
end;

procedure TCellView.SetSelectionType(newValue: TTableViewSelection);
begin
  selectionType := newValue;
  if selectionType = TTableViewSelection.None then
    ClearSelection;
end;

procedure TCellView.SetEnableDragSelection(newValue: boolean);
begin
  enableDragSelection := newValue;
end;

function TCellView.GetSelection: TRowList;
begin
  result := selection;
end;

procedure TCellView.RemoveSelection(cell: TCell);
var
  delegate: ICellViewDelegate;
begin
  if selection.IndexOf(cell.rowIndex) <> -1 then
    begin
      cell.selectionState -= [TCellState.Selected];
      selection.Remove(cell.rowIndex);
      if Supports(GetDelegate, ICellViewDelegate, delegate) then
        delegate.HandleSelectionChanged(self);
    end;
end;

function TCellView.FindCellWithObjectValue(obj: pointer): TCell;
var
  cell: TCell;
begin
  result := nil;
  for cell in cells do
    if cell.GetObjectValue = obj then
      exit(cell);
end;

procedure TCellView.SelectCell(cell: TCell; extendSelection: boolean = false; notifyDelegate: boolean = true);
var
  delegate: ICellViewDelegate;
begin
  if not cell.IsSelectable or(selectionType = TTableViewSelection.None) then
    exit;
    
  if not extendSelection then
    ClearSelection(false);
    
  if selection.IndexOf(cell.rowIndex) = -1 then 
    selection.Add(cell.rowIndex);
  cell.selectionState += [TCellState.Selected];

  if notifyDelegate and Supports(GetDelegate, ICellViewDelegate, delegate) then
    delegate.HandleSelectionChanged(self);
end;

procedure TCellView.SelectionChanged; 
var
  delegate: ICellViewDelegate;
begin
  if Supports(GetDelegate, ICellViewDelegate, delegate) then
    delegate.HandleSelectionChanged(self);
end;

procedure TCellView.ClearSelection(notifyDelegate: boolean = true);
var
  delegate: ICellViewDelegate;
  cell: TCell;
begin
  if selection.Count > 0 then
    begin
      for cell in cells do
        cell.selectionState -= [TCellState.Selected];
      selection.Clear;
      if notifyDelegate and Supports(GetDelegate, ICellViewDelegate, delegate) then
        delegate.HandleSelectionChanged(self);
    end;
end;

procedure TCellView.HandleInputDragged(event: TEvent);

  function FindCellForEvent(event: TEvent): TCell;
  var
    cell: TCell;
    delegate: ICellViewDelegate;
  begin
    result := nil;
    for cell in cells do
      if cell.InputHit(event) then
        begin
          if Supports(GetDelegate, ICellViewDelegate, delegate) then
            if not delegate.HandleShouldSelectCell(self, cell) then
              continue;
          exit(cell);
        end;
  end;

  function CellForRow(row: integer): TCell;
  var
    cell: TCell;
  begin
    result := nil;
    for cell in cells do
      if cell.rowIndex = row then
        exit(cell);
  end;

var
  cell: TCell;
  i: integer;
begin

  if not enableDragSelection then
    begin
      inherited HandleInputDragged(event);
      exit;
    end;
    
  if tracking then
    event.Accept(self);
    
  if InputHit(event) and tracking then
    begin
      cell := FindCellForEvent(event);
      if assigned(cell) then
        begin
          if not(ssSuper in event.MouseModifiers) then
            ClearSelection(false);
          if pivotRow < cell.rowIndex then
            begin
              for i := pivotRow to cell.rowIndex do
                SelectCell(CellForRow(i), true);
            end
          else
            begin
              for i := cell.rowIndex to pivotRow do
                SelectCell(CellForRow(i), true);
            end;
        end;
    end;
end;

procedure TCellView.HandleInputEnded(event: TEvent);
begin
  tracking := false;
  inherited HandleInputEnded(event);
end;

procedure TCellView.HandleInputStarted(event: TEvent);
var
  cell: TCell;
  select: boolean;
  delegate: ICellViewDelegate;
  child: TView;
begin 
  if InputHit(event) then
    begin

      // no cells to hit, bail
      if cells = nil then
        exit;
        
      select := false;

      for cell in cells do
        if cell.InputHit(event) then
          begin

            // ask delegate
            if Supports(GetDelegate, ICellViewDelegate, delegate) then
              if not delegate.HandleShouldSelectCell(self, cell) then
                begin
                  // the cell could not be selected but still handle the event
                  cell.HandleInputStarted(event);
                  if event.IsAccepted then
                    break
                  else
                    continue;
                end;
                        
            // handle mouse down for cell children first
            for child in subviews do
              begin
                child.HandleInputStarted(event);
                if event.IsAccepted then
                  exit;
              end;
            
            // if the event was not accepted process the cell
            select := selectionType <> TTableViewSelection.None;

            if select then
              SelectCell(cell, (selectionType = TTableViewSelection.Multiple) and (ssSuper in event.MouseModifiers));
            
            tracking := (selectionType = TTableViewSelection.Multiple);
            event.Accept(self);
            if CanAcceptFocus then
              GiveFocus;

            pivotRow := cell.rowIndex;
            exit;
          end;
      
      tracking := (selectionType = TTableViewSelection.Multiple);
    end
  else
    inherited HandleInputStarted(event);
end;

procedure TCellView.AddCells(newValue: TCellList);
var
  cell: TCell;
begin
  if cells = nil then
    cells := newValue
  else
    begin
      for cell in newValue do
        cells.Add(cell);
    end;
  
  ArrangeCells;
end;

procedure TCellView.RemoveCells(newValue: TCellList);
var
  cell: TCell;
begin
  if cells <> nil then
    begin
  
      // remove cells from table view
      for cell in newValue do
        cell.RemoveFromParent;
      
      for cell in newValue do
        cells.Remove(cell);

      ArrangeCells;
    end;
end;

procedure TCellView.RemoveAllCells;
var
  cell: TView;  
begin
  for cell in cells do
    cell.RemoveFromParent;
  cells.Clear;
  ArrangeCells;
end;

procedure TCellView.SetCells(newValue: TCellList);
var
  cell: TCell;
begin
  ClearSelection;
  // remove old cells from parent
  for cell in cells do
    cell.RemoveFromParent;
  cells := newValue;
  // make sure new cells have no parent
  for cell in cells do
    cell.RemoveFromParent;
  ArrangeCells;
end;

procedure TCellView.AddCell(cell: TCell);
begin
  cells.Add(cell);
end;

function TCellView.GetCells: TCellList;
begin
  result := cells;
end;

procedure TCellView.ArrangeCells; 
begin
end;

procedure TCellView.Initialize;
begin
  inherited;
  cells := TCellList.Create;
  selection := TRowList.Create;
  SetSelectionType(TTableViewSelection.Single);
  SetCanAcceptFocus(true);
end;

destructor TCellView.Destroy;
begin   
  cells.Free;
  _delegate := nil;
  inherited;
end;

{ TABLE VIEW }

class operator TTableColumn.= (left: TTableColumn; right: TTableColumn): boolean;
begin
  result := left.id = right.id;
end;

procedure TTableView.SetLastColumnTracksWidth(newValue: boolean);
begin
  lastColumnTracksWidth := newValue;
end;

procedure TTableView.SetDataSource(newValue: TObject; cellDelegate: boolean);
begin
  m_dataSource := newValue;
  m_cellDelegate := cellDelegate;
end;

procedure TTableView.SetCellHeight(newValue: integer);
begin
  cellHeight := newValue;
  cellsNeedArranging := true;
end;

procedure TTableView.SetCellSpacing(newValue: integer);
begin
  cellSpacing := newValue;
  cellsNeedArranging := true;
end;

procedure TTableView.SetCellFont(newValue: IFont);
begin
  cellFont := newValue;
  cellsNeedArranging := true;
end;

procedure TTableView.SetCellClass(newValue: TCellClass);
begin
  cellClass := newValue;
end;

function TTableView.GetCellHeight: integer;
begin
  result := cellHeight;
end;

function TTableView.GetCellSpacing: integer;
begin
  result := cellSpacing;
end;

function TTableView.GetVisibleRange: TRangeInt;
var
  scrollView: TScrollView;
begin
  scrollView := EnclosingScrollView;
  if assigned(scrollView) then
    begin
      result.min := trunc(abs(scrollView.GetVisibleRect.minY) / (cellHeight + cellSpacing));
      result.max := RoundUp(scrollView.GetClipRect.Height / (cellHeight + cellSpacing)) + 1;
    end
  else
    begin
      result.min := 0;
      result.max := RoundUp(GetHeight / (cellHeight + cellSpacing)) + 1;
    end;
end;

function TTableView.ColumnAtIndex(index: integer): PTableColumn;
begin
  result := PTableColumn(TFPSList(columns)[index]);
end;

procedure TTableView.InsertCells(newValue: TCellList; index: integer);
var
  cell: TCell;
begin
  ClearSelection;
  
  // remove cells from table view
  if cells <> nil then
    for cell in cells do
      cell.RemoveFromParent;
  
  if cells = nil then
    cells := TCellList.Create;
    
  for cell in newValue do
    cells.Insert(index, cell);
    
  Reload;
end;

function TTableView.GetCell(index: integer): TCell;
begin
  result := cells[index];
end;

procedure TTableView.SizeLastColumnToFit;
var
  cell, 
  child: TCell;
  column, totalWidth: integer;
  newFrame: TRect;
begin
  writeln('SizeLastColumnToFit ', columns.count, ' ', GetFrame.tostr);
  for cell in cells do
    begin
      column := 0;
      totalWidth := 0; 
      child := cell;
      while assigned(child) do
        begin
          // TODO: resize to GetWidth
          //writeln(column, ': ', columns[column].width);
          newFrame := child.GetFrame;
          newFrame.size.width := GetWidth;

          if columns.Count > 0 then
            begin
              if column = columns.Count - 1 then
                ColumnAtIndex(column)^.width := trunc(GetWidth - totalWidth);
              totalWidth += columns[column].width + cellSpacing;
            end;

          // TODO: we don't need to do this since we're going to arrange cells
          // but we do about tables with no columns?? i think dataSource
          // based tables always need to have one table for this reason

          child.SetFrame(newFrame);
          child := child.next;
          column += 1;
        end;
    end;
  ArrangeCells;
end;

function TTableView.HeightForCell(cell: TCell): integer;
begin
  result := cellHeight;
end;

procedure TTableView.Reload;
begin
  cellsNeedArranging := true;
  ArrangeCells;
end;

procedure TTableView.ReloadCellsFromDataSource(dataSource: ITableViewDataSource; firstRow, maxRows: integer);
var
  rowCount,
  totalRows: integer;
  value: pointer;
  cell,
  child: TCell;
  i, 
  column: integer;
  rect: TRect;
begin
  totalRows := dataSource.TableViewNumberOfRows(self);
  rowCount := Min(totalRows, maxRows);
  //writeln('reload ', firstRow,' to ', rowCount, ' total=',totalRows, ' cells=', cells.Count);

  if rowCount <> cells.Count then
    begin

      // add default column if user didn't add one yet
      if columns.Count = 0 then
        AddColumn(0, '');

      // free old cells
      for cell in cells do
        cell.RemoveFromParent;
      cells.Free;

      cells := TCellList.Create;
      for i := 0 to rowCount - 1 do
        begin
          cell := nil;
          for column := 0 to columns.Count - 1 do
            begin
              if cell = nil then 
                begin
                  cell := cellClass.Create;
                  child := cell;
                end
              else
                begin
                  child.next := cellClass.Create;
                  child := child.next;
                end;
              AddSubview(child);
            end;
          cells.Add(cell);
        end;

      writeln('allocated new cells -> ', cells.Count);

      // resize table view to fit
      rect := GetFrame;
      rect.size.height := ((cellHeight + cellSpacing) * totalRows) - cellSpacing;
      SetFrame(rect);
    end;

  for i := 0 to cells.Count - 1 do
    if firstRow + i < totalRows then
      begin
        column := 0;
        // TODO: if the cell didn't go in/out of view then we don't need to update object value
        // TODO: we also need to know if cells go in out of view so we can disable clipping on them
        child := cells[i];
        while assigned(child) do
          begin
            value := dataSource.TableViewValueForRow(self, columns[column], firstRow + i);

            child.rowIndex := firstRow + i;
            if selection.IndexOf(child.rowIndex) > -1 then
              child.selectionState += [TCellState.Selected]
            else
              child.selectionState -= [TCellState.Selected];

            child.SetFont(cellFont);

            // if the tableview uses cell delegates then call the delegate on the object
            if m_cellDelegate then
              ITableViewCellDelegate(value).TableViewPrepareCell(self, columns[column], child)
            else
              child.SetObjectValue(value);

            child := child.next;
            column += 1;
          end;
      end;
end;

procedure TTableView.ArrangeCells;
var
  rect,
  cellFrame: TRect;
  cell, child: TCell;
  i: integer;
  dataSource: ITableViewDataSource;
  range: TRangeInt;
  column: integer;
begin
  if arrangingCells then
    exit;

  arrangingCells := true;

  range := VisibleRange;

  // load cells from data source
  if Supports(m_dataSource, ITableViewDataSource, dataSource) then
    begin
      ReloadCellsFromDataSource(dataSource, range.Min, range.Max);

      cellFrame := RectMake(0, range.Min * (cellHeight + cellSpacing), GetWidth, 0);

      for i := 0 to cells.Count - 1 do
        begin
          cell := cells[i];
          child := cell;
          column := 0;
          while assigned(child) do
            begin
              cellFrame.size.height := HeightForCell(child);
              cellFrame.size.width := columns[column].width;
              child.SetFrame(cellFrame);

              cellFrame.origin.x += cellFrame.size.width + cellSpacing;
              child := child.next;
              column += 1;
            end;
          cellFrame.origin.y += cellFrame.size.height + cellSpacing;
          cellFrame.origin.x := 0;
        end;
    end
  else if assigned(cells) and cellsNeedArranging then
    begin
      totalHeight := 0;
      cellFrame := RectMake(0, 0, GetWidth, 0);
      for i := 0 to cells.Count - 1 do
        begin
          cell := cells[i];

          cell.rowIndex := i;
          cell.SetHidden(false);

          if cell.GetParent = nil then
            AddSubview(cell);
          
          cellFrame.size.height := cellHeight;
          cell.SetFrame(cellFrame);

          cellFrame.origin.y += cellFrame.size.height + cellSpacing;
          totalHeight += cellFrame.size.height + cellSpacing;
        end;
      
      // remove last space
      totalHeight -= cellSpacing;
      
      // resize table view to fit cells
      rect := GetFrame;
      rect.size.height := totalHeight;
      SetFrame(rect);
    end;

  arrangingCells := false;
  cellsNeedArranging := false;
end;

function TTableView.ShouldDrawSubview(view: TView): boolean;
var
  scrollView: TScrollView;
  rect: TRect;
begin
  // if the table view is enclosed in a scroll view
  // then we can test if the cells are not clipped
  scrollView := EnclosingScrollView;
  if assigned(scrollView) then
    begin
      rect := view.ConvertRectTo(view.GetBounds, scrollView);
      result := scrollView.GetBounds.Intersects(rect);
    end;
end;

procedure TTableView.HandleDrawSelection(rect: TRect);
begin
  FillRect(rect, RGBA(0,0,0,0.2));
end;

procedure TTableView.Draw;
var
  cell, child: TCell;
  rect: TRect;
begin
  //FillRect(GetBounds, RGBA(0,0.6,0,0.2));

  for cell in cells do
    if TCellState.Selected in cell.selectionState then
      begin
        child := cell;
        rect := child.GetFrame;
        while assigned(child) do
          begin
            child := child.next;
            if assigned(child) then
              rect := rect.Union(child.GetFrame);
          end;
        HandleDrawSelection(rect);
      end;
  
  inherited;
end;

procedure TTableView.HandleKeyDown(event: TEvent);
var
  index: integer;
begin
  case event.KeyCode of
    KEY_UP:
      begin
        {
          TODO: this fails because rowIndex is not global to the data source
        }
        if selection.Count > 0 then
          index := cells[selection[0]].rowIndex - 1
        else
          index := 0;
        if index < 0 then
          index := 0;
        SelectCell(cells[index]);
        if not VisibleRange.Contains(index) then
          ScrollUp;
        event.Accept(self);
      end;
    KEY_DOWN:
      begin
        if selection.Count > 0 then
          index := cells[selection[0]].rowIndex + 1
        else
          index := 0;
        if index > cells.Count - 1 then
          index := cells.Count - 1;
        SelectCell(cells[index]);
        if not VisibleRange.Contains(index) then
          ScrollDown;
        event.Accept(self);
      end;
  end;
end;

procedure TTableView.HandleFrameDidChange(previousFrame: TRect);
begin
  inherited HandleFrameDidChange(previousFrame);
  
  ArrangeCells;
end;

procedure TTableView.HandleDidAddToParent(sprite: TView);
begin
  inherited HandleDidAddToParent(sprite);
  
  ArrangeCells;
end;

procedure TTableView.ScrollUp;
var
  scrollView: TScrollView;
begin
  writeln('ScrollUp');
  scrollView := EnclosingScrollView;
  if scrollView <> nil then
    scrollView.Scroll(V2(0, cellHeight));
end;

procedure TTableView.ScrollDown;
var
  scrollView: TScrollView;
begin
  scrollView := EnclosingScrollView;
  if scrollView <> nil then
    scrollView.Scroll(V2(0, -cellHeight));
end;

function TTableView.GetColumns: TTableColumnList;
begin
  if m_columns = nil then
    m_columns := TTableColumnList.Create;
  result := m_columns;
end;

procedure TTableView.AddColumn(column: TTableColumn);
begin
  columns.Add(column);
  Reload;
end;

procedure TTableView.AddColumn(id: integer; title: string);
var
  column: TTableColumn;
begin
  column.id := id;
  column.title := title;
  column.width := 100;
  AddColumn(column);
end;

procedure TTableView.Initialize;
begin
  inherited Initialize;
    
  SetCellHeight(18);
  SetCellSpacing(0);

  cellsNeedArranging := true;
end;

destructor TTableView.Destroy;
begin 
  m_dataSource := nil;
  m_columns.Free;

  inherited;
end;

{ TImageAndTextCellDataSource }

function TImageAndTextCellDataSource.TableViewValueForRow(tableView: TTableView; column: TTableColumn; row: integer): pointer;
begin
  result := data[row];
end;

function TImageAndTextCellDataSource.TableViewNumberOfRows(tableView: TTableView): integer;
begin
  result := data.Count;
end;

procedure TImageAndTextCellDataSource.Add(item: ITableViewCellDelegate);
begin
  data.Add(item);
end;

destructor TImageAndTextCellDataSource.Destroy;
var
  item: ITableViewCellDelegate;
begin
  for item in data do
    TObject(item).Free;
  data.Free;
  inherited;
end;

constructor TImageAndTextCellDataSource.Create;
begin
  data := TDataList.Create;
end;

{ TEXT VIEW }

constructor TTextView.Create(inFrame: TRect; text: string; inWidthTracksContainer: boolean = true; inFont: IFont = nil);
begin
  Initialize;
  SetFrame(inFrame);
  SetText(text);
  SetFont(inFont);
  SetWidthTracksContainer(inWidthTracksContainer);
end;

procedure TTextView.SetText(newValue: TTextViewString);
begin
  // TODO: update cursor!
  m_text := newValue;
  MoveCursor(Length(text));
  TextLayoutChanged;
end;

procedure TTextView.SetFont(newValue: IFont);
begin
  textFont := newValue;
  if assigned(textFont) and (textColor.a = 0) then
    SetTextColor(textFont.PreferredTextColor);
  TextLayoutChanged;
end;

procedure TTextView.ToggleOption(newValue: boolean; option: TTextViewOption);
begin
  if newValue then
    Include(options, option)
  else
    Exclude(options, option);
end;

{ The height of the view tracks the height of the container }
procedure TTextView.SetHeightTracksContainer(newValue: boolean);
begin
  ToggleOption(newValue, TTextViewOption.HeightTracksContainer);
end;

{ The width of the view tracks the width of the container i.e.,
  view resizes by width of text and constrained by maximumWidth. }
procedure TTextView.SetWidthTracksContainer(newValue: boolean);
begin
  ToggleOption(newValue, TTextViewOption.WidthTracksContainer);
  ToggleOption(false, TTextViewOption.WidthTracksView);
  NeedsLayoutSubviews;
end;

{ The width of the container tracks the width of the view (text wraps to container) }
procedure TTextView.SetWidthTracksView(newValue: boolean);
begin
  ToggleOption(newValue, TTextViewOption.WidthTracksView);
  ToggleOption(false, TTextViewOption.WidthTracksContainer);
  NeedsLayoutSubviews;
end;

procedure TTextView.SetTextAlignment(newValue: TTextAlignment);
begin
  textAlignment := newValue;
end;

procedure TTextView.SetEditable(newValue: boolean);
begin
  //editable := newValue;
  ToggleOption(newValue, TTextViewOption.Editable);
  canAcceptFocus := newValue;
end;

procedure TTextView.SetTextColor(newValue: TColor);
begin
  textColor := newValue;
end;

procedure TTextView.SetMaximumWidth(newValue: integer);
begin
  maximumWidth := newValue;
  NeedsLayoutSubviews;
end;

function TTextView.IsEditable: boolean;
begin
  result := TTextViewOption.Editable in options;
end;

function TTextView.IsSelectable: boolean;
begin
  // TODO: for now selectable is editable
  result := IsEditable;
end;

function TTextView.GetTextSize: TVec2;
var
  layout: TTextLayoutOptions;
begin
  // TODO: cache this result, only update if text changes
  Assert(IsReadyToLayout, 'text view must set font');

  if IsEditable then
    begin
      layout := TextLayout;
      layout.draw := false;
      LayoutText(layout);
      result := layout.textSize;
    end
  else
    result := MeasureText(textFont, Text, maximumWidth);
end;

function TTextView.GetFont: IFont;
begin
  result := textFont;
end;

function TTextView.HandleWillInsertText(var newText: TTextViewString): boolean;
begin
  result := true;
end;

{ Called before any text deletion event }
function TTextView.HandleWillDelete: boolean;
begin
  result := true;
end;

{ Moves the cursor to a single location and reverts the selection }
procedure TTextView.MoveCursor(location: TTextOffset; grow: boolean); 
var
  oldLocation: TTextOffset;
begin
  location := Clamp(location, 0, Length(text));

  if grow then
    begin

      // grow left
      if location < cursor.location then
        begin
          oldLocation := cursor.location;
          cursor.location := location;
          cursor.length += abs(cursor.location - oldLocation);
          cursor.insertion := location;
        end
      else // grow right
        begin
          cursor.length := abs(cursor.location - location);
          cursor.insertion := location;
        end;
    end
  else
    begin
      cursor.insertion := location;
      cursor.location := location;
      cursor.length := 0;
    end;

  cursor.location := Clamp(cursor.location, 0, Length(text));
  cursor.length := Clamp(cursor.length, 0, Length(text));
end;

procedure TTextView.SelectRange(location, length: TTextOffset);
begin
  cursor.location := location;
  cursor.length := length;
  cursor.insertion := cursor.location + cursor.length;
  cursor.location := Clamp(cursor.location, 0, System.Length(text));
  cursor.length := Clamp(cursor.length, 0, System.Length(text));
end;

procedure TTextView.InsertText(newText: TTextViewString);
begin
  InsertText(cursor.location + 1, cursor.length, newText)
end;

procedure TTextView.InsertText(location, length: TTextOffset; newText: TTextViewString);
begin
  if HandleWillInsertText(newText) then
    begin
      if length > 0 then
        Delete(m_text, location, length);
      Insert(newText, m_text, location);
      MoveCursor(location + (System.Length(newText) - 1));
      TextLayoutChanged;
    end;
end;

procedure TTextView.DeleteText(location, length: TTextOffset);
begin
  Delete(m_text, location, length);
  TextLayoutChanged;
end;

procedure TTextView.TextLayoutChanged;
begin
  dirty := true;
  NeedsLayoutSubviews;
end;


{$macro on}
{$define TCharSetLineEnding:=#10, #12, #13}
{$define TCharSetWhiteSpace:=#32, #9, TCharSetLineEnding}
{$define TCharSetWord:='a'..'z','A'..'Z','_'}
{$define TCharSetInteger:='0'..'9'}

function AdvanceNextWord(text: UnicodeString; location: LongWord): LongWord;
var
  offset: LongWord;
begin
  offset := location + 1;

  while offset < Length(text) do
    begin
      if text[offset] in [TCharSetWhiteSpace] then
        inc(offset)
      else
        break
    end;

  location := offset;

  for offset := location to High(text) do
    case text[offset] of
      TCharSetWord, TCharSetInteger:
        continue;
      otherwise
        exit(offset - 1);
    end;
  result := High(text);
end;

function AdvancePreviousWord(text: UnicodeString; location: LongWord): LongWord;
var
  offset: LongInt;
begin
  offset := location;

  while offset >= 0 do
    begin
      if text[offset] in [TCharSetWhiteSpace] then
        dec(offset)
      else
        break
    end;

  location := offset;

  for offset := location downto 0 do
    case text[offset] of
      TCharSetWord, TCharSetInteger:
        continue;
      otherwise
        exit(offset);
    end;
  result := 0;
end;

function AdvanceLineStart(text: UnicodeString; location: LongWord): LongWord;
var
  offset: LongWord;
begin
  for offset := location downto 0 do
    case text[offset] of
      TCharSetLineEnding:
        exit(offset);
    end;
  result := 0;
end;

class operator TLineLayout.= (left: TLineLayout; right: TLineLayout): boolean;
begin
  result := left.offset = right.offset;
end;

procedure TLayoutManager.SetText(const newText: ansistring);
var
  i,
  offset, rows, columns: integer;
  line: TLineLayout;
begin
  offset := 0;
  rows := 0;
  columns := 0;
  lines.Clear;

  text := newText;//Copy(newText, 0, length);

  for i := 0 to Length(newText) - 1 do
    begin
      {
        wrap to column/word or line ending
      }
      if newText[i] in [LineEnding] then
        begin
          //writeln(rows,'x',offset,':',columns,': ', Copy(newText, offset, columns));

          line.line := rows;
          line.offset := offset;
          line.columns := columns;
          if lines.Count > 0 then
            line.prev := TFPSList(lines).Last
          else
            line.prev := nil;

          if line.prev <> nil then
            line.prev.next := @self;

          lines.Add(line);

          inc(rows);
          columns :=0;
          offset := i;
          continue;
        end;
      inc(columns);
    end;
end;

procedure TLayoutManager.DrawLine(origin: TVec2; line: TLineLayout);
var
  offset: integer;
  c: char;
  renderFrame: TFontRenderFrame;
  newOrigin: TVec2;
  charFrame: TRect;
begin
  //writeln(line.line,':',line.offset);
  for offset := line.offset to (line.offset + line.columns) - 1 do
    begin
      c := text[offset + 1];

      if not font.HasGlyph(c) then
        begin
          /// TODO: SpaceWidth is character width for monospace fonts
          case c of
            #32: origin.x += font.SpaceWidth;                   // space
            #9: origin.x += font.SpaceWidth * font.TabWidth;    // tab
            otherwise
              origin.x += font.SpaceWidth;                      // other characters
          end;

          continue;
        end;

      renderFrame := font.CharacterRenderFrame(c);

      newOrigin.x := origin.x + renderFrame.bearing.x;
      newOrigin.y := origin.y + renderFrame.bearing.y;

      {
        H: 4.0/8.0
        e: 6.0/6.0
        l: 4.0/8.0
        o: 6.0/6.0
        j: 4.0/10.0
        g: 6.0/8.0
      }
      // "originY": (options.font.LineHeight - (renderFrame.bearing.y + renderFrame.faceSize.y)):1:1
      //writeln(char(c),':',renderFrame.bearing.y:1:1,'/',renderFrame.faceSize.y:1:1);

      charFrame := RectMake(newOrigin, renderFrame.faceSize) * scale;

      { TODO: move to direct quad drawing
        charQuad.SetOrigin(origin);
        charQuad.SetSize(face.size);
        charQuad.SetTexture(face.textureFrame);
        DrawQuad(charQuad);
      }

      DrawTexture(font, charFrame, renderFrame.textureFrame, color);
      {$ifdef DEBUG_FONTS}
      FillRect(charFrame, RGBA(1, 0, 0, 0.2));
      {$endif}

      origin.x += renderFrame.advance;
    end;
end;

procedure TLayoutManager.DrawGutter(origin: TVec2; startLine, endLine: integer; out gutterWidth: integer);
var
  i: integer;
  lineColor: TColor;
begin
  lineColor := RGBA(0, 1);

  gutterWidth := 32;

  FillRect(RectMake(origin.x, origin.y, gutterWidth, (endLine - startLine) * LineHeight), RGBA(0.8, 1));

  for i := startLine to endLine do
    begin
      DrawText(font, lines[i].line.ToString, origin, lineColor);
      origin.y += LineHeight;
    end;
end;

procedure TLayoutManager.Draw(origin: TVec2; visibleRect: TRect);
var
  i, startLine, endLine: integer;
  gutterWidth: integer;
begin
  startLine := Trunc(visibleRect.MinY / LineHeight);
  endLine := Trunc(visibleRect.MaxY / LineHeight);

  DrawGutter(origin, startLine, endLine, gutterWidth);

  origin.x += gutterWidth;

  for i := startLine to endLine do
    begin
      DrawLine(origin, lines[i]);
      origin.y += LineHeight;
    end;
end;

function TLayoutManager.GetLineHeight: integer;
begin
  result := font.LineHeight;
end;

constructor TLayoutManager.Create;
begin
  lines := TLineList.Create;
  scale := 1;
  color := RGBA(0, 1);
end;

procedure LayoutText(var options: TTextLayoutOptions);

  procedure DrawCursor(origin: TVec2); inline;
  var
    cursorFrame: TRect;
    yMargin: integer;
  begin
    yMargin := 1;
    cursorFrame.width := 1;
    cursorFrame.x := (origin.x - trunc(cursorFrame.width / 2)) - 1 { always draw on left side };
    cursorFrame.y := origin.y - yMargin;
    cursorFrame.height := options.font.LineHeight + (yMargin * 2);
    FillRect(cursorFrame, RGBA(1, 0, 0, 0.9));
  end;

  procedure TestPoints(offset: LongInt; rect: TRect);
  begin
    // test hit offset
    if offset = options.testOffset then
      options.hitPoint := rect.origin;

    // test the hit point
    if options.testPoint.y >= rect.minY then
      begin
        if options.testPoint.x >= rect.midX then
          options.hitOffset := offset + 1
        else if options.testPoint.x >= rect.minX then
          options.hitOffset := offset;
      end;
  end;

var
  offset: TTextOffset;
  c: TFontChar;
  renderFrame: TFontRenderFrame;
  newOrigin,
  prevOrigin,
  origin,
  size: TVec2;
  charFrame: TRect;
  selFrame: TRect;
  newLine: boolean;
begin
  Assert(options.font <> nil, 'DrawText font must not be nil');

  case options.textAlignment of
    TTextAlignment.Left:
      origin := options.where / options.scale;
    TTextAlignment.Center:
      begin
        origin := options.where / options.scale;
        size := MeasureText(options.font, options.text);
        origin.x -= size.width / 2; 
      end;
  end;

  options.hitOffset := -1;
  selFrame.height := 0;
  options.textSize := V2(0, 0);

  for offset := options.range.location to options.range.length - 1 do
    begin
      c := options.text[offset + 1];

      // draw cursor
      if options.draw and (options.cursor.location > -1) then
        begin

          if offset = options.cursor.insertion then
            DrawCursor(origin);

          if (offset = options.cursor.location) and (options.cursor.length > 0) then
            begin
              // start selection frame
              selFrame := RectMake(origin.x, origin.y , 0, options.font.LineHeight);
            end
          else if (offset = options.cursor.location + options.cursor.length) and (selFrame.height > 0) then
            begin
              // end selection frame
              selFrame.size.x := origin.x - selFrame.origin.x;
              FillRect(selFrame, RGBA(1, 0, 0, 0.25));
              selFrame.height := 0;
            end;
        end;

      if not options.font.HasGlyph(c) then
        begin
          newLine := false;
          prevOrigin := origin;

          case c of
            #32: origin.x += options.font.SpaceWidth;                         // space
            #9: origin.x += options.font.SpaceWidth * options.font.TabWidth;  // tab
            #10, #12, #13:                                                    // EOL
              begin
                newLine := true;

                // test for points outside the line range and
                // and place the hit offset at the end of the line
                // but not after the line break characters
                if (options.testPoint.y >= origin.y) and (options.testPoint.x >= origin.x) then
                  options.hitOffset := offset;

                if offset = options.testOffset then
                  options.hitPoint := origin;

                // before advacing to the next line draw the selection
                // for the current line
                if options.draw and (selFrame.height > 0) then
                  begin
                    selFrame.size.x := origin.x - selFrame.origin.x;
                    // add an extra amount of space to indicate the line break is selected
                    selFrame.size.x += Max(2, options.font.SpaceWidth / 2);
                    FillRect(selFrame, RGBA(1, 0, 0, 0.25));
                  end;

                origin.y += options.font.LineHeight;
                origin.x := options.where.x / options.scale;

                selFrame.origin := origin;
              end
            otherwise
              origin.x += options.font.SpaceWidth;                            // other characters
          end;

          // test points
          if not newLine then
            TestPoints(offset, RectMake(origin.x, origin.y, origin.y - prevOrigin.y, options.font.LineHeight));

          // adjust text size
          if origin.x > options.textSize.width then
            options.textSize.width := origin.x;
          if origin.y > options.textSize.height then
            options.textSize.height := origin.y;  

          continue;
        end;

      renderFrame := options.font.CharacterRenderFrame(c);

      newOrigin.x := origin.x + renderFrame.bearing.x;
      newOrigin.y := origin.y + renderFrame.bearing.y;

      {
        H: 4.0/8.0
        e: 6.0/6.0
        l: 4.0/8.0
        o: 6.0/6.0
        j: 4.0/10.0
        g: 6.0/8.0
      }
      // "originY": (options.font.LineHeight - (renderFrame.bearing.y + renderFrame.faceSize.y)):1:1
      //writeln(char(c),':',renderFrame.bearing.y:1:1,'/',renderFrame.faceSize.y:1:1);

      charFrame := RectMake(newOrigin, renderFrame.faceSize) * options.scale;

      // test points
      TestPoints(offset, charFrame);

      // draw character
      if options.draw then
        begin
          { TODO: move to direct quad drawing
            charQuad.SetOrigin(origin);
            charQuad.SetSize(face.size);
            charQuad.SetTexture(face.textureFrame);
            DrawQuad(charQuad);
          }
          DrawTexture(options.font, charFrame, renderFrame.textureFrame, options.color);
          {$ifdef DEBUG_FONTS}
          FillRect(charFrame, RGBA(1, 0, 0, 0.2));
          {$endif}
        end;

      origin.x += renderFrame.advance;

      // adjust text size
      if origin.x > options.textSize.width then
        options.textSize.width := origin.x;
      if origin.y > options.textSize.height then
        options.textSize.height := origin.y;
    end;

  options.textSize.y += options.font.LineHeight;

  if (options.testPoint.y >= origin.y) and (options.testPoint.x >= origin.x - renderFrame.advance) then
    options.hitOffset := offset;

  // draw cursor at the final offset
  if options.draw and 
    (options.cursor.location > -1) and (
      (options.cursor.location = options.range.location + options.range.length) or 
      (options.range.length = 0)) then
    DrawCursor(origin);
end;

function TTextView.FindPointAtLocation(location: LongInt): TVec2i;
var
  layout: TTextLayoutOptions;
begin
  layout := TextLayout;
  layout.draw := false;
  layout.testOffset := location;
  layout.hitPoint := 0;
  LayoutText(layout);
  result := layout.hitPoint;
end;

function TTextView.FindCharacterAtPoint(point: TVec2i): LongInt;
var
  layout: TTextLayoutOptions;
begin
  layout := TextLayout;
  layout.draw := false;
  layout.testPoint := point;
  layout.hitOffset := 0;
  LayoutText(layout);
  result := layout.hitOffset;
end;

function TTextView.FindWordAtPoint(point: TVec2i): TTextRange;
var
  start, 
  offset: LongInt;
begin
  start := FindCharacterAtPoint(point);

  result.location := 0;
  result.length := 0;

  for offset := start downto 0 do
    case text[offset] of
      TCharSetWord, TCharSetInteger:
        continue;
      otherwise
        begin
          result.location := offset;
          break;
        end;
    end;

  for offset := start to high(text) do
    begin
      if offset = high(text) then
        begin
          result.length := (offset - 1) - result.location;
          break;
        end;

      case text[offset] of
        TCharSetWord, TCharSetInteger:
          continue;
        otherwise
          begin
            result.length := (offset - 1) - result.location;
            break;
          end;
      end;
    end;

  result.insertion := result.location + result.length;
end;

function TTextView.FindLineAtPoint(point: TVec2i): TTextRange;
var
  start, 
  offset: LongInt;
begin
  start := FindCharacterAtPoint(point);

  result.location := 0;
  result.length := 0;

  for offset := start downto 0 do
    if (offset = 0) or (text[offset] in [TCharSetLineEnding]) then
      begin
        result.location := offset;
        break;
      end;

  for offset := start to high(text) do
    if (offset = high(text)) or (text[offset] in [TCharSetLineEnding]) then
      begin
        result.length := (offset - 1) - result.location;
        break;
      end;

  result.insertion := result.location + result.length;
end;

procedure TTextView.HandleKeyEquivalent(event: TEvent);
begin
  if (event.KeyCode = KEY_v) and (event.KeyboardModifiers = [ssSuper]) then
    begin
      InsertText(GetClipboardText);
      event.Accept(self);
    end
  else if (event.KeyCode = KEY_c) and (event.KeyboardModifiers = [ssSuper]) then
    begin
      if cursor.length > 0 then
        SetClipboardText(System.Copy(Text, cursor.location + 1, cursor.length));
      event.Accept(self);
    end;
end;

procedure TTextView.HandleInputStarted(event: TEvent);
var
  range: TTextRange;
  grow: boolean;
begin
  inherited HandleInputStarted(event);

  if InputHit(event) then
    begin
      // TODO: this enables a selection mode also: char,word,line

      if event.ClickCount = 3 then
        begin
          selMode := TTextViewSelectionMode.Line;
          range := FindLineAtPoint(event.Location(self));
          SelectRange(range.location, range.length);
          event.Accept(self);
        end
      else if event.ClickCount = 2 then
        begin
          selMode := TTextViewSelectionMode.Word;
          range := FindWordAtPoint(event.Location(self));
          SelectRange(range.location, range.length);
          event.Accept(self);
        end
      else if IsSelectable then
        begin
          dragStart := cursor.insertion;
          selMode := TTextViewSelectionMode.Character;
          grow := ssShift in event.MouseModifiers;
          MoveCursor(FindCharacterAtPoint(event.Location(self)), grow);
          event.Accept(self);
        end;
    end;
end;

procedure TTextView.HandleInputDragged(event: TEvent);
var
  offset: longint;
begin
  inherited HandleInputDragged(event);

  if InputHit(event) and (event.InputSender = self) then
    begin

      case selMode of
        TTextViewSelectionMode.Character:
          offset := FindCharacterAtPoint(event.Location(self));
        TTextViewSelectionMode.Word:
          begin
            // TODO: this can deselect the initial word
            // because the insertion point will be the same
            offset := FindWordAtPoint(event.Location(self)).insertion;
          end;
        TTextViewSelectionMode.Line:
          offset := FindLineAtPoint(event.Location(self)).insertion;
      end;

      if offset < dragStart then
        cursor.location := offset
      else
        cursor.location := dragStart;

      cursor.insertion := offset;
      cursor.length := abs(offset - dragStart);

      cursor.location := Clamp(cursor.location, 0, Length(text));
      cursor.length := Clamp(cursor.length, 0, System.Length(text));
      //writeln('start: ',cursor.location, ' end:', cursor.location+cursor.length);

      event.Accept(self);
    end
  else if event.InputSender = self then
    begin
      writeln('scroll drag');
    end;
end;

procedure TTextView.HandleInputEnded(event: TEvent);
begin
  inherited HandleInputEnded(event);

  if event.InputSender = self then
    begin
      //writeln('selection ended');
      dragStart := -1;
      event.Accept(self);
    end;
end;

procedure TTextView.HandleKeyDown(event: TEvent);
var
  newLocation, 
  deleteLength,
  offset: longint;
  point: TVec2;
  grow: boolean;
begin
  if IsEditable then
    begin
      grow := ssShift in event.KeyboardModifiers;

      case event.KeyCode of
        KEY_RETURN:
          InsertText(LineEnding);
        KEY_BACKSPACE, KEY_DELETE:
          if HandleWillDelete then
            begin
              if ssSuper in event.KeyboardModifiers then
                begin
                  // delete line
                  newLocation := AdvanceLineStart(text, cursor.location);

                  // always delete at least 1 character
                  if newLocation = cursor.location then
                    newLocation := Clamp(newLocation - 1, 0, MaxInt);

                  deleteLength := cursor.location - newLocation;
                  if deleteLength > high(text) then
                    deleteLength := high(text);
                  DeleteText(newLocation + 1, deleteLength);
                  MoveCursor(newLocation);
                end
              else if ssAlt in event.KeyboardModifiers then 
                begin
                  // delete word
                  newLocation := AdvancePreviousWord(text, cursor.location);
                  deleteLength := cursor.location - newLocation;
                  if deleteLength > high(text) then
                    deleteLength := high(text);
                  DeleteText(newLocation + 1, deleteLength);
                  MoveCursor(newLocation);
                end
              else
                begin
                  if cursor.length = 0 then
                    begin
                      DeleteText(cursor.location, 1);
                      MoveCursor(cursor.location - 1);
                    end
                  else
                    begin
                      DeleteText(cursor.location + 1, cursor.length);
                      MoveCursor(cursor.location);
                    end;
                end;
            end;
        KEY_PAGEUP:
          ;
        KEY_PAGEDOWN:
          ;
        KEY_RIGHT:
          begin
            if ssSuper in event.KeyboardModifiers then
              MoveCursor(MaxInt, grow)
            else if ssAlt in event.KeyboardModifiers then
              MoveCursor(AdvanceNextWord(text, cursor.location), grow)
            else
              MoveCursor(cursor.insertion + 1, grow);
          end;
        KEY_LEFT:
          begin
            if ssSuper in event.KeyboardModifiers then
              MoveCursor(0, grow)
            else if ssAlt in event.KeyboardModifiers then
              MoveCursor(AdvancePreviousWord(text, cursor.location), grow)
            else
              MoveCursor(cursor.insertion - 1, grow);
          end;
        KEY_DOWN:
          begin
            point := FindPointAtLocation(cursor.location);
            point.y += textFont.LineHeight;
            offset := FindCharacterAtPoint(point);
            MoveCursor(offset);
          end;
        KEY_UP:
          begin
            point := FindPointAtLocation(cursor.location);
            point.y -= textFont.LineHeight;
            offset := FindCharacterAtPoint(point);
            MoveCursor(offset);
          end;
        otherwise
          begin
            InsertText(event.KeyChar);
          end;

        event.Accept(self);
      end;
    end;
end;

function TTextView.GetTextFrame: TRect;
begin
  result := Bounds;
end;

function TTextView.GetTextLayout: TTextLayoutOptions;
begin
  result.font := textFont;
  result.text := text;
  result.range := TTextRange.Create(0, length(result.text));
  result.where := TextFrame.origin;
  result.color := textColor;
  result.scale := 1.0;
  result.textAlignment := textAlignment;
  result.wrap := TTextWrapping.Word;
  result.hitPoint := 0;
  result.draw := true;
  result.cursor := cursor;
end;

procedure TTextView.Draw;
var
  layout: TTextLayoutOptions;
begin
  inherited;

  if IsEditable then
    begin
      layout := TextLayout;
      LayoutText(layout);
    end
  else if Text <> '' then
    DrawText(textFont, text, textAlignment, TextFrame, textColor)
end;

function TTextView.IsReadyToLayout: boolean;
begin
  result := assigned(textFont);
end;

procedure TTextView.LayoutSubviews;
var
  newSize: TVec2;
  textSize: TVec2;
  scrollView: TScrollView;
begin
  // no font was set so we can't update the container
  if textFont = nil then
    exit;

  scrollView := EnclosingScrollView;

  if dirty and ((TTextViewOption.WidthTracksContainer in options) or (TTextViewOption.HeightTracksContainer in options)) then
    begin
      textSize := GetTextSize;
      newSize := Bounds.size;

      // resize to fit text
      if (TTextViewOption.WidthTracksContainer in options) {and (newSize.width < textSize.width)} then
        newSize.width := textSize.width;

      // fill to fit scrollview size
      //if (scrollView <> nil) and (GetParent = scrollView) and (newSize.width < scrollView.ClipRect.Width) then
      //  newSize.width := scrollView.ClipRect.width;

      // note: this was "text wraps to view" but not sure how it's going to be
      //if TTextViewOption.WidthTracksView in options then
      //  newSize.width := newSize.width;

      if TTextViewOption.HeightTracksContainer in options then
        newSize.height := textSize.height;

      SetSize(newSize);
      dirty := false;
    end;

  if (scrollView <> nil) and (GetParent = scrollView) then
    begin
      //writeln('bounds: ', scrollView.Bounds.tostr);
      //writeln('visible rect: ', scrollView.GetVisibleRect.tostr);
      //writeln('clip rect: ', scrollView.GetClipRect.tostr);
      //firstRow := trunc(abs(scrollView.GetVisibleRect.minY) / (cellHeight + cellSpacing));
      //maxRows := RoundUp(scrollView.GetClipRect.Height / (cellHeight + cellSpacing)) + 1;
    end
  else
    begin
      //firstRow := 0;
      //maxRows := RoundUp(GetHeight / (cellHeight + cellSpacing)) + 1;
    end;
  
  inherited;
end;

procedure TTextView.HandleFrameDidChange(previousFrame: TRect);
begin
  inherited HandleFrameDidChange(previousFrame);
  if previousFrame.size <> GetFrame.size then
    NeedsLayoutSubviews;
end;

procedure TTextView.Initialize;
begin
  inherited;
  
  dirty := true;

  SetWidthTracksContainer(true);
  SetHeightTracksContainer(true);
  SetMaximumWidth(0);
  SetTextAlignment(TTextAlignment.Left);
  SetTextColor(RGBA(0, 0));
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

procedure TTextField.SetFont(newValue: IFont);
begin
  m_font := newValue;
  if m_text <> nil then
    AdjustFrame;
end;

procedure TTextField.SetLabelString(newValue: string);
begin
  if LabelView = nil then
    m_labelView := TTextView.Create();
end;

procedure TTextField.HandleInputStarted(event: TEvent);
begin
  // clicked outside the text view
  if not m_text.InputHit(event)  then
    begin
      m_text.MoveCursor(MaxInt);
    end;

  inherited HandleInputStarted(event);
end;

procedure TTextField.HandleViewFocusChanged(notification: TNotification);
begin
  GiveFocus;
end;

procedure TTextField.HandleViewFrameChanged(notification: TNotification);
var
  newFrame,
  parentFrame: TRect;
  rightMargin: single;
begin
  textFrame := GetBounds.Inset(BorderWidth, BorderWidth);

  parentFrame := m_text.ConvertRectTo(m_text.GetBounds, self);
  newFrame := m_text.GetFrame;

  rightMargin := GetBounds.width - 2;
  if parentFrame.Width > rightMargin then
    newFrame.origin.x := trunc(rightMargin - newFrame.Width)
  else
    newFrame.origin.x := textFrame.MinX;

  //rightMargin := GetBounds.height - 2;
  //if parentFrame.Height > rightMargin then
  //  newFrame.origin.y := trunc(rightMargin - newFrame.height)
  //else
  //  newFrame.origin.y := textFrame.MinY;

  m_text.SetFrame(newFrame);  
end;

procedure TTextField.HandleKeyDown(event: TEvent);
begin
  case event.KeyCode of
    KEY_TAB:
      begin
        Window.AdvanceFocus;
        event.Accept(self);
      end;
    KEY_RETURN:
      begin
        InvokeAction;
        event.Accept(self);
      end;
    otherwise
      inherited HandleKeyDown(event);
  end;  
end;

procedure TTextField.HandleWillAddToParent(view: TView);
begin
  inherited HandleWillAddToParent(view);

  BorderWidth := 4;
  SetCanAcceptFocus(true);

  textFrame := GetBounds.Inset(BorderWidth, BorderWidth);

  m_text := TTextView.Create(textFrame);
  m_text.SetEditable(true);
  m_text.SetWidthTracksContainer(true);
  m_text.SetText(GetStringValue);
  m_text.SetFont(TextFont);
  m_text.SetPostsFrameChangedNotifications(true);
  AddSubview(m_text);

  ObserveNotification(kNotificationFocusChanged, @self.HandleViewFocusChanged, pointer(m_text));
  ObserveNotification(kNotificationFrameChanged, @self.HandleViewFrameChanged, pointer(m_text));
end;

procedure TTextField.Draw;
begin   
  // TODO: Testing!
  if not IsFocused then
    FillRect(GetBounds, RGBA(0.1, 0.1, 1, 0.5))
  else
    FillRect(GetBounds, RGBA(0.1, 1, 0.1, 0.5));

  StrokeRect(Bounds, TColor.Black);

  FlushDrawing;
  // TODO: we need to add some margin for cursors/selection range
  PushClipRect(textFrame.Inset(-2, -2));
  inherited;
  PopClipRect;
end;

{ IMAGE VIEW }

procedure TImageView.Draw;
var
  scaledSize, 
  destSize, 
  srcSize: TVec2;
  ratio: TScalar;
  scrollView: TScrollView;
  imageFrame,
  textureFrame: TRect;
begin 
  // TODO: make an option to clip by texture coords for embedded scrollviews
  //scrollView := FindParent(TScrollView)  as TScrollView;
  //if assigned(scrollView) then
  //  begin
  //    scrollView.GetVisibleRect.show;
  //  end;

  if assigned(Image) then
    begin
      if TImageViewOption.ScaleProportionately in options then
        begin
          destSize := GetSize;
          srcSize := Image.GetSize;
          if destSize.width > srcSize.width then
            destSize.width := srcSize.width;
          if destSize.height > srcSize.height then
            destSize.height := srcSize.height;
          ratio := Min(destSize.width / srcSize.width, destSize.height / srcSize.height);
          scaledSize := srcSize * ratio;
        end
      else if TImageViewOption.ScaleToFit in options then
        scaledSize := GetSize
      else
        scaledSize := Image.GetSize; // don't scale

      if TImageViewOption.Center in options then
        imageFrame := RectMake((GetWidth / 2) - (scaledSize.width / 2), (GetHeight / 2) - (scaledSize.height / 2), scaledSize.width, scaledSize.height)
      else
        imageFrame := RectMake(0, 0, scaledSize.width, scaledSize.height);

      textureFrame := Image.TextureFrame;
      DrawTexture(Image, imageFrame, textureFrame);
    end;

  inherited;
end;

procedure TImageView.SetBackgroundImage(newValue: TTexture);
begin
  backgroundImage := newValue;
end;

procedure TImageView.SetOptions(newValue: TImageViewOptions);
begin
  options := newValue;
end;

procedure TImageView.SetImage(newValue: TTexture);
begin
  m_frontImage := newValue;
end;

constructor TImageView.Create(inFrame: TRect; image: TTexture);
begin
  SetImage(image);
  SetFrame(inFrame);
  Initialize;
end;

{ BUTTON }

constructor TButton.Create(_frame: TRect; _title: string; _font: IFont; _action: TInvocation);
begin
  Initialize;
  SetTitle(_title);
  if _font <> nil then
    SetFont(_font);
  if _action <> nil then
    SetAction(_action);
  SetFrame(_frame);
end;

procedure TButton.SetTitle(newValue: string);
begin
  textView.SetText(newValue);
  SetIdentifierFromTitle(newValue);
  NeedsDisplay := true;
end;

procedure TButton.SetFont(newValue: IFont);
begin
  Assert(textView <> nil, 'button text view is not loaded');
  textView.SetFont(newValue);
  controlFont := newValue;
  RecalculateText;
end;

procedure TButton.SetSound(newValue: string);
begin
  sound := newValue;
end;

procedure TButton.SetEnableContentClipping(newValue: boolean);
begin
  enableContentClipping := newValue;
end;

procedure TButton.SetDefault(newValue: boolean);
begin
  if GetParent = nil then
    wantsDefault := true
  else
    GetWindow.defaultButton := self;
end;

procedure TButton.SetImagePosition(newValue: TButtonImagePosition);
begin
  imagePosition := newValue;
  NeedsLayoutSubviews;
end;

procedure TButton.SetImage(newValue: TTexture);
begin
  imageView.SetImage(newValue);
  imageView.SetSize(newValue.GetSize);
  NeedsLayoutSubviews;
end;

procedure TButton.SetResizeByWidth(newValue: boolean);
begin
  resizeByWidth := newValue;
end;

procedure TButton.SetMaximumWidth(newValue: integer);
begin
  textView.SetMaximumWidth(newValue);
end;

function TButton.IsPressed: boolean;
begin
  result := pressed;
end;

function TButton.IsTracking: boolean;
begin
  result := tracking;
end;

function TButton.GetImagePosition: TButtonImagePosition;
begin
  result := imagePosition;
end;

function TButton.GetImage: TTexture;
begin
  if imageView <> nil then
    result := TTexture(imageView.image)
  else
    result := nil;
end;

procedure TButton.HandlePressed;
begin
end;

procedure TButton.HandleAction;
var
  action: TInvocation;
begin
  if HasActions then
    for action in actions do
      action.Invoke(self);
end;

procedure TButton.HandleInputEnded(event: TEvent);
begin
  if pressed then
    begin
      HandlePressed;
      HandleAction;
      DepressButton;
    end
  else
    begin
      tracking := false;
      pressed := false;
    end;
end;

procedure TButton.HandleInputDragged(event: TEvent);
var
  previous: boolean;
begin
  if tracking then
    begin
      previous := pressed;
      pressed := InputHit(event);
      if previous <> pressed then
        HandleStateChanged;
    end;
end;

procedure TButton.HandleInputStarted(event: TEvent);
begin 
  if InputHit(event) and IsEnabled then
    begin
      tracking := true;
      pressed := true;
      HandleStateChanged;
      event.Accept(self);
    end
  else
    inherited HandleInputStarted(event);
end;

procedure TButton.DepressButton; 
begin
  pressed := false;
  tracking := false;
  needsDisplay := true;
  HandleStateChanged;
end;

procedure TButton.RecalculateText;
begin
  textView.NeedsLayoutSubviews;
  HandleValueChanged;
end;

function TButton.GetTitle: string;
begin
  result := textView.Text;
end;

function TButton.GetTitleFrame: TRect;
begin
  result := RectCenter(textView.GetFrame, GetBounds);
  if GetImage <> nil then
    result.origin.x := imageView.GetFrame.MaxX;
end;

function TButton.GetContainerFrame: TRect;
begin
  result := GetFrame;
  if resizeByWidth then
    begin
      if GetTitle <> '' then
        result.size.width := textView.GetWidth + (4 * 2);
      if GetImage <> nil then
        result.size.x += imageView.GetWidth;
    end;
end;

procedure TButton.LayoutSubviews;
var
  newFrame: TRect;
begin
  if GetImage <> nil then
    begin
      case imagePosition of
        TButtonImagePosition.Left,
        TButtonImagePosition.Right:
          begin
            newFrame.origin := V2(0, 0);
            newFrame.size := V2(GetHeight, GetHeight);
            imageView.SetHidden(false);
            imageView.SetFrame(newFrame);
          end;
        TButtonImagePosition.Center:
          begin
            newFrame := imageView.GetFrame;
            newFrame := RectCenter(newFrame, GetBounds);
            imageView.SetHidden(false);
            imageView.SetFrame(newFrame);
          end;
      end;
    end;

  if GetTitle <> '' then
    begin 
      Assert(textView <> nil, 'text view has not been initialized(set string value before init was called).');
      textView.SetText(GetTitle);
      textView.LayoutSubviews;

      newFrame := GetContainerFrame;
      SetFrame(newFrame);

      textView.SetFrame(GetTitleFrame);
    end
  else
    begin
      newFrame := GetContainerFrame;
      SetFrame(newFrame);
    end;
end;

procedure TButton.HandleValueChanged;
begin
  inherited;
  NeedsLayoutSubviews;
end;

procedure TButton.HandleStateChanged;
begin
  inherited;
  NeedsDisplay := true;
end;

procedure TButton.HandleWillAddToWindow(win: TWindow);
begin
  inherited HandleWillAddToWindow(win);

  if wantsDefault then
    begin
      win.defaultButton := self;
      wantsDefault := false;
    end;
end;

procedure TButton.Draw;
begin 
  if enableContentClipping then
    PushClipRect(GetBounds);

  inherited;

  if enableContentClipping then
    PopClipRect;
end;

procedure TButton.Initialize;
begin
  inherited;

  textView := TTextView.Create;
  textView.SetWidthTracksContainer(true);
  AddSubview(textView);
  
  // TODO: only allocate if we set the image
  imageView := TImageView.Create;
  imageView.SetOptions([TImageViewOption.Center]);
  imageView.SetHidden(true);
  AddSubview(imageView);
end;

{ CHECK BOX }

procedure TCheckBox.Initialize;
begin
  inherited;
  enableContentClipping := false;
  SetResizeByWidth(true);
  SetChecked(false);
end;

procedure TCheckBox.HandlePressed;
begin
  SetChecked(state = TControlState.Off);
end;

procedure TCheckBox.SetChecked(newValue: boolean);
begin
  if newValue then
    state := TControlState.On
  else
    state := TControlState.Off;
  SetValue(IsChecked);
end;

function TCheckBox.IsChecked: boolean; 
begin
  result := state = TControlState.On;
end;

function TCheckBox.GetButtonFrame: TRect; 
begin
  result := RectMake(0, 0, GetHeight, GetHeight);
end;

function TCheckBox.GetTitleFrame: TRect;
begin
  result := inherited;
  result.x := GetButtonFrame.Width + 2;
end;

function TCheckBox.GetContainerFrame: TRect;
begin
  result := inherited;
  if GetTitle <> '' then
    result.size.x += GetButtonFrame.Width + 2;
end;

{ RADIO BUTTON }

function TRadioButton.GetRadioGroup: TRadioGroup;
begin
  if assigned(GetParent) and GetParent.IsMember(TRadioGroup) then
    result := TRadioGroup(GetParent)
  else
    result := nil;
end;

procedure TRadioButton.HandlePressed;
var
  child: TView;
  group: TRadioGroup;
begin
  group := RadioGroup;
  if group <> nil then
    for child in group.subviews do
      if (child <> self) and (TRadioButton(child).GetControlState = TControlState.On) then
        TRadioButton(child).SetControlState(TControlState.Off);

  if state = TControlState.Off then
    state := TControlState.On;
end;

{ RADIO GROUP }

class function TRadioGroup.ButtonClass: TRadioButtonClass;
begin
  result := TRadioButton;
end;

constructor TRadioGroup.Create(position: TVec2; vertical: boolean; count: integer = 0);
var
  i: integer;
begin
  Initialize;
  SetFrame(RectMake(position, 80, 12));
  //resizeByWidth := false;
  //buttonMargin := round(GetWidth / 4);
  if count > 0 then
    for i := 0 to count - 1 do
      AddButton('');
  self.vertical := vertical;
end;

procedure TRadioGroup.AddButton(title: string);
var
  button: TRadioButton;
begin
  button := ButtonClass.Create(RectMake(0, 0, 0, 0));
  button.SetTitle(title);
  AddSubview(button);
end;

function TRadioGroup.SelectedButton: TRadioButton;
var
  child: TView;
begin
  result := nil;
  for child in subviews do
    if TRadioButton(child).GetControlState = TControlState.On then
      exit(TRadioButton(child));
end;

function TRadioGroup.IndexOfSelectedButton: integer;
var
  button: TRadioButton;
begin
  button := SelectedButton;
  if assigned(button) then
    result := subviews.IndexOf(button)
  else
    result := -1;
end;

procedure TRadioGroup.Initialize;
begin
  inherited;

  resizeByWidth := true;
  buttonMargin := 4;
end;

procedure TRadioGroup.LayoutSubviews;
var
  child: TView;
  newFrame,
  containerFrame: TRect;
begin
  inherited;

  if subviews = nil then
    exit;

  containerFrame := GetFrame;

  if vertical then
    begin
      containerFrame.size.height := 0;
      containerFrame.size.width := 0;

      for child in subviews do
        begin
          if child.GetWidth > containerFrame.size.width then
            containerFrame.size.width := child.GetWidth;
        end;

      newFrame.origin := 0;
      newFrame.size.width := containerFrame.size.width;
      // TODO: get height from button 
      newFrame.size.height := 12;

      for child in subviews do
        begin
          child.SetFrame(newFrame);
          newFrame.origin.y += child.GetHeight + buttonMargin;
          containerFrame.size.y += child.GetHeight + buttonMargin;
        end;

      containerFrame.size.y -= buttonMargin;
      SetFrame(containerFrame);
    end
  else
    begin
      // TODO: if SizeToFit is not on then determine the correct margin and add that in
      // how do we find the margin though?

      if resizeByWidth then
        containerFrame.size.width := 0
      else
        containerFrame.size.width := GetWidth;
      containerFrame.size.height := 12;

      newFrame.origin := 0;
      newFrame.size.height := containerFrame.size.height;
      newFrame.size.width := 12;

      for child in subviews do
        begin
          child.SetFrame(newFrame);

          newFrame.origin.x += child.GetWidth + buttonMargin;
          if resizeByWidth then
            containerFrame.size.x += child.GetWidth + buttonMargin;
        end;

      if resizeByWidth then
        containerFrame.size.x -= buttonMargin;
      SetFrame(containerFrame);
    end;
end;


{ POPUP BUTTON }

procedure TPopupButton.SelectItem(item: TMenuItem);
var
  index: integer;
begin
  index := menu.items.IndexOf(item);
  SelectItemAtIndex(index);
end;

procedure TPopupButton.SelectItemAtIndex(index: integer);
var
  item: TMenuItem;
begin
  if not pullsdown then
    begin
      item := SelectedItem;
      if assigned(item) then
        item.SetChecked(false);
    end;

  HandleWillSelectItem;
  SelectedItem := menu.items[index];
  HandleDidSelectItem;
  NeedsLayoutSubviews;

  if not pullsdown then
    begin
      item := SelectedItem;
      item.SetChecked(true);
    end;
end;

procedure TPopupButton.SelectItemWithTag(_tag: integer);
var
  i: integer;
  item: TMenuItem;
begin
  for i := 0 to menu.items.Count - 1 do
    begin
      item := menu.items[i];
      if item.GetTag = _tag then
        begin
          SelectItemAtIndex(i);
          break;
        end;
    end;
end;

procedure TPopupButton.SelectItemWithTitle(title: string);
var
  i: integer;
  item: TMenuItem;
begin
  for i := 0 to menu.items.Count - 1 do
    begin
      item := menu.items[i];
      if item.GetTitle = title then
        begin
          SelectItemAtIndex(i);
          break;
        end;
    end;
end;

procedure TPopupButton.SetSelectedItem(newValue: TMenuItem);
begin
  // toggle check mark for selected item
  if (selectedItem <> newValue) and (selectedItem <> nil) then
    selectedItem.SetImage(nil);
  m_selectedItem := newValue;
  selectedItem.SetImage(CheckmarkImage);
end;

function TPopupButton.TitleOfSelectedItem: string;
begin
  Assert(assigned(SelectedItem), 'No selected item');
  result := SelectedItem.GetTitle;
end;

function TPopupButton.IndexOfSelectedItem: integer;
begin
  Assert(assigned(SelectedItem), 'No selected item');
  result := menu.items.IndexOf(SelectedItem);
end;

function TPopupButton.SelectedTag: integer;
begin
  Assert(assigned(SelectedItem), 'No selected item');
  result := SelectedItem.GetTag;
end;

function TPopupButton.GetMinimumMenuWidth: integer;
begin
  result := trunc(GetWidth);
end;

function TPopupButton.GetCheckmarkImage: TTexture;
begin
  result := nil;
end;

procedure TPopupButton.SetPullsdown(newValue: boolean);
begin
  pullsdown := newValue;
end;

class function TPopupButton.MenuClass: TMenuClass;
begin
  result := TMenu;
end;

class function TPopupButton.MenuItemClass: TMenuItemClass;
begin
  result := TMenuItem;
end;

function TPopupButton.InsertItem(index: integer; title: string): TMenuItem;
begin
  result := MenuItemClass.Create(title, GetAction);
  menu.InsertItem(index, result);
  NeedsLayoutSubviews;
end;

function TPopupButton.AddItem(title: string): TMenuItem;
begin
  result := InsertItem(menu.items.Count, title);
end;

procedure TPopupButton.HandleWillSelectItem;
begin
end;

procedure TPopupButton.HandleDidSelectItem;
begin
end;

procedure TPopupButton.HandleMenuWillSelectItem(menu: TMenu; item: TMenuItem);
begin
  if not pullsdown then
    SelectItem(item);
end;

procedure TPopupButton.HandleWindowWillClose(win: TWindow);
begin
  if win = menu then
    DepressButton;
end;

function TPopupButton.HandleWindowShouldClose(win: TWindow): boolean;
begin
  result := true;
end;

procedure TPopupButton.LayoutSubviews;
begin
  // TODO: use title from selected item
  if not pullsdown and assigned(SelectedItem) then
    SetTitle(SelectedItem.GetTitle);

  inherited;
end;

procedure TPopupButton.Initialize;
begin
  inherited;  

  menu := MenuClass.Create;
  menu.SetBehavior(TPopoverBehavior.Transient);
  menu.SetDelegate(self);
end;

procedure TPopupButton.HandleInputStarted(event: TEvent);
begin 
  inherited HandleInputStarted(event);

  if IsPressed then
    begin
      // click and hold should be able to select menu item then close the menu
      // so we need the button to not reject the event and block window dragging
      event.Reject;
      HandlePressed;
    end;
end;

procedure TPopupButton.HandleInputDragged(event: TEvent);
begin
  // TODO: popover is getting closed from dragging! how do we intercept this???
  if InputHit(event) then
    event.Accept(self);
end;

procedure TPopupButton.HandleInputEnded(event: TEvent);
begin
end;

procedure TPopupButton.Popup;
var
  buttonFrame: TRect;
  target: TVec2;
  item: TMenuItem;
begin
  if pullsdown then
    menu.Popup(self)
  else
    begin
      item := SelectedItem;
      if assigned(item) then
        begin
          menu.minimumWidth := GetMinimumMenuWidth;
          menu.LayoutSubviews;

          // align menu over title of menu bar
          buttonFrame := ConvertRectTo(GetBounds, nil);
          target := buttonFrame.origin;
          target.y -= item.GetFrame.MinY;

          menu.Popup(target);
        end
      else
        menu.Popup(self);
    end;
end;

procedure TPopupButton.HandlePressed;
begin
  menu.SetFont(controlFont);
  Popup;
end;

{ BINDING }

procedure TControlBinding.Apply(control: TControl);
begin
  case PropType(controller, prop) of
    tkInteger:
      SetOrdProp(controller, prop, control.GetIntegerValue);
    tkBool:
      SetOrdProp(controller, prop, Int64(control.GetBoolValue));
    tkChar, tkSString, tkAString:
      SetStrProp(controller, prop, control.GetStringValue);
    tkFloat:
      SetFloatProp(controller, prop, control.GetFloatValue);
    tkVariant:
      SetVariantProp(controller, prop, control.GetValue);
    otherwise
      Assert(false, 'Binding type '+prop+' isn''t supported.');
  end;
end;

{ CONTROL }

function TControl.GetControlState: TControlState;
begin
  result := state;
end;

function TControl.GetValue: variant;
begin
  result := m_value;
end;

function TControl.GetStringValue: string;
begin
  result := m_value;
end;

function TControl.GetFloatValue: single;
begin
  result := m_value;
end;

function TControl.GetDoubleValue: double;
begin
  result := m_value;
end;

function TControl.GetIntegerValue: integer;
begin
  result := m_value;
end;

function TControl.GetLongValue: longint;
begin
  result := m_value;
end;

function TControl.GetBoolValue: boolean;
begin
  result := m_value;
end;

function TControl.GetAction: TInvocation;
begin
  if assigned(m_actions) then
    result := m_actions.Last
  else
    result := nil;
end;

function TControl.IsEnabled: boolean;
begin
  result := m_enabled;
  if assigned(Window) and not Window.ShouldAllowEnabling then
    result := false;
end;

function TControl.HasActions: boolean;
begin
  result := assigned(m_actions);
end;

procedure TControl.SetEnabled(newValue: boolean);
var
  changed: boolean;
begin
  changed := IsEnabled <> newValue;
  m_enabled := newValue;
  if changed then
    HandleActivityChanged;
end;

{ Transforms title string to camel_case as the
  default identifier if the control has explicity defined on. }
procedure TControl.SetIdentifierFromTitle(newValue: string);
begin
  if identifier <> '' then
    exit;
  newValue := Lowercase(newValue);
  newValue := StringReplace(newValue, ' ', '_', [rfReplaceAll]);
  SetIdentifier(newValue);
end;

procedure TControl.SetValue(newValue: variant; alwaysNotify: boolean);
var
  changed: boolean;
begin
  changed := GetValue <> newValue;
  m_value := newValue;
  if changed or alwaysNotify then
    HandleValueChanged;
  NeedsLayoutSubviews;
end;

procedure TControl.SetStringValue(newValue: string; alwaysNotify: boolean);
begin
  SetValue(newValue, alwaysNotify);
end;

procedure TControl.SetStringValue(newValue: string);
begin
  SetStringValue(newValue, false);
end;

procedure TControl.SetControlState(newValue: TControlState);
begin
  state := newValue;
  HandleStateChanged;
  NeedsLayoutSubviews;
end;

procedure TControl.SetKeyEquivalent(keycode: TKeyCode; modifiers: TShiftState);
begin
  keyEquivalent.keycode := keycode;
  keyEquivalent.modifiers := modifiers;
end;

procedure TControl.SetIdentifier(newValue: string);
begin
  identifier := newValue;
end;

procedure TControl.SetBinding(prop: string; controller: TObject);
begin
  binding.prop := prop;
  binding.controller := controller;
end;

procedure TControl.SetController(controller: TObject);
begin
  binding.controller := controller;
end;

procedure TControl.AddAction(newValue: TInvocation);
begin
  Assert(newValue <> nil, 'trying to add nil action.');
  actions.Add(newValue);
end;

procedure TControl.InsertAction(index: integer; newValue: TInvocation);
begin
  Assert(newValue <> nil, 'trying to insert nil action.');
  actions.Insert(index, newValue);
end;

procedure TControl.SetAction(newValue: TInvocation);
begin
  actions.Clear;
  AddAction(newValue);
end;

procedure TControl.SetAction(newValue: string);
begin
  SetAction(TInvocation.Create(TInvocationCallbackDispatch.Create(self, newValue)));
end;

function TControl.GetActions: TInvocationList;
begin
  if m_actions = nil then
    m_actions := TInvocationList.Create(true);
  result := m_actions;
end;

procedure TControl.InvokeAction;
var
  action: TInvocation;
begin
  if HasActions then
    for action in actions do
      begin
        if action.params = nil then
          action.Invoke(self)
        else
          action.Invoke;
      end;
end;

{ Resize the control so that it encloses its subviews.
  This is different from LayoutSubviews in which the control
  should resize its subviews to fit within its bounds }

procedure TControl.SizeToFit;
begin
end;

procedure TControl.Bind;
begin
  if binding.controller <> nil then
    binding.Apply(self);
end;

destructor TControl.Destroy;
begin
  FreeAndNil(m_actions);
  inherited;
end;

procedure TControl.HandleKeyEquivalent(event: TEvent);
begin
  inherited HandleKeyEquivalent(event);
  if event.IsAccepted then
    exit;

  if (keyEquivalent.keycode = event.KeyCode) and 
    (keyEquivalent.modifiers = event.KeyboardModifiers) then
    begin
      InvokeAction;
      event.Accept(self);
    end;
end;

procedure TControl.HandleActivityChanged;
begin
end;

procedure TControl.HandleStateChanged;
begin
end;

procedure TControl.HandleValueChanged;
begin
  Bind;
end;

procedure TControl.Initialize;
begin
  inherited Initialize;
  
  m_value := false;

  SetEnabled(true);
  SetControlState(TControlState.Off);
end;

{ NAVIGATION BAR }

procedure TNavigationBar.SetTitle(newValue: string);
begin
  titleView.SetText(newValue);
end;

procedure TNavigationBar.HandleDidAddToParent(sprite: TView);
begin
  inherited HandleDidAddToParent(sprite);
  
  backButton.SetAction(TInvocation.Create(@TNavigationView(GetParent).GoBack));
end;

procedure TNavigationBar.Initialize;
begin
  inherited Initialize;
  
  backButton := TButton.Create;
  backButton.SetHidden(true);
  backButton.SetStringValue('Back');
  AddSubview(backButton);
    
  titleView := TTextView.Create;
  titleView.SetWidthTracksView(true);
  titleView.SetTextAlignment(TTextAlignment.Center);
  AddSubview(titleView);
end;

procedure TNavigationBar.HandleFrameDidChange(previousFrame: TRect);
begin
  inherited HandleFrameDidChange(previousFrame);
  
  backButton.SetFrame(RectMake(0, 0, 0, GetHeight));
  titleView.SetFrame(GetBounds);
end;

{ NAVIGATION VIEW }

procedure TNavigationView.SetTitle(newValue: string);
begin
  navigationBar.SetTitle(newValue);
end;

procedure TNavigationView.PushPage(page: TView);
begin
  // remove last page from parent
  if pages.Last <> nil then
    pages.Last.RemoveFromParent;
  
  pages.Add(page);
  AddSubview(page);
  UpdateContents; 
end;

procedure TNavigationView.PopPage(page: TView);
begin
  page.RemoveFromParent;
  pages.Remove(page);
  
  page := pages.Last;
  Assert(page <> nil, 'Can''t pop last page.');
  if page <> nil then
    begin
      AddSubview(page);
      UpdateContents;
    end;
end;

procedure TNavigationView.GoBack(params: TInvocationParams);
begin
  PopPage(pages.Last);
end;

procedure TNavigationView.UpdateContents;
var
  page: TView;
begin
  navigationBar.SetFrame(RectMake(0, 0, GetWidth, 12));

  page := pages.Last;
  if page <> nil then
    page.SetFrame(RectMake(0, navigationBar.GetHeight, GetWidth, GetHeight - navigationBar.GetHeight));
    
  navigationBar.backButton.SetHidden(pages.Count <= 1);
end;

procedure TNavigationView.HandleFrameDidChange(previousFrame: TRect);
begin
  inherited HandleFrameDidChange(previousFrame);
  
  if GetWindow = nil then
    exit;
    
  UpdateContents;
end;

procedure TNavigationView.Initialize;
begin
  inherited Initialize;
  
  navigationBar := TNavigationBar.Create;
  AddSubview(navigationBar);
  
  pages := TViewList.Create;
end;

destructor TNavigationView.Destroy;
var
  page: TView;
begin
  for page in pages do
    page.RemoveFromParent;
  pages.Free;
  inherited;
end;

begin
  TApplication.Create;
  MainScreen := TScreen.Create;
  ScreenMouseLocation := V2(-1, -1);
  PlatformScreenScale := 1.0;
  PendingEvents := TEventList.Create(true);

  {$define INITIALIZATION}
  {$include include/NotificationCenter.inc}
  {$include include/Timer.inc}
  {$undef INITIALIZATION}
end.