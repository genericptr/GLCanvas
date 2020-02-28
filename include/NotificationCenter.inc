
{$ifdef INTERFACE}
	
type
	TNotification = class (TMap)
		public
			
			{ Class Methods }
			class function Notification (name: string; _objct: pointer; userInfo: variant): TNotification; overload;
			
			{ Accessors }
			function GetName: string;
			function GetObject: pointer;
			function GetUserInfo: variant;
			
		private
			objct: pointer;
	end;
	TNotificationClass = class of TNotification;
	TNotificationCallback = procedure (notification: TNotification) of object;

type 
	TNotificationHandler = class (TInvocation)
		strict private
			function GetTarget: TObject;
		public
			notification: string;
			property Target: TObject read GetTarget;
			property Obj: TInvocationParams read params;
			constructor Create (callback: TNotificationCallback; _notification: string; _object: pointer);
	end;
	TNotificationHandlerList = specialize TFPGList<TNotificationHandler>;

{ The dispatch message parameter for all notification handlers }	
type
	TNotificationMessage = record
		method: string;
		notification: TNotification;
	end;
	
type 
	TNotificationCenter = class
		public
			
			{ Class Methods }
			class function DefaultCenter: TNotificationCenter;
			
			{ Posting Notifications }
			procedure PostNotification (name: string; objct: pointer = nil); overload;
			procedure PostNotification (name: string; objct: pointer; userInfo: variant); overload;
			procedure PostNotification (notification: TNotification); overload;
			
			{ Observing Notifications }
			procedure ObserveNotification (name: string; action: TNotificationCallback; objct: pointer = nil); overload;
			
			procedure RemoveObserver (observer: TObject; notification: string); overload;
			procedure RemoveEveryObserver (observer: TObject);
				
			{ Accessors }
			function IsObserving (observer: TObject; notification: string): boolean;
			
			procedure AfterConstruction; override;
			destructor Destroy; override;
			
		private
			handlers: TNotificationHandlerList;
	end;

{$endif}

{$ifdef IMPLEMENTATION}

const
	kNotificiationUserInfoKey = 'userInfo';
	kNotificiationNameKey = 'name';

var
	GlobalDefaultCenter: TNotificationCenter = nil;

function TNotificationHandler.GetTarget: TObject;
begin
	if callbackClass <> nil then
		result := TObject(TMethod(callbackClass).data)
	else
		result := nil;
end;

constructor TNotificationHandler.Create (callback: TNotificationCallback; _notification: string; _object: pointer);
begin
	callbackClass := TInvocationCallbackClass(callback);
	notification := _notification;
	params := _object;
end;

class function TNotification.Notification (name: string; _objct: pointer; userInfo: variant): TNotification;
begin
	result := TNotification.Create;
	result.objct := _objct;
	result.Add(kNotificiationNameKey, name);
	result.Add(kNotificiationUserInfoKey, userInfo);
end;

function TNotification.GetUserInfo: variant;
begin
	result := self[kNotificiationUserInfoKey];
end;

function TNotification.GetName: string;
begin
	result := string(self[kNotificiationNameKey]);
end;

function TNotification.GetObject: pointer;
begin
	result := objct;
end;

function TNotificationCenter.IsObserving (observer: TObject; notification: string): boolean;
var
	handler: TNotificationHandler;
begin
	result := false;
	for handler in handlers do
		if (handler.target = observer) and (handler.notification = notification) then
			exit(true);
end;

procedure TNotificationCenter.RemoveObserver (observer: TObject; notification: string);
var
	handler: TNotificationHandler;
	removedHandlers: TNotificationHandlerList;
begin
	removedHandlers := TNotificationHandlerList.Create;
	
	for handler in handlers do
		if (handler.target = observer) and (handler.notification = notification) then
			removedHandlers.Add(handler);
	
	for handler in removedHandlers do
		handlers.Remove(handler);
		
	removedHandlers.Free;
end;

{ Invoked to remove observer from notification centers }
procedure TNotificationCenter.RemoveEveryObserver (observer: TObject);
var
	handler: TNotificationHandler;
	removedHandlers: TNotificationHandlerList;
begin
	removedHandlers := TNotificationHandlerList.Create;
	
	for handler in handlers do
		if handler.target = observer then
			removedHandlers.Add(handler);

	for handler in removedHandlers do
		handlers.Remove(handler);

	removedHandlers.Free;
end;

procedure TNotificationCenter.PostNotification (name: string; objct: pointer = nil); overload;
begin
	PostNotification(name, objct, 0);
end;

procedure TNotificationCenter.PostNotification (name: string; objct: pointer; userInfo: variant);
var
	handler: TNotificationHandler;
	notification: TNotification;
begin
	notification := TNotification.Notification(name, objct, userInfo);
	for handler in handlers do
		if (handler.notification = name) and (handler.obj = objct) then
			handler.Invoke(notification);
end;

procedure TNotificationCenter.PostNotification (notification: TNotification);
begin
	PostNotification(notification.GetName, notification.GetObject, pointer(notification));
end;

procedure TNotificationCenter.ObserveNotification (name: string; action: TNotificationCallback; objct: pointer = nil);
var
	handler: TNotificationHandler;
begin
	handler := TNotificationHandler.Create(action, name, objct);
	handlers.Add(handler);
end;

class function TNotificationCenter.DefaultCenter: TNotificationCenter;
begin
	result := GlobalDefaultCenter;
end;

procedure TNotificationCenter.AfterConstruction;
begin
	inherited;
	handlers := TNotificationHandlerList.Create;
end;

destructor TNotificationCenter.Destroy;
begin
	handlers.Free;
	inherited;
end;

{$endif}

{$ifdef INITIALIZATION}
	GlobalDefaultCenter := TNotificationCenter.Create;
{$endif}