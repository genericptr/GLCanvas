{$mode objfpc}
{$modeswitch advancedrecords}
{$modeswitch multihelpers}
{$modeswitch nestedprocvars}
{$modeswitch arrayoperators}
{$modeswitch autoderef}

{$interfaces corba}
{$scopedenums on}
{$assertions on}

// ImGUI
// https://www.geeks3d.com/hacklab/20170929/how-to-build-user-interfaces-with-imgui/

// NanoVG
// https://www.geeks3d.com/hacklab/20160205/how-to-build-user-interfaces-and-2d-shapes-with-nanovg/

unit GLGUI;
interface
uses
	{$ifdef LIBRARY_OPENGLES}
	GLES11,
	{$else}
	GL,
	{$endif}
	SysUtils, FGL,
	GLPT, GLCanvas,
	GeometryTypes, VectorMath;

type
	TMap = specialize TFPGMap<String, Variant>;
	TObjectList = specialize TFPGObjectList<TObject>;
	TPoint = TVec2i;

	// TODO: implement a timer just for the GUI? UTimer.pas needs to be there and UInvocation.inc made
	TTimer = class
	end;

type
	TInvocation = class;
	TInvocationParams = pointer;
	TInvocationCallbackClass = procedure (params: TInvocationParams) of object;
	TInvocationCallbackProcedure = procedure (params: TInvocationParams);
	TInvocationCallbackNested = procedure (params: TInvocationParams) is nested;
	TInvocation = class
		callbackClass: TInvocationCallbackClass;
		callbackProcedure: TInvocationCallbackProcedure;
		callbackNested: TInvocationCallbackNested;
		params: TInvocationParams;
		procedure Invoke(withParams: TInvocationParams = nil);
		constructor Create(callback: TInvocationCallbackProcedure; _params: TInvocationParams = nil); overload;
		constructor Create(callback: TInvocationCallbackNested; _params: TInvocationParams = nil); overload;
		constructor Create(callback: TInvocationCallbackClass; _params: TInvocationParams = nil); overload;
	end;

{$define INTERFACE}
{$include include/ExtraTypes.inc}
{$include include/NotificationCenter.inc}
{$include include/GUIStyles.inc}
{$undef INTERFACE}


type
	TEvent = class
		msg: pGLPT_MessageRec;
		accepted: boolean;
		acceptedObject: TObject;
		// TODO: use the keycode! this will change with keyboard layouts
		// https://stackoverflow.com/questions/56915258/dİfference-between-sdl-scancode-and-sdl-keycode
		function KeyCode: GLPT_Scancode;
		function ScrollWheel: TVec2;
		function ClickCount: integer;
		function KeyboardModifiers: TShiftState;
		function MouseModifiers: TShiftState;
		function KeyboardCharacter: char;
		function Location(system: TObject = nil): TPoint;
		property IsAccepted: boolean read accepted;
		procedure Accept(obj: TObject = nil);
		procedure Reject;
		constructor Create(raw: pGLPT_MessageRec);
	end;

// TODO: not sure what this is yet. we may need to implement drag and drop in GLPT
type
	TDraggingSession = class
	end;

const
  kDragOperationNone = 0;
  kDragOperationGeneric = 1;
  kDragOperationCopy = 2;
  kDragOperationMove = 3;
  kDragOperationDelete = 4;

type
	IDelegate = interface ['IDelegate']
	end;

type
	IDelegation = interface
		procedure SetDelegate(newValue: TObject);
		function GetDelegate: TObject;
	end;

type
	IDraggingDestinationDelegate = interface (IDelegate) ['IDraggingDestinationDelegate']
		function HandleDraggingEntered(session: TDraggingSession): integer;
    function HandleDraggingUpdated(session: TDraggingSession): integer;
    procedure HandleDraggingExited(session: TDraggingSession);
    function HandlePerformDragOperation(session: TDraggingSession): boolean;
	end;

type
	IDraggingSourceDelegate = interface (IDelegate) ['IDraggingSourceDelegate']
		procedure HandleDraggingSessionWillBeginAtPoint(session: TDraggingSession; canvasPoint: TPoint);
    procedure HandleDraggingSessionMovedToPoint(session: TDraggingSession; canvasPoint: TPoint);
    procedure HandleDraggingSessionEndedAtPoint(session: TDraggingSession; canvasPoint: TPoint; operation: integer);
	end;

type
	ICoordinateConversion = interface (IDelegate) ['ISpriteCoordinateConversion']
		
		// return the parent coordinate system(canvas, layer or sprite)
		function GetParentCoordinateSystem: TObject;
		
		// point: A point specifying a location in the coordinate system of the caller.
		// system: The system into whose coordinate system "point" is to be converted.
		// result: The point converted to the coordinate system of "system".
		function ConvertPointTo(point: TPoint; system: TObject): TPoint;
		
		// point: A point specifying a location in the coordinate system of "system".
		// system: The system with "point" in its coordinate system.
		// result: The point converted to the coordinate system of the caller.
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

type
	TAutoresizingOption = (	MinXMargin,
													WidthSizable,
													MaxXMargin,
													MinYMargin,
													HeightSizable,
													MaxYMargin,
													RelativeXMargin,
													RelativeYMargin
													);	
	TAutoresizingOptions = set of TAutoresizingOption;	

type
	TWindowOptions = set of ( Modal,
															MoveableByBackground
															);

// TODO: make an enum instead of consts! this is c stuff not pascal
const
	kWindowLevels = 2;
	kWindowLevelNormal = 0;
	kWindowLevelUtility = 1;
	
type
	TWindow = class;
	TView = class;
	TViewList = specialize TFPGList<TView>;
	TViewClass = class of TView;
	
	TView = class (ICoordinateConversion)
		private
			function GetSubviews: TViewList; inline;
		public
			property Subviews: TViewList read GetSubviews;
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

			procedure ChangeAutoresizingOptions(newValue: TAutoresizingOptions; add: boolean);

			{ Methods }
			procedure AddSubview(view: TView);
			procedure InsertSubview(view: TView; index: integer);
			procedure RemoveSubview(view: TView);
			procedure RemoveSubviews;
			procedure RemoveFromParent;			

			function FindParent(ofClass: TViewClass): TView;
			function FindSubview(withTag: integer): TView;			
			procedure SendKeyDown(event: TEvent);
			function IsFocused(global: boolean = false): boolean;
			procedure GiveFocus;
			function IsMember(viewClass: TViewClass): boolean;
			destructor Destroy; override;

			{ Layout }
			procedure LayoutIfNeeded;
			procedure NeedsLayoutSubviews;
			procedure LayoutSubviews; virtual;

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
			procedure Update; virtual;
			procedure AutoResize; virtual;
			function ShouldDrawSubview(view: TView): boolean; virtual;
			function IsSubviewClipping(view: TView): boolean; inline;

			procedure PushClipRect(rect: TRect);
			function GetClipRect: TRect; inline;

			{ View Handlers }
			procedure HandleFrameDidChange(previousFrame: TRect); virtual;
			procedure HandleFrameWillChange(var newFrame: TRect); virtual;
			procedure HandleWillRemoveFromParent(view: TView); virtual;
			procedure HandleDidRemoveFromParent(view: TView); virtual;
			procedure HandleWillAddToParent(view: TView); virtual;
			procedure HandleWillAddToWindow(window: TWindow); virtual;
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
						
			{ Dragging }
			function StartDrag(face: TTexture; event: TEvent; offset: TVec2; data: TMap): TDraggingSession;
			
		private
			parentWindow: TWindow;
			backgroundColor: TColor;
			autoresizingOptions: TAutoresizingOptions;
			m_subviews: TViewList;
			m_parent: TView;
			m_tag: integer;
			m_frame: TRect;
			m_clipRect: TRect;
			initialMargin: TAABB;
			initialRelative: TRect;
			renderOrigin: TVec2;

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

			procedure SetParent(newValue: TView);
			function GetResolution: TScalar;
			procedure DisplayNeedsUpdate;
			procedure PostFrameChangedNotification;
			procedure FindSubviewDeep(withTag: integer; var ioView);
			procedure ReliquishFocus;
			procedure DrawInternal(parentOrigin: TVec2);
			procedure LayoutRoot;
			procedure SubviewsAreClipping(var clipping: boolean; deep: boolean = true);
			function PollEvent(constref raw: pGLPT_MessageRec): boolean;
			procedure TestMouseTracking(event: TEvent);
	end;

	TWindowList = specialize TFPGList<TWindow>;
	TWindowClass = class of TWindow;
	TWindowArray = array of TWindow;

	TWindowCursor = record
		mouseDown: boolean;		
		hover: TView;			
		//focus: TView;			
		//dropTarget: TView;
		//dragTarget: TView;
		//inputTarget: TView;
	end; 

	IWindowDelegate = interface (IDelegate) ['IWindowDelegate']
		procedure HandleWindowWillClose(window: TWindow);
	end;

	TWindow = class (TView, IDraggingDestinationDelegate, IDelegation)
		public

			{ Class Methods }
			class function ScreenRect: TRect;
			class function KeyWindow: TWindow;
			class function FrontWindow: TWindow;
			class function AvailableWindows: TWindowArray;
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
			procedure SetWindowLevel(newValue: integer);

			function GetContentSize: TVec2;
			function GetContentFrame: TRect;
			function GetFocusedView: TView;
			function GetParentCoordinateSystem: TObject; override;

			function IsFront: boolean;
			function IsModal: boolean;
			function IsFloating: boolean;
			function IsKey: boolean;

			{ IDelegation }
			procedure SetDelegate(newValue: TObject);
			function GetDelegate: TObject;
			
			{ Methods }
			procedure MakeKey; 
			procedure MakeKeyAndOrderFront;
			procedure Close;
			procedure OrderFront;
			procedure Center;
			procedure AdvanceFocus;
			procedure SendDefaultAction;

			destructor Destroy; override;

		protected
			procedure Initialize; override;
			procedure SetModal(newValue: boolean);		
			procedure PerformClose(params: TInvocationParams);
			function ShouldMoveByBackground(event: TEvent): boolean; virtual;

			procedure HandleFrameDidChange(previousFrame: TRect); override;
			
			{ Notifications }
			procedure HandleWillClose; virtual;
			procedure HandleDidAddToScreen; virtual;
			procedure HandleWillRemoveFromScreen; virtual;
			procedure HandleWillResignKeyWindow; virtual;
			procedure HandleWillBecomeKeyWindow; virtual;
			procedure HandleDidBecomeKeyWindow; virtual;
			procedure HandleWillResignFrontWindow; virtual;
			procedure HandleWillBecomeFrontWindow; virtual;
			procedure HandleDidBecomeFrontWindow; virtual;

			{ Events }
			procedure HandleInputStarted(event: TEvent); override;
			procedure HandleInputDragged(event: TEvent); override;
			procedure HandleInputEnded(event: TEvent); override;
			
			{ Mouse Events }
			function AcceptsMouseMovedEvents: boolean; override;
			function AcceptsKeyboardEvents: boolean; virtual;
			procedure HandleMouseMoved(event: TEvent); override;
			
			{ IDraggingDestinationDelegate }
			function HandleDraggingEntered(session: TDraggingSession): integer;
	    function HandleDraggingUpdated(session: TDraggingSession): integer;
	    procedure HandleDraggingExited(session: TDraggingSession);
	    function HandlePerformDragOperation(session: TDraggingSession): boolean;
			
			{ IKeyboardEventDelegate }
			procedure HandleKeyDown(event: TEvent); override;
			
		private
			windowLevel: integer;
			modal: boolean;
			moveableByBackground: boolean;
			contentSize: TVec2;
			wantsCenter: boolean;
			delegate: TObject;
			pressOrigin: TPoint;
			dragOrigin: TPoint;
			focusedView: TView;
			mouseInsideView: TView;
			defaultButton: TView;

			function GetWindowLevel: integer;
			procedure HandleDefaultAction(var msg); message 'DefaultAction';
			procedure FindSubviewForMouseEvent(event: TEvent; parent: TView; var outView: TView);
			procedure SetFocusedView(newValue: TView);
	end;

type
	TPopoverBehavior = (ApplicationDefined, 		{ Your application assumes responsibility for closing the popover. }
											Transient,							{ The system will close the popover when the user interacts with a user interface element outside the popover. }
											Semitransient);					{ The system will close the popover when the user interacts 
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
		private
			positioningRect: TRect;
			positioningView: TView;
			preferredEdge: TRectEdge;
			procedure UpdatePosition;
			procedure HandleWindowWillOpen(notification: TNotification);
	end;

type
	TControlState = (Off, On, Mixed);
	TControl = class (TView)
		public
			{ Accessors }
			procedure SetStringValue(newValue: string); virtual; overload;
			procedure SetEnabled(newValue: boolean);
			procedure SetControlState(newValue: TControlState);
			procedure SetAction(newValue: TInvocation);

			function GetStringValue: string;
			function GetAction: TInvocation;
			function GetControlState: TControlState;
			function IsEnabled: boolean;

			{ Methods }
			procedure InvokeAction;
			procedure SizeToFit; virtual;

		protected
			procedure Initialize; override;
			procedure HandleValueChanged; virtual;
			procedure HandleStateChanged; virtual;
		private
			stringValue: string;
			enabled: boolean;
			action: TInvocation;
			controlFont: IFont;
			state: TControlState;

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
		public
			constructor Create(inFrame: TRect; image: TTexture); overload;
			
			procedure SetImage(newValue: TTexture); overload;
			procedure SetOptions(newValue: TImageViewOptions);
			
			procedure SetBackgroundImage(newValue: TTexture);

			destructor Destroy; override;
		protected
			procedure Draw; override;
		private
			frontImage: TTexture;
			backgroundImage: TTexture;
			options: TImageViewOptions;
	end;

type
	TTextView = class (TControl)
		public

			{ Constructors }
			constructor Create(inFrame: TRect; text: string; inWidthTracksContainer: boolean = true; inFont: IFont = nil); overload;

			{ Accessors }
			procedure SetFont(newValue: IFont);
			procedure SetWidthTracksContainer(newValue: boolean);
			procedure SetHeightTracksContainer(newValue: boolean);
			procedure SetWidthTracksView(newValue: boolean);
			procedure SetMaximumWidth(newValue: integer);
			procedure SetTextAlignment(newValue: TTextAlignment);
			procedure SetEditable(newValue: boolean);
			procedure SetTextColor(newValue: TColor);

			function GetFont: IFont;
			function GetTextSize: TVec2;
			function IsReadyToLayout: boolean;

		protected
			procedure Initialize; override;
			
			procedure HandleFrameDidChange(previousFrame: TRect); override;
			procedure HandleKeyDown(event: TEvent); override;
			function HandleWillInsertCharacter(var c: char): boolean; virtual;
			function HandleWillDelete: boolean; virtual;
			procedure HandleValueChanged; override;

			procedure Draw; override;
			procedure LayoutSubviews; override;

		private
			textFont: IFont;
			textColor: TColor;

			widthTracksContainer: boolean;
			widthTracksView: boolean;
			heightTracksContainer: boolean;
			
			maximumWidth: integer;
			textAlignment: TTextAlignment;
			editable: boolean;
	end;

type
	TButtonImagePosition = (Left, Center, Right);

type
	TButton = class (TControl)
		public
			constructor Create(frame: TRect; _title: string; _font: IFont = nil); overload;

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
			procedure HandleWillAddToWindow(window: TWindow); override;

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
		public
			constructor Create(min, max: integer; _frame: TRect); overload;

			procedure SetCurrentValue(newValue: integer);
			procedure SetInterval(newValue: integer);
			procedure SetTickMarks(newValue: integer);

			function GetCurrentValue: integer;

			function IsVertical: boolean;
			function IsDragging: boolean;
		protected
			range: TRangeInt;

			procedure Initialize; override;
			procedure Draw; override;
			procedure DrawHandle(rect: TRect); virtual;
			procedure DrawTrack(rect: TRect); virtual;

			procedure HandleInputStarted(event: TEvent); override;
			procedure HandleInputDragged(event: TEvent); override;
			procedure HandleInputEnded(event: TEvent); override;

			function GetTrackSize: TVec2;
			function GetTrackFrame: TRect; virtual;
			function GetHandleFrame: TRect; virtual;

			function ClosestTickMarkToValue(value: integer): integer;
			function ValueAtRelativePosition(percent: single): integer;
			function RectOfTickMarkAtIndex(index: integer): TRect;
		private
			currentValue: integer;
			handleFrame: TRect;
			dragOrigin: TPoint;
			interval: integer;
			dragging: boolean;
			tickMarks: integer;
			liveUpdate: boolean;
			tickMarkFrames: array[0..32] of TRect;
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

		protected
			procedure Initialize; override;
			
			procedure HandleMouseWheelScroll(event: TEvent); override;
			procedure HandleInputStarted(event: TEvent); override;
			procedure HandleInputEnded(event: TEvent); override;
			procedure HandleInputDragged(event: TEvent); override;
			procedure Draw; override;
			procedure Update; override;
			procedure LayoutSubviews; override;

			function GetHorizontalScrollerFrame: TRect; virtual;
			function GetVerticalScrollerFrame: TRect; virtual;

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
			function GetClipRect: TRect;
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

			procedure SizeToFit; override;
		protected
			textView: TTextView;
			imageView: TImageView;

			procedure Initialize; override;
			procedure LayoutSubviews; override;

			function GetTextView: TTextView;
			function GetTextFrame: TRect; virtual;
			function GetImageFrame: TRect; virtual;
		private
			imageTitleMargin: TScalar;
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
	TTableView = class (TCellView)
		public						
			procedure SetCellSpacing(newValue: integer);
			procedure SetCellHeight(newValue: integer);
			procedure SetCellFont(newValue: IFont);
			procedure SetCellClass(newValue: TCellClass);
			procedure InsertCells(newValue: TCellList; index: integer);
			function GetCell(index: integer): TCell;
			procedure SetDataSource(newValue: TObject);
			procedure SetLastColumnTracksWidth(newValue: boolean);

			function GetCellHeight: integer;
			function GetCellSpacing: integer;
						
			procedure AddColumn(column: TTableColumn); overload;
			procedure AddColumn(id: integer; title: string); overload;
			procedure Reload;
			procedure SizeLastColumnToFit;

			destructor Destroy; override;

		protected
			procedure Initialize; override;
			
			procedure Draw; override;
			procedure HandleDrawSelection(rect: TRect); virtual;
			procedure HandleFrameDidChange(previousFrame: TRect); override;
			procedure HandleDidAddToParent(sprite: TView); override;
			procedure HandleKeyDown(event: TEvent); override;
			
			procedure ArrangeCells; override;
			function ShouldDrawSubview(view: TView): boolean; override;

		private
			m_dataSource: TObject;
			m_columns: TTableColumnList;

			cellSpacing: integer;
			cellHeight: integer;
			cellFont: IFont;
			cellClass: TCellClass;
			totalHeight: TScalar;
			arrangingCells: boolean;
			cellsNeedArranging: boolean;
			lastColumnTracksWidth: boolean;

			function ColumnAtIndex(index: integer): PTableColumn; inline;
			function GetColumns: TTableColumnList; inline;
			property Columns: TTableColumnList read GetColumns;
			function EnclosingScrollView: TScrollView;
			procedure ReloadCellsFromDataSource(dataSource: ITableViewDataSource; firstRow, maxRows: integer);
			procedure ScrollUp;
			procedure ScrollDown;
			function HeightForCell(cell: TCell): integer; inline;
	end;

type
	ICellViewDelegate = interface (IDelegate) ['ICellViewDelegate']
		procedure HandleSelectionChanged(cellView: TCellView);
		function HandleShouldSelectCell(cellView: TCellView; cell: TCell): boolean;
	end;

type
	ITableViewDelegate = interface (ICellViewDelegate) ['ITableViewDelegate']
		procedure TableViewWillDisplayCell(tableView: TTableView; row: integer; cell: TCell);
	end;
	

type
	TBarItem = class (TControl)
		public
			constructor Create(_view: TView); overload;
			constructor Create(width: integer); overload;
			procedure SetView(newValue: TView);
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

	TMenuItem = class (TControl)
		public
		
			{ Constructors }
			constructor Create(_title: string; _action: TInvocation); overload;
			
			{ Accessors }
			procedure SetChecked(newValue: boolean);
			procedure SetFont(newValue: IFont);
			
			function GetTextSize: TVec2i;
			function GetTitle: string;
			function IsChecked: boolean;
			function IsSelected: boolean;
		protected
			procedure Initialize; override;
			procedure LayoutSubviews; override;
			procedure Draw; override;

			procedure DrawAccessory(rect: TRect); virtual;
			function GetAccessoryFrame: TRect; virtual;

			procedure HandleMouseEntered(event: TEvent); override;
			procedure HandleMouseExited(event: TEvent); override;
			procedure HandleInputEnded(event: TEvent); override;
		private
			checked: boolean;
			selected: boolean;
			cell: TTextAndImageCell;

			function GetMenu: TMenu;
			property Menu: TMenu read GetMenu;
	end;
	TMenuItemClass = class of TMenuItem;
	TMenuItemList = specialize TFPGList<TMenuItem>;

	TSeperatorMenuItem = class (TMenuItem)
	end;

	IMenuDelegate = interface ['IMenuDelegate']
		procedure HandleMenuWillSelectItem(menu: TMenu; item: TMenuItem);
	end;

	TMenu = class (TPopover)
		private
			items: TMenuItemList;
		public
			constructor Create;
			procedure SetFont(newValue: IFont);
			
			{ Methods }
			procedure AddItem(item: TMenuItem); overload;
			function AddItem(title: string; action: TInvocation): TMenuItem; overload;
			procedure InsertItem(index: integer; item: TMenuItem);
			procedure RemoveItem(item: TMenuItem); overload;
			procedure RemoveItem(index: integer); overload;
			
			procedure Popup(where: TPoint); overload;
			procedure Popup(parentView: TView); overload;
			
			destructor Destroy; override;	

		protected
			procedure Initialize; override;
			procedure LayoutSubviews; override;
			procedure DrawSelection(rect: TRect); virtual;
			procedure HandleCloseEvent(event: TEvent); override;
			function GetItemFrame(item: TMenuItem): TRect; virtual;
		private
			font: IFont;
			margin: TVec2i;
			itemHeight: integer;
			minimumWidth: integer;
			popupOrigin: TVec2i;
	end;
	TMenuClass = class of TMenu;

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
			procedure SelectItemWithTag(tag: integer);
			procedure SelectItemWithTitle(title: string);

			function SelectedItem: TMenuItem;
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

		private
			procedure HandleWindowWillClose(window: TWindow);
			procedure HandleMenuWillSelectItem(menu: TMenu; item: TMenuItem);
		private
			menu: TMenu;
			m_selectedItem: TMenuItem;
			pullsdown: boolean;
			procedure Popup;
	end;

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

function PollWindowEvents(constref event: pGLPT_MessageRec): boolean;
procedure UpdateWindows;

procedure Draw3PartImage(parts: TTextureArray; frame: TRect; vertical: boolean = false); 
procedure Draw9PartImage(parts: TTextureSheet; frame: TRect); 

implementation
uses
	StrUtils, Math;

function MainPlatformWindow: pGLPTwindow; inline;
begin
	result := GLCanvasState.window;
end;

type
	TWindowManifest = class
		private
			list: array[0..kWindowLevels - 1] of TWindowList;
			function GetWindow(level, index: integer): TWindow;
		public
			property Get[level, index: integer]: TWindow read GetWindow; default;
			function AvailableWindows: TWindowArray;
			function FindWindow(window: TWindow): boolean;
			function FrontWindow: TWindow;
			function FrontWindowOfAnyLevel: TWindow;
			procedure Update;
			function PollEvents(constref event: pGLPT_MessageRec): boolean;
			procedure Add(window: TWindow);
			procedure Remove(window: TWindow);
			procedure MoveToFront(window: TWindow);
			procedure AfterConstruction; override;
	end;

var
	WindowManifest: TWindowManifest;
	RootWindow: TView = nil;
	KeyWindow: TWindow;
	ScreenMouseLocation: TPoint;
	SubpixelAccuracyEnabled: boolean = false;
	SharedCursor: TWindowCursor;
	CurrentEvent: TEvent = nil;

{$define IMPLEMENTATION}
{$include include/ExtraTypes.inc}
{$include include/NotificationCenter.inc}
{$include include/GUIStyles.inc}
{$undef IMPLEMENTATION}

const
	kNormalPressDelay = 0.2;
	kLongPressDelay = 0.75;

function PollWindowEvents(constref event: pGLPT_MessageRec): boolean;
begin
	result := WindowManifest.PollEvents(event);
end;

procedure UpdateWindows;
begin
	WindowManifest.Update;
end;

//#########################################################
// WINDOW MANIFEST
//#########################################################

function TWindowManifest.FrontWindowOfAnyLevel: TWindow;
var
	level: integer;
	window: TWindow;
begin
	result := nil;
	for level := 0 to kWindowLevels - 1 do
		begin
			window := GetWindow(level, 0);
			if assigned(window) then
				exit(window);
		end;
end;

function TWindowManifest.FrontWindow: TWindow;
begin
	if list[kWindowLevelNormal].Count > 0 then
		result := list[kWindowLevelNormal][0]
	else
		result := nil;
end;

function TWindowManifest.FindWindow(window: TWindow): boolean;
var
	level, index: integer;
begin
	result := false;
	for level := 0 to kWindowLevels - 1 do
		for index := 0 to list[level].Count - 1 do
			if GetWindow(level, index) = window then
				exit(true);
end;

function TWindowManifest.AvailableWindows: TWindowArray;
var
	level, window: integer;
begin
	result := nil;
	for level := 0 to kWindowLevels - 1 do
		for window := list[level].Count - 1 downto 0 do
			result += [GetWindow(level, window)];
end;

procedure TWindowManifest.Update;
var
	level, index: integer;
	window: TWindow;
begin
	// TODO: push/pop view transform
	for level := 0 to kWindowLevels - 1 do
		for index := list[level].Count - 1 downto 0 do
			begin
				window := self[level, index];
				if window.IsHidden then
					continue;
				window.LayoutRoot;
				window.Update;
				// TODO: we can kill this once we make a render backend that doesn't need shaders
				SetViewTransform(0, 0, 1);
				window.DrawInternal(V2(0, 0));
				SetViewTransform(0, 0, 1);
			end;
end;

function TWindowManifest.PollEvents(constref event: pGLPT_MessageRec): boolean;
var
	window: TWindow;
	level: integer;
begin
	result := false;
	for level := kWindowLevels - 1 downto 0 do
		for window in list[level] do
			if not window.IsHidden then
				begin
					if window.PollEvent(event) then
						exit(true);
				end;
end;

procedure TWindowManifest.Add(window: TWindow);
begin
	list[window.GetWindowLevel].Add(window);
end;

procedure TWindowManifest.Remove(window: TWindow);
begin
	if KeyWindow = window then
		KeyWindow := nil;
	list[window.GetWindowLevel].Remove(window);
	if (KeyWindow = nil) and (FrontWindow <> nil) then
		KeyWindow := FrontWindow;
end;

function TWindowManifest.GetWindow(level, index: integer): TWindow;
begin
	result := list[level].Get(index);
end;

procedure TWindowManifest.MoveToFront(window: TWindow);
var
	level: integer;
begin
	level := window.GetWindowLevel;
	list[level].Move(list[level].IndexOf(window), 0);
end;

procedure TWindowManifest.AfterConstruction;
var
	i: integer;
begin
	for i := 0 to kWindowLevels - 1 do
		list[i] := TWindowList.Create;
end;

//#########################################################
// EVENT
//#########################################################

function TEvent.KeyCode: GLPT_Scancode;
begin
	result := msg^.params.keyboard.scancode;
end;

function TEvent.KeyboardModifiers: TShiftState;
begin
	result := msg^.params.keyboard.shiftstate;
end;

function TEvent.MouseModifiers: TShiftState;
begin
	result := msg^.params.mouse.shiftstate;
end;

function TEvent.KeyboardCharacter: char;
begin
	result := char(msg^.params.keyboard.keycode);
end;

function TEvent.ScrollWheel: TVec2;
begin
	result := V2(msg^.params.mouse.deltaX, msg^.params.mouse.deltaY);
end;

function TEvent.ClickCount: integer;
begin
	result := msg^.params.mouse.buttons;
end;

function TEvent.Location(system: TObject = nil): TPoint;
begin
	result := V2(msg^.params.mouse.x, msg^.params.mouse.y);
	if system <> nil then
		result := TView(system).ConvertPointFrom(result, RootWindow);
end;

procedure TEvent.Reject;
begin
	accepted := false;
	acceptedObject := nil;
end;

procedure TEvent.Accept(obj: TObject = nil);
begin
	accepted := true;
	acceptedObject := obj;
end;

constructor TEvent.Create(raw: pGLPT_MessageRec); 
begin
	msg := raw;
end;

constructor TInvocation.Create(callback: TInvocationCallbackClass; _params: TInvocationParams = nil);
begin
	callbackClass := callback;
	params := _params;
end;

constructor TInvocation.Create(callback: TInvocationCallbackProcedure; _params: TInvocationParams = nil);
begin
	callbackProcedure := callback;
	params := _params;
end;

constructor TInvocation.Create(callback: TInvocationCallbackNested; _params: TInvocationParams = nil);
begin
	callbackNested := callback;
	params := _params;
end;

procedure TInvocation.Invoke(withParams: TInvocationParams = nil);
var
	newParams: TInvocationParams;
begin
	if assigned(withParams) then
		newParams := withParams
	else
		newParams := params;

	if callbackClass <> nil then
		callbackClass(newParams)
	else if callbackProcedure <> nil then
		callbackProcedure(newParams)
	else if callbackNested <> nil then
		callbackNested(newParams)
	else
		halt(-1);
end;


//#########################################################
// VIEW
//#########################################################

function TView.StartDrag(face: TTexture; event: TEvent; offset: TVec2; data: TMap): TDraggingSession;
begin
	// TODO: drag and drop needs to be implemented in GLPT
	//result := TDraggingSession.StartDrag(self, face, event, offset, data);
end;	

function TView.InputHit(event: TEvent): boolean;
begin
	result := GetBounds.ContainsPoint(event.Location(self));
end;

function TView.ContainsPoint(point: TPoint): boolean;
begin
	result := GetBounds.ContainsPoint(point);
end;

function TView.ContainsRect(rect: TRect): boolean;
begin
	result := GetBounds.ContainsRect(rect);
end;

function TView.IntersectsRect(rect: TRect): boolean;
begin
	result := GetBounds.IntersectsRect(rect);
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
		system := RootWindow;

	if system = self then
		exit(rect)
	else
		result := RectMake(-maxInt, -maxInt, 0, 0);

	if Supports(system, ICoordinateConversion, delegate) then
		if delegate.GetParentCoordinateSystem <> GetParentCoordinateSystem then
			begin
				result.origin.x := rect.origin.x + (GetLocation.x);
				result.origin.y := rect.origin.y + (GetLocation.y);
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
		system := RootWindow;

	if system = self then
		exit(rect)
	else
		result := RectMake(-maxInt, -maxInt, 0, 0);

	if Supports(system, ICoordinateConversion, delegate) then
		if delegate.GetParentCoordinateSystem <> GetParentCoordinateSystem then
			begin
				result.origin.x := rect.origin.x - (GetLocation.x * GetResolution);
				result.origin.y := rect.origin.y - (GetLocation.y * GetResolution);
				result.size := rect.size * GetResolution;
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
			//view.LayoutSubviews;
			HandleSubviewsChanged;
		end;
	DisplayNeedsUpdate;
	LayoutSubviews;
end;

procedure TView.AddSubview(view: TView);
begin
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

procedure TView.LayoutSubviews;
var
	child: TView;
begin
	if (GetParent <> nil) and (GetAutoresizingOptions <> []) then
		AutoResize;

	for child in subviews do
		begin
			child.LayoutSubviews;
			child.m_needsLayoutSubviews := false;
		end;

	m_needsLayoutSubviews := false;
end;

{ Private layout method which is always called from the window. }
procedure TView.LayoutRoot;
var
	child: TView;
begin
	for child in subviews do
		begin
			child.LayoutIfNeeded;
			child.LayoutRoot;
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

function TView.FindSubview(withTag: integer): TView;
begin
	result := nil;
	FindSubviewDeep(withTag, result);
end;

procedure TView.FindSubviewDeep(withTag: integer; var ioView);
var
	child: TView;
	view: TView absolute ioView;
begin
	if subviews <> nil then
		for child in subviews do
			if child.GetTag = withTag then
				begin
					view := child;
					break;
				end
			else if child.subviews.Count > 0 then
				begin
					child.FindSubviewDeep(withTag, ioView);
					if view <> nil then
						break;
				end;
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
	TNotificationCenter.DefaultCenter.PostNotification(kNotificationFrameChanged, self);
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
			//NeedsLayoutSubviews;

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
			initialMargin.left := newFrame.MinX;
			initialMargin.top := newFrame.MinY;
			initialMargin.right := enclosingFrame.Width - newFrame.MaxX;
			initialMargin.bottom := enclosingFrame.Height - newFrame.MaxY;

			initialRelative.origin.x := initialMargin.left / enclosingFrame.Width;
			initialRelative.origin.y := initialMargin.top / enclosingFrame.Height;

			initialRelative.size.x := newFrame.Width / enclosingFrame.Width;
			initialRelative.size.y := newFrame.Height / enclosingFrame.Height;

			//writeln(classname, ' margin: ', initialMargin.tostr, ' initialRelativeMargin: ', initialRelativeMargin.tostr);
			didAutoResize := true;
		end;

	// relative origins
	if TAutoresizingOption.RelativeXMargin in GetAutoresizingOptions then
		resizedFrame.origin.x := initialRelative.origin.x * enclosingFrame.Width;

	if TAutoresizingOption.RelativeYMargin in GetAutoresizingOptions then
		resizedFrame.origin.y := initialRelative.origin.y * enclosingFrame.Height;

	// x margins
	if TAutoresizingOption.MinXMargin in GetAutoresizingOptions then
		resizedFrame.origin.x := initialMargin.left
	else if(TAutoresizingOption.MaxXMargin in GetAutoresizingOptions) and
				  not (TAutoresizingOption.WidthSizable in GetAutoresizingOptions) then
		resizedFrame.origin.x := enclosingFrame.width - initialMargin.right - newFrame.width;

	// y margins
	if TAutoresizingOption.MinYMargin in GetAutoresizingOptions then
		resizedFrame.origin.y := initialMargin.top
	else if(TAutoresizingOption.MaxYMargin in GetAutoresizingOptions ) and
				  not (TAutoresizingOption.HeightSizable in GetAutoresizingOptions) then
		resizedFrame.origin.y := enclosingFrame.height - initialMargin.bottom - newFrame.height;

	// width
	if TAutoresizingOption.WidthSizable in GetAutoresizingOptions then
		begin
			if TAutoresizingOption.MaxXMargin in GetAutoresizingOptions then
				resizedFrame.size.x := (enclosingFrame.Width - resizedFrame.MinX) - initialMargin.right
			else
				resizedFrame.size.x := initialRelative.size.x * enclosingFrame.Width;
		end;
	
	// height
	if TAutoresizingOption.HeightSizable in GetAutoresizingOptions then
		begin
			if TAutoresizingOption.MaxYMargin in GetAutoresizingOptions then
				resizedFrame.size.y := (enclosingFrame.Height - resizedFrame.MinY) - initialMargin.bottom
			else
				resizedFrame.size.y := initialRelative.size.y * enclosingFrame.Height;
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

procedure TView.HandleWillAddToWindow(window: TWindow);
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
			if GetWindow <> TWindow.FrontWindow then
				exit;
			
			for child in subviews do
				begin
					child.HandleMouseDown(event);
					if event.IsAccepted then
						exit;
				end;
		end;
end;

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

			if SharedCursor.hover <> self then
				begin
					HandleMouseEntered(event);
					if event.IsAccepted then
						begin
							if assigned(SharedCursor.hover) then
								begin
									//writeln('exited: ', SharedCursor.hover.classname);	
									SharedCursor.hover.HandleMouseExited(event);
								end;
							//writeln('entered: ', classname);
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
	SetAutoresizingOptions([TAutoresizingOption.MinXMargin, TAutoresizingOption.MinYMargin]);
end;

function TView.GetClipRect: TRect; 
begin
	if m_clipRect.size = 0 then
		result := GetBounds
	else
		result := m_clipRect;
end;

procedure TView.PushClipRect(rect: TRect);
begin
	rect := ConvertRectTo(rect, RootWindow);
	rect := RectFlip(rect, GetViewPort);
	GLCanvas.PushClipRect(rect);
end;

procedure TView.DrawInternal(parentOrigin: TVec2);

	function ShouldDraw: boolean; inline;
	begin
		if assigned(GetParent) then
			result := GetParent.ShouldDrawSubview(self)
		else
			result := true;
	end;

var
	child: TView;
begin
	// TODO: we need to flush for SetViewTransform since it's a shader property
	// once we have a render backend for GUI's we can add the view transform into the root functions
	renderOrigin := GetFrame.origin + parentOrigin;
	FlushDrawing;
	if not IsHidden then
		begin
			if enableClipping then
				PushClipRect(GetClipRect);
			SetViewTransform(renderOrigin.x, renderOrigin.y, 1);
			if ShouldDraw then
				Draw;
			FlushDrawing;
			if enableClipping then
				PopClipRect;
		end
	else
		begin
			if assigned(subviews) then
				for child in subviews do
					child.DrawInternal(renderOrigin);
		end;
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
	result := not GetBounds.ContainsRect(view.GetFrame);
end;

function TView.ShouldDrawSubview(view: TView): boolean;
begin
	result := true;
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

//#########################################################
// WINDOW
//#########################################################

function TWindow.GetDelegate: TObject;
begin
	result := delegate;
end;

function TWindow.GetParentCoordinateSystem: TObject;
begin
	result := RootWindow;
end;

function TWindow.GetContentFrame: TRect;
begin
	result := RectMake(0, 0, contentSize.Width, contentSize.Height);
end;

function TWindow.GetFocusedView: TView;
begin
	result := focusedView;
end;

function TWindow.GetContentSize: TVec2;
begin
	result := contentSize;
end;

procedure TWindow.SetFocusedView(newValue: TView);
begin
	if focusedView <> nil then
		focusedView.HandleWillResignFocus;
	newValue.HandleWillBecomeFocused;
	focusedView := newValue;
	newValue.HandleDidBecomeFocused;
	TNotificationCenter.DefaultCenter.PostNotification(kNotificationFocusChanged, newValue);
end;

procedure TWindow.SetContentSize(newValue: TVec2);
begin
	contentSize := newValue;
	SetSize(V2(contentSize.width, contentSize.height));
end;

procedure TWindow.SetContentView(newValue: TView);
begin
	newValue.SetAutoresizingOptions([TAutoresizingOption.MinXMargin, TAutoresizingOption.MinYMargin, TAutoresizingOption.WidthSizable, TAutoresizingOption.HeightSizable]);
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

procedure TWindow.SetWindowLevel(newValue: integer);
begin
	windowLevel := newValue;
end;

procedure TWindow.SetModal(newValue: boolean);		
begin
	modal := newValue;
end;

function TWindow.GetWindowLevel: integer;
begin
	result := windowLevel;
end;

procedure TWindow.PerformClose(params: TInvocationParams);
begin
	// TODO: ask delegate to close
	Close;
end;

procedure TWindow.Center;
begin	
	wantsCenter := false;
	SetLocation(RectCenter(GetBounds, ScreenRect).origin);
end;

procedure TWindow.MakeKey; 
begin
	if assigned(KeyWindow) then
		KeyWindow.HandleWillResignKeyWindow;
	HandleWillbecomeKeyWindow;
	GLGUI.KeyWindow := self;
	HandleDidbecomeKeyWindow;
	OrderFront;
end;

procedure TWindow.MakeKeyAndOrderFront; 
begin
	MakeKey;
	OrderFront;
end;

procedure TWindow.OrderFront;
var
	window: TWindow;
begin
	
	if not WindowManifest.FindWindow(self) then
		HandleDidAddToScreen;

	// already ordered front
	if not IsFloating and IsFront then
		begin
			SetHidden(false);
			exit;
		end;
			
	if not IsFloating then
		begin
			window := TWindow.FrontWindow;
			if window <> nil then
				window.HandleWillResignFrontWindow;

			SetHidden(false);
			HandleWillBecomeFrontWindow;
			WindowManifest.MoveToFront(self);
			HandleDidBecomeFrontWindow;
		end;

	if assigned(CurrentEvent) then
		TestMouseTracking(CurrentEvent);
end;

function TWindow.IsFront: boolean;
begin
	result := TWindow.FrontWindow = self;
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
	result := windowLevel > kWindowLevelNormal;
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

procedure TWindow.HandleWillResignFrontWindow;
begin
end;

procedure TWindow.HandleWillBecomeFrontWindow;
begin
end;

procedure TWindow.HandleDidBecomeFrontWindow;
begin
end;

procedure TWindow.HandleWillClose;
var
	windowDelegate: IWindowDelegate;
begin
	if Supports(delegate, IWindowDelegate, windowDelegate) then
		windowDelegate.HandleWindowWillClose(self);
end;

function TWindow.HandleDraggingEntered(session: TDraggingSession): integer;
begin
	// NOTE: this is kind of hack for now since dragging requires the parent
	// implement dragging so children can be checked for
	result := kDragOperationNone;
end;

function TWindow.HandleDraggingUpdated(session: TDraggingSession): integer;
begin
	result := kDragOperationNone;
end;

procedure TWindow.HandleDraggingExited(session: TDraggingSession);
begin
end;

function TWindow.HandlePerformDragOperation(session: TDraggingSession): boolean;
begin
	result := false;
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
		result :=
		 true;
end;

{ Fullscreen constructor }
constructor TWindow.Create;
begin
	Initialize;
	SetMoveableByBackground(false);
	SetFrame(TWindow.ScreenRect);
end;

class function TWindow.ScreenRect: TRect;
var
	width, height: integer;
begin
	result.origin := 0;
	result.size := 0;
	GLPT_GetFrameBufferSize(MainPlatformWindow, width, height);

	result.size.x := width;
	result.size.y := height;
end;

function TWindow.ShouldMoveByBackground(event: TEvent): boolean;
begin
	result := moveableByBackground and IsKey{(WindowManifest.FrontWindowOfAnyLevel <> self)};
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

procedure TWindow.HandleMouseMoved(event: TEvent);
var
	child: TView;
	outView: TView;
begin
	if not AcceptsMouseMovedEvents then
		exit;
	
	// block events that are from a window behind the front window
	if (self <> TWindow.FrontWindow) and TWindow.FrontWindow.InputHit(event) then
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

procedure TWindow.HandleKeyDown(event: TEvent);
begin

	if (event.KeyCode = GLPT_SCANCODE_RETURN) and
		 (defaultButton <> nil) then
		begin
			TButton(defaultButton).InvokeAction;
			event.Accept(self);
			exit;
		end;
		
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
		
	pressOrigin := V2(-1, -1);
	dragOrigin := V2(-1, -1);
end;

procedure TWindow.HandleInputDragged(event: TEvent);
var
	where, newPos: TPoint;
begin	
	pressOrigin := V2(-1, -1);

	if not event.IsAccepted and(dragOrigin <> -1) then
		begin
			where := event.Location(self);
			newPos := GetLocation + V2(where.x - dragOrigin.x, where.y - dragOrigin.y);
			SetLocation(newPos);
			event.Accept(self);
		end;
		
	inherited HandleInputDragged(event);
end;

procedure TWindow.HandleInputStarted(event: TEvent);
var
	front: TWindow;
begin		
	pressOrigin := event.Location;
	front := TWindow.FrontWindow;

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
	TNotificationCenter.DefaultCenter.PostNotification(kNotificationWindowWillOpen, self);
				
	WindowManifest.Add(self);
	
	if wantsCenter then
		Center;	
	
	TNotificationCenter.DefaultCenter.PostNotification(kNotificationWindowDidOpen, self);
end;

procedure TWindow.HandleFrameDidChange(previousFrame: TRect);
begin
	wantsCenter := false;
	inherited HandleFrameDidChange(previousFrame);
end;

procedure TWindow.HandleWillRemoveFromScreen;
begin	
	TNotificationCenter.DefaultCenter.PostNotification(kNotificationWindowWillClose, nil, pointer(self));
	WindowManifest.Remove(self);
	TNotificationCenter.DefaultCenter.PostNotification(kNotificationWindowDidClose, nil, pointer(self));
end;

procedure TWindow.Close;
begin	
	HandleWillClose;
	HandleWillRemoveFromScreen;
end;

procedure TWindow.Initialize;
begin
	inherited Initialize;
	
	dragOrigin := -1;
end;

destructor TWindow.Destroy;
begin
	delegate := nil;
	inherited;
end;

procedure TWindow.SendDefaultAction;
begin
	if defaultButton <> nil then
		TButton(defaultButton).InvokeAction;
end;

procedure TWindow.AdvanceFocus;
var
	child: TView;
begin
	for child in subviews do
		if child.canAcceptFocus and(child <> focusedView) then	
			begin
				child.GiveFocus;
				break;
			end;
end;

function TView.PollEvent(constref raw: pGLPT_MessageRec): boolean;
var
	event: TEvent;
begin
	event := TEvent.Create(raw);
	result := false;
	if CurrentEvent <> nil then
		CurrentEvent.Free;
	CurrentEvent := event;

	ScreenMouseLocation := event.Location;

	case raw^.mcode of
		GLPT_MESSAGE_RESIZE:
			begin
				RootWindow.SetSize(V2(raw^.params.rect.width, raw^.params.rect.height));
			end;
		GLPT_MESSAGE_MOUSEDOWN:
			begin
				SharedCursor.mouseDown := true;
				HandleMouseDown(event);
				if event.IsAccepted then
					exit(true);

				HandleInputStarted(event);
				if event.IsAccepted then
					exit(true);
			end;
		GLPT_MESSAGE_MOUSEUP:
			begin
				SharedCursor.mouseDown := false;
				HandleMouseUp(event);
				if event.IsAccepted then
					exit(true);

				HandleInputEnded(event);
				if event.IsAccepted then
					exit(true);
			end;
		GLPT_MESSAGE_MOUSEMOVE:
			begin
				if SharedCursor.mouseDown then
					begin
						HandleMouseDragged(event);
						if event.IsAccepted then
							exit(true);
					
						HandleInputDragged(event);
						if event.IsAccepted then
							exit(true);
					end
				else if AcceptsMouseMovedEvents then
					begin
						HandleMouseMoved(event);
						if event.IsAccepted then
							exit(true);
					end;

				TestMouseTracking(event);

				// mouse went outside of hover targert
				if assigned(SharedCursor.hover) and not SharedCursor.hover.InputHit(event) then
					begin
						SharedCursor.hover.HandleMouseExited(event);
						SharedCursor.hover := nil;
					end;
			end;
		GLPT_MESSAGE_SCROLL:
			begin
				HandleMouseWheelScroll(event);
				if event.IsAccepted then
					exit(true);
			end;
	  GLPT_MESSAGE_KEYPRESS:
	    begin
	    	if assigned(KeyWindow) then
		    	KeyWindow.HandleKeyDown(event);
		    exit(true);
	    end;
	 end;
	
	//event.Free;
	//CurrentEvent := nil;
end;

class function TWindow.MouseLocation: TPoint;
begin
	result := ScreenMouseLocation;
end;

class function TWindow.AvailableWindows: TWindowArray;
begin
	result := WindowManifest.AvailableWindows;
end;

class function TWindow.FindWindow(ofClass: TWindowClass): TWindow;
var
	window: TWindow;
begin
	result := nil;
	for window in AvailableWindows do
		if window.IsMember(ofClass) then
			exit(window);
end;

class function TWindow.FindWindowAtMouse: TWindow;
var
	window: TWindow;
begin
	result := nil;
	for window in AvailableWindows do
		if window.GetFrame.ContainsPoint(TWindow.MouseLocation) then
			exit(window);
end;

class function TWindow.IsFrontWindowBlockingInput(event: TEvent = nil): boolean;
var
	window: TWindow;
begin
	window := FrontWindow;
	if window <> nil then
		begin
			result := not window.IsFloating;
			if event <> nil then
				result := window.InputHit(event);
		end
	else
		result := false;
end;

class function TWindow.DoesFrontWindowHaveKeyboardFocus: boolean;
var
	window: TWindow;
begin
	window := FrontWindow;
	if window <> nil then
		result := window.focusedView <> nil
	else
		result := false;
end;

class function TWindow.KeyWindow: TWindow;
begin
	result := GLGUI.KeyWindow;
end;

class function TWindow.FrontWindow: TWindow;
begin
	result := WindowManifest.FrontWindow;
end;

//#########################################################
// CONTEXTUAL WINDOW
//#########################################################
constructor TPopover.Create(inDelegate: TWindow; inContentSize: TVec2i);
begin
	SetContentSize(inContentSize);
	SetDelegate(inDelegate);
	Initialize;
end;

procedure TPopover.UpdatePosition;
var
	rect, newFrame: TRect;
	margin: float;
begin
	if positioningView <> nil then
		rect := positioningView.ConvertRectTo(positioningRect, nil)
	else
		rect := positioningRect;
		
	margin := 8;

	case preferredEdge of
		TRectEdgeMinX:
			begin
				newFrame := GetFrame;
				newFrame.origin.x := rect.origin.x - (self.GetWidth + margin);
				newFrame.origin.y := rect.origin.y + (rect.height / 2 - self.GetHeight / 2);
				SetFrame(newFrame);
			end;
		TRectEdgeMaxX:
			begin
				newFrame := GetFrame;
				newFrame.origin.x := rect.MaxX + margin;
				newFrame.origin.y := rect.origin.y + (rect.height / 2 - self.GetHeight / 2);
				SetFrame(newFrame);
			end;
		TRectEdgeMinY:
			begin
				newFrame := GetFrame;
				newFrame.origin.x := rect.origin.x + (rect.width / 2 - self.GetWidth / 2);
				newFrame.origin.y := rect.origin.y - (self.GetHeight + margin);
				SetFrame(newFrame);
			end;
		TRectEdgeMaxY:
			begin
				newFrame := GetFrame;
				newFrame.origin.x := rect.origin.x + (rect.width / 2 - self.GetWidth / 2);
				newFrame.origin.y := rect.maxY + margin;
				SetFrame(newFrame);
			end;
		TRectEdgeAny:
			begin
				SetLocation(rect.origin);
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
	
	behavior := TPopoverBehavior.ApplicationDefined;
	windowLevel := kWindowLevelUtility;
	// TODO: kill these dumb ass singltons
	TNotificationCenter.DefaultCenter.ObserveNotification(kNotificationWindowWillOpen, @self.HandleWindowWillOpen, pointer(self));
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
	//	begin
	//		HandleCloseEvent(event);
	//		exit;
	//	end;
			
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

//#########################################################
// TAB VIEW ITEM
//#########################################################

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
	button.SizeToFit;
	SetView(button);
end;

//#########################################################
// TAB VIEW
//#########################################################

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

//#########################################################
// STATUS BAR
//#########################################################

procedure TStatusBar.SetCurrentValue(newValue: TScalar);
begin
	
end;

procedure TStatusBar.SetMaximumValue(newValue: TScalar);
begin
	
end;

procedure TStatusBar.SetMinimumValue(newValue: TScalar);
begin
	
end;

//#########################################################
// MATRIX VIEW
//#########################################################

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

//#########################################################
// MENU ITEM
//#########################################################

function TMenuItem.GetMenu: TMenu;
begin
	result := TMenu(GetParent);
end;

procedure TMenuItem.SetFont(newValue: IFont);
begin
	cell.SetFont(newValue);
end;

procedure TMenuItem.SetChecked(newValue: boolean);
begin
	checked := newValue;
end;

function TMenuItem.IsChecked: boolean;
begin
	result := checked;
end;

function TMenuItem.IsSelected: boolean;
begin
	result := selected;
end;

function TMenuItem.GetTitle: string;
begin
	result := cell.GetStringValue;
end;

function TMenuItem.GetTextSize: TVec2i;
begin
	result := cell.textView.GetTextSize;
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
			menu.Close;
		end;
	
	inherited HandleInputEnded(event);
end;

procedure TMenuItem.HandleMouseEntered(event: TEvent);
begin	
	selected := true;
	event.Accept(self);
end;

procedure TMenuItem.HandleMouseExited(event: TEvent);
begin	
	selected := false;
end;

procedure TMenuItem.DrawAccessory(rect: TRect);
begin
	if IsChecked then
		FillOval(RectCenter(RectMake(0,0,4,4), rect), RGBA(0, 0, 0, 0.9));
end;

function TMenuItem.GetAccessoryFrame: TRect;
begin
	result.origin := 0;
	result.size := V2(GetHeight, GetHeight);
end;

procedure TMenuItem.Draw;
begin
	if selected then
		menu.DrawSelection(GetBounds);
	DrawAccessory(GetAccessoryFrame);

  inherited;
end;

procedure TMenuItem.LayoutSubviews;
var
	newFrame: TRect;
	accessorWidth: float;
begin	
	inherited;

	if menu <> nil then
		begin
			cell.SizeToFit;

			// TODO: use this for indents
			accessorWidth := GetAccessoryFrame.Width;

			// resize cell
			newFrame := cell.GetFrame;
			newFrame.origin.x := {menu.margin.x}accessorWidth;
			newFrame.size.y := GetHeight;
			cell.SetFrame(newFrame);

			// resize menu item to fit cell
			newFrame := GetFrame;
			newFrame.size.width := cell.GetWidth + accessorWidth + menu.margin.x;
			newFrame.size.height := cell.GetHeight;
			SetFrame(newFrame);
		end;
end;

procedure TMenuItem.Initialize;
begin
	inherited;
	cell := TTextAndImageCell.Create;
	AddSubview(cell);
end;

constructor TMenuItem.Create(_title: string; _action: TInvocation);
begin
	Initialize;
	cell.SetStringValue(_title);
	SetAction(_action);
end;

//#########################################################
// MENU
//#########################################################

constructor TMenu.Create;
begin
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

procedure TMenu.Popup(where: TPoint);
begin
	LayoutSubviews;
	Show(RectMake(where, 0, 0), nil, TRectEdgeAny);
	UpdatePosition;
	popupOrigin := TWindow.MouseLocation;
end;

procedure TMenu.Popup(parentView: TView);
begin
	Assert(parentView <> nil, 'parent view must not be nil');
	LayoutSubviews;
	Show(parentView.GetBounds, parentView, TRectEdgeMaxY);
	UpdatePosition;
	popupOrigin := TWindow.MouseLocation;
end;

procedure TMenu.HandleCloseEvent(event: TEvent);
begin
	Close;
	event.Accept(self);
end;

function TMenu.GetItemFrame(item: TMenuItem): TRect;
begin
	if itemHeight = 0 then
		result := RectMake(0, margin.y, 0, item.GetTextSize.Height + 4)
	else
		result := RectMake(0, margin.y, 0, itemHeight);
end;

procedure TMenu.DrawSelection(rect: TRect); 
begin
	FillRect(rect, RGBA(0, 0, 0.7, 0.4));
end;

procedure TMenu.LayoutSubviews;
var
	item: TMenuItem;
	widestItem: integer = 0;
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

			item.LayoutSubviews;

			if widestItem < item.GetWidth then
				widestItem := trunc(item.GetWidth);
		end;

	if widestItem < minimumWidth then
		widestItem := minimumWidth;

	itemFrame := GetItemFrame(item);
	itemFrame.size.width := widestItem;

	for item in items do
		begin			
			item.SetFrame(itemFrame);
			itemFrame.origin.y += itemFrame.height;
		end;
	
	// resize menu to fit all items
	SetSize(itemFrame.Width, (itemFrame.MaxY - itemFrame.Height) + margin.y);
end;

procedure TMenu.Initialize;
begin
	inherited Initialize;
	
	itemHeight := 0;
	margin := V2(8, 8);
	minimumWidth := 0;
	items := TMenuItemList.Create;
	SetBackgroundColor(RGBA(1.0, 0.75));
end;

destructor TMenu.Destroy;
begin
	items.Free;
	font := nil;
	inherited;
end;

//#########################################################
// BAR ITEM
//#########################################################

procedure TBarItem.SetView(newValue: TView);
begin
	newValue.SetAutoresizingOptions([TAutoresizingOption.MinXMargin, TAutoresizingOption.MinYMargin, TAutoresizingOption.WidthSizable, TAutoresizingOption.HeightSizable]);
	SetWidth(newValue.GetWidth);
	AddSubview(newValue);
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

//#########################################################
// ITEM BAR
//#########################################################

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
	FillRect(GetBounds, RGBA(0,0,0,0.25));

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
			writeln('item ', rect.tostr);
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
end;

destructor TItemBar.Destroy;
begin
	items.Free;
end;


//#########################################################
// CELL
//#########################################################

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

//#########################################################
// SECTION CELL
//#########################################################

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

//#########################################################
// TEXT AND IMAGE CELL
//#########################################################

procedure TTextAndImageCell.SetStringValue(newValue: string);
begin
	inherited SetStringValue(newValue);
	textView.SetStringValue(newValue);
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

function TTextAndImageCell.GetImageValue: TTexture;
begin
	result := TTexture(imageView.frontImage);
end;

function TTextAndImageCell.GetStringValue: string;
begin
	result := textView.GetStringValue;
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
	rect,
	imageFrame: TRect;
begin
	imageFrame := GetImageFrame;

	rect := GetBounds;
	rect.origin.x += imageFrame.width + imageTitleMargin;
	rect.size.x -= imageFrame.height;
	rect.size.height := textView.GetTextSize.height;
	if GetBounds.size.height > rect.size.height then
		result := RectCenterY(rect, GetBounds)
	else
		result := rect;
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

//#########################################################
// SCROLLER
//#########################################################

procedure TScroller.Initialize;
begin
	inherited;
	range := TRangeInt.Make(0, 100);
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
	if scrollView <> nil then
		if IsVertical then
			begin
				total := scrollView.GetScrollableFrame.Height;
				percent := currentValue / range.Total;
				scrollView.SetScrollOrigin(V2(0, total * percent), false, true);
			end
		else
			begin
				total := scrollView.GetScrollableFrame.Width;
				percent := currentValue / range.Total;
				scrollView.SetScrollOrigin(V2(total * percent, 0), true, false);
			end;
end;

function TScroller.GetTrackFrame: TRect; 
begin
	result := inherited;
	//if IsVertical then
	//	result := RectMake(0, {scrollerParts.upButtonNormal.GetHeight}20, GetWidth, GetHeight - ({scrollerParts.upButtonNormal.GetHeight}20 * 2))
	//else
	//	result := RectMake(0, 0, GetWidth, GetHeight);
end;

//#########################################################
// SLIDER
//#########################################################

constructor TSlider.Create(min, max: integer; _frame: TRect);
begin
	range := TRangeInt.Make(min, max);
	SetFrame(_frame);
	Initialize;
end;

procedure TSlider.SetCurrentValue(newValue: integer);
begin
	currentValue := newValue;
	currentValue := interval * Ceil(currentValue / interval);
	//percent := currentValue / range.Total;
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

function TSlider.GetCurrentValue: integer;
begin
	result := currentValue;
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

function TSlider.ClosestTickMarkToValue(value: integer): integer;
begin
	result := Ceil(currentValue / interval);
end;

function TSlider.RectOfTickMarkAtIndex(index: integer): TRect;
begin
	result := tickMarkFrames[index];
end;

function TSlider.ValueAtRelativePosition(percent: single): integer;
begin
	percent := Clamp(percent, 0, 1);
	result := range.ValueOfPercent(percent);//PercentOfRange(range, percent);
	result := interval * Ceil(result / interval);
end;

procedure TSlider.Draw;
var
	percent: float;
	rect: TRect;
	i: integer;
begin

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
	percent := currentValue / range.Total;
	if IsVertical then
		begin
			handleFrame := RectMake(0, GetTrackFrame.MinY + (percent * GetTrackSize.height), GetHandleFrame.Width, GetHandleFrame.Height);
			handleFrame := RectCenterX(handleFrame, GetBounds);
			if tickMarks > 1 then
				begin
					handleFrame := RectCenterY(handleFrame, tickMarkFrames[ClosestTickMarkToValue(currentValue)]);
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
					handleFrame := RectCenterX(handleFrame, tickMarkFrames[ClosestTickMarkToValue(currentValue)]);
					//handleFrame.origin := tickMarkFrames[ClosestTickMarkToValue(currentValue)].origin;
					//handleFrame.origin += GetHandleFrame.origin;
				end
			else
				handleFrame.origin += GetHandleFrame.origin;
		end;
	DrawHandle(handleFrame);
end;

procedure TSlider.HandleInputStarted(event: TEvent);
var
	where: TPoint;
begin
	inherited;

	if event.IsAccepted then
		exit;


	//if InputHit(event) then
	//	begin
	//		where := (event.Location(self) - GetTrackFrame.origin);
	//		if IsVertical then
	//			currentValue := ValueAtRelativePosition(where.y / GetTrackSize.height)
	//		else
	//			currentValue := ValueAtRelativePosition(where.x / GetTrackSize.width);
	//		if liveUpdate then
	//			HandleValueChanged;
	//		event.Accept;
	//		dragging :=true;

	//		if handleFrame.ContainsPoint(event.Location(self)) then
	//			dragOrigin := event.Location(self) - handleFrame.origin;
	//	end;

	if handleFrame.ContainsPoint(event.Location(self)) then
		begin
			dragOrigin := event.Location(self) - handleFrame.origin;
			event.Accept;
			dragging := true;
		end
	else if InputHit(event) then
		begin
			where := (event.Location(self) - GetTrackFrame.origin);
			if IsVertical then
				currentValue := ValueAtRelativePosition(where.y / GetTrackSize.height)
			else
				currentValue := ValueAtRelativePosition(where.x / GetTrackSize.width);
			if liveUpdate then
				HandleValueChanged;
			event.Accept;
			dragging := true;
		end;

	writeln('input started at ', currentValue);
end;

procedure TSlider.HandleInputDragged(event: TEvent);
var
	where: TPoint;
begin
	inherited HandleInputDragged(event);

	if IsDragging then
		begin
			where := (event.Location(self) - GetTrackFrame.origin) - dragOrigin;
			if IsVertical then
				currentValue := ValueAtRelativePosition(where.y / GetTrackSize.height)
			else
				currentValue := ValueAtRelativePosition(where.x / GetTrackSize.width);
			if liveUpdate then
				HandleValueChanged;
			event.Accept;
		end;
end;

procedure TSlider.HandleInputEnded(event: TEvent);
begin
	inherited HandleInputEnded(event);

	// snap to interval
	if interval > 1 then
		SetCurrentValue(GetCurrentValue);

	writeln('new value: ', GetCurrentValue, ' tick=', ClosestTickMarkToValue(GetCurrentValue)+1);
	if not liveUpdate then
		HandleValueChanged;

	InvokeAction;
	dragging := false;
end;

procedure TSlider.Initialize; 
begin
	inherited;

	interval := 1;
	liveUpdate := true;
end;

//#########################################################
// SCROLL VIEW
//#########################################################

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
		verticalScroller.SetCurrentValue(verticalScroller.range.ValueOfPercent(scrollOrigin.y / GetScrollableFrame.Height));
	
	if assigned(horizontalScroller) and axisX then
		horizontalScroller.SetCurrentValue(horizontalScroller.range.ValueOfPercent(scrollOrigin.x / GetScrollableFrame.Width));

	if Supports(contentView, IScrollingContent, delegate) then
		delegate.HandleScrollingContentChanged(self);
end;

procedure TScrollView.HandleInputStarted(event: TEvent);
begin
	inherited HandleInputStarted(event);

	if event.IsAccepted then
		exit;

	if InputHit(event) and enableDragScrolling then
		begin
			dragScrollingDown := event.Location(self);
			dragScrollingOrigin := scrollOrigin;
			// TODO: we need to make an option for this for touch only
			dragScrolling := false;
			event.Accept;
		end;
end;

procedure TScrollView.HandleInputEnded(event: TEvent);
begin
	inherited HandleInputEnded(event);

	if event.IsAccepted then
		exit;
	
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

	if event.IsAccepted then
		exit;

	if dragScrolling and InputHit(event) then
		begin
			where := event.Location(self);
			
			//if swipeTimer = nil then
			//	swipeTimer := InvokeMethodAfterDelay(0.25, @TScrollView.HandleSwipeTimer);
			
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
	if contentView.IsMember(TTextView) then
		begin
			TTextView(contentView).SetMaximumWidth(Trunc(GetWidth));
			TTextView(contentView).SetWidthTracksContainer(true);
			SetContentSize(contentView.GetSize);
		end
	else if contentView.IsMember(TMatrixView) then
		begin
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

	TNotificationCenter.DefaultCenter.ObserveNotification(kNotificationFrameChanged, @self.HandleContentViewFrameChanged);
end;

//#########################################################
// CELL VIEW
//#########################################################

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
	oldCell: TCell;
begin
	if not cell.IsSelectable or(selectionType = TTableViewSelection.None) then
		begin
			//if Supports(GetDelegate, ICellViewDelegate, delegate) then
			//	delegate.HandleSelectionChanged(self);
			exit;
		end;
		
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

//#########################################################
// TABLE VIEW
//#########################################################

class operator TTableColumn.= (left: TTableColumn; right: TTableColumn): boolean;
begin
	result := left.id = right.id;
end;

procedure TTableView.SetLastColumnTracksWidth(newValue: boolean);
begin
	lastColumnTracksWidth := newValue;
end;

procedure TTableView.SetDataSource(newValue: TObject);
begin
	m_dataSource := newValue;
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

function TTableView.EnclosingScrollView: TScrollView;
begin
	// TODO: cache this
	result := FindParent(TScrollView) as TScrollView;
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
	writeln('reload ', firstRow,' to ', rowCount, ' total=',totalRows);

	// TODO: update if rows change(from datasoure or frame change)
	if rowCount <> cells.Count then
		begin
			writeln('allocate new cells -> ', rowCount);

			for cell in cells do
				cell.RemoveFromParent;
			cells.Free;

			cells := TCellList.Create;
			for i := 0 to rowCount - 1 do
				begin
					cell := nil;

					// TODO: add default column if user didn't add one yet
					Assert(columns.Count > 0, 'Must add a valid column');

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
	firstRow, 
	maxRows: integer;
	scrollView: TScrollView;
	column: integer;
begin
	
	// TODO: save this as the visible range. not sure what the other idea I had was...
	// determine the visible cell range
	scrollView := EnclosingScrollView;
	if assigned(scrollView) then
		begin
			firstRow := trunc(abs(scrollView.GetVisibleRect.minY) / (cellHeight + cellSpacing));
			maxRows := RoundUp(scrollView.GetClipRect.Height / (cellHeight + cellSpacing)) + 1;
		end
	else
		begin
			firstRow := 0;
			maxRows := RoundUp(GetHeight / (cellHeight + cellSpacing)) + 1;
		end;


	// load cells from data source
	if Supports(m_dataSource, ITableViewDataSource, dataSource) then
		begin
			ReloadCellsFromDataSource(dataSource, firstRow, maxRows);

			cellFrame := RectMake(0, firstRow * (cellHeight + cellSpacing), GetWidth, 0);

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

			cellsNeedArranging := false;
			arrangingCells := true;
			totalHeight := 0;

			cellFrame := RectMake(0, 0, GetWidth, 0);

			for i := 0 to cells.Count - 1 do
				begin
					cell := cells[i];

					cell.rowIndex := i;
					cell.SetHidden(false);

					if cell.GetParent = nil then
						AddSubview(cell);
					
					// TODO: this doesn't work
					//if cell.GetHeight = 0 then	
					//	cellFrame.size.height := cellHeight
					//else
					//	cellFrame.size.height := cell.GetHeight;
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

			arrangingCells := false;
		end;
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
			result := scrollView.GetBounds.IntersectsRect(rect);
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
	FillRect(GetBounds, RGBA(0,0.6,0,0.2));

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
	writeln(event.KeyCode);
	case event.KeyCode of
		GLPT_SCANCODE_UP:
			begin
				//if selection.Count > 0 then
				//	index := cells.IndexOf(selection[0]) - 1
				//else
				//	index := 0;
				//if index < 0 then
				//	index := 0;
				//SelectCell(index);
				//if not visibleRange.Contains(index) then
				//	begin
				//		//ScrollUp;
				//	end;
				event.Accept(self);
			end;
		GLPT_SCANCODE_DOWN:
			begin
				//if selection.Count > 0 then
				//	index := cells.IndexOf(selection[0]) + 1
				//else
				//	index := 0;
				//if index > cells.Count - 1 then
				//	index := cells.Count - 1;
				//SelectCell(index);
				//if not visibleRange.Contains(index) then
				//	begin
				//		//ScrollDown;
				//	end;
				event.Accept(self);
			end;
	end;
end;

procedure TTableView.HandleFrameDidChange(previousFrame: TRect);
begin
	inherited HandleFrameDidChange(previousFrame);
	
	if not arrangingCells then
		ArrangeCells;
end;

procedure TTableView.HandleDidAddToParent(sprite: TView);
begin
	inherited HandleDidAddToParent(sprite);
	
	ArrangeCells;
end;

procedure TTableView.ScrollUp;
begin
end;

procedure TTableView.ScrollDown;
begin
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
	
	//RegisterMethod('ScrollUp', @TTableView.ScrollUp);
	//RegisterMethod('ScrollDown', @TTableView.ScrollDown);
	
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

//#########################################################
// TEXT VIEW
//#########################################################

constructor TTextView.Create(inFrame: TRect; text: string; inWidthTracksContainer: boolean = true; inFont: IFont = nil);
begin
	Initialize;
	SetFrame(inFrame);
	SetStringValue(text);
	SetFont(inFont);
	SetWidthTracksContainer(inWidthTracksContainer);
end;

procedure TTextView.SetFont(newValue: IFont);
begin
	textFont := newValue;
	if textColor.a = 0 then
		SetTextColor(textFont.PreferredTextColor);
	NeedsLayoutSubviews;
end;

procedure TTextView.SetHeightTracksContainer(newValue: boolean);
begin
	heightTracksContainer := newValue;
end;

// The width of the view tracks the width of the container(i.e. view scales by width and constrained by maximumWidth)
procedure TTextView.SetWidthTracksContainer(newValue: boolean);
begin
	widthTracksContainer := newValue;
	widthTracksView := false;
	NeedsLayoutSubviews;
end;

// The width of the container tracks the width of the view(text wraps to container)
procedure TTextView.SetWidthTracksView(newValue: boolean);
begin
	widthTracksView := newValue;
	widthTracksContainer := false;
	NeedsLayoutSubviews;
end;

procedure TTextView.SetTextAlignment(newValue: TTextAlignment);
begin
	textAlignment := newValue;
end;

procedure TTextView.SetEditable(newValue: boolean);
begin
	editable := newValue;
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


function TTextView.GetTextSize: TVec2;
begin
	// TODO: cache this result, only update if text changes
	Assert(IsReadyToLayout, 'text view must set font');
	result := MeasureText(textFont, GetStringValue, maximumWidth);
end;

function TTextView.GetFont: IFont;
begin
	result := textFont;
end;

function TTextView.HandleWillInsertCharacter(var c: char): boolean;
begin
	result := true;
end;

function TTextView.HandleWillDelete: boolean;
begin
	result := true;
end;

procedure TTextView.HandleKeyDown(event: TEvent);
var
	c: char;
begin
	if editable then
		begin
			if event.KeyCode = GLPT_SCANCODE_RETURN then
				begin
					if assigned(action) then
						InvokeAction
					else
						SetStringValue(GetStringValue + LineEnding);
				end
			else if(event.KeyCode = GLPT_SCANCODE_BACKSPACE) or 
						  (event.KeyCode = GLPT_SCANCODE_DELETE) and 
						  HandleWillDelete then
				begin
					// TODO: delete entire line
					if ssSuper in event.KeyboardModifiers then
						begin
							SetStringValue('')
						end
					else if(ssAlt in event.KeyboardModifiers) or (ssCtrl in event.KeyboardModifiers) then 
						begin
							{$ifdef DARWIN}
							SetStringValue('')
							{$else}
							SetStringValue('')
							{$endif}
						end
					else
						SetStringValue(AnsiLeftStr(GetStringValue, Length(GetStringValue) - 1));
				end
			else
				begin
					c := event.KeyboardCharacter;
					if HandleWillInsertCharacter(c) then
						SetStringValue(GetStringValue + c);
				end;
			event.Accept(self);
		end;
end;

procedure TTextView.HandleValueChanged;
begin
	inherited;
	NeedsLayoutSubviews;
end;

procedure TTextView.Draw;
begin		
	inherited;

	if GetStringValue <> '' then
		DrawText(textFont, GetStringValue, textAlignment, GetBounds, textColor);
end;

function TTextView.IsReadyToLayout: boolean;
begin
	result := assigned(textFont);
end;

procedure TTextView.LayoutSubviews;
var
	newSize: TVec2;
begin		
	// no font was set so we can't update the container
	if textFont = nil then
		exit;
		
	if widthTracksContainer then
		SetSize(GetTextSize);
	
	if widthTracksView and heightTracksContainer then
		begin
			newSize.width := GetWidth;
			newSize.height := GetTextSize.height;
			SetSize(newSize);
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

	SetWidthTracksContainer(true);
	SetMaximumWidth(0);
	SetTextAlignment(kAlignmentLeft);
	SetTextColor(RGBA(0, 0));
end;

//#########################################################
// IMAGE VIEW
//#########################################################

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
	//	begin
	//		scrollView.GetVisibleRect.show;
	//	end;

	if assigned(frontImage) then
		begin
			if TImageViewOption.ScaleProportionately in options then
				begin
					destSize := GetSize;
					srcSize := frontImage.GetSize;
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
				scaledSize := frontImage.GetSize; // don't scale

			if TImageViewOption.Center in options then
				imageFrame := RectMake((GetWidth / 2) - (scaledSize.width / 2), (GetHeight / 2) - (scaledSize.height / 2), scaledSize.width, scaledSize.height)
			else
				imageFrame := RectMake(0, 0, scaledSize.width, scaledSize.height);

			textureFrame := frontImage.TextureFrame;
			DrawTexture(frontImage, imageFrame, textureFrame);
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
	frontImage := newValue;
end;

destructor TImageView.Destroy;
begin
	backgroundImage := nil;
	inherited;
end;

constructor TImageView.Create(inFrame: TRect; image: TTexture);
begin
	SetImage(image);
	SetFrame(inFrame);
	Initialize;
end;

//#########################################################
// BUTTON
//#########################################################

constructor TButton.Create(frame: TRect; _title: string; _font: IFont = nil);
begin
	Initialize;
	SetTitle(_title);
	SetFont(_font);
	SetFrame(frame);
end;

procedure TButton.SetTitle(newValue: string);
begin
	SetStringValue(newValue);
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
		result := TTexture(imageView.frontImage)
	else
		result := nil;
end;

procedure TButton.HandlePressed;
begin
end;

procedure TButton.HandleAction;
begin
	if action <> nil then
		action.Invoke(self);
end;

procedure TButton.HandleInputEnded(event: TEvent);
begin			
	if pressed then
		begin
			// TODO: sounds and timers
			//if sound <> '' then
			//	TSound.Play(sound);
			//if action <> nil then
			//	TTimer.Invoke(0.0, action);
			HandleAction;
			HandlePressed;
		end;
	
	DepressButton;		
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
	HandleStateChanged;
end;

procedure TButton.RecalculateText;
begin
	textView.HandleValueChanged;
	HandleValueChanged;
end;

function TButton.GetTitle: string;
begin
	result := GetStringValue;
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
			textView.SetStringValue(GetTitle);
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
	NeedsLayoutSubviews;
end;

procedure TButton.HandleWillAddToWindow(window: TWindow);
begin
	inherited HandleWillAddToWindow(window);

	if wantsDefault then
		begin
			window.defaultButton := self;
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

//#########################################################
// CHECK BOX
//#########################################################

procedure TCheckBox.Initialize;
begin
	inherited;

	enableContentClipping := false;
	SetResizeByWidth(true);
end;

procedure TCheckBox.HandlePressed;
begin
	if state = TControlState.Off then
		state := TControlState.On
	else
		state := TControlState.Off;
end;

procedure TCheckBox.SetChecked(newValue: boolean);
begin
	if newValue then
		state := TControlState.On
	else
		state := TControlState.Off;
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

//#########################################################
// RADIO BUTTON
//#########################################################

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

//#########################################################
// RADIO GROUP
//#########################################################

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


//#########################################################
// POPUP BUTTON
//#########################################################

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
	m_selectedItem := menu.items[index];
	HandleDidSelectItem;
	NeedsLayoutSubviews;

	if not pullsdown then
		begin
			item := SelectedItem;
			item.SetChecked(true);
		end;
end;

procedure TPopupButton.SelectItemWithTag(tag: integer);
var
	i: integer;
	item: TMenuItem;
begin
	for i := 0 to menu.items.Count - 1 do
		begin
			item := menu.items[i];
			if item.GetTag = tag then
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

function TPopupButton.SelectedItem: TMenuItem;
begin
	result := m_selectedItem;
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
	result := MenuItemClass.Create(title, action);
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

procedure TPopupButton.HandleWindowWillClose(window: TWindow);
begin
	if window = menu then
		DepressButton;
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

//#########################################################
// CONTROL
//#########################################################

function TControl.GetControlState: TControlState;
begin
	result := state;
end;

function TControl.GetAction: TInvocation;
begin
	result := action;
end;

function TControl.GetStringValue: string;
begin
	result := stringValue;
end;

function TControl.IsEnabled: boolean;
begin
	result := enabled;
end;

procedure TControl.SetEnabled(newValue: boolean);
begin
	enabled := newValue;
end;

procedure TControl.SetStringValue(newValue: string; alwaysNotify: boolean);
var
	changed: boolean;
begin
	changed := stringValue <> newValue;
	stringValue := newValue;
	if changed or alwaysNotify then
		HandleValueChanged;
	NeedsLayoutSubviews;
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

procedure TControl.SetAction(newValue: TInvocation);
begin
	if action <> nil then
		action.Free;
	action := newValue;
end;

procedure TControl.InvokeAction;
begin
	if action <> nil then
		begin
			if action.params = nil then
				action.Invoke(self)
			else
				action.Invoke;
		end;
end;

procedure TControl.SizeToFit;
begin
	LayoutSubviews;
end;

procedure TControl.HandleStateChanged;
begin
end;

procedure TControl.HandleValueChanged;
begin
end;

procedure TControl.Initialize;
begin
	inherited Initialize;
	
	SetEnabled(true);
	SetControlState(TControlState.Off);
end;

//#########################################################
// NAVIGATION BAR
//#########################################################

procedure TNavigationBar.SetTitle(newValue: string);
begin
	titleView.SetStringValue(newValue);
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
	titleView.SetTextAlignment(kAlignmentCenter);
	AddSubview(titleView);
end;

procedure TNavigationBar.HandleFrameDidChange(previousFrame: TRect);
begin
	inherited HandleFrameDidChange(previousFrame);
	
	backButton.SetFrame(RectMake(0, 0, 0, GetHeight));
	titleView.SetFrame(GetBounds);
end;

//#########################################################
// NAVIGATION VIEW
//#########################################################

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
	WindowManifest := TWindowManifest.Create;
	RootWindow := TView.Create;
	ScreenMouseLocation := V2(-1, -1);

	{$define INITIALIZATION}
	{$include include/NotificationCenter.inc}
	{$undef INITIALIZATION}
end.