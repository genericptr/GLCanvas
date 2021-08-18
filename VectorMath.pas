{$mode objfpc}
{$modeswitch advancedrecords}
{$modeswitch typehelpers}
{$modeswitch multihelpers}

unit VectorMath;
interface
uses
  FGL, Math, SysUtils;

// NOTE: constref is bugged on 3.0.4 and below
{$macro on}
{$if FPC_FULLVERSION < 30005}
{$define constref := }
{$endif}

type
  TScalar = Single;
  Float = TScalar;

type
  TVec2 = record
    public
      class function Zero: TVec2; static; inline;
      class function FromAngle(radians: TScalar): TVec2; static; inline;

      function Length: TScalar; inline;
      function SquaredLength: TScalar; inline;
      function Magnitude: TScalar; inline;
      function Normalize: TVec2; inline;
      function Dot(constref vec: TVec2): TScalar; inline;
      function Cross(constref vec:TVec2): TVec2; inline;
      function Negate: TVec2; inline;
      function PerpendicularRight: TVec2; inline;
      function PerpendicularLeft: TVec2; inline;
      function Angle: TScalar; inline;
      function Distance(point: TVec2): TScalar; inline; 
      function Lerp(t: TScalar; p: TVec2): TVec2;
      function Reflect(n: TVec2): TVec2; inline;
      function Rotate(radians: TScalar): TVec2; overload;
      function Rotate(origin: TVec2; radians: TScalar): TVec2; overload;
      function Offset(byX, byY: TScalar): TVec2; overload; inline;
      function Offset(by: TVec2): TVec2; overload; inline;
      function Clamp(lowest, highest: TVec2): TVec2; inline;
      function Clamp(lowest, highest: TScalar): TVec2; inline;
      function Pinch(max, min: TScalar): TVec2; inline;
      function Min: TScalar;
      function Max: TScalar;
      function Sum: TScalar;
      function IsZero: boolean; inline;
      procedure Show;
      function ToStr(places: integer = -1): string;
    private
      function GetComponent(pIndex:integer):TScalar; inline;
      procedure SetComponent(pIndex:integer;pValue:TScalar); inline;
    public
      property Components[pIndex:integer]:TScalar read GetComponent write SetComponent; default;  
    public
      class operator := (right: TScalar): TVec2;
      class operator - (constref right: TVec2): TVec2;
      class operator + (constref left, right: TVec2): TVec2; overload;
      class operator - (constref left, right: TVec2): TVec2; overload; 
      class operator * (constref left, right: TVec2): TVec2; overload; 
      class operator / (constref left, right: TVec2): TVec2; overload;
      class operator = (constref left, right: TVec2): boolean; 
      class operator + (constref left: TVec2; right: TScalar): TVec2; overload; 
      class operator - (constref left: TVec2; right: TScalar): TVec2; overload; 
      class operator * (constref left: TVec2; right: TScalar): TVec2; overload; 
      class operator / (constref left: TVec2; right: TScalar): TVec2; overload;
      class operator + (left: string; right: TVec2): string; overload;
    public
      case integer of
        0: (v: array[0..1] of TScalar);
        1: (x, y: TScalar);
  end;
  PVec2 = ^TVec2;

type
  TVec3 = record
    public
      class function Zero: TVec3; static; inline;
      class function Up: TVec3; static; inline;
      
      function Length: TScalar; inline;
      function SquaredLength: TScalar; inline;
      function Magnitude: TScalar;
      function Normalize: TVec3; inline;
      function Dot(constref vec: TVec3): TScalar; inline;
      function Cross(constref vec:TVec3): TVec3; inline;
      function Negate: TVec3; inline;
      function Distance(point: TVec3): TScalar; inline; 
      function Lerp(t: TScalar; p: TVec3): TVec3; inline;
      function Reflect(n: TVec3): TVec3; inline;
      function Offset(byX, byY, byZ: TScalar): TVec3; overload; inline;
      function Offset(by: TVec3): TVec3; overload; inline;
      function Clamp(lowest, highest: TVec3): TVec3; inline;
      function Clamp(lowest, highest: TScalar): TVec3; inline;
      function IsZero: boolean; inline;
      function Sum: TScalar; inline;
      function XY: TVec2; inline;
      procedure Show;
      function ToStr(places: integer = -1): string;
    private
      function GetComponent(pIndex:integer):TScalar; inline;
      procedure SetComponent(pIndex:integer; pValue:TScalar); inline;
    public
      property Components[pIndex:integer]:TScalar read GetComponent write SetComponent; default;
    public
      class operator := (a: TScalar): TVec3;
      class operator explicit (right: TVec3): TVec2;
      class operator - (right: TVec3): TVec3;
      class operator + (constref left, right: TVec3): TVec3; overload;
      class operator - (constref left, right: TVec3): TVec3; overload; 
      class operator * (constref left, right: TVec3): TVec3; overload; 
      class operator / (constref left, right: TVec3): TVec3; overload;
      class operator = (constref left, right: TVec3): boolean; 
      class operator + (constref left: TVec3; right: TScalar): TVec3; overload; 
      class operator - (constref left: TVec3; right: TScalar): TVec3; overload; 
      class operator * (constref left: TVec3; right: TScalar): TVec3; overload; 
      class operator / (constref left: TVec3; right: TScalar): TVec3; overload;
      class operator + (left: string; right: TVec3): string; overload;
    public
      case integer of
        0: (v: array[0..2] of TScalar);
        1: (x, y, z: TScalar);
        2: (r, g, b: TScalar);
        3: (Pitch,Yaw,Roll:TScalar);
  end;
  PVec3 = ^TVec3;

type
  TVec4 = record
    public 
      class function Zero: TVec4; static; inline;
      function Length: TScalar; inline;
      function SquaredLength: TScalar; inline;
      function Normalize: TVec4; inline;
      function Dot(constref vec: TVec4): TScalar; inline;
      function Cross(constref vec: TVec4): TVec4; inline;
      function Negate: TVec4; inline;
      function XY: TVec2; inline;
      function XYZ: TVec3; inline;
      function IsZero: boolean; inline;
      procedure Show;
      function ToStr(places: integer = -1): string;
    private
      function GetComponent(pIndex:integer):TScalar; inline;
      procedure SetComponent(pIndex:integer; pValue:TScalar); inline;
    public
      property Components[pIndex:integer]:TScalar read GetComponent write SetComponent; default;
    public
      class operator := (a:TScalar): TVec4;
      class operator + (constref left, right: TVec4): TVec4; overload;
      class operator - (constref left, right: TVec4): TVec4; overload; 
      class operator * (constref left, right: TVec4): TVec4; overload; 
      class operator / (constref left, right: TVec4): TVec4; overload;
      class operator = (constref left, right: TVec4): boolean; 
      class operator + (constref left: TVec4; right: TScalar): TVec4; overload; 
      class operator - (constref left: TVec4; right: TScalar): TVec4; overload; 
      class operator * (constref left: TVec4; right: TScalar): TVec4; overload; 
      class operator / (constref left: TVec4; right: TScalar): TVec4; overload;
      class operator + (left: string; right: TVec4): string; overload;
    public
      case integer of
        0: (v: array[0..3] of TScalar);
        1: (x, y, z, w: TScalar);
        2: (r, g, b, a: TScalar);
  end;
  PVec4 = ^TVec4;

type
  TMat4 = record
    public
      function Ptr: pointer;
      class function Identity: TMat4; static; inline;
            
      constructor Translate(tx, ty, tz: TScalar); overload;
      constructor Translate(constref pTranslate: TVec3); overload;
      constructor Translate(tx, ty, tz, tw: TScalar); overload;
      
      constructor Scale(x, y, z: TScalar); overload;
      constructor Scale(constref pScale: TVec2; z: TScalar); overload;
      constructor Scale(constref pScale: TVec3); overload;

      constructor RotateX(Angle: TScalar);
      constructor RotateY(Angle: TScalar);
      constructor RotateZ(Angle: TScalar);
      constructor Rotate(Angle: TScalar; constref Axis: TVec3); overload;
      constructor Rotate(constref pMatrix: TMat4); overload;
      constructor Ortho(Left, Right, Bottom, Top, zNear, zFar: TScalar);
      constructor OrthoGL(Left, Right, Bottom, Top, zNear, zFar: TScalar);
      constructor Perspective(fovy, Aspect, zNear, zFar: TScalar);
      constructor PerspectiveGL(fovy, Aspect, zNear, zFar: TScalar);
      constructor LookAt(constref Eye, Center, Up: TVec3);
      
      function Inverse: TMat4; inline;
      function Transpose: TMat4; inline;
     
      function ToStr: string;
      procedure Show;
    private
      function GetComponent(column, row:integer):TScalar; inline;
      procedure SetComponent(column, row:integer; pValue:TScalar); inline;
    public
      property Components[column, row:integer]:TScalar read GetComponent write SetComponent; default;
    public
      class operator := (a:TScalar):TMat4;
      class operator = (constref a,b:TMat4):boolean;
      class operator <> (constref a,b:TMat4):boolean;
      class operator + (constref a,b:TMat4):TMat4;
      class operator + (constref a:TMat4; b:TScalar):TMat4;
      class operator + (a:TScalar;constref b:TMat4):TMat4;
      class operator - (constref a,b:TMat4):TMat4;
      class operator - (constref a:TMat4; b:TScalar):TMat4;
      class operator - (a:TScalar;constref b:TMat4): TMat4;
      class operator * (constref b,a:TMat4):TMat4;
      class operator * (constref a:TMat4;b:TScalar):TMat4;
      class operator * (a:TScalar;constref b:TMat4):TMat4;
      class operator * (constref a:TMat4;constref b:TVec2):TVec2;
      class operator * (constref a:TVec2;constref b:TMat4):TVec2;
      class operator * (constref a:TMat4;constref b:TVec3):TVec3;
      class operator * (constref a:TVec3;constref b:TMat4):TVec3;
      class operator * (constref a:TMat4;constref b:TVec4):TVec4;
      class operator * (constref a:TVec4;constref b:TMat4):TVec4;
      class operator / (constref a,b:TMat4):TMat4;
      class operator / (constref a:TMat4;b:TScalar):TMat4;
      class operator / (a:TScalar;constref b:TMat4):TMat4;
    public
      case integer of
        0: (m: array[0..3, 0..3] of TScalar);
        1: (column: array[0..3] of TVec4);
        2: (Right, Up, Forwards, Offset: TVec4);
        3: (Tangent, Bitangent, Normal, Translation: TVec4);
  end;
  PMat4 = ^TMat4;

type
  TVec2Array = array of TVec2;
  TVec3Array = array of TVec3;
  TVec4Array = array of TVec4;

type
  PVec2Array = ^TVec2Array;
  PVec3Array = ^TVec3Array;
  PVec4Array = ^TVec4Array;

type
  TVec2List = specialize TFPGList<TVec2>;
  TVec3List = specialize TFPGList<TVec3>;
  TVec4List = specialize TFPGList<TVec4>;
  TMat4List = specialize TFPGList<TMat4>;

{ Generic Vectors }

type 
  generic TGVec2<TComponent> = record
    public
      x, y: TComponent;
    private
      function GetComponent(index: byte): TComponent; inline;
      procedure SetComponent(index: byte; newValue: TComponent); inline;
    public
      constructor Create(_x, _y: TComponent);
      function Offset(byX, byY: TComponent): TGVec2; overload; inline;
      function Offset(by: TGVec2): TGVec2; overload; inline;
      function Length: TComponent;
      function SquaredLength: TComponent;
      function Magnitude: TComponent;
      function Min: TComponent;
      function Max: TComponent;
      function Sum: TComponent;
      function ToStr: string;
      procedure Show;
    public
      property V[index: byte]: TComponent read GetComponent write SetComponent; default;
      property Width: TComponent read x write x;
      property Height: TComponent read y write y;
    public
      class operator explicit (right: TGVec2): TVec2;
      class operator := (right: TComponent): TGVec2;
      class operator = (constref left, right: TGVec2): boolean; 
      class operator + (constref left, right: TGVec2): TGVec2; overload;
      class operator - (constref left, right: TGVec2): TGVec2; overload; 
      class operator * (constref left, right: TGVec2): TGVec2; overload; 
      class operator div (constref left, right: TGVec2): TGVec2; overload;
      class operator + (constref left: TGVec2; right: TComponent): TGVec2; overload; 
      class operator - (constref left: TGVec2; right: TComponent): TGVec2; overload; 
      class operator * (constref left: TGVec2; right: TComponent): TGVec2; overload; 
      class operator div (constref left: TGVec2; right: TComponent): TGVec2; overload;
      class operator + (left: string; right: TGVec2): string; overload;
  end;

type 
  generic TGVec3<TComponent> = record
    private type
      PComponent = ^TComponent;
    private
      function GetComponent(index: integer): TComponent; inline;
      procedure SetComponent(index: integer; newValue: TComponent); inline;
    public
      x, y, z: TComponent;
    public

      { Constructors }
      constructor Create(_x, _y, _z: TComponent);

      { Methods }
      function XY: specialize TGVec2<TComponent>;
      function Offset(byX, byY, byZ: TComponent): TGVec3; overload; inline;
      function Offset(by: TGVec3): TGVec3; overload; inline;
      function ToStr: string;
      procedure Show;

      { Properties }
      property Components[index: integer]: TComponent read GetComponent write SetComponent; default;
      
      property R: TComponent read x write x;
      property G: TComponent read y write y;
      property B: TComponent read z write z;

      property Width: TComponent read x write x;
      property Height: TComponent read y write y;
      property Depth: TComponent read z write z;
      function Volume: TComponent; inline;
      
      { Operators }
      class operator explicit (right: TGVec3): TVec2;
      class operator explicit (right: TGVec3): TVec3;
      class operator := (right: TComponent): TGVec3;
      class operator = (constref left, right: TGVec3): boolean;
      class operator + (constref left, right: TGVec3): TGVec3; overload;
      class operator - (constref left, right: TGVec3): TGVec3; overload; 
      class operator * (constref left, right: TGVec3): TGVec3; overload; 
      // TODO: these should be div operators!
      //class operator / (constref left, right: TGVec3): TGVec3; overload;
      class operator + (constref left: TGVec3; right: TComponent): TGVec3; overload; 
      class operator - (constref left: TGVec3; right: TComponent): TGVec3; overload; 
      class operator * (constref left: TGVec3; right: TComponent): TGVec3; overload; 
      //class operator / (constref left: TGVec3; right: TComponent): TGVec3; overload;
  end;

type 
  generic TGVec4<TComponent> = record
    private type
      PComponent = ^TComponent;
    private
      function GetComponent(index: integer): TComponent; inline;
      procedure SetComponent(index: integer; newValue: TComponent); inline;
    public
      x, y, z, w: TComponent;
    public

      { Constructors }
      constructor Create(_x, _y, _z, _w: TComponent);

      { Methods }
      function XY: specialize TGVec2<TComponent>;
      function XYZ: specialize TGVec3<TComponent>;
      function ToStr: string;
      procedure Show;

      { Properties }
      property Components[index: integer]: TComponent read GetComponent write SetComponent; default;
        
      property R: TComponent read x write x;
      property G: TComponent read y write y;
      property B: TComponent read z write z;
      property A: TComponent read w write w;

      { Operators }
      class operator = (constref left, right: TGVec4): boolean; 
  end;

type
  TVec2i = specialize TGVec2<Integer>;
  TVec3i = specialize TGVec3<Integer>;
  TVec4i = specialize TGVec4<Integer>;

type
  PVec2i = ^TVec2i;
  PVec3i = ^TVec3i;
  PVec4i = ^TVec4i;

type
  TVec2iList = specialize TFPGList<TVec2i>;
  TVec3iList = specialize TFPGList<TVec3i>;
  TVec4iList = specialize TFPGList<TVec4i>;

type
  TVec2iArray = array of TVec2i;
  TVec3iArray = array of TVec3i;
  TVec4iArray = array of TVec4i;

type
  TVec2iMap = specialize TFPGMap<String, TVec2i>;
  TVec3iMap = specialize TFPGMap<String, TVec3i>;
  TVec4iMap = specialize TFPGMap<String, TVec4i>;

{ Generic Vector Functions }

function V2i(x, y: integer): TVec2i;
function V3i(x, y, z: integer): TVec3i;
function V4i(x, y, z, w: integer): TVec4i;

operator := (right: TVec2i): TVec2;
operator := (right: TVec3i): TVec3;
operator := (right: TVec4i): TVec4;

operator := (right: TVec2): TVec2i;
operator := (right: TVec3): TVec3i;
operator := (right: TVec4): TVec4i;

{ Functions }

function M4: TMat4;

function Vec2(x, y: TScalar): TVec2; overload;
function Vec2(constref vec: TVec2i): TVec2; overload;

function Vec3(x, y, z: TScalar): TVec3; overload;
function Vec3(constref vec: TVec2; z: TScalar): TVec3; overload;
function Vec3(constref vec: TVec3i): TVec3; overload;

function Vec4(x, y, z, w: TScalar): TVec4; overload;
function Vec4(constref vec: TVec3; w: TScalar): TVec4; overload;
function Vec4(constref vec: TVec2; z, w: TScalar): TVec4; overload;
function Vec4(constref vec: TVec4i): TVec4; overload;

function V2(x, y: TScalar): TVec2;
function V2(constref vec: TVec2i): TVec2; overload;
function V2(constref vec: TVec3): TVec2; overload;

function V3(x, y, z: TScalar): TVec3; overload;
function V3(constref vec: TVec2; z: TScalar): TVec3; overload;
function V3(constref vec: TVec3i): TVec3; overload;

function V4(x, y, z, w: TScalar): TVec4;
function V4(constref vec: TVec3; w: TScalar): TVec4; overload;
function V4(constref vec: TVec2; z, w: TScalar): TVec4; overload;
function V4(constref vec: TVec4i): TVec4; overload;

function Trunc(vec: TVec2): TVec2; overload;
function Trunc(vec: TVec3): TVec3; overload;
function Trunc(vec: TVec4): TVec4; overload;

function Abs(vec: TVec2): TVec2; overload; inline;
function Abs(vec: TVec3): TVec3; overload; inline;
function Abs(vec: TVec4): TVec4; overload; inline;

function Angle(constref a,b,c: TVec3): TScalar;
function Clamp(int: integer; lowest, highest: integer): integer; overload; inline;
function Clamp(int: TScalar; lowest, highest: TScalar): TScalar; overload; inline;
function RoundTo(Number: TScalar; Places: longint): TScalar;
function RoundUp(Number: TScalar): longint;

function Normalize(vec: TVec2): TVec2; overload; inline;
function Normalize(vec: TVec3): TVec3; overload; inline;

function FloatToStr(number: single; places: integer): string; overload;

implementation

var
  Matrix4x4Identity: TMat4 = (m:((1.0,0.0,0.0,0.0), 
                                 (0.0,1.0,0.0,0.0), 
                                 (0.0,0.0,1.0,0.0), 
                                 (0.0,0.0,0.0,1.0)
                                 ));
                              
const
  DEG2RAD=pi/180.0;
  RAD2DEG=180.0/pi;
  HalfPI=pi*0.5;  

{ Helpers }

type
  TComponentIntegerHelper = type helper for Integer
    function ToStr: String;
  end;
  TComponentByteHelper = type helper for Byte
    function ToStr: String;
  end;
  TComponentShortIntHelper = type helper for ShortInt
    function ToStr: String;
  end;
  TComponentWordHelper = type helper for Word
    function ToStr: String;
  end;
  TComponentFloatHelper = type helper for Float
    function ToStr: String;
  end;

function TComponentWordHelper.ToStr: String;
begin
  result := IntToStr(self);
end;

function TComponentShortIntHelper.ToStr: String;
begin
  result := IntToStr(self);
end;

function TComponentByteHelper.ToStr: String;
begin
  result := IntToStr(self);
end;

function TComponentIntegerHelper.ToStr: String;
begin
  result := IntToStr(self);
end;

function TComponentFloatHelper.ToStr: String;
begin
  result := FloatToStr(self);
end;

function FloatToStr(number: single; places: integer): string; overload;
begin
  if places = -1 then
    result := FloatToStr(number)
  else if places = 0 then
    result := FloatToStr(Trunc(number))
  else
    result := Format('%.'+IntToStr(places)+'f', [number]);
end;

function FloatToStr(number: double; places: integer): string; overload;
begin
  if places = -1 then
    result := FloatToStr(number)
  else if places = 0 then
    result := FloatToStr(Trunc(number))
  else
    result := Format('%.'+IntToStr(places)+'f', [number]);
end;

{ Generic Vector Functions }

function V2i(x, y: integer): TVec2i; inline;
begin
  result.x := x;
  result.y := y;
end;

function V3i(x, y, z: integer): TVec3i; inline;
begin
  result.x := x;
  result.y := y;
  result.z := z;
end;

function V4i(x, y, z, w: integer): TVec4i; inline;
begin
  result.x := x;
  result.y := y;
  result.z := z;
  result.w := w;
end;

operator := (right: TVec2i): TVec2;
begin
  result.x := right.x;
  result.y := right.y;
end;

operator := (right: TVec3i): TVec3;
begin
  result.x := right.x;
  result.y := right.y;
  result.z := right.z;
end;

operator := (right: TVec4i): TVec4;
begin
  result.x := right.x;
  result.y := right.y;
  result.z := right.z;
  result.w := right.w;
end;

operator := (right: TVec2): TVec2i;
begin
  result.x := trunc(right.x);
  result.y := trunc(right.y);
end;

operator := (right: TVec3): TVec3i;
begin
  result.x := trunc(right.x);
  result.y := trunc(right.y);
  result.z := trunc(right.z);
end;

operator := (right: TVec4): TVec4i;
begin
  result.x := trunc(right.x);
  result.y := trunc(right.y);
  result.z := trunc(right.z);
  result.w := trunc(right.w);
end;

{*****************************************************************************
 *                                 TGVec2
 *****************************************************************************}

class operator TGVec2.explicit (right: TGVec2): TVec2;
begin
  result.x := right.x;
  result.y := right.y;
end;

class operator TGVec2.:= (right: TComponent): TGVec2;
begin
  result.x := right;
  result.y := right;
end;

class operator TGVec2.= (constref left, right: TGVec2): boolean; 
begin
  result := (left.x = right.x) and (left.y = right.y);
end;

class operator TGVec2.+ (constref left, right: TGVec2): TGVec2;
begin
  result := V2i(left.x+right.x, left.y+right.y);
end;

class operator TGVec2.- (constref left, right: TGVec2): TGVec2;
begin
  result := V2i(left.x-right.x, left.y-right.y);
end;

class operator TGVec2.* (constref left, right: TGVec2): TGVec2; 
begin
  result := V2i(left.x*right.x, left.y*right.y);
end;

class operator TGVec2.div (constref left, right: TGVec2): TGVec2; 
begin
  result := V2i(left.x div right.x, left.y div right.y);
end;

class operator TGVec2.+ (constref left: TGVec2; right: TComponent): TGVec2;
begin
  result := V2i(left.x+right, left.y+right);
end;

class operator TGVec2.- (constref left: TGVec2; right: TComponent): TGVec2;
begin
  result := V2i(left.x-right, left.y-right);
end;

class operator TGVec2.* (constref left: TGVec2; right: TComponent): TGVec2;
begin
  result := V2i(left.x*right, left.y*right);
end;

class operator TGVec2.div (constref left: TGVec2; right: TComponent): TGVec2;
begin
  result := V2i(left.x div right, left.y div right);
end;

class operator TGVec2.+ (left: string; right: TGVec2): string;
begin
  result := left+right.ToStr;
end;

function TGVec2.GetComponent(index: byte): TComponent;
begin
  case index of
    0: result := x;
    1: result := y;
    otherwise
      Assert(false, 'component #'+IntToStr(index)+' exceeds vector range(2).');
  end;
end;

procedure TGVec2.SetComponent(index: byte; newValue: TComponent);
begin
  case index of
    0: x := newValue;
    1: y := newValue;
    otherwise
      Assert(false, 'component #'+IntToStr(index)+' exceeds vector range(2).');
  end;
end;

constructor TGVec2.Create(_x, _y: TComponent);
begin
  x := _x;
  y := _y;
end;

function TGVec2.Min: TComponent;
begin
  if x < y then
    result := x
  else if y > x then
    result := y
  else
    result := x;
end;

function TGVec2.Max: TComponent;
begin
  if x > y then
    result := x
  else if y > x then
    result := y
  else
    result := x;
end;

function TGVec2.Sum: TComponent;
begin
  result := x + y;
end;

function TGVec2.Offset(byX, byY: TComponent): TGVec2;
begin
  result.x := x + byX;
  result.y := y + byY;
end;

function TGVec2.Offset(by: TGVec2): TGVec2;
begin
  result.x := x + by.X;
  result.y := y + by.Y;
end;

function TGVec2.Length: TComponent;
begin
  result := Trunc(Sqrt(SquaredLength));
end;

function TGVec2.SquaredLength: TComponent;
begin
  result := Trunc(Power(x, 2) + Power(y, 2));
end;

function TGVec2.Magnitude: TComponent;
begin
  result := Length;
end;

function TGVec2.ToStr: string;
begin
  result := '{'+x.ToStr+','+y.ToStr+'}';
end;

procedure TGVec2.Show;
begin
  writeln(ToStr);
end;

{*****************************************************************************
 *                                 TGVec3
 *****************************************************************************}

class operator TGVec3.explicit (right: TGVec3): TVec2;
begin
  result.x := right.x;
  result.y := right.y;
end;

class operator TGVec3.explicit (right: TGVec3): TVec3;
begin
  result.x := right.x;
  result.y := right.y;
  result.z := right.z;
end;

class operator TGVec3.:= (right: TComponent): TGVec3;
begin
  result.x := right;
  result.y := right;
  result.z := right;
end;

class operator TGVec3.= (constref left, right: TGVec3): boolean;
begin
  result := (left.x = right.x) and (left.y = right.y) and (left.z = right.z);
end;

class operator TGVec3.+ (constref left, right: TGVec3): TGVec3;
begin
  result := TGVec3.Create(left.x+right.x, left.y+right.y, left.z+right.z);
end;

class operator TGVec3.- (constref left, right: TGVec3): TGVec3;
begin
  result := TGVec3.Create(left.x-right.x, left.y-right.y, left.z-right.z);
end;

class operator TGVec3.* (constref left, right: TGVec3): TGVec3; 
begin
  result := TGVec3.Create(left.x*right.x, left.y*right.y, left.z*right.z);
end;

//class operator TGVec3./ (constref left, right: TGVec3): TGVec3; 
//begin
//  result := Vec3(left.x div right.x, left.y div right.y, left.z div right.z);
//end;

class operator TGVec3.+ (constref left: TGVec3; right: TComponent): TGVec3;
begin
  result := TGVec3.Create(left.x+right, left.y+right, left.z+right);
end;

class operator TGVec3.- (constref left: TGVec3; right: TComponent): TGVec3;
begin
  result := TGVec3.Create(left.x-right, left.y-right, left.z-right);
end;

class operator TGVec3.* (constref left: TGVec3; right: TComponent): TGVec3;
begin
  result := TGVec3.Create(left.x*right, left.y*right, left.z*right);
end;

//class operator TGVec3./ (constref left: TGVec3; right: TComponent): TGVec3;
//begin
//  result := Vec3(left.x div right, left.y/right, left.z div right);
//end;

function TGVec3.GetComponent(index: integer): TComponent;
begin
  result := PComponent(PComponent(@x) + index)^;
end;

procedure TGVec3.SetComponent(index: integer; newValue: TComponent);
begin
  PComponent(PComponent(@x) + index)^ := newValue;
end;

constructor TGVec3.Create(_x, _y, _z: TComponent);
begin
  x := _x;
  y := _y;
  z := _z;
end;

function TGVec3.Volume: TComponent;
begin
  result := x * y * z;
end;

function TGVec3.XY: specialize TGVec2<TComponent>;
begin
  result.x := x;
  result.y := y;
end;

function TGVec3.Offset(byX, byY, byZ: TComponent): TGVec3;
begin
  result.x := x + byX;
  result.y := y + byY;
  result.z := z + byZ;
end;

function TGVec3.Offset(by: TGVec3): TGVec3;
begin
  result.x := x + by.X;
  result.y := y + by.Y;
  result.z := z + by.Z;
end;

function TGVec3.ToStr: string;
begin
  result := '{'+x.ToStr+','+y.ToStr+','+z.ToStr+'}';
end;

procedure TGVec3.Show;
begin
  writeln(ToStr);
end;

{*****************************************************************************
 *                                TGVec4
 *****************************************************************************}

class operator TGVec4.= (constref left, right: TGVec4): boolean;
begin
  result := (left.x = right.x) and (left.y = right.y) and (left.z = right.z) and (left.w = right.w);
end;

function TGVec4.GetComponent(index: integer): TComponent;
begin
  result := PComponent(PComponent(@x) + index)^;
end;

procedure TGVec4.SetComponent(index: integer; newValue: TComponent);
begin
  PComponent(PComponent(@x) + index)^ := newValue;
end;

constructor TGVec4.Create(_x, _y, _z, _w: TComponent);
begin
  x := _x;
  y := _y;
  z := _z;
  w := _w;
end;

function TGVec4.XY: specialize TGVec2<TComponent>;
begin
  result.x := x;
  result.y := y;
end;

function TGVec4.XYZ: specialize TGVec3<TComponent>;
begin
  result.x := x;
  result.y := y;
  result.z := z;
end;

function TGVec4.ToStr: string;
begin
  result := '{'+x.ToStr+','+y.ToStr+','+z.ToStr+','+w.ToStr+'}';
end;

procedure TGVec4.Show;
begin
  writeln(ToStr);
end;

{*****************************************************************************
 *                               Procedural
 *****************************************************************************}

function Normalize(vec: TVec2): TVec2;
begin
  result := vec.Normalize;
end;

function Normalize(vec: TVec3): TVec3;
begin
  result := vec.Normalize;
end;

function RoundUp(number: TScalar): longint;
begin
  if Frac(number) > 0 then
    result := trunc(number) + 1
  else
    result := trunc(number);
end;

function RoundTo(number: TScalar; Places: longint): TScalar;
var
  t: TScalar;
begin
  if places = 0 then
    exit(number);
  t := power(10, places);
  result := round(number * t) / t;
end;

function Angle(constref a,b,c: TVec3): TScalar;
var 
  DeltaAB, DeltaCB: TVec3;
  LengthAB, LengthCB: TScalar;
begin
  DeltaAB:=a-b;
  DeltaCB:=c-b;
  LengthAB:=DeltaAB.Magnitude;
  LengthCB:=DeltaCB.Magnitude;
  if (LengthAB=0.0) or (LengthCB=0.0) then
    result:=0.0
  else
    result:=ArcCos(DeltaAB.Dot(DeltaCB)/(LengthAB*LengthCB));
end;

function Clamp(int: integer; lowest, highest: integer): integer;
begin
  if int < lowest then
    result := lowest
  else if int > highest then
    result := highest
  else
    result := int;
end;

function Clamp(int: TScalar; lowest, highest: TScalar): TScalar;
begin
  if int < lowest then
    result := lowest
  else if int > highest then
    result := highest
  else
    result := int;
end;

function Abs(vec: TVec2): TVec2;
begin
  result.x := abs(vec.x);
  result.y := abs(vec.y);
end;

function Abs(vec: TVec3): TVec3;
begin
  result.x := abs(vec.x);
  result.y := abs(vec.y);
  result.z := abs(vec.z);
end;

function Abs(vec: TVec4): TVec4;
begin
  result.x := abs(vec.x);
  result.y := abs(vec.y);
  result.z := abs(vec.z);
  result.w := abs(vec.w);
end;

function Trunc(vec: TVec2): TVec2;
begin
  result.x := trunc(vec.x);
  result.y := trunc(vec.y);
end;

function Trunc(vec: TVec3): TVec3;
begin
  result.x := trunc(vec.x);
  result.y := trunc(vec.y);
  result.z := trunc(vec.z);
end;

function Trunc(vec: TVec4): TVec4;
begin
  result.x := trunc(vec.x);
  result.y := trunc(vec.y);
  result.z := trunc(vec.z);
  result.w := trunc(vec.w);
end;

{ Vec2 }

function Vec2(x, y: TScalar): TVec2; inline;
begin
  result.x := x;
  result.y := y;
end;

function Vec2(constref vec: TVec2i): TVec2; inline;
begin
  result := Vec2(vec.x, vec.y);
end;

function V2(x, y: TScalar): TVec2; inline;
begin
  result := Vec2(x, y);
end;

function V2(constref vec: TVec2i): TVec2; inline;
begin
  result := Vec2(vec.x, vec.y);
end;

function V2(constref vec: TVec3): TVec2; inline;
begin
  result := Vec2(vec.x, vec.y);
end;

{ Vec3 }

function Vec3(x, y, z: TScalar): TVec3; inline;
begin
  result.x := x;
  result.y := y;
  result.z := z;
end;

function Vec3(constref vec: TVec2; z: TScalar): TVec3; inline;
begin
  result.x := vec.x;
  result.y := vec.y;
  result.z := z;
end;

function Vec3(constref vec: TVec3i): TVec3; inline;
begin
  result := Vec3(vec.x, vec.y, vec.z);
end;

function V3(x, y, z: TScalar): TVec3; inline;
begin
  result := Vec3(x, y, z);
end;

function V3(constref vec: TVec2; z: TScalar): TVec3; inline;
begin
  result := Vec3(vec, z);
end;

function V3(constref vec: TVec3i): TVec3; inline;
begin
  result := Vec3(vec.x, vec.y, vec.z);
end;

{ Vec4 }

function Vec4(x, y, z, w: TScalar): TVec4; inline;
begin
  result.x := x;
  result.y := y;
  result.z := z;
  result.w := w;
end;

function Vec4(constref vec: TVec3; w: TScalar): TVec4; inline;
begin
  result.x := vec.x;
  result.y := vec.y;
  result.z := vec.z;
  result.w := w;
end;

function Vec4(constref vec: TVec2; z, w: TScalar): TVec4; inline;
begin
  result.x := vec.x;
  result.y := vec.y;
  result.z := z;
  result.w := w;
end;

function Vec4(constref vec: TVec4i): TVec4; inline;
begin
  result := Vec4(vec.x, vec.y, vec.z, vec.w);
end;

function V4(constref vec: TVec3; w: TScalar): TVec4; inline;
begin
  result := Vec4(vec, w);
end;

function V4(constref vec: TVec2; z, w: TScalar): TVec4; inline;
begin
  result := Vec4(vec, z, w);
end;

function V4(x, y, z, w: TScalar): TVec4; inline;
begin
  result := Vec4(x, y, z, w);
end;

function V4(constref vec: TVec4i): TVec4; inline;
begin
  result := Vec4(vec.x, vec.y, vec.z, vec.w);
end;

{*****************************************************************************
 *                                    TVec2
 *****************************************************************************}

function TVec2.GetComponent(pIndex:integer):TScalar;
begin
 result:=v[pIndex];
end;

procedure TVec2.SetComponent(pIndex:integer; pValue:TScalar);
begin
 v[pIndex]:=pValue;
end;

function TVec2.PerpendicularRight: TVec2;
begin
  result := V2(-y, x);
end;

function TVec2.PerpendicularLeft: TVec2;
begin
  result := V2(y, -x);
end;

function TVec2.Angle: TScalar;
begin
  result := Arctan2(y, x);
end;

function TVec2.Distance(point: TVec2): TScalar;
begin
  result := (self - point).Magnitude;
end;

function TVec2.Lerp(t: TScalar; p: TVec2): TVec2;
begin
  result := (self * (1 - t)) + (p * t);
end;

function TVec2.Reflect(n: TVec2): TVec2;
begin
  result := self - ((n * self.Dot(n)) * 2);
end;

function TVec2.Length: TScalar;
begin
  result := Sqrt(SquaredLength);
end;

function TVec2.SquaredLength: TScalar;
begin
  result := Power(x, 2) + Power(y, 2);
end;

function TVec2.Magnitude: TScalar;
begin
  result := Length;
end;

function TVec2.Normalize: TVec2;
var
  fac: TScalar;
begin
  //result := self / Magnitude;
  fac:=Sqrt(Sqr(x)+Sqr(y));
  if fac<>0.0 then begin
    fac:=1.0/fac;
    result.x:=x*fac;
    result.y:=y*fac;
  end else begin
    result.x:=0.0;
    result.y:=0.0;
  end;
end;

function TVec2.Negate: TVec2;
begin
  result := Vec2(-x, -y);
end;

function TVec2.Dot(constref vec: TVec2): TScalar;
begin
  result := (x * vec.x) + (y * vec.y);
end;

function TVec2.Cross(constref vec: TVec2): TVec2;
begin
 result.x := (y * vec.x) - (x * vec.y);
 result.y := (x * vec.y) - (y * vec.x);
end; 

function TVec2.Rotate(radians: TScalar): TVec2;
begin
  result.x := (self.x * cos(radians)) - (self.y * sin(radians));
  result.y := (self.x * sin(radians)) + (self.y * cos(radians));
end;

function TVec2.Rotate(origin: TVec2; radians: TScalar): TVec2;
var
  dx,dy: TScalar;
begin
  dx := (origin.y * sin(radians)) - (origin.x * cos(radians)) + origin.x;
  dy := -(origin.x * sin(radians)) - (origin.y * cos(radians)) + origin.y;
  result.x := (self.x * cos(radians)) - (self.y * sin(radians)) + dx;
  result.y := (self.x * sin(radians)) + (self.y * cos(radians)) + dy;
end;

function TVec2.Offset(byX, byY: TScalar): TVec2;
begin
  result.x := x + byX;
  result.y := y + byY;
end;

function TVec2.Offset(by: TVec2): TVec2;
begin
  result.x := x + by.X;
  result.y := y + by.Y;
end;

function TVec2.Min: TScalar;
begin
  if x < y then
    result := x
  else if y > x then
    result := y
  else
    result := x;
end;

function TVec2.Max: TScalar;
begin
  if x > y then
    result := x
  else if y > x then
    result := y
  else
    result := x;
end;

function TVec2.Sum: TScalar;
begin
  result := x + y;
end;

function TVec2.Pinch(max, min: TScalar): TVec2;
begin
  result := self;
  if abs(result.x) < max then
    result.x := min;
  if abs(result.y) < max then
    result.y := min;
end;

function TVec2.Clamp(lowest, highest: TVec2): TVec2;
begin
  result := self;
  if result.x < lowest.x then
    result.x := lowest.x
  else if result.x > highest.x then
    result.x := highest.x;
  if result.y < lowest.y then
    result.y := lowest.y
  else if result.y > highest.y then
    result.y := highest.y;
end;

function TVec2.Clamp(lowest, highest: TScalar): TVec2;
begin
  result := self;
  if result.x < lowest then
    result.x := lowest
  else if result.x > highest then
    result.x := highest;
  if result.y < lowest then
    result.y := lowest
  else if result.y > highest then
    result.y := highest;
end;

function TVec2.IsZero: boolean;
begin
  result := (x = 0) and (y = 0);
end;

procedure TVec2.Show;
begin
  writeln(ToStr);
end;

function TVec2.ToStr(places: integer = -1): string;
begin
  result := '{'+FloatToStr(x, places)+','+FloatToStr(y, places)+'}';
end;

class operator TVec2.:= (right: TScalar): TVec2;
begin
  result.x := right;
  result.y := right;
end;

class operator TVec2.- (constref right: TVec2): TVec2;
begin
  result.x := -right.x;
  result.y := -right.y;
end;

class operator TVec2.+ (left: string; right: TVec2): string;
begin
  result := left+right.ToStr;
end;

class operator TVec2.+ (constref left, right: TVec2): TVec2;
begin
  result := Vec2(left.x+right.x, left.y+right.y);
end;

class operator TVec2.- (constref left, right: TVec2): TVec2;
begin
  result := Vec2(left.x-right.x, left.y-right.y);
end;

class operator TVec2.* (constref left, right: TVec2): TVec2; 
begin
  result := Vec2(left.x*right.x, left.y*right.y);
end;

class operator TVec2./ (constref left, right: TVec2): TVec2; 
begin
  result := Vec2(left.x/right.x, left.y/right.y);
end;

class operator TVec2.= (constref left, right: TVec2): boolean; 
begin
  result := (left.x = right.x) and (left.y = right.y);
end;

class operator TVec2.+ (constref left: TVec2; right: TScalar): TVec2;
begin
  result := Vec2(left.x+right, left.y+right);
end;

class operator TVec2.- (constref left: TVec2; right: TScalar): TVec2;
begin
  result := Vec2(left.x-right, left.y-right);
end;

class operator TVec2.* (constref left: TVec2; right: TScalar): TVec2;
begin
  result := Vec2(left.x*right, left.y*right);
end;

class operator TVec2./ (constref left: TVec2; right: TScalar): TVec2;
begin
  result := Vec2(left.x/right, left.y/right);
end;

class function TVec2.Zero: TVec2;
begin
  result.x := 0;
  result.y := 0;
end;

class function TVec2.FromAngle(radians: TScalar): TVec2;
begin
  SinCos(radians, result.y, result.x);
end;

{*****************************************************************************
 *                                  TVec3
 *****************************************************************************}

function TVec3.GetComponent(pIndex:integer):TScalar;
begin
 result:=v[pIndex];
end;

procedure TVec3.SetComponent(pIndex:integer; pValue:TScalar);
begin
 v[pIndex]:=pValue;
end;

class function TVec3.Up: TVec3;
begin
  result := Vec3(0,1,0);
end;

procedure TVec3.Show;
begin
  writeln(ToStr);
end;

function TVec3.XY: TVec2;
begin
  result := V2(x, y);
end;

function TVec3.ToStr(places: integer = -1): string;
begin
  result := '{'+FloatToStr(x, places)+','+FloatToStr(y, places)+','+FloatToStr(z, places)+'}';
end;

function TVec3.Length: TScalar;
begin
  result := Sqrt(SquaredLength);
end;

function TVec3.SquaredLength: TScalar;
begin
  result := Power(x, 2) + Power(y, 2) + Power(z, 2);
end;

function TVec3.Magnitude: TScalar;
begin
  result := Length;
end;

function TVec3.Normalize: TVec3;
var
  fac: TScalar;
begin
  fac:=Sqrt(Sqr(x)+Sqr(y)+Sqr(z));
  if fac<>0.0 then begin
    fac:=1.0/fac;
    result.x:=x*fac;
    result.y:=y*fac;
    result.z:=z*fac;
  end else begin
    result.x:=0.0;
    result.y:=0.0;
    result.z:=0.0;
  end;
end;

function TVec3.Negate: TVec3;
begin
  result := Vec3(-x, -y, -z);
end;

function TVec3.Dot(constref vec: TVec3): TScalar;
begin
  result := (x * vec.x) + (y * vec.y) + (z * vec.z);
end;

function TVec3.Cross(constref vec: TVec3): TVec3;
begin
 result.x:=(y*vec.z)-(z*vec.y);
 result.y:=(z*vec.x)-(x*vec.z);
 result.z:=(x*vec.y)-(y*vec.x);
end;

function TVec3.Distance(point: TVec3): TScalar;
begin
  result := (self - point).Magnitude;
end;

function TVec3.Lerp(t: TScalar; p: TVec3): TVec3;
begin
  result := (self * (1 - t)) + (p * t);
end;

function TVec3.Reflect(n: TVec3): TVec3;
begin
  result := self - ((n * self.Dot(n)) * 2);
end;

function TVec3.Offset(byX, byY, byZ: TScalar): TVec3;
begin
  result.x := x + byX;
  result.y := y + byY;
  result.z := z + byZ;
end;

function TVec3.Offset(by: TVec3): TVec3;
begin
  result.x := x + by.X;
  result.y := y + by.Y;
  result.z := z + by.Z;
end;

function TVec3.Clamp(lowest, highest: TVec3): TVec3;
begin
  result := self;
  if result.x < lowest.x then
    result.x := lowest.x;
  if result.y < lowest.y then
    result.y := lowest.y;
  if result.z < lowest.z then
    result.z := lowest.z;
  if result.x > highest.x then
    result.x := highest.x;
  if result.y > highest.y then
    result.y := highest.y;
  if result.z > highest.z then
    result.z := highest.z;
end;

function TVec3.Clamp(lowest, highest: TScalar): TVec3;
begin
  result := self;
  if result.x < lowest then
    result.x := lowest;
  if result.y < lowest then
    result.y := lowest;
  if result.z < lowest then
    result.z := lowest;
  if result.x > highest then
    result.x := highest;
  if result.y > highest then
    result.y := highest;
  if result.z > highest then
    result.z := highest;
end;

function TVec3.IsZero: boolean;
begin
  result := (x = 0) and (y = 0) and (z = 0);
end;

function TVec3.Sum: TScalar;
begin
  result := x + y + z;
end;

class operator TVec3.:= (a:TScalar): TVec3;
begin
  result.x := a;
  result.y := a;
  result.z := a;
end;

class operator TVec3.explicit (right: TVec3): TVec2;
begin
  result.x := right.x;
  result.y := right.y;
end;

class operator TVec3.- (right: TVec3): TVec3;
begin
  result.x := -right.x;
  result.y := -right.y;
  result.z := -right.z;
end;

class operator TVec3.+ (left: string; right: TVec3): string;
begin
  result := left+right.ToStr;
end;

class operator TVec3.+ (constref left, right: TVec3): TVec3;
begin
  result := Vec3(left.x+right.x, left.y+right.y, left.z+right.z);
end;

class operator TVec3.- (constref left, right: TVec3): TVec3;
begin
  result := Vec3(left.x-right.x, left.y-right.y, left.z-right.z);
end;

class operator TVec3.* (constref left, right: TVec3): TVec3; 
begin
  result := Vec3(left.x*right.x, left.y*right.y, left.z*right.z);
end;

class operator TVec3./ (constref left, right: TVec3): TVec3; 
begin
  result := Vec3(left.x/right.x, left.y/right.y, left.z/right.z);
end;

class operator TVec3.= (constref left, right: TVec3): boolean; 
begin
  result := (left.x = right.x) and (left.y = right.y) and (left.z = right.z);
end;

class operator TVec3.+ (constref left: TVec3; right: TScalar): TVec3;
begin
  result := Vec3(left.x+right, left.y+right, left.z+right);
end;

class operator TVec3.- (constref left: TVec3; right: TScalar): TVec3;
begin
  result := Vec3(left.x-right, left.y-right, left.z-right);
end;

class operator TVec3.* (constref left: TVec3; right: TScalar): TVec3;
begin
  result := Vec3(left.x*right, left.y*right, left.z*right);
end;

class operator TVec3./ (constref left: TVec3; right: TScalar): TVec3;
begin
  result := Vec3(left.x/right, left.y/right, left.z/right);
end;

class function TVec3.Zero: TVec3;
begin
  result.x := 0;
  result.y := 0;
  result.z := 0;
end;

{*****************************************************************************
 *                                    TVec4
 *****************************************************************************}

function TVec4.Length: TScalar;
begin
  result := Sqrt(SquaredLength);
end;

function TVec4.SquaredLength: TScalar;
begin
  result := Power(x, 2) + Power(y, 2) + Power(z, 2) + Power(w, 2);
end;

function TVec4.Normalize: TVec4;
var
  fac: TScalar;
begin
  //result := self / Magnitude;
  fac:=Sqrt(Sqr(x)+Sqr(y)+Sqr(z)+Sqr(w));
  if fac<>0.0 then begin
    fac:=1.0/fac;
    result.x:=x*fac;
    result.y:=y*fac;
    result.z:=z*fac;
    result.w:=w*fac;
  end else begin
    result.x:=0.0;
    result.y:=0.0;
    result.z:=0.0;
    result.w:=0.0;
  end;
end;

function TVec4.Negate: TVec4;
begin
  result := Vec4(-x, -y, -z, -w);
end;

function TVec4.Dot(constref vec: TVec4): TScalar;
begin
  result := (x * vec.x) + (y * vec.y) + (z * vec.z) + (w * vec.w);
end;

function TVec4.Cross(constref vec: TVec4): TVec4;
begin
 result.x:=(y*vec.z)-(z*vec.y);
 result.y:=(z*vec.x)-(x*vec.z);
 result.z:=(x*vec.y)-(y*vec.x);
 result.w:=1.0;
end;

function TVec4.GetComponent(pIndex:integer):TScalar;
begin
 result:=v[pIndex];
end;

procedure TVec4.SetComponent(pIndex:integer; pValue:TScalar);
begin
 v[pIndex]:=pValue;
end;

function TVec4.IsZero: boolean;
begin
  result := (x = 0) and (y = 0) and (z = 0) and (w = 0);
end;

class operator TVec4.:= (a:TScalar): TVec4;
begin
  result.x := a;
  result.y := a;
  result.z := a;
  result.w := a;
end;

class operator TVec4.+ (left: string; right: TVec4): string;
begin
  result := left+right.ToStr;
end;

class operator TVec4.+ (constref left, right: TVec4): TVec4;
begin
  result := Vec4(left.x+right.x, left.y+right.y, left.z+right.z, left.w+right.w);
end;

class operator TVec4.- (constref left, right: TVec4): TVec4;
begin
  result := Vec4(left.x-right.x, left.y-right.y, left.z-right.z, left.w-right.w);
end;

class operator TVec4.* (constref left, right: TVec4): TVec4; 
begin
  result := Vec4(left.x*right.x, left.y*right.y, left.z*right.z, left.w*right.w);
end;

class operator TVec4./ (constref left, right: TVec4): TVec4; 
begin
  result := Vec4(left.x/right.x, left.y/right.y, left.z/right.z, left.w/right.w);
end;

class operator TVec4.= (constref left, right: TVec4): boolean; 
begin
  result := (left.x = right.x) and (left.y = right.y) and (left.z = right.z) and (left.w = right.w);
end;

class operator TVec4.+ (constref left: TVec4; right: TScalar): TVec4;
begin
  result := Vec4(left.x+right, left.y+right, left.z+right, left.w+right);
end;

class operator TVec4.- (constref left: TVec4; right: TScalar): TVec4;
begin
  result := Vec4(left.x-right, left.y-right, left.z-right, left.w-right);
end;

class operator TVec4.* (constref left: TVec4; right: TScalar): TVec4;
begin
  result := Vec4(left.x*right, left.y*right, left.z*right, left.w*right);
end;

class operator TVec4./ (constref left: TVec4; right: TScalar): TVec4;
begin
  result := Vec4(left.x/right, left.y/right, left.z/right, left.w/right);
end; 

procedure TVec4.Show;
begin
  writeln(ToStr);
end;

function TVec4.XY: TVec2;
begin
  result := V2(x, y);
end;

function TVec4.XYZ: TVec3;
begin
  result := V3(x, y, z);
end;

function TVec4.ToStr(places: integer = -1): string;
begin
  result := '{'+FloatToStr(x, places)+','+FloatToStr(y, places)+','+FloatToStr(z, places)+','+FloatToStr(w, places)+'}';
end;

class function TVec4.Zero: TVec4;
begin
  result.x := 0;
  result.y := 0;
  result.z := 0;
  result.w := 0;
end;

{*****************************************************************************
 *                                  TMat4
 *****************************************************************************}

function M4: TMat4;
begin
  result := TMat4.Identity;
end;

function TMat4.GetComponent(column, row:integer):TScalar;
begin
 result:=m[column,row];
end;

procedure TMat4.SetComponent(column, row:integer; pValue:TScalar);
begin
 m[column,row]:=pValue;
end;

function SameValue(a, b: TScalar): boolean; inline;
begin
  result := a = b;
end;

function TMat4.Ptr: pointer;
begin
  result := @column[0];
end;

class function TMat4.Identity: TMat4;
begin
  result := Matrix4x4Identity;
end;

constructor TMat4.Translate(tx,ty,tz:TScalar);
begin
 m[0,0]:=1.0;
 m[0,1]:=0.0;
 m[0,2]:=0.0;
 m[0,3]:=0.0;
 m[1,0]:=0.0;
 m[1,1]:=1.0;
 m[1,2]:=0.0;
 m[1,3]:=0.0;
 m[2,0]:=0.0;
 m[2,1]:=0.0;
 m[2,2]:=1.0;
 m[2,3]:=0.0;
 m[3,0]:=tx;
 m[3,1]:=ty;
 m[3,2]:=tz;
 m[3,3]:=1.0;
end;

constructor TMat4.Translate(constref pTranslate:TVec3);
begin
 m[0,0]:=1.0;
 m[0,1]:=0.0;
 m[0,2]:=0.0;
 m[0,3]:=0.0;
 m[1,0]:=0.0;
 m[1,1]:=1.0;
 m[1,2]:=0.0;
 m[1,3]:=0.0;
 m[2,0]:=0.0;
 m[2,1]:=0.0;
 m[2,2]:=1.0;
 m[2,3]:=0.0;
 m[3,0]:=pTranslate.x;
 m[3,1]:=pTranslate.y;
 m[3,2]:=pTranslate.z;
 m[3,3]:=1.0;
end;

constructor TMat4.Translate(tx,ty,tz,tw:TScalar);
begin
 m[0,0]:=1.0;
 m[0,1]:=0.0;
 m[0,2]:=0.0;
 m[0,3]:=0.0;
 m[1,0]:=0.0;
 m[1,1]:=1.0;
 m[1,2]:=0.0;
 m[1,3]:=0.0;
 m[2,0]:=0.0;
 m[2,1]:=0.0;
 m[2,2]:=1.0;
 m[2,3]:=0.0;
 m[3,0]:=tx;
 m[3,1]:=ty;
 m[3,2]:=tz;
 m[3,3]:=tw;
end;

constructor TMat4.Scale(x, y, z: TScalar);
begin 
  column[0].x := x;
  column[0].y := 0;
  column[0].z := 0;
  column[0].w := 0;
          
  column[1].x := 0;
  column[1].y := y;
  column[1].z := 0;
  column[1].w := 0;
 
  column[2].x := 0;
  column[2].y := 0;
  column[2].z := z;
  column[2].w := 0;
          
  column[3].x := 0;
  column[3].y := 0;
  column[3].z := 0;
  column[3].w := 1;
end;

constructor TMat4.Scale(constref pScale: TVec2; z: TScalar);
begin
  Scale(pScale.x, pScale.y, z);
end;

constructor TMat4.Scale(constref pScale: TVec3);
begin
  Scale(pScale.x, pScale.y, pScale.z);
end;

constructor TMat4.RotateX(Angle:TScalar);
begin
 m[0,0]:=1.0;
 m[0,1]:=0.0;
 m[0,2]:=0.0;
 m[0,3]:=0.0;
 m[1,0]:=0.0;
 SinCos(Angle,m[1,2],m[1,1]);
 m[1,3]:=0.0;
 m[2,0]:=0.0;
 m[2,1]:=-m[1,2];
 m[2,2]:=m[1,1];
 m[2,3]:=0.0;
 m[3,0]:=0.0;
 m[3,1]:=0.0;
 m[3,2]:=0.0;
 m[3,3]:=1.0;
end;

constructor TMat4.RotateY(Angle:TScalar);
begin
 SinCos(Angle,m[2,0],m[0,0]);
 m[0,1]:=0.0;
 m[0,2]:=-m[2,0];
 m[0,3]:=0.0;
 m[1,0]:=0.0;
 m[1,1]:=1.0;
 m[1,2]:=0.0;
 m[1,3]:=0.0;
 m[2,1]:=0.0;
 m[2,2]:=m[0,0];
 m[2,3]:=0.0;
 m[3,0]:=0.0;
 m[3,1]:=0.0;
 m[3,2]:=0.0;
 m[3,3]:=1.0;
end;

constructor TMat4.RotateZ(Angle:TScalar);
begin
 SinCos(Angle,m[0,1],m[0,0]);
 m[0,2]:=0.0;
 m[0,3]:=0.0;
 m[1,0]:=-m[0,1];
 m[1,1]:=m[0,0];
 m[1,2]:=0.0;
 m[1,3]:=0.0;
 m[2,0]:=0.0;
 m[2,1]:=0.0;
 m[2,2]:=1.0;
 m[2,3]:=0.0;
 m[3,0]:=0.0;
 m[3,1]:=0.0;
 m[3,2]:=0.0;
 m[3,3]:=1.0;
end;

constructor TMat4.Rotate(Angle:TScalar; constref Axis:TVec3);
var SinusAngle,CosinusAngle:TScalar;
begin
 SinCos(Angle,SinusAngle,CosinusAngle);
 m[0,0]:=CosinusAngle+((1.0-CosinusAngle)*sqr(Axis.x));
 m[1,0]:=((1.0-CosinusAngle)*Axis.x*Axis.y)-(Axis.z*SinusAngle);
 m[2,0]:=((1.0-CosinusAngle)*Axis.x*Axis.z)+(Axis.y*SinusAngle);
 m[0,3]:=0.0;
 m[0,1]:=((1.0-CosinusAngle)*Axis.x*Axis.z)+(Axis.z*SinusAngle);
 m[1,1]:=CosinusAngle+((1.0-CosinusAngle)*sqr(Axis.y));
 m[2,1]:=((1.0-CosinusAngle)*Axis.y*Axis.z)-(Axis.x*SinusAngle);
 m[1,3]:=0.0;
 m[0,2]:=((1.0-CosinusAngle)*Axis.x*Axis.z)-(Axis.y*SinusAngle);
 m[1,2]:=((1.0-CosinusAngle)*Axis.y*Axis.z)+(Axis.x*SinusAngle);
 m[2,2]:=CosinusAngle+((1.0-CosinusAngle)*sqr(Axis.z));
 m[2,3]:=0.0;
 m[3,0]:=0.0;
 m[3,1]:=0.0;
 m[3,2]:=0.0;
 m[3,3]:=1.0;
end;

constructor TMat4.Rotate(constref pMatrix:TMat4);
begin
 m[0,0]:=pMatrix.m[0,0];
 m[0,1]:=pMatrix.m[0,1];
 m[0,2]:=pMatrix.m[0,2];
 m[0,3]:=0.0;
 m[1,0]:=pMatrix.m[1,0];
 m[1,1]:=pMatrix.m[1,1];
 m[1,2]:=pMatrix.m[1,2];
 m[1,3]:=0.0;
 m[2,0]:=pMatrix.m[2,0];
 m[2,1]:=pMatrix.m[2,1];
 m[2,2]:=pMatrix.m[2,2];
 m[2,3]:=0.0;
 m[3,0]:=0.0;
 m[3,1]:=0.0;
 m[3,2]:=0.0;
 m[3,3]:=1.0;
end;

constructor TMat4.OrthoGL(Left,Right,Bottom,Top,zNear,zFar:TScalar);
var rml,tmb,fmn:TScalar;
begin
 rml:=Right-Left;
 tmb:=Top-Bottom;
 fmn:=zFar-zNear;
 m[0,0]:=2.0/rml;
 m[0,1]:=0.0;
 m[0,2]:=0.0;
 m[0,3]:=0.0;
 m[1,0]:=0.0;
 m[1,1]:=2.0/tmb;
 m[1,2]:=0.0;
 m[1,3]:=0.0;
 m[2,0]:=0.0;
 m[2,1]:=0.0;
 m[2,2]:=(-2.0)/fmn;
 m[2,3]:=0.0;
 m[3,0]:=(-(Right+Left))/rml;
 m[3,1]:=(-(Top+Bottom))/tmb;
 m[3,2]:=(-(zFar+zNear))/fmn;
 m[3,3]:=1.0;
end;

constructor TMat4.Ortho(Left,Right,Bottom,Top,zNear,zFar:TScalar);
var rml,tmb,fmn: TScalar;
begin
  rml:=Right-Left;
  tmb:=Top-Bottom;
  fmn:=zFar-zNear;
  m[0,0]:=2.0/rml;
  m[0,1]:=0.0;
  m[0,2]:=0.0;
  m[0,3]:=0.0;
  m[1,0]:=0.0;
  m[1,1]:=2.0/tmb;
  m[1,2]:=0.0;
  m[1,3]:=0.0;
  m[2,0]:=0.0;
  m[2,1]:=0.0;
  m[2,2]:=(-1.0)/fmn;
  m[2,3]:=0.0;
  m[3,0]:=(-(Right+Left))/rml;
  m[3,1]:=(-(Top+Bottom))/tmb;
  m[3,2]:=(-(zNear))/fmn;
  m[3,3]:=1.0;  
end;

constructor TMat4.Perspective(fovy,Aspect,zNear,zFar:TScalar);
var Sine,Cotangent,ZDelta,Radians:TScalar;
begin
 Radians:=(fovy*0.5)*DEG2RAD;
 ZDelta:=zFar-zNear;
 Sine:=sin(Radians);
 if not ((ZDelta=0) or (Sine=0) or (aspect=0)) then begin
  Cotangent:=cos(Radians)/Sine;
  m:= Matrix4x4Identity.m;
  m[0,0]:=Cotangent/aspect;
  m[1,1]:=Cotangent;
  m[2,2]:=(-zFar)/ZDelta;
  m[2,3]:=-1;
  m[3,2]:=(-(zNear*zFar))/ZDelta;
  m[3,3]:=0.0;
 end;
end; 

constructor TMat4.PerspectiveGL(fovy,Aspect,zNear,zFar:TScalar);
var Sine,Cotangent,ZDelta,Radians:TScalar;
begin
 Radians:=(fovy*0.5)*DEG2RAD;
 ZDelta:=zFar-zNear;
 Sine:=sin(Radians);
 if not ((ZDelta=0) or (Sine=0) or (aspect=0)) then begin
  Cotangent:=cos(Radians)/Sine;
  m:=Matrix4x4Identity.m;
  m[0,0]:=Cotangent/aspect;
  m[1,1]:=Cotangent;
  m[2,2]:=(-(zFar+zNear))/ZDelta;
  m[2,3]:=-1-0;
  m[3,2]:=(-(2.0*zNear*zFar))/ZDelta;
  m[3,3]:=0.0;
 end;
end;

constructor TMat4.LookAt(constref Eye,Center,Up:TVec3);
var RightVector,UpVector,ForwardVector:TVec3;
begin
 ForwardVector:=(Eye-Center).Normalize;
 RightVector:=(Up.Cross(ForwardVector)).Normalize;
 UpVector:=(ForwardVector.Cross(RightVector)).Normalize;
 m[0,0]:=RightVector.x;
 m[1,0]:=RightVector.y;
 m[2,0]:=RightVector.z;
 m[3,0]:=-((RightVector.x*Eye.x)+(RightVector.y*Eye.y)+(RightVector.z*Eye.z));
 m[0,1]:=UpVector.x;
 m[1,1]:=UpVector.y;
 m[2,1]:=UpVector.z;
 m[3,1]:=-((UpVector.x*Eye.x)+(UpVector.y*Eye.y)+(UpVector.z*Eye.z));
 m[0,2]:=ForwardVector.x;
 m[1,2]:=ForwardVector.y;
 m[2,2]:=ForwardVector.z;
 m[3,2]:=-((ForwardVector.x*Eye.x)+(ForwardVector.y*Eye.y)+(ForwardVector.z*Eye.z));
 m[0,3]:=0.0;
 m[1,3]:=0.0;
 m[2,3]:=0.0;
 m[3,3]:=1.0;
end;

function TMat4.Inverse:TMat4;
var
  t0,t4,t8,t12,d:TScalar;
begin
 t0:=(((m[1,1]*m[2,2]*m[3,3])-(m[1,1]*m[2,3]*m[3,2]))-(m[2,1]*m[1,2]*m[3,3])+(m[2,1]*m[1,3]*m[3,2])+(m[3,1]*m[1,2]*m[2,3]))-(m[3,1]*m[1,3]*m[2,2]);
 t4:=((((-(m[1,0]*m[2,2]*m[3,3]))+(m[1,0]*m[2,3]*m[3,2])+(m[2,0]*m[1,2]*m[3,3]))-(m[2,0]*m[1,3]*m[3,2]))-(m[3,0]*m[1,2]*m[2,3]))+(m[3,0]*m[1,3]*m[2,2]);
 t8:=((((m[1,0]*m[2,1]*m[3,3])-(m[1,0]*m[2,3]*m[3,1]))-(m[2,0]*m[1,1]*m[3,3]))+(m[2,0]*m[1,3]*m[3,1])+(m[3,0]*m[1,1]*m[2,3]))-(m[3,0]*m[1,3]*m[2,1]);
 t12:=((((-(m[1,0]*m[2,1]*m[3,2]))+(m[1,0]*m[2,2]*m[3,1])+(m[2,0]*m[1,1]*m[3,2]))-(m[2,0]*m[1,2]*m[3,1]))-(m[3,0]*m[1,1]*m[2,2]))+(m[3,0]*m[1,2]*m[2,1]);
 d:=(m[0,0]*t0)+(m[0,1]*t4)+(m[0,2]*t8)+(m[0,3]*t12);
 if d<>0.0 then begin
  d:=1.0/d;
  result.m[0,0]:=t0*d;
  result.m[0,1]:=(((((-(m[0,1]*m[2,2]*m[3,3]))+(m[0,1]*m[2,3]*m[3,2])+(m[2,1]*m[0,2]*m[3,3]))-(m[2,1]*m[0,3]*m[3,2]))-(m[3,1]*m[0,2]*m[2,3]))+(m[3,1]*m[0,3]*m[2,2]))*d;
  result.m[0,2]:=(((((m[0,1]*m[1,2]*m[3,3])-(m[0,1]*m[1,3]*m[3,2]))-(m[1,1]*m[0,2]*m[3,3]))+(m[1,1]*m[0,3]*m[3,2])+(m[3,1]*m[0,2]*m[1,3]))-(m[3,1]*m[0,3]*m[1,2]))*d;
  result.m[0,3]:=(((((-(m[0,1]*m[1,2]*m[2,3]))+(m[0,1]*m[1,3]*m[2,2])+(m[1,1]*m[0,2]*m[2,3]))-(m[1,1]*m[0,3]*m[2,2]))-(m[2,1]*m[0,2]*m[1,3]))+(m[2,1]*m[0,3]*m[1,2]))*d;
  result.m[1,0]:=t4*d;
  result.m[1,1]:=((((m[0,0]*m[2,2]*m[3,3])-(m[0,0]*m[2,3]*m[3,2]))-(m[2,0]*m[0,2]*m[3,3])+(m[2,0]*m[0,3]*m[3,2])+(m[3,0]*m[0,2]*m[2,3]))-(m[3,0]*m[0,3]*m[2,2]))*d;
  result.m[1,2]:=(((((-(m[0,0]*m[1,2]*m[3,3]))+(m[0,0]*m[1,3]*m[3,2])+(m[1,0]*m[0,2]*m[3,3]))-(m[1,0]*m[0,3]*m[3,2]))-(m[3,0]*m[0,2]*m[1,3]))+(m[3,0]*m[0,3]*m[1,2]))*d;
  result.m[1,3]:=(((((m[0,0]*m[1,2]*m[2,3])-(m[0,0]*m[1,3]*m[2,2]))-(m[1,0]*m[0,2]*m[2,3]))+(m[1,0]*m[0,3]*m[2,2])+(m[2,0]*m[0,2]*m[1,3]))-(m[2,0]*m[0,3]*m[1,2]))*d;
  result.m[2,0]:=t8*d;
  result.m[2,1]:=(((((-(m[0,0]*m[2,1]*m[3,3]))+(m[0,0]*m[2,3]*m[3,1])+(m[2,0]*m[0,1]*m[3,3]))-(m[2,0]*m[0,3]*m[3,1]))-(m[3,0]*m[0,1]*m[2,3]))+(m[3,0]*m[0,3]*m[2,1]))*d;
  result.m[2,2]:=(((((m[0,0]*m[1,1]*m[3,3])-(m[0,0]*m[1,3]*m[3,1]))-(m[1,0]*m[0,1]*m[3,3]))+(m[1,0]*m[0,3]*m[3,1])+(m[3,0]*m[0,1]*m[1,3]))-(m[3,0]*m[0,3]*m[1,1]))*d;
  result.m[2,3]:=(((((-(m[0,0]*m[1,1]*m[2,3]))+(m[0,0]*m[1,3]*m[2,1])+(m[1,0]*m[0,1]*m[2,3]))-(m[1,0]*m[0,3]*m[2,1]))-(m[2,0]*m[0,1]*m[1,3]))+(m[2,0]*m[0,3]*m[1,1]))*d;
  result.m[3,0]:=t12*d;
  result.m[3,1]:=(((((m[0,0]*m[2,1]*m[3,2])-(m[0,0]*m[2,2]*m[3,1]))-(m[2,0]*m[0,1]*m[3,2]))+(m[2,0]*m[0,2]*m[3,1])+(m[3,0]*m[0,1]*m[2,2]))-(m[3,0]*m[0,2]*m[2,1]))*d;
  result.m[3,2]:=(((((-(m[0,0]*m[1,1]*m[3,2]))+(m[0,0]*m[1,2]*m[3,1])+(m[1,0]*m[0,1]*m[3,2]))-(m[1,0]*m[0,2]*m[3,1]))-(m[3,0]*m[0,1]*m[1,2]))+(m[3,0]*m[0,2]*m[1,1]))*d;
  result.m[3,3]:=(((((m[0,0]*m[1,1]*m[2,2])-(m[0,0]*m[1,2]*m[2,1]))-(m[1,0]*m[0,1]*m[2,2]))+(m[1,0]*m[0,2]*m[2,1])+(m[2,0]*m[0,1]*m[1,2]))-(m[2,0]*m[0,2]*m[1,1]))*d;
 end;
end;

function TMat4.Transpose:TMat4;
begin
 result.m[0,0]:=m[0,0];
 result.m[0,1]:=m[1,0];
 result.m[0,2]:=m[2,0];
 result.m[0,3]:=m[3,0];
 result.m[1,0]:=m[0,1];
 result.m[1,1]:=m[1,1];
 result.m[1,2]:=m[2,1];
 result.m[1,3]:=m[3,1];
 result.m[2,0]:=m[0,2];
 result.m[2,1]:=m[1,2];
 result.m[2,2]:=m[2,2];
 result.m[2,3]:=m[3,2];
 result.m[3,0]:=m[0,3];
 result.m[3,1]:=m[1,3];
 result.m[3,2]:=m[2,3];
 result.m[3,3]:=m[3,3];
end;

procedure TMat4.Show; 
begin
  writeln(Tostr);
end;

function TMat4.ToStr: string;
var
  x, y: integer;
begin
  result := '';
  for y := 0 to 3 do
    begin
      result += '[';
      for x := 0 to 3 do
        begin
          if x < 3 then
            result += FloatToStr(m[x, y])+','
          else
            result += FloatToStr(m[x, y]);
        end;
      result += ']';
    end;
end;

class operator TMat4.:= (a:TScalar):TMat4;
begin
 result.m[0,0]:=a;
 result.m[0,1]:=a;
 result.m[0,2]:=a;
 result.m[0,3]:=a;
 result.m[1,0]:=a;
 result.m[1,1]:=a;
 result.m[1,2]:=a;
 result.m[1,3]:=a;
 result.m[2,0]:=a;
 result.m[2,1]:=a;
 result.m[2,2]:=a;
 result.m[2,3]:=a;
 result.m[3,0]:=a;
 result.m[3,1]:=a;
 result.m[3,2]:=a;
 result.m[3,3]:=a;
end;

class operator TMat4.=(constref a,b:TMat4):boolean;
begin
 result:=SameValue(a.m[0,0],b.m[0,0]) and
         SameValue(a.m[0,1],b.m[0,1]) and
         SameValue(a.m[0,2],b.m[0,2]) and
         SameValue(a.m[0,3],b.m[0,3]) and
         SameValue(a.m[1,0],b.m[1,0]) and
         SameValue(a.m[1,1],b.m[1,1]) and
         SameValue(a.m[1,2],b.m[1,2]) and
         SameValue(a.m[1,3],b.m[1,3]) and
         SameValue(a.m[2,0],b.m[2,0]) and
         SameValue(a.m[2,1],b.m[2,1]) and
         SameValue(a.m[2,2],b.m[2,2]) and
         SameValue(a.m[2,3],b.m[2,3]) and
         SameValue(a.m[3,0],b.m[3,0]) and
         SameValue(a.m[3,1],b.m[3,1]) and
         SameValue(a.m[3,2],b.m[3,2]) and
         SameValue(a.m[3,3],b.m[3,3]);
end;

class operator TMat4.<>(constref a,b:TMat4):boolean;
begin
 result:=(not SameValue(a.m[0,0],b.m[0,0])) or
         (not SameValue(a.m[0,1],b.m[0,1])) or
         (not SameValue(a.m[0,2],b.m[0,2])) or
         (not SameValue(a.m[0,3],b.m[0,3])) or
         (not SameValue(a.m[1,0],b.m[1,0])) or
         (not SameValue(a.m[1,1],b.m[1,1])) or
         (not SameValue(a.m[1,2],b.m[1,2])) or
         (not SameValue(a.m[1,3],b.m[1,3])) or
         (not SameValue(a.m[2,0],b.m[2,0])) or
         (not SameValue(a.m[2,1],b.m[2,1])) or
         (not SameValue(a.m[2,2],b.m[2,2])) or
         (not SameValue(a.m[2,3],b.m[2,3])) or
         (not SameValue(a.m[3,0],b.m[3,0])) or
         (not SameValue(a.m[3,1],b.m[3,1])) or
         (not SameValue(a.m[3,2],b.m[3,2])) or
         (not SameValue(a.m[3,3],b.m[3,3]));
end;

class operator TMat4.+(constref a,b:TMat4):TMat4;
begin
 result.m[0,0]:=a.m[0,0]+b.m[0,0];
 result.m[0,1]:=a.m[0,1]+b.m[0,1];
 result.m[0,2]:=a.m[0,2]+b.m[0,2];
 result.m[0,3]:=a.m[0,3]+b.m[0,3];
 result.m[1,0]:=a.m[1,0]+b.m[1,0];
 result.m[1,1]:=a.m[1,1]+b.m[1,1];
 result.m[1,2]:=a.m[1,2]+b.m[1,2];
 result.m[1,3]:=a.m[1,3]+b.m[1,3];
 result.m[2,0]:=a.m[2,0]+b.m[2,0];
 result.m[2,1]:=a.m[2,1]+b.m[2,1];
 result.m[2,2]:=a.m[2,2]+b.m[2,2];
 result.m[2,3]:=a.m[2,3]+b.m[2,3];
 result.m[3,0]:=a.m[3,0]+b.m[3,0];
 result.m[3,1]:=a.m[3,1]+b.m[3,1];
 result.m[3,2]:=a.m[3,2]+b.m[3,2];
 result.m[3,3]:=a.m[3,3]+b.m[3,3];
end;

class operator TMat4.+(constref a:TMat4;b:TScalar):TMat4;
begin
 result.m[0,0]:=a.m[0,0]+b;
 result.m[0,1]:=a.m[0,1]+b;
 result.m[0,2]:=a.m[0,2]+b;
 result.m[0,3]:=a.m[0,3]+b;
 result.m[1,0]:=a.m[1,0]+b;
 result.m[1,1]:=a.m[1,1]+b;
 result.m[1,2]:=a.m[1,2]+b;
 result.m[1,3]:=a.m[1,3]+b;
 result.m[2,0]:=a.m[2,0]+b;
 result.m[2,1]:=a.m[2,1]+b;
 result.m[2,2]:=a.m[2,2]+b;
 result.m[2,3]:=a.m[2,3]+b;
 result.m[3,0]:=a.m[3,0]+b;
 result.m[3,1]:=a.m[3,1]+b;
 result.m[3,2]:=a.m[3,2]+b;
 result.m[3,3]:=a.m[3,3]+b;
end;

class operator TMat4.+(a:TScalar;constref b:TMat4):TMat4;
begin
 result.m[0,0]:=a+b.m[0,0];
 result.m[0,1]:=a+b.m[0,1];
 result.m[0,2]:=a+b.m[0,2];
 result.m[0,3]:=a+b.m[0,3];
 result.m[1,0]:=a+b.m[1,0];
 result.m[1,1]:=a+b.m[1,1];
 result.m[1,2]:=a+b.m[1,2];
 result.m[1,3]:=a+b.m[1,3];
 result.m[2,0]:=a+b.m[2,0];
 result.m[2,1]:=a+b.m[2,1];
 result.m[2,2]:=a+b.m[2,2];
 result.m[2,3]:=a+b.m[2,3];
 result.m[3,0]:=a+b.m[3,0];
 result.m[3,1]:=a+b.m[3,1];
 result.m[3,2]:=a+b.m[3,2];
 result.m[3,3]:=a+b.m[3,3];
end;

class operator TMat4.-(constref a,b:TMat4):TMat4;
begin
 result.m[0,0]:=a.m[0,0]-b.m[0,0];
 result.m[0,1]:=a.m[0,1]-b.m[0,1];
 result.m[0,2]:=a.m[0,2]-b.m[0,2];
 result.m[0,3]:=a.m[0,3]-b.m[0,3];
 result.m[1,0]:=a.m[1,0]-b.m[1,0];
 result.m[1,1]:=a.m[1,1]-b.m[1,1];
 result.m[1,2]:=a.m[1,2]-b.m[1,2];
 result.m[1,3]:=a.m[1,3]-b.m[1,3];
 result.m[2,0]:=a.m[2,0]-b.m[2,0];
 result.m[2,1]:=a.m[2,1]-b.m[2,1];
 result.m[2,2]:=a.m[2,2]-b.m[2,2];
 result.m[2,3]:=a.m[2,3]-b.m[2,3];
 result.m[3,0]:=a.m[3,0]-b.m[3,0];
 result.m[3,1]:=a.m[3,1]-b.m[3,1];
 result.m[3,2]:=a.m[3,2]-b.m[3,2];
 result.m[3,3]:=a.m[3,3]-b.m[3,3];
end;

class operator TMat4.-(constref a:TMat4;b:TScalar):TMat4;
begin
 result.m[0,0]:=a.m[0,0]-b;
 result.m[0,1]:=a.m[0,1]-b;
 result.m[0,2]:=a.m[0,2]-b;
 result.m[0,3]:=a.m[0,3]-b;
 result.m[1,0]:=a.m[1,0]-b;
 result.m[1,1]:=a.m[1,1]-b;
 result.m[1,2]:=a.m[1,2]-b;
 result.m[1,3]:=a.m[1,3]-b;
 result.m[2,0]:=a.m[2,0]-b;
 result.m[2,1]:=a.m[2,1]-b;
 result.m[2,2]:=a.m[2,2]-b;
 result.m[2,3]:=a.m[2,3]-b;
 result.m[3,0]:=a.m[3,0]-b;
 result.m[3,1]:=a.m[3,1]-b;
 result.m[3,2]:=a.m[3,2]-b;
 result.m[3,3]:=a.m[3,3]-b;
end;

class operator TMat4.-(a:TScalar;constref b:TMat4): TMat4;
begin
 result.m[0,0]:=a-b.m[0,0];
 result.m[0,1]:=a-b.m[0,1];
 result.m[0,2]:=a-b.m[0,2];
 result.m[0,3]:=a-b.m[0,3];
 result.m[1,0]:=a-b.m[1,0];
 result.m[1,1]:=a-b.m[1,1];
 result.m[1,2]:=a-b.m[1,2];
 result.m[1,3]:=a-b.m[1,3];
 result.m[2,0]:=a-b.m[2,0];
 result.m[2,1]:=a-b.m[2,1];
 result.m[2,2]:=a-b.m[2,2];
 result.m[2,3]:=a-b.m[2,3];
 result.m[3,0]:=a-b.m[3,0];
 result.m[3,1]:=a-b.m[3,1];
 result.m[3,2]:=a-b.m[3,2];
 result.m[3,3]:=a-b.m[3,3];
end;

class operator TMat4.*(constref b,a:TMat4):TMat4;
begin
 result.m[0,0]:=(a.m[0,0]*b.m[0,0])+(a.m[0,1]*b.m[1,0])+(a.m[0,2]*b.m[2,0])+(a.m[0,3]*b.m[3,0]);
 result.m[0,1]:=(a.m[0,0]*b.m[0,1])+(a.m[0,1]*b.m[1,1])+(a.m[0,2]*b.m[2,1])+(a.m[0,3]*b.m[3,1]);
 result.m[0,2]:=(a.m[0,0]*b.m[0,2])+(a.m[0,1]*b.m[1,2])+(a.m[0,2]*b.m[2,2])+(a.m[0,3]*b.m[3,2]);
 result.m[0,3]:=(a.m[0,0]*b.m[0,3])+(a.m[0,1]*b.m[1,3])+(a.m[0,2]*b.m[2,3])+(a.m[0,3]*b.m[3,3]);
 result.m[1,0]:=(a.m[1,0]*b.m[0,0])+(a.m[1,1]*b.m[1,0])+(a.m[1,2]*b.m[2,0])+(a.m[1,3]*b.m[3,0]);
 result.m[1,1]:=(a.m[1,0]*b.m[0,1])+(a.m[1,1]*b.m[1,1])+(a.m[1,2]*b.m[2,1])+(a.m[1,3]*b.m[3,1]);
 result.m[1,2]:=(a.m[1,0]*b.m[0,2])+(a.m[1,1]*b.m[1,2])+(a.m[1,2]*b.m[2,2])+(a.m[1,3]*b.m[3,2]);
 result.m[1,3]:=(a.m[1,0]*b.m[0,3])+(a.m[1,1]*b.m[1,3])+(a.m[1,2]*b.m[2,3])+(a.m[1,3]*b.m[3,3]);
 result.m[2,0]:=(a.m[2,0]*b.m[0,0])+(a.m[2,1]*b.m[1,0])+(a.m[2,2]*b.m[2,0])+(a.m[2,3]*b.m[3,0]);
 result.m[2,1]:=(a.m[2,0]*b.m[0,1])+(a.m[2,1]*b.m[1,1])+(a.m[2,2]*b.m[2,1])+(a.m[2,3]*b.m[3,1]);
 result.m[2,2]:=(a.m[2,0]*b.m[0,2])+(a.m[2,1]*b.m[1,2])+(a.m[2,2]*b.m[2,2])+(a.m[2,3]*b.m[3,2]);
 result.m[2,3]:=(a.m[2,0]*b.m[0,3])+(a.m[2,1]*b.m[1,3])+(a.m[2,2]*b.m[2,3])+(a.m[2,3]*b.m[3,3]);
 result.m[3,0]:=(a.m[3,0]*b.m[0,0])+(a.m[3,1]*b.m[1,0])+(a.m[3,2]*b.m[2,0])+(a.m[3,3]*b.m[3,0]);
 result.m[3,1]:=(a.m[3,0]*b.m[0,1])+(a.m[3,1]*b.m[1,1])+(a.m[3,2]*b.m[2,1])+(a.m[3,3]*b.m[3,1]);
 result.m[3,2]:=(a.m[3,0]*b.m[0,2])+(a.m[3,1]*b.m[1,2])+(a.m[3,2]*b.m[2,2])+(a.m[3,3]*b.m[3,2]);
 result.m[3,3]:=(a.m[3,0]*b.m[0,3])+(a.m[3,1]*b.m[1,3])+(a.m[3,2]*b.m[2,3])+(a.m[3,3]*b.m[3,3]);
end;

class operator TMat4.*(constref a:TMat4;b:TScalar):TMat4;
begin
 result.m[0,0]:=a.m[0,0]*b;
 result.m[0,1]:=a.m[0,1]*b;
 result.m[0,2]:=a.m[0,2]*b;
 result.m[0,3]:=a.m[0,3]*b;
 result.m[1,0]:=a.m[1,0]*b;
 result.m[1,1]:=a.m[1,1]*b;
 result.m[1,2]:=a.m[1,2]*b;
 result.m[1,3]:=a.m[1,3]*b;
 result.m[2,0]:=a.m[2,0]*b;
 result.m[2,1]:=a.m[2,1]*b;
 result.m[2,2]:=a.m[2,2]*b;
 result.m[2,3]:=a.m[2,3]*b;
 result.m[3,0]:=a.m[3,0]*b;
 result.m[3,1]:=a.m[3,1]*b;
 result.m[3,2]:=a.m[3,2]*b;
 result.m[3,3]:=a.m[3,3]*b;
end;

class operator TMat4.*(a:TScalar;constref b:TMat4):TMat4;
begin
 result.m[0,0]:=a*b.m[0,0];
 result.m[0,1]:=a*b.m[0,1];
 result.m[0,2]:=a*b.m[0,2];
 result.m[0,3]:=a*b.m[0,3];
 result.m[1,0]:=a*b.m[1,0];
 result.m[1,1]:=a*b.m[1,1];
 result.m[1,2]:=a*b.m[1,2];
 result.m[1,3]:=a*b.m[1,3];
 result.m[2,0]:=a*b.m[2,0];
 result.m[2,1]:=a*b.m[2,1];
 result.m[2,2]:=a*b.m[2,2];
 result.m[2,3]:=a*b.m[2,3];
 result.m[3,0]:=a*b.m[3,0];
 result.m[3,1]:=a*b.m[3,1];
 result.m[3,2]:=a*b.m[3,2];
 result.m[3,3]:=a*b.m[3,3];
end;

class operator TMat4.*(constref a:TMat4;constref b:TVec2):TVec2;
begin
 result.x:=(a.m[0,0]*b.x)+(a.m[1,0]*b.y)+a.m[2,0]+a.m[3,0];
 result.y:=(a.m[0,1]*b.x)+(a.m[1,1]*b.y)+a.m[2,1]+a.m[3,1];
end;

class operator TMat4.*(constref a:TVec2;constref b:TMat4):TVec2;
begin
 result.x:=(a.x*b.m[0,0])+(a.y*b.m[0,1])+b.m[0,2]+b.m[0,3];
 result.y:=(a.x*b.m[1,0])+(a.y*b.m[1,1])+b.m[1,2]+b.m[1,3];
end;

class operator TMat4.*(constref a:TMat4;constref b:TVec3):TVec3;
begin
 result.x:=(a.m[0,0]*b.x)+(a.m[1,0]*b.y)+(a.m[2,0]*b.z)+a.m[3,0];
 result.y:=(a.m[0,1]*b.x)+(a.m[1,1]*b.y)+(a.m[2,1]*b.z)+a.m[3,1];
 result.z:=(a.m[0,2]*b.x)+(a.m[1,2]*b.y)+(a.m[2,2]*b.z)+a.m[3,2];
end;

class operator TMat4.*(constref a:TVec3;constref b:TMat4):TVec3;
begin
 result.x:=(a.x*b.m[0,0])+(a.y*b.m[0,1])+(a.z*b.m[0,2])+b.m[0,3];
 result.y:=(a.x*b.m[1,0])+(a.y*b.m[1,1])+(a.z*b.m[1,2])+b.m[1,3];
 result.z:=(a.x*b.m[2,0])+(a.y*b.m[2,1])+(a.z*b.m[2,2])+b.m[2,3];
end;

class operator TMat4.*(constref a:TMat4;constref b:TVec4):TVec4;
begin
 result.x:=(a.m[0,0]*b.x)+(a.m[1,0]*b.y)+(a.m[2,0]*b.z)+(a.m[3,0]*b.w);
 result.y:=(a.m[0,1]*b.x)+(a.m[1,1]*b.y)+(a.m[2,1]*b.z)+(a.m[3,1]*b.w);
 result.z:=(a.m[0,2]*b.x)+(a.m[1,2]*b.y)+(a.m[2,2]*b.z)+(a.m[3,2]*b.w);
 result.w:=(a.m[0,3]*b.x)+(a.m[1,3]*b.y)+(a.m[2,3]*b.z)+(a.m[3,3]*b.w);
end;

class operator TMat4.*(constref a:TVec4;constref b:TMat4):TVec4;
begin
 result.x:=(a.x*b.m[0,0])+(a.y*b.m[0,1])+(a.z*b.m[0,2])+(a.w*b.m[0,3]);
 result.y:=(a.x*b.m[1,0])+(a.y*b.m[1,1])+(a.z*b.m[1,2])+(a.w*b.m[1,3]);
 result.z:=(a.x*b.m[2,0])+(a.y*b.m[2,1])+(a.z*b.m[2,2])+(a.w*b.m[2,3]);
 result.w:=(a.x*b.m[3,0])+(a.y*b.m[3,1])+(a.z*b.m[3,2])+(a.w*b.m[3,3]);
end;

class operator TMat4./(constref a,b:TMat4):TMat4;
begin
 result:=a*b.Inverse;
end;

class operator TMat4./(constref a:TMat4;b:TScalar):TMat4;
begin
 result.m[0,0]:=a.m[0,0]/b;
 result.m[0,1]:=a.m[0,1]/b;
 result.m[0,2]:=a.m[0,2]/b;
 result.m[0,3]:=a.m[0,3]/b;
 result.m[1,0]:=a.m[1,0]/b;
 result.m[1,1]:=a.m[1,1]/b;
 result.m[1,2]:=a.m[1,2]/b;
 result.m[1,3]:=a.m[1,3]/b;
 result.m[2,0]:=a.m[2,0]/b;
 result.m[2,1]:=a.m[2,1]/b;
 result.m[2,2]:=a.m[2,2]/b;
 result.m[2,3]:=a.m[2,3]/b;
 result.m[3,0]:=a.m[3,0]/b;
 result.m[3,1]:=a.m[3,1]/b;
 result.m[3,2]:=a.m[3,2]/b;
 result.m[3,3]:=a.m[3,3]/b;
end;

class operator TMat4./(a:TScalar;constref b:TMat4):TMat4;
begin
 result.m[0,0]:=a/b.m[0,0];
 result.m[0,1]:=a/b.m[0,1];
 result.m[0,2]:=a/b.m[0,2];
 result.m[0,3]:=a/b.m[0,3];
 result.m[1,0]:=a/b.m[1,0];
 result.m[1,1]:=a/b.m[1,1];
 result.m[1,2]:=a/b.m[1,2];
 result.m[1,3]:=a/b.m[1,3];
 result.m[2,0]:=a/b.m[2,0];
 result.m[2,1]:=a/b.m[2,1];
 result.m[2,2]:=a/b.m[2,2];
 result.m[2,3]:=a/b.m[2,3];
 result.m[3,0]:=a/b.m[3,0];
 result.m[3,1]:=a/b.m[3,1];
 result.m[3,2]:=a/b.m[3,2];
 result.m[3,3]:=a/b.m[3,3];
end;

end.