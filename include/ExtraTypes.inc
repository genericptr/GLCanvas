
{$ifdef INTERFACE}

type
	generic TRange<T> = record
		public
			min: T;
			max: T;
		public
			constructor Make (_min, _max: T); overload;
			constructor Make (values: array of T); overload;
			function Contains (value: T): boolean; overload;
			function Clamp (value: T): T;
			function Total: T; inline;
			function Sum: T; inline;
			function ToStr: string;
			function ValueOfPercent (percent: single): T;
			function PercentOfValue (value: T): single;
			procedure Show;
	end;
	TRangeInt = specialize TRange<Integer>;
	TRangeFloat = specialize TRange<Single>;

{$endif}

{$ifdef IMPLEMENTATION}

function TRange.Clamp (value: T): T;
begin
	if value < min then
		value := min
	else if value > max then
		value := max;
	result := value;
end;

function TRange.Contains (value: T): boolean;
begin
	result := (value >= min) and (value <= max);
end;

constructor TRange.Make (values: array of T);
begin
	min := values[0];
	max := values[1];
end;

constructor TRange.Make (_min, _max: T);
begin
	min := _min;
	max := _max;
end;

function TRange.Total: T;
begin
	result := max - min;
end;

function TRange.Sum: T;
begin
	result := max + min;
end;

function TRange.PercentOfValue (value: T): single;
begin
	result := (value-min)/Total;
end;

function TRange.ValueOfPercent (percent: single): T;
begin
	result := min + System.Trunc(Total * percent);
end;

function TRange.ToStr: string;
begin
	if GetTypeKind(T) in [tkInteger, tkInt64, tkQWord] then
		result := IntToStr(integer(min))+'-'+IntToStr(integer(max))
	else if GetTypeKind(T) in [tkFloat] then
		result := FloatToStr(single(min))+'-'+FloatToStr(single(max))
	else
		Assert(false, 'Range type can''t be converted to string');
end;

procedure TRange.Show;
begin
	writeln(ToStr);
end;

{$endif}
