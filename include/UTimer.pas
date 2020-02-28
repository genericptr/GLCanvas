{$mode objfpc}

unit UTimer;
interface
uses
	SysUtils,
	UInvocation, UArray, USystem, UObject;

const
	kTimerInterval = 1;
	kTimerIntervalSecond = kTimerInterval * 60;
	kTimerIntervalMinute = kTimerIntervalSecond * 60;
	kTimerIntervalHour = kTimerIntervalMinute * 60;

type
	TimerInterval = double;
	TTimerInterval = TimerInterval;
	
type
	TTimerDispatchHandler = procedure (context: pointer);

type
	TTimer = class;
	
	TTimerDispatcher = class (TObject)
		public
			class procedure Register (dispatcher: TTimerDispatcher);
			
			procedure AddTimer (timer: TTimer);
			procedure RemoveTimer (timer: TTimer);
			function TimerForTarget (target: TObject): TTimer;
			function Process: boolean; virtual;
		protected
			procedure Initialize; override;
			procedure Deallocate; override;
		private
			timers: TArray;
			currentTimer: TTimer;
	end;
	
	TTimer = class (TObject)
		public
			
			{ Class Methods }
			class function InvokeMethod (_interval: TimerInterval; _action: pointer; _target: TObject; _argument: pointer = nil; _repeats: boolean = false): TTimer; overload;
			class function InvokeMethod (_interval: TimerInterval; _action: string; _target: TObject; _argument: pointer = nil; _repeats: boolean = false): TTimer; overload;
			class function Invoke (_interval: TimerInterval; _invocation: TInvocation; _repeats: boolean = false): TTimer; overload;

			class procedure CancelPreviousInvocationsWithTarget (_target: TObject);
			class procedure RegisterDispatchHandler (handler: TTimerDispatchHandler; context: pointer);
			
			class function DefaultDispatcher: TTimerDispatcher; virtual;

			{ Constructors }
			constructor Create (_interval: TimerInterval; _action: pointer; _target: TObject; _argument: pointer = nil; _repeats: boolean = false); overload;
			constructor Create (_interval: TimerInterval; _action: string; _target: TObject; _argument: pointer = nil; _repeats: boolean = false); overload;
			constructor Create (_interval: TimerInterval; _invocation: TInvocation; _repeats: boolean = false); overload;
			
			{ Accessors }
			procedure SetName (newValue: string);
			procedure SetStartDelay (newValue: TimerInterval);
			
			function GetArguments: pointer;
			function GetInvocation: TInvocation;
			function IsValid: boolean;
			function IsPaused: boolean;
			function GetRepeats: boolean;
			function GetInterval: TimerInterval;
			
			{ Methods }
			function Fire: boolean; virtual;
			procedure Invalidate; virtual;
			procedure Reset; overload;
			procedure Reset (nextInterval: TimerInterval); overload;
			procedure Install (in_dispatcher: TTimerDispatcher = nil);
			procedure Pause;
			procedure Resume;
			
		protected
			interval: TimerInterval;
			procedure Deallocate; override;
		private
			dispatcher: TTimerDispatcher;
			intervalCount: LongInt;
			startDelay: TimerInterval;
			startDelayIntervalCount: LongInt; 
			repeats: boolean;
			valid: boolean;
			invocation: TInvocation;
			paused: boolean;
			name: string;
	end;
	TTimerClass = class of TTimer;

type
	TTimerInvocations = class helper for TObject
		function InvokeMethodAfterDelay (_interval: TimerInterval; _action: pointer; _repeats: boolean): TTimer; overload;
		function InvokeMethodAfterDelay (_interval: TimerInterval; _action: pointer): TTimer; overload;
		function InvokeMethodAfterDelay (_interval: TimerInterval; _action: string): TTimer; overload;
	end;

type
	TOperationQueue = class (TTimer)
		public
			constructor Create (_limit: TimerInterval; _finishedAction: TInvocation);
			procedure Add (op: TInvocation);
			function Fire: boolean; override;
		private
			finishedAction: TInvocation;
			limit: TimerInterval;
			queue: TArray;
	end;

var
	GlobalTimerCount: LongInt = 0;

function ProcessTimersForLoop: boolean;
procedure InvalidateTimer (var timer: TTimer);

implementation

var
	GlobalDispatchers: TPointerArray = nil;
	GlobalDispatchHandler: TTimerDispatchHandler = nil;
	GlobalDispatchHandlerContext: Pointer = nil;
	
{=============================================}
{@! ___PROCEDURAL___ } 
{=============================================}
function ProcessTimersForLoop: boolean;
var
	dispatcher: TTimerDispatcher;
	i: integer;
begin
	for i := 0 to GlobalDispatchers.High do
		begin
			dispatcher := TTimerDispatcher(GlobalDispatchers.GetValue(i));
			dispatcher.Process;
		end;
	result := true;
end;

procedure InvalidateTimer (var timer: TTimer);
begin
	if timer <> nil then
		begin
			timer.Invalidate;
			timer := nil;
		end;
end;

{=============================================}
{@! ___OPERATION QUEUE___ } 
{=============================================}

procedure TOperationQueue.Add (op: TInvocation);
begin
	queue.AddValue(op);
end;

function TOperationQueue.Fire: boolean;
var
	op: TInvocation;
	startTime: TimerInterval;
begin
	startTime := SystemTime;
	while queue.Count > 0 do
		begin
			queue.GetValue(0, op);
			op.Invoke;
			queue.RemoveIndex(0);
			if SystemTime - startTime > limit then
				break;
		end;
	result := queue.Count > 0;
	
	// the queue is empty so call the finished action
	if not result and (finishedAction <> nil) then
		finishedAction.Invoke;
end;

constructor TOperationQueue.Create (_limit: TimerInterval; _finishedAction: TInvocation);
begin
	limit := _limit;
	interval := 0.0;
	if _finishedAction <> nil then
		ManageObject(_finishedAction, finishedAction);
	ManageObject(TArray, queue);
	Initialize;
end;

{=============================================}
{@! ___TIMER INVOCATIONS___ } 
{=============================================}
function TTimerInvocations.InvokeMethodAfterDelay (_interval: TimerInterval; _action: pointer; _repeats: boolean): TTimer;
begin
	result := TTimer.InvokeMethod(_interval, _action, self, nil, _repeats);	
end;

function TTimerInvocations.InvokeMethodAfterDelay (_interval: TimerInterval; _action: pointer): TTimer;
begin
	result := TTimer.InvokeMethod(_interval, _action, self, nil, false);	
end;

function TTimerInvocations.InvokeMethodAfterDelay (_interval: TimerInterval; _action: string): TTimer;
begin
	result := TTimer.InvokeMethod(_interval, _action, self, nil, false);
end;

{=============================================}
{@! ___TIMER DISPATCHER___ } 
{=============================================}
function TTimerDispatcher.TimerForTarget (target: TObject): TTimer;
var
	timer: TTimer;
begin
	result := nil;
	for pointer(timer) in timers do
		if timer.invocation.GetTarget = target then
			exit(timer);
end;

procedure TTimerDispatcher.AddTimer (timer: TTimer);
begin		
	timers.AddValue(timer);	
end;

procedure TTimerDispatcher.RemoveTimer (timer: TTimer);
begin
	timers.RemoveFirstValue(timer);
end;

function TTimerDispatcher.Process: boolean;
var
	timer: TTimer;
	repeats: boolean;
begin
	//writeln('timers in queue: ', timers.count);
	GlobalTimerCount := timers.Count;

	for pointer(timer) in timers do
	if not timer.IsPaused then
		begin
		
			// decrement count
			if timer.startDelayIntervalCount = 0 then
				timer.intervalCount -= 1
			else
				begin
					timer.startDelayIntervalCount -= 1;
					continue;
				end;
			
			// invoke and set current timer
			if timer.intervalCount <= 0 then
				begin
					currentTimer := timer;
					repeats := timer.Fire;
					currentTimer := nil;
					if repeats and timer.IsValid then
						begin
							timer.Reset;
							continue;
						end;
				end;
			
			if timer.IsValid and (timer.intervalCount <= 0) then
				begin
					timer.Invalidate;
					timer.Release;
				end
			else if not timer.IsValid then
				begin
					// if the timer was invalidated in invoke release us here
					timer.Release;
				end;	
		end;
	
	result := timers.Count > 0;
end;

procedure TTimerDispatcher.Initialize;
begin
	inherited Initialize;
	
	timers := TArray.Create;
end;

procedure TTimerDispatcher.Deallocate;
begin
	timers.Release;
	
	inherited Deallocate;
end;

class procedure TTimerDispatcher.Register (dispatcher: TTimerDispatcher);
begin
	GlobalDispatchers.AddValue(dispatcher);
end;

{=============================================}
{@! ___TIMER___ } 
{=============================================}	

function TTimer.GetInvocation: TInvocation;
begin
	result := invocation;
end;

procedure TTimer.SetName (newValue: string);
begin
	name := newValue;
end;

procedure TTimer.SetStartDelay (newValue: TimerInterval);
begin
	startDelay := newValue;
	startDelayIntervalCount := Round(startDelay * GetPreferredSystemFrameRate);
end;

function TTimer.GetArguments: pointer;
begin
	result := invocation.GetArguments;
end;

function TTimer.IsPaused: boolean;
begin
	result := paused;
end;

function TTimer.IsValid: boolean;
begin
	result := valid;
end;

function TTimer.GetRepeats: boolean;
begin
	result := repeats;
end;

function TTimer.GetInterval: TimerInterval;
begin
	result := interval;
end;

procedure TTimer.Resume;
begin
	paused := false;
end;

procedure TTimer.Pause;
begin
	paused := true;
end;

procedure TTimer.Reset;
begin
	intervalCount := Round(interval * GetPreferredSystemFrameRate);
end;

procedure TTimer.Reset (nextInterval: TimerInterval);
begin
	interval := nextInterval;
	Reset;
end;

function TTimer.Fire: boolean;
begin
	// can't fire yet!
	if startDelayIntervalCount > 0 then
		exit(false);
	invocation.Invoke;
	result := GetRepeats;
end;

class function TTimer.DefaultDispatcher: TTimerDispatcher;
begin
	result := TTimerDispatcher(GlobalDispatchers.GetValue(0)); 
end;

procedure TTimer.Install (in_dispatcher: TTimerDispatcher = nil);
begin	
	Fatal(valid, 'Timer has already been installed.');
	Fatal(GetCurrentThreadID <> GetMainThreadID, 'Timer access outside of main thread.');
	
	if in_dispatcher = nil then
		dispatcher := DefaultDispatcher
	else
		dispatcher := in_dispatcher;
	
	if name = '' then
		name := ClassName;
	valid := true;
	intervalCount := Round(interval * GetPreferredSystemFrameRate);
	dispatcher.AddTimer(self);
	Retain;
	
	// the first timer was added so notify the dispatch handler
	if GlobalDispatchHandlerContext <> nil then
		if dispatcher.timers.Count = 1 then
			GlobalDispatchHandler(GlobalDispatchHandlerContext);
end;

procedure TTimer.Invalidate;
begin
	Fatal(GetCurrentThreadID <> GetMainThreadID, 'Timer access outside of main thread.');
	
	//writeln('invalidate timer');
	valid := false;
	
	// remove the timer from the dispatcher
	dispatcher.RemoveTimer(self);
	
	// release the invocation now to avoid retain cycles
	ReleaseObject(invocation);
	
	//writeln('timer invalidated ', getretaincount);
end;

procedure TTimer.Deallocate;
begin
	//writeln('dealloc timer');
	ReleaseObject(invocation);
		
	inherited Deallocate;
end;

class procedure TTimer.RegisterDispatchHandler (handler: TTimerDispatchHandler; context: pointer);
begin
	GlobalDispatchHandler := handler;
	GlobalDispatchHandlerContext := context;
end;

class procedure TTimer.CancelPreviousInvocationsWithTarget (_target: TObject);
var
	aTimer: TTimer;
	aDispatcher: TTimerDispatcher;
begin
	Fatal(GetCurrentThreadID <> GetMainThreadID, 'Timer access outside of main thread.');
	for pointer(aDispatcher) in GlobalDispatchers do
		begin
			aTimer := aDispatcher.timerForTarget(_target);
			if aTimer <> nil then
				if aTimer.IsValid then
					begin
						aTimer.Invalidate;
						aTimer.Release;
					end;
		end;
end;

constructor TTimer.Create (_interval: TimerInterval; _action: pointer; _target: TObject; _argument: pointer = nil; _repeats: boolean = false); overload;
begin
	interval := _interval;
	repeats := _repeats;
	invocation := TInvocation.Create(_action, _target);
	if _argument = nil then
		invocation.SetArguments(self)
	else
		invocation.SetArguments(_argument);
	Initialize;
end;

constructor TTimer.Create (_interval: TimerInterval; _action: string; _target: TObject; _argument: pointer = nil; _repeats: boolean = false); overload;
begin
	interval := _interval;
	repeats := _repeats;
	invocation := TInvocation.Create(_action, _target);
	if _argument = nil then
		invocation.SetArguments(self)
	else
		invocation.SetArguments(_argument);
	Initialize;
end;

constructor TTimer.Create (_interval: TimerInterval; _invocation: TInvocation; _repeats: boolean = false);
begin
	interval := _interval;
	repeats := _repeats;
	invocation := TInvocation(_invocation.Retain);
	Initialize;
end;

class function TTimer.InvokeMethod (_interval: TimerInterval; _action: pointer; _target: TObject; _argument: pointer = nil; _repeats: boolean = false): TTimer;
begin
	result := TTimerClass(ClassType).Create(_interval, _action, _target, _argument, _repeats);
	result.Install;
	result.Release;
end;

class function TTimer.InvokeMethod (_interval: TimerInterval; _action: string; _target: TObject; _argument: pointer = nil; _repeats: boolean = false): TTimer;
begin
	result := TTimerClass(ClassType).Create(_interval, _action, _target, _argument, _repeats);
	result.Install;
	result.Release;
end;

class function TTimer.Invoke (_interval: TimerInterval; _invocation: TInvocation; _repeats: boolean = false): TTimer;
begin
	result := TTimerClass(ClassType).Create(_interval, _invocation, _repeats);
	result.Install;
	result.Release;
end;

begin
	GlobalDispatchers := TPointerArray.Create;
	TTimerDispatcher.Register(TTimerDispatcher.Create);
end.