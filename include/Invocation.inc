
{$ifdef INTERFACE}

type
	TInvocationParams = pointer;
	TInvocationCallbackClass = procedure (params: TInvocationParams) of object;
	TInvocationCallbackProcedure = procedure (params: TInvocationParams);
	TInvocationCallbackNested = procedure (params: TInvocationParams) is nested;

	TInvocationCallbackClassNoParams = procedure of object;
	TInvocationCallbackProcedureNoParams = procedure;
	TInvocationCallbackNestedNoParams = procedure is nested;

	TInvocationCallbackDispatch = record
		method: ansistring;
		target: TObject;
		params: TInvocationParams;
		constructor Create(_target: TObject; const _method: string);
		class operator := (right: TInvocationCallbackDispatch): boolean;
	end;

	TInvocationCallback = record
		// TODO: can we make an enum and single pointer? "of object" may be larger than
		{
			TInvocationCallbackClass 16
			TInvocationCallbackProcedure 8
			TInvocationCallbackNested 16
			TInvocationCallbackDispatch 272
			TInvocationCallbackClassNoParams 16
			TInvocationCallbackProcedureNoParams 8
			TInvocationCallbackNestedNoParams 16
		}
		callbackClass: TInvocationCallbackClass;
		callbackProcedure: TInvocationCallbackProcedure;
		callbackNested: TInvocationCallbackNested;
		callbackDispatch: TInvocationCallbackDispatch;
		callbackClassNoParams: TInvocationCallbackClassNoParams;
		callbackProcedureNoParams: TInvocationCallbackProcedureNoParams;
		callbackNestedNoParams: TInvocationCallbackNestedNoParams;
	end;

	TInvocation = class
		private type
			TVariantParams = array of variant;
		private
			callbackClass: TInvocationCallbackClass;
			callbackProcedure: TInvocationCallbackProcedure;
			callbackNested: TInvocationCallbackNested;
			callbackClassNoParams: TInvocationCallbackClassNoParams;
			callbackProcedureNoParams: TInvocationCallbackProcedureNoParams;
			callbackNestedNoParams: TInvocationCallbackNestedNoParams;
			callbackDispatch: TInvocationCallbackDispatch;

			retainParams: boolean;
			m_params: TInvocationParams;
			function GetTarget: TObject;
			function CreateVariantParams(const _params: TVariantParams): TVariantList;
		public

			{ Constructors }
			constructor Create(callback: TInvocationCallbackProcedureNoParams); overload;
			constructor Create(callback: TInvocationCallbackNestedNoParams); overload;
			constructor Create(callback: TInvocationCallbackClassNoParams); overload;

			constructor Create(callback: TInvocationCallbackProcedure; _params: TInvocationParams = nil); overload;
			constructor Create(callback: TInvocationCallbackNested; _params: TInvocationParams = nil); overload;
			constructor Create(callback: TInvocationCallbackClass; _params: TInvocationParams = nil); overload;
			constructor Create(callback: TInvocationCallbackDispatch; _params: TInvocationParams = nil); overload;

			constructor Create(callback: TInvocationCallbackProcedure; _params: TVariantParams); overload;
			constructor Create(callback: TInvocationCallbackNested; _params: TVariantParams); overload;
			constructor Create(callback: TInvocationCallbackClass; _params: TVariantParams); overload;
			constructor Create(callback: TInvocationCallbackDispatch; _params: TVariantParams); overload;

			constructor Create(_target: TObject; method: string; _params: TInvocationParams = nil); overload;
			constructor Create(_target: TObject; method: string; _params: TVariantParams); overload;

			destructor Destroy; override;

			{ Methods }
			procedure Invoke(withParams: TInvocationParams = nil);
			function HasTarget: boolean;

			{ Properties }
			property Params: TInvocationParams read m_params;
			property Target: TObject read GetTarget;
	end;
	TInvocationList = specialize TFPGObjectList<TInvocation>;

operator := (right: TInvocationCallbackClass): TInvocation;
operator := (right: TInvocationCallbackProcedure): TInvocation;
operator := (right: TInvocationCallbackNested): TInvocation;

operator := (right: TInvocationCallbackClassNoParams): TInvocation;
operator := (right: TInvocationCallbackProcedureNoParams): TInvocation;
operator := (right: TInvocationCallbackNestedNoParams): TInvocation;

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

operator := (right: TInvocationCallbackClassNoParams): TInvocation;
begin
	result := TInvocation.Create(right);
end;

operator := (right: TInvocationCallbackProcedureNoParams): TInvocation;
begin
	result := TInvocation.Create(right);
end;

operator := (right: TInvocationCallbackNestedNoParams): TInvocation;
begin
	result := TInvocation.Create(right);
end;

{ TInvocationCallbackDispatch }

class operator TInvocationCallbackDispatch.:= (right: TInvocationCallbackDispatch): boolean;
begin
	result := (right.target <> nil) and (right.method <> '');
end;

constructor TInvocationCallbackDispatch.Create(_target: TObject; const _method: string);
begin
	Assert(_target <> nil, 'dispatch target can not be nil.');
	target := _target;
	method := _method;
end;

{ TInvocation }

function TInvocation.CreateVariantParams(const _params: TVariantParams): TVariantList;
var
	value: variant;
	list: TVariantList;
begin
	list := TVariantList.Create;
	for value in _params do
		list.Add(value);
		result := list;
end;

constructor TInvocation.Create(callback: TInvocationCallbackProcedure; _params: TVariantParams);
begin
	Create(callback, CreateVariantParams(_params));
end;

constructor TInvocation.Create(callback: TInvocationCallbackNested; _params: TVariantParams);
begin
	retainParams := true;
	Create(callback, CreateVariantParams(_params));
end;

constructor TInvocation.Create(callback: TInvocationCallbackClass; _params: TVariantParams);
begin
	retainParams := true;
	Create(callback, CreateVariantParams(_params));
end;

constructor TInvocation.Create(callback: TInvocationCallbackDispatch; _params: TVariantParams);
begin
	retainParams := true;
	Create(callback, CreateVariantParams(_params));
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

constructor TInvocation.Create(callback: TInvocationCallbackDispatch; _params: TInvocationParams = nil);
begin
	callbackDispatch := callback;
	callbackDispatch.params := _params;
	m_params := _params;
end;

constructor TInvocation.Create(callback: TInvocationCallbackProcedureNoParams);
begin
	callbackProcedureNoParams := callback;	
end;

constructor TInvocation.Create(callback: TInvocationCallbackNestedNoParams);
begin
	callbackNestedNoParams := callback;
end;

constructor TInvocation.Create(callback: TInvocationCallbackClassNoParams);
begin
	callbackClassNoParams := callback;
end;

constructor TInvocation.Create(_target: TObject; method: string; _params: TInvocationParams = nil);
begin
	Create(TInvocationCallbackDispatch.Create(_target, method), _params);
end;

constructor TInvocation.Create(_target: TObject; method: string; _params: TVariantParams);
begin
	Create(TInvocationCallbackDispatch.Create(_target, method), _params);
end;

function TInvocation.HasTarget: boolean;
begin
	result := (callbackClass <> nil) or (callbackClassNoParams <> nil);
end;

function TInvocation.GetTarget: TObject;
begin
	Assert(HasTarget, 'can only get target for method invocations.');
	result := TObject(TMethod(callbackClass).Data);
end;

destructor TInvocation.Destroy;
begin
	if retainParams then
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
	else if callbackDispatch then
		callbackDispatch.target.DispatchStr(callbackDispatch)
	else if callbackClassNoParams <> nil then
		callbackClassNoParams
	else if callbackProcedureNoParams <> nil then
		callbackProcedureNoParams
	else if callbackNestedNoParams <> nil then
		callbackNestedNoParams
	else
		Assert(false, 'no callback for invocation');
end;

{$endif}

{$ifdef INITIALIZATION}
{$endif}