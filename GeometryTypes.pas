{$mode objfpc}
{$modeswitch advancedrecords}
{$modeswitch multihelpers}

unit GeometryTypes;
interface
uses
  VectorMath;

type
  TRect = record
    public
      origin: TVec2;
      size: TVec2;
    public
      constructor Create(inX, inY: TScalar; inWidth, inHeight: TScalar);

      property Width: TScalar read size.x;
      property Height: TScalar read size.y;
      property MinX: TScalar read origin.x;
      property MinY: TScalar read origin.y;

      function MaxX: TScalar; inline;
      function MidX: TScalar; inline;
      function MaxY: TScalar; inline;
      function MidY: TScalar; inline;

      property X: TScalar read origin.x write origin.x;
      property Y: TScalar read origin.y write origin.y;
      property W: TScalar read size.x write size.x;
      property H: TScalar read size.y write size.y;

      procedure Show;
      function ToStr: string;
    public
      class operator + (r1, r2: TRect): TRect; overload;
      class operator - (r1, r2: TRect): TRect; overload; 
      class operator * (r1, r2: TRect): TRect; overload; 
      class operator / (r1, r2: TRect): TRect;  overload;
      class operator + (r1: TRect; r2: TScalar): TRect; overload; 
      class operator - (r1: TRect; r2: TScalar): TRect; overload; 
      class operator * (r1: TRect; r2: TScalar): TRect; overload; 
      class operator / (r1: TRect; r2: TScalar): TRect; overload;
      class operator = (r1, r2: TRect): boolean; 
  end;

type
  TSizeHelper = record helper for TVec2
    function Min: TScalar; inline;
    function Max: TScalar; inline;
    procedure SetWidth(newValue: TScalar); inline;
    procedure SetHeight(newValue: TScalar); inline;
    function GetWidth: TScalar; inline;
    function GetHeight: TScalar; inline;
    property Width: TScalar read GetWidth write SetWidth;
    property Height: TScalar read GetHeight write SetHeight;
  end;

function RectMake(x, y: TScalar; width, height: TScalar): TRect; overload; inline;
function RectMake(origin, size: TVec2): TRect; overload; inline;
function RectMake(origin: TVec2; width, height: TScalar): TRect; overload; inline;
function RectMake(x, y: TScalar; size: TVec2): TRect; overload; inline;

{ Colors }
type
  TColor = TVec4;
  
type
  TColorHelper = record helper for TVec4
    class function Red(alpha: TScalar = 1.0): TVec4; static;
    class function Green(alpha: TScalar = 1.0): TVec4; static;
    class function Blue(alpha: TScalar = 1.0): TVec4; static;
    class function White(alpha: TScalar = 1.0): TVec4; static;
    class function Black(alpha: TScalar = 1.0): TVec4; static;
    class function Clear: TVec4; static;
  end;

function RGBA(r, g, b, a: TScalar): TColor;
function HexColorToRGB (hexValue: integer; alpha: TScalar = 1.0): TVec4;

function PolyContainsPoint (points: TVec2Array; point: TVec2): boolean;

implementation

function RGBA(r, g, b, a: TScalar): TColor;
begin
  result := V4(r, g, b, a);
end;

function HexColorToRGB (hexValue: integer; alpha: TScalar = 1.0): TVec4;
begin
  result.r := ((hexValue shr 16) and $FF) / 255.0;  // Extract the RR byte
  result.g := ((hexValue shr 8) and $FF) / 255.0;   // Extract the GG byte
  result.b := ((hexValue) and $FF) / 255.0;         // Extract the BB byte
  result.a := alpha;
end;

function PolyContainsPoint (points: TVec2Array; point: TVec2): boolean;
var
  i, j, c: integer;
begin
  i := 0;
  j := high(points);
  c := 0;
  while i < length(points) do
    begin
      if ((points[i].y > point.y) <> (points[j].y > point.y)) 
          and (point.x < (points[j].x - points[i].x) * (point.y - points[i].y) / (points[j].y - points[i].y) + points[i].x) then
        c := not c;
      j := i;
      i += 1;
    end;
  result := c <> 0;
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

class function TColorHelper.Clear: TVec4;
begin
  result := V4(0, 0, 0, 0);
end;

function TSizeHelper.Min: TScalar;
begin
  if width < height then
    result := width
  else
    result := height;
end;

function TSizeHelper.Max: TScalar;
begin
  if width > height then
    result := width
  else
    result := height;
end;

procedure TSizeHelper.SetWidth(newValue: TScalar);
begin
  x := newValue;
end;

procedure TSizeHelper.SetHeight(newValue: TScalar);
begin
  y := newValue;  
end;

function TSizeHelper.GetWidth: TScalar;
begin
  result := x;
end;

function TSizeHelper.GetHeight: TScalar;
begin
  result := y;
end;

function RectMake(origin, size: TVec2): TRect;
begin
  result := TRect.Create(origin.x, origin.y, size.width, size.height);
end;

function RectMake(x, y: TScalar; width, height: TScalar): TRect;
begin
  result := TRect.Create(x, y, width, height);
end;

function RectMake(origin: TVec2; width, height: TScalar): TRect;
begin
  result := TRect.Create(origin.x, origin.y, width, height);
end;

function RectMake(x, y: TScalar; size: TVec2): TRect;
begin
  result := TRect.Create(x, y, size.width, size.height);
end;

procedure TRect.Show;
begin
  writeln(ToStr);
end;

function TRect.ToStr: string;
begin
  result := '{'+origin.ToStr+','+size.ToStr+'}';
end;

constructor TRect.Create(inX, inY: TScalar; inWidth, inHeight: TScalar);
begin
  self.origin.x := inX;
  self.origin.y := inY;
  self.size.width := inWidth;
  self.size.height := inHeight;
end;

function TRect.MaxX: TScalar;
begin
  result := MinX + Width;
end;

function TRect.MidX: TScalar;
begin
  result := MinX + Width / 2;
end;

function TRect.MaxY: TScalar;
begin
  result := MinY + Height;
end;

function TRect.MidY: TScalar;
begin
  result := MinY + Height / 2;
end;

class operator TRect.+ (r1, r2: TRect): TRect;
begin
  result := RectMake(r1.origin.x + r2.origin.x, r1.origin.y + r2.origin.y, r1.size.width + r2.size.width, r1.size.height + r2.size.height);
end;

class operator TRect.- (r1, r2: TRect): TRect;
begin
  result := RectMake(r1.origin.x - r2.origin.x, r1.origin.y - r2.origin.y, r1.size.width - r2.size.width, r1.size.height - r2.size.height);
end;

class operator TRect.* (r1, r2: TRect): TRect; 
begin
  result := RectMake(r1.origin.x * r2.origin.x, r1.origin.y * r2.origin.y, r1.size.width * r2.size.width, r1.size.height * r2.size.height);
end;

class operator TRect./ (r1, r2: TRect): TRect; 
begin
  result := RectMake(r1.origin.x / r2.origin.x, r1.origin.y / r2.origin.y, r1.size.width / r2.size.width, r1.size.height / r2.size.height);
end;

class operator TRect.= (r1, r2: TRect): boolean; 
begin
  result := (r1.origin = r2.origin) and (r1.size = r2.size);
end;

class operator TRect.+ (r1: TRect; r2: TScalar): TRect;
begin
  result := RectMake(r1.origin.x + r2, r1.origin.y + r2, r1.size.width + r2, r1.size.height + r2);
end;

class operator TRect.- (r1: TRect; r2: TScalar): TRect;
begin
  result := RectMake(r1.origin.x - r2, r1.origin.y +- r2, r1.size.width - r2, r1.size.height - r2);
end;

class operator TRect.* (r1: TRect; r2: TScalar): TRect;
begin
  result := RectMake(r1.origin.x * r2, r1.origin.y * r2, r1.size.width * r2, r1.size.height * r2);
end;

class operator TRect./ (r1: TRect; r2: TScalar): TRect;
begin
  result := RectMake(r1.origin.x / r2, r1.origin.y / r2, r1.size.width / r2, r1.size.height / r2);
end;

end.