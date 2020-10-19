
{$ifdef INTERFACE}

type
  TIntegerList = specialize TFPGList<Integer>;
  TBooleanList = specialize TFPGList<Boolean>;

type
  TColor = TVec4;
  
type
  TColorHelper = record helper for TVec4
    class function Red(alpha: TScalar = 1.0): TVec4; static;
    class function Green(alpha: TScalar = 1.0): TVec4; static;
    class function Blue(alpha: TScalar = 1.0): TVec4; static;
    class function Cyan(alpha: TScalar = 1.0): TVec4; static;
    class function Magenta(alpha: TScalar = 1.0): TVec4; static;
    class function Yellow(alpha: TScalar = 1.0): TVec4; static;
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
			constructor Create(_min, _max: T); overload;
			constructor Create(values: array of T); overload;
			function Contains(value: T): boolean; overload;
			function Clamp(value: T): T;
			function Total: T; inline;
			function Sum: T; inline;
			function ToStr: string;
			function ValueOfPercent(percent: single): T;
			function PercentOfValue(value: T): single;
			procedure Show;
      class operator := (right: T): TRange;
	end;
	TRangeInt = specialize TRange<Integer>;
	TRangeFloat = specialize TRange<Single>;

type
  generic TMutableValue<T> = record
    public
      current: T;
      total: T;   
    public
      constructor Create(_total: T);      
      function Percent: single;
      function ToStr: string;
      procedure Show;
      procedure Reset; inline;
      procedure Inc(amount: T = 1); inline;
      procedure Dec(amount: T = 1); inline;
      function Full: boolean; inline;
      class operator := (right: T): TMutableValue;
      class operator + (constref left: TMutableValue; right: T): TMutableValue;
      class operator - (constref left: TMutableValue; right: T): TMutableValue;
      class operator = (constref left: TMutableValue; right: T): boolean;
      class operator > (constref left: TMutableValue; right: T): boolean; 
      class operator < (constref left: TMutableValue; right: T): boolean;
      class operator <= (constref left: TMutableValue; right: T): boolean;
      class operator >= (constref left: TMutableValue; right: T): boolean;
  end;
  TMutableValueInt = specialize TMutableValue<Integer>;
  TMutableValueFloat = specialize TMutableValue<Single>;

type
  TVariantMap = specialize TFPGMap<String, Variant>;

type
  generic TFPGMatrix<T> = class(specialize TFPGList<T>)
    private
      m_width: integer; 
      m_height: integer;
      m_size: TVec2i;
      function GetRef(x, y: integer): PT; inline; overload;
      function GetRef(pos: TVec2i): PT; inline; overload;
      procedure SetRef(x, y: integer; value: PT);
      function GetItem(pos: TVec2i): T; overload;
      function GetItem(x, y: integer): T; overload;
      function GetItem(index: integer): T; overload;
      procedure SetItem(x, y: integer; value: T); overload;
      procedure SetItem(index: integer; value: T); overload;
    public type
      TForEachFunction = procedure (matrix: TFPGMatrix; constref src, dest: TVec2i);
      TForEachFunctionNested = procedure (matrix: TFPGMatrix; constref src, dest: TVec2i) is nested;
    private
      procedure ForEachNeighborInternal(pos: TVec2i; func1: TForEachFunction; func2: TForEachFunctionNested);
    public

      { Constructors }
      constructor Create(_width, _height: integer); overload;
      constructor Create(_size: TVec2i); overload;

      { Methods }
      procedure Fill(constref value: T);
      procedure Resize(w, h: integer; const f: T);

      procedure ForEachNeighbor(pos: TVec2i; func: TForEachFunction); overload;
      procedure ForEachNeighbor(pos: TVec2i; func: TForEachFunctionNested); overload;

      function IndexAt(x, y: integer): integer; inline; overload;
      function IndexAt(pos: TVec2i): integer; inline; overload;
      function InBounds(x, y: integer): boolean; inline; overload;
      function InBounds(pos: TVec2i): boolean; inline; overload;
      function CopyBlock(offsetX, offsetY, width, height: integer): PTypeList;

      { Properties }
      property Values[x, y: integer]: T read GetItem write SetItem; default;
      property Refs[x, y: integer]: PT read GetRef write SetRef;
      property Width: integer read m_width;
      property Height: integer read m_height;
      property Size: TVec2i read m_size;
  end;

{$endif}

{$ifdef IMPLEMENTATION}

{ Color Helpers }

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

class function TColorHelper.Cyan(alpha: TScalar = 1.0): TVec4;
begin
  result := V4(0, 1, 1, alpha);
end;

class function TColorHelper.Magenta(alpha: TScalar = 1.0): TVec4;
begin
  result := V4(1, 0, 1, alpha);
end;

class function TColorHelper.Yellow(alpha: TScalar = 1.0): TVec4;
begin
  result := V4(1, 1, 0, alpha);
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

{ TMutableValue }

function TMutableValue.Percent: single;
begin
  result := current / total;  
end;

procedure TMutableValue.Reset; 
begin
  current := total;
end;

function TMutableValue.Full: boolean;
begin
  result := current = total;
end;

procedure TMutableValue.Inc(amount: T); 
begin
  current += amount;
  if current > total then
    current := total;
end;

procedure TMutableValue.Dec(amount: T); 
begin
  current -= amount;
  if current < 0 then
    current := 0;
end;

constructor TMutableValue.Create (_total: T);
begin
  total := _total;
  current := total;
end;

class operator TMutableValue.= (constref left: TMutableValue; right: T): boolean;
begin
  result := left.current = right;
end;

class operator TMutableValue.> (constref left: TMutableValue; right: T): boolean;
begin
  result := left.current > right;
end;

class operator TMutableValue.< (constref left: TMutableValue; right: T): boolean;
begin
  result := left.current < right;
end;

class operator TMutableValue.>= (constref left: TMutableValue; right: T): boolean;
begin
  result := left.current >= right;
end;

class operator TMutableValue.<= (constref left: TMutableValue; right: T): boolean;
begin
  result := left.current <= right;
end;

class operator TMutableValue.+ (constref left: TMutableValue; right: T): TMutableValue;
begin
  result := left;
  result.Inc(right);
end;

class operator TMutableValue.- (constref left: TMutableValue; right: T): TMutableValue;
begin
  result := left;
  result.Dec(right);
end;

class operator TMutableValue.:= (right: T): TMutableValue;
begin
  result.current := right;
  result.total := right;
end;

function TMutableValue.ToStr: string;
begin
  result := current.ToString+'/'+total.ToString;
end;

procedure TMutableValue.Show;
begin
  writeln(ToStr);
end;

{ TRange }

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

constructor TRange.Create(values: array of T);
begin
	min := values[0];
	max := values[1];
end;

constructor TRange.Create(_min, _max: T);
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

class operator TRange.:= (right: T): TRange;
begin
  result.min := right;
  result.max := right;
end;

{ TFPGMatrix }

function TFPGMatrix.CopyBlock(offsetX, offsetY, width, height: integer): PTypeList;
var
  total: integer;
  x, y: integer;
  i: integer = 0;
begin
  total := (width + 1) * (height + 1);

  // todo: 1) use pointer input so we can write to stack
  // todo: 2) make overload that copies to dynamic array
  result := PTypeList(GetMem(total * sizeof(T)));
  if result = nil then
    exit(nil);

  for y := offsetY to offsetY + height do
  for x := offsetX to offsetX + width do
    begin
      // todo: use move to copy rows
      //Move(List[0] + );
      result^[i] := self[x, y];
      inc(i);
    end;
end;

procedure TFPGMatrix.Resize(w, h: integer; const f: T);
var
  temp: array of T;
  x, y, i: integer;
  ow, oh: integer;
  shiftX, shiftY: integer;
begin
  // TODO: what even if the structure of the list?
  //temp := PTypeList(GetMem(Count * sizeof(T)));
  //System.Move(List, temp^, Count * sizeof(T));
  //FreeMem(temp);

  // copy old values
  SetLength(temp, Count);
  for i := 0 to Count - 1 do
    temp[i] := Items[i];

  ow := width;
  oh := height;
  shiftX := 0;
  shiftY := 0;

  if w < 0 then shiftX := abs(w);
  if h < 0 then shiftY := abs(h);

  m_width := width + abs(w);
  m_height := height + abs(h);
  m_size := V2i(width, height);
  Count := width * height;

  // fill with values
  for i := 0 to Count - 1 do
    Items[i] := f;

  // replace old values
  for y := 0 to Min(height - 1, oh - 1) do
  for x := 0 to Min(width - 1, ow - 1) do
    Items[IndexAt(x + shiftX, y + shiftY)] := temp[x + y * ow];
end;

procedure TFPGMatrix.Fill(constref value: T);
var
  i: integer;
begin
  for i := 0 to Count - 1 do
    Items[i] := value;
end;

procedure TFPGMatrix.ForEachNeighborInternal(pos: TVec2i; func1: TForEachFunction; func2: TForEachFunctionNested);
var
  x, y: integer;
  target: TVec2i;
begin
  for y := -1 to 1 do
  for x := -1 to 1 do
    begin
      target := V2i(pos.x + x, pos.y + y);
      if not InBounds(target) or (target = pos) then
        continue;
      if func1 <> nil then
        func1(self, pos, target)
      else
        func2(self, pos, target);
    end;
end;

procedure TFPGMatrix.ForEachNeighbor(pos: TVec2i; func: TForEachFunctionNested);
begin
  ForEachNeighborInternal(pos, nil, func);
end;

procedure TFPGMatrix.ForEachNeighbor(pos: TVec2i; func: TForEachFunction);
begin
  ForEachNeighborInternal(pos, func, nil);
end;

constructor TFPGMatrix.Create(_size: TVec2i);
begin
  Create(_size.width, _size.height);
end;

constructor TFPGMatrix.Create(_width, _height: integer);
begin
  inherited Create;
  m_width := _width;
  m_height := _height;
  m_size := V2i(width, height);
  Count := width * height;
end;

function TFPGMatrix.InBounds(x, y: integer): boolean;
begin
  result := (x >= 0) and 
            (y >= 0) and 
            (x < width) and 
            (y < height);
end;

function TFPGMatrix.InBounds(pos: TVec2i): boolean;
begin
  result := InBounds(pos.x, pos.y);
end;

function TFPGMatrix.IndexAt(x, y: integer): integer;
begin
  result := x + y * width;
end;

function TFPGMatrix.IndexAt(pos: TVec2i): integer;
begin
  result := IndexAt(pos.x, pos.y);
end;

function TFPGMatrix.GetRef(x, y: integer): PT;
begin
  result := TFPSList(self).Items[IndexAt(x, y)];
end;

function TFPGMatrix.GetRef(pos: TVec2i): PT;
begin
  result := GetRef(pos.x, pos.y);
end;

procedure TFPGMatrix.SetRef(x, y: integer; value: PT);
begin
  TFPSList(self).items[IndexAt(x, y)] := value;
end;

function TFPGMatrix.GetItem(pos: TVec2i): T;
begin
  result := GetItem(pos.x, pos.y);
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

function TFPGMatrix.GetItem(index: integer): T;
begin
  result := items[index];
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

procedure TFPGMatrix.SetItem(index: integer; value: T);
begin
  items[index] := value;
end;


{$endif}
