

{$ifdef INTERFACE}
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
	TTimerList = specialize TFPGObjectList<TTimer>;

	TTimerDispatcher = class
		public
			class procedure Register(dispatcher: TTimerDispatcher);
			procedure AfterConstruction; override;
			destructor Destroy; override;

			procedure AddTimer(timer: TTimer);
			procedure RemoveTimer(timer: TTimer);
			function TimerForTarget(target: TObject): TTimer;
			function Process: boolean; virtual;
		private
			timers: TTimerList;
			currentTimer: TTimer;
	end;
	TTimerDispatcherList = specialize TFPGObjectList<TTimerDispatcher>;

	TTimer = class
		public
			
			{ Class Methods }
			class function Invoke(_interval: TimerInterval; _invocation: TInvocation; _repeats: boolean = false): TTimer; overload;

			class procedure CancelPreviousInvocationsWithTarget(_target: TObject);
			class procedure RegisterDispatchHandler(handler: TTimerDispatchHandler; context: pointer);
			
			class function DefaultDispatcher: TTimerDispatcher; virtual;

			{ Constructors }
			constructor Create(_interval: TimerInterval; _invocation: TInvocation; _repeats: boolean = false); overload;
			destructor Destroy; override;

			{ Accessors }
			procedure SetName(newValue: string);
			procedure SetStartDelay(newValue: TimerInterval);
			
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
			procedure Reset(nextInterval: TimerInterval); overload;
			procedure Install(in_dispatcher: TTimerDispatcher = nil);
			procedure Pause;
			procedure Resume;
			
		protected
			interval: TimerInterval;
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
	TTimerInvocations = class helper for System.TObject
		function InvokeAfterDelay(_interval: TimerInterval; method: TInvocationCallbackProcedure; params: TInvocation.TVariantParams = nil; _repeats: boolean = false): TTimer; overload;
		function InvokeAfterDelay(_interval: TimerInterval; method: TInvocationCallbackClass; params: TInvocation.TVariantParams = nil; _repeats: boolean = false): TTimer; overload;
		function InvokeAfterDelay(_interval: TimerInterval; Code: CodePointer; params: TInvocation.TVariantParams = nil; _repeats: boolean = false): TTimer; overload;
	end;

type
	TOperationQueue = class(TTimer)
		public
			constructor Create(_limit: TimerInterval; _finishedAction: TInvocation);
			procedure Add(op: TInvocation);
			function Fire: boolean; override;
			destructor Destroy; override;
		private
			finishedAction: TInvocation;
			limit: TimerInterval;
			queue: TInvocationList;
	end;

var
	GlobalTimerCount: LongInt = 0;

function ProcessTimersForLoop: boolean;
procedure InvalidateTimer(var timer: TTimer);

{$endif}

{$ifdef IMPLEMENTATION}

var
	MainThreadID: GLPT_Thread_ID;
	GlobalDispatchers: TTimerDispatcherList = nil;
	GlobalDispatchHandler: TTimerDispatchHandler = nil;
	GlobalDispatchHandlerContext: Pointer = nil;
	
//#########################################################
// PROCEDURAL
//#########################################################

function GetTargetFrameRate: integer;
begin
	result := 60;
end;

function ProcessTimersForLoop: boolean;
var
	dispatcher: TTimerDispatcher;
	i: integer;
begin
	for dispatcher in GlobalDispatchers do
		dispatcher.Process;
	result := true;
end;

procedure InvalidateTimer(var timer: TTimer);
begin
	if timer <> nil then
		begin
			timer.Invalidate;
			timer := nil;
		end;
end;

//#########################################################
// OPERATION QUEUE
//#########################################################

procedure TOperationQueue.Add(op: TInvocation);
begin
	queue.Add(op);
end;

function TOperationQueue.Fire: boolean;
var
	op: TInvocation;
	startTime: TimerInterval;
begin
	startTime := GLPT_GetTime;
	while queue.Count > 0 do
		begin
			//queue.GetValue(0, op);
			op := queue[0];
			op.Invoke;
			queue.Delete(0);
			if GLPT_GetTime - startTime > limit then
				break;
		end;
	result := queue.Count > 0;
	
	// the queue is empty so call the finished action
	if not result and (finishedAction <> nil) then
		finishedAction.Invoke;
end;

destructor TOperationQueue.Destroy;
begin
	FreeAndNil(finishedAction);
	queue.Free;
	inherited;
end;

constructor TOperationQueue.Create(_limit: TimerInterval; _finishedAction: TInvocation);
begin
	limit := _limit;
	interval := 0.0;
	finishedAction := _finishedAction;
	queue := TInvocationList.Create;
end;

//#########################################################
// TIMER INVOCATIONS
//#########################################################

function TTimerInvocations.InvokeAfterDelay(_interval: TimerInterval; method: TInvocationCallbackProcedure; params: TInvocation.TVariantParams = nil; _repeats: boolean = false): TTimer;
begin
	result := TTimer.Invoke(_interval, TInvocation.Create(method, params), _repeats);	
end;

function TTimerInvocations.InvokeAfterDelay(_interval: TimerInterval; method: TInvocationCallbackClass; params: TInvocation.TVariantParams = nil; _repeats: boolean = false): TTimer;
begin
	result := TTimer.Invoke(_interval, TInvocation.Create(method, params), _repeats);	
end;

function TTimerInvocations.InvokeAfterDelay(_interval: TimerInterval; code: CodePointer; params: TInvocation.TVariantParams = nil; _repeats: boolean = false): TTimer;
var
	method: TInvocationCallbackClass;
begin
	TMethod(method).data := self;
	TMethod(method).code := code;
	result := TTimer.Invoke(_interval, TInvocation.Create(method, params), _repeats);	
end;

//#########################################################
// TIMER DISPATCHER
//#########################################################

function TTimerDispatcher.TimerForTarget(target: TObject): TTimer;
var
	timer: TTimer;
begin
	result := nil;
	for pointer(timer) in timers do
		if timer.invocation.GetTarget = target then
			exit(timer);
end;

procedure TTimerDispatcher.AddTimer(timer: TTimer);
begin		
	timers.Add(timer);	
end;

procedure TTimerDispatcher.RemoveTimer(timer: TTimer);
begin
	timers.Remove(timer);
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
					timer.Free;
				end
			else if not timer.IsValid then
				begin
					// if the timer was invalidated in invoke release us here
					timer.Free;
				end;	
		end;
	
	result := timers.Count > 0;
end;

procedure TTimerDispatcher.AfterConstruction;
begin
	inherited;
	
	timers := TTimerList.Create(false);
end;

destructor TTimerDispatcher.Destroy;
begin
	timers.Free;
	
	inherited;
end;

class procedure TTimerDispatcher.Register(dispatcher: TTimerDispatcher);
begin
	GlobalDispatchers.Add(dispatcher);
end;

//#########################################################
// TIMER
//#########################################################

function TTimer.GetInvocation: TInvocation;
begin
	result := invocation;
end;

procedure TTimer.SetName(newValue: string);
begin
	name := newValue;
end;

procedure TTimer.SetStartDelay(newValue: TimerInterval);
begin
	startDelay := newValue;
	startDelayIntervalCount := Round(startDelay * GetTargetFrameRate);
end;

function TTimer.GetArguments: pointer;
begin
	result := invocation.params;
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
	intervalCount := Round(interval * GetTargetFrameRate);
end;

procedure TTimer.Reset(nextInterval: TimerInterval);
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
	result := TTimerDispatcher(GlobalDispatchers[0]); 
end;

procedure TTimer.Install(in_dispatcher: TTimerDispatcher = nil);
begin	
	Assert(not valid, 'Timer has already been installed.');
	Assert(GLPT_ThreadID = MainThreadID, 'Timer access outside of main thread.');
	
	if in_dispatcher = nil then
		dispatcher := DefaultDispatcher
	else
		dispatcher := in_dispatcher;
	
	if name = '' then
		name := ClassName;
	valid := true;
	intervalCount := Round(interval * 60{todo: why do we need this????});
	dispatcher.AddTimer(self);
	
	// the first timer was added so notify the dispatch handler
	if GlobalDispatchHandlerContext <> nil then
		if dispatcher.timers.Count = 1 then
			GlobalDispatchHandler(GlobalDispatchHandlerContext);
end;

procedure TTimer.Invalidate;
begin
	Assert(GLPT_ThreadID = MainThreadID, 'Timer access outside of main thread.');
	
	//writeln('invalidate timer');
	valid := false;
	dispatcher.RemoveTimer(self);
end;

destructor TTimer.Destroy;
begin
	//writeln('destroyed timer');
	FreeAndNil(invocation);
		
	inherited;
end;

class procedure TTimer.RegisterDispatchHandler(handler: TTimerDispatchHandler; context: pointer);
begin
	GlobalDispatchHandler := handler;
	GlobalDispatchHandlerContext := context;
end;

class procedure TTimer.CancelPreviousInvocationsWithTarget(_target: TObject);
var
	aTimer: TTimer;
	aDispatcher: TTimerDispatcher;
begin
	Assert(GLPT_ThreadID = MainThreadID, 'Timer access outside of main thread.');
	for pointer(aDispatcher) in GlobalDispatchers do
		begin
			aTimer := aDispatcher.timerForTarget(_target);
			if aTimer <> nil then
				if aTimer.IsValid then
					begin
						aTimer.Invalidate;
						aTimer.Free;
					end;
		end;
end;

constructor TTimer.Create(_interval: TimerInterval; _invocation: TInvocation; _repeats: boolean = false);
begin
	interval := _interval;
	repeats := _repeats;
	invocation := _invocation;
end;

class function TTimer.Invoke(_interval: TimerInterval; _invocation: TInvocation; _repeats: boolean = false): TTimer;
begin
	result := TTimerClass(ClassType).Create(_interval, _invocation, _repeats);
	result.Install;
end;
{$endif}

{$ifdef INITIALIZATION}
MainThreadID := GLPT_ThreadID;
GlobalDispatchers := TTimerDispatcherList.Create;
TTimerDispatcher.Register(TTimerDispatcher.Create);
{$endif}