
{$ifdef INTERFACE}

type
  TColor = TVec4;
  
type
  TColorHelper = record helper for TVec4
    class function Red(alpha: TScalar = 1.0): TVec4; static;
    class function Green(alpha: TScalar = 1.0): TVec4; static;
    class function Blue(alpha: TScalar = 1.0): TVec4; static;
    class function White(alpha: TScalar = 1.0): TVec4; static;
    class function Black(alpha: TScalar = 1.0): TVec4; static;
    class function LightGray(alpha: TScalar = 1.0): TVec4; static;
    class function DarkGray(alpha: TScalar = 1.0): TVec4; static;
    class function Clear: TVec4; static;
  end;

function RGBA(r, g, b, a: TScalar): TColor;
function RGBA(white: TScalar; alpha: TScalar = 1.0): TColor;
function HexColorToRGB(hexValue: integer; alpha: TScalar = 1.0): TVec4;

type
	generic TRange<T> = record
		public
			min: T;
			max: T;
		public
			constructor Make(_min, _max: T); overload;
			constructor Make(values: array of T); overload;
			function Contains(value: T): boolean; overload;
			function Clamp(value: T): T;
			function Total: T; inline;
			function Sum: T; inline;
			function ToStr: string;
			function ValueOfPercent(percent: single): T;
			function PercentOfValue(value: T): single;
			procedure Show;
	end;
	TRangeInt = specialize TRange<Integer>;
	TRangeFloat = specialize TRange<Single>;

type
  TVariantMap = specialize TFPGMap<String, Variant>;

type
  generic TFPGMatrix<T> = class(specialize TFPGList<T>)
    private
      m_width: integer; 
      m_height: integer;
      function GetRef(x, y: integer): PT;
      procedure SetRef(x, y: integer; value: PT);
      function GetItem(x, y: integer): T;
      procedure SetItem(x, y: integer; value: T);
    public
      constructor Create(inWidth, inHeight: integer); overload;
      constructor Create(size: TVec2i); overload;
      function IndexAt(x, y: integer): integer; inline;
      property Values[x, y: integer]: T read GetItem write SetItem; default;
      property Refs[x, y: integer]: PT read GetRef write SetRef;
      property Width: integer read m_width;
      property Height: integer read m_height;
  end;

type
  TMemoryPool = class
    public
      class procedure Push;
      class procedure Pop;
      class procedure Add(obj: TObject);
      class function Stack: TObjectList; inline;
    private
      class var m_stack: TObjectList;
  end;

{$endif}

{$ifdef IMPLEMENTATION}

class function TMemoryPool.Stack: TObjectList;
begin
  if m_stack = nil then
    m_stack := TObjectList.Create(true);
  result := m_stack;
end;  
  
class procedure TMemoryPool.Push;
begin
  stack.Add(TObjectList.Create(true));
end;

class procedure TMemoryPool.Pop;
begin
  stack.Delete(stack.Count - 1);
end;

class procedure TMemoryPool.Add(obj: TObject);  
begin
  if stack.Count > 0 then
    TObjectList(stack.Last).Add(obj); 
end;

function RGBA(r, g, b, a: TScalar): TColor;
begin
  result := V4(r, g, b, a);
end;

function RGBA(white: TScalar; alpha: TScalar = 1.0): TColor;
begin
  result := V4(white, white, white, alpha);
end;

function HexColorToRGB(hexValue: integer; alpha: TScalar = 1.0): TVec4;
begin
  result.r := ((hexValue shr 16) and $FF) / 255.0;  // Extract the RR byte
  result.g := ((hexValue shr 8) and $FF) / 255.0;   // Extract the GG byte
  result.b := ((hexValue) and $FF) / 255.0;         // Extract the BB byte
  result.a := alpha;
end;

class function TColorHelper.Red(alpha: TScalar = 1.0): TVec4;
begin
  result := V4(1, 0, 0, alpha);
end;

class function TColorHelper.Green(alpha: TScalar = 1.0): TVec4;
begin
  result := V4(0, 1, 0, alpha);
end;

class function TColorHelper.Blue(alpha: TScalar = 1.0): TVec4;
begin
  result := V4(0, 0, 1, alpha);
end;

class function TColorHelper.White(alpha: TScalar = 1.0): TVec4;
begin
  result := V4(1, 1, 1, alpha);
end;

class function TColorHelper.Black(alpha: TScalar = 1.0): TVec4;
begin
  result := V4(0, 0, 0, alpha);
end;

class function TColorHelper.LightGray(alpha: TScalar = 1.0): TVec4;
begin
  result := V4(0.8, 0.8, 0.8, alpha);
end;

class function TColorHelper.DarkGray(alpha: TScalar = 1.0): TVec4;
begin
  result := V4(0.2, 0.2, 0.2, alpha);
end;

class function TColorHelper.Clear: TVec4;
begin
  result := V4(0, 0, 0, 0);
end;

function TRange.Clamp(value: T): T;
begin
	if value < min then
		value := min
	else if value > max then
		value := max;
	result := value;
end;

function TRange.Contains(value: T): boolean;
begin
	result := (value >= min) and (value <= max);
end;

constructor TRange.Make(values: array of T);
begin
	min := values[0];
	max := values[1];
end;

constructor TRange.Make(_min, _max: T);
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

function TRange.PercentOfValue(value: T): single;
begin
	result := (value-min)/Total;
end;

function TRange.ValueOfPercent(percent: single): T;
begin
	{$ifdef CPUAARCH64}
	Assert(false, 'TRange.ValueOfPercent is broken in CPUAARCH64');
	{$else}
	result := min + System.Trunc(Total * percent);
	{$endif}
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

constructor TFPGMatrix.Create(size: TVec2i);
begin
  Create(size.width, size.height);
end;

constructor TFPGMatrix.Create(inWidth, inHeight: integer);
begin
  inherited Create;
  m_width := inWidth;
  m_height := inHeight;
  Count := width * height;
end;

function TFPGMatrix.IndexAt(x, y: integer): integer;
begin
  result := x + y * width;
end;

function TFPGMatrix.GetRef(x, y: integer): PT;
begin
  result := TFPSList(self).items[IndexAt(x, y)];
end;

procedure TFPGMatrix.SetRef(x, y: integer; value: PT);
begin
  TFPSList(self).items[IndexAt(x, y)] := value;
end;

function TFPGMatrix.GetItem(x, y: integer): T;
var
  index: integer;
begin
  index := IndexAt(x, y);
  if (index < 0) or (index >= Count) then
    exit(Default(T));
  result := items[IndexAt(x, y)];
end;

procedure TFPGMatrix.SetItem(x, y: integer; value: T);
var
  index: integer;
begin
  index := IndexAt(x, y);
  if (index < 0) or (index >= Count) then
    exit;
  items[IndexAt(x, y)] := value;
end;

{$endif}
