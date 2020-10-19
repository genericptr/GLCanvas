
{$ifdef INTERFACE}

type
	TInvocationParams = pointer;
	TInvocationCallbackClass = procedure (params: TInvocationParams) of object;
	TInvocationCallbackProcedure = procedure (params: TInvocationParams);
	TInvocationCallbackNested = procedure (params: TInvocationParams) is nested;
	TInvocation = class
		private type
			TVariantParams = array of variant;
		private
			callbackClass: TInvocationCallbackClass;
			callbackProcedure: TInvocationCallbackProcedure;
			callbackNested: TInvocationCallbackNested;
			freeParams: boolean;
			m_params: TInvocationParams;
			function GetTarget: TObject;
		public
			constructor Create(callback: TInvocationCallbackProcedure; _params: TInvocationParams = nil); overload;
			constructor Create(callback: TInvocationCallbackNested; _params: TInvocationParams = nil); overload;
			constructor Create(callback: TInvocationCallbackClass; _params: TInvocationParams = nil); overload;

			constructor Create(callback: TInvocationCallbackProcedure; _params: TVariantParams); overload;
			constructor Create(callback: TInvocationCallbackNested; _params: TVariantParams); overload;
			constructor Create(callback: TInvocationCallbackClass; _params: TVariantParams); overload;

			destructor Destroy; override;

			procedure Invoke(withParams: TInvocationParams = nil);

			property Params: TInvocationParams read m_params;
			property Target: TObject read GetTarget;
	end;
	TInvocationList = specialize TFPGObjectList<TInvocation>;

operator := (right: TInvocationCallbackClass): TInvocation;
operator := (right: TInvocationCallbackProcedure): TInvocation;
operator := (right: TInvocationCallbackNested): TInvocation;

{$endif}

{$ifdef IMPLEMENTATION}

{ Operators }

operator := (right: TInvocationCallbackClass): TInvocation;
begin
	result := TInvocation.Create(right);
end;

operator := (right: TInvocationCallbackProcedure): TInvocation;
begin
	result := TInvocation.Create(right);
end;

operator := (right: TInvocationCallbackNested): TInvocation;
begin
	result := TInvocation.Create(right);
end;

{ TInvocation }

constructor TInvocation.Create(callback: TInvocationCallbackProcedure; _params: TVariantParams);
var
	value: variant;
	list: TVariantList;
begin
	list := TVariantList.Create;
	for value in _params do
		list.Add(value);
	freeParams := true;
	Create(callback, list);
end;

constructor TInvocation.Create(callback: TInvocationCallbackNested; _params: TVariantParams);
var
	value: variant;
	list: TVariantList;
begin
	list := TVariantList.Create;
	for value in _params do
		list.Add(value);
	freeParams := true;
	Create(callback, list);
end;

constructor TInvocation.Create(callback: TInvocationCallbackClass; _params: TVariantParams);
var
	value: variant;
	list: TVariantList;
begin
	list := TVariantList.Create;
	for value in _params do
		list.Add(value);
	freeParams := true;
	Create(callback, list);
end;

constructor TInvocation.Create(callback: TInvocationCallbackClass; _params: TInvocationParams = nil);
begin
	callbackClass := callback;
	m_params := _params;
end;

constructor TInvocation.Create(callback: TInvocationCallbackProcedure; _params: TInvocationParams = nil);
begin
	callbackProcedure := callback;
	m_params := _params;
end;

constructor TInvocation.Create(callback: TInvocationCallbackNested; _params: TInvocationParams = nil);
begin
	callbackNested := callback;
	m_params := _params;
end;

function TInvocation.GetTarget: TObject;
begin
	Assert(callbackClass <> nil, 'can only get target for method invocations.');
	result := TObject(TMethod(callbackClass).Data);
end;

destructor TInvocation.Destroy;
begin
	if freeParams then
		TObject(params).Free;
	inherited;
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
		Assert(false, 'no callback for invocation');
end;

{$endif}

{$ifdef INITIALIZATION}
{$endif}