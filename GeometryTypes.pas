{$mode objfpc}
{$modeswitch advancedrecords}
{$modeswitch multihelpers}

unit GeometryTypes;
interface
uses
  VectorMath;

type
  TRectEdge = ( TRectEdgeMinX, 
                TRectEdgeMinY,
                TRectEdgeMaxX,
                TRectEdgeMaxY,
                TRectEdgeAny
                );

type
  TRect = record
    private
      function GetPoint(index: integer): TVec2;
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

      function Center: TVec2; inline;
      function TopLeft: TVec2; inline;
      function TopRight: TVec2; inline;
      function BottomLeft: TVec2; inline;
      function BottomRight: TVec2; inline;

      function Min: TVec2; inline;
      function Max: TVec2; inline;

      property X: TScalar read origin.x write origin.x;
      property Y: TScalar read origin.y write origin.y;
      property W: TScalar read size.x write size.x;
      property H: TScalar read size.y write size.y;
      property Points[index: integer]: TVec2 read GetPoint;

      function IsEmpty: boolean;
      function ContainsPoint (point: TVec2): boolean;
      function ContainsRect (rect: TRect): boolean;
      function IntersectsRect (rect: TRect): boolean;
      function Inset (byX, byY: TScalar): TRect; overload; inline;
      function Inset (amount: TScalar): TRect; overload; inline;
      function Union (rect: TRect): TRect;

      procedure Show;
      function ToStr: string;
    public
      class operator := (right: TScalar): TRect;
      class operator := (right: array of TScalar): TRect;
      class operator + (left, right: TRect): TRect; overload;
      class operator - (left, right: TRect): TRect; overload; 
      class operator * (left, right: TRect): TRect; overload; 
      class operator / (left, right: TRect): TRect;  overload;
      class operator + (left: TRect; right: TScalar): TRect; overload; 
      class operator - (left: TRect; right: TScalar): TRect; overload; 
      class operator * (left: TRect; right: TScalar): TRect; overload; 
      class operator / (left: TRect; right: TScalar): TRect; overload;
      class operator = (left, right: TRect): boolean; 
  end;

type
  TAABB = record
    public
      left: TScalar;
      top: TScalar;
      right: TScalar;
      bottom: TScalar;
    public
      constructor Create(l, t, r, b: TScalar);
      function Width: TScalar; inline;
      function Height: TScalar; inline;
      property X: TScalar read left write left;
      property Y: TScalar read top write top;

      procedure Show;
      function ToStr: string;
  end;

operator := (left: TAABB): TRect;
operator := (left: TRect): TAABB;

function AABB(left, top, right, bottom: TScalar): TAABB; inline;
function AABB(rect: TRect): TAABB; inline;

type
  TSizeHelper = record helper for TVec2
    function Min: TScalar; inline;
    function Max: TScalar; inline;
    procedure AddWidth(by: TScalar); inline;
    procedure AddHeight(by: TScalar); inline;
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

function RectCenter (sourceRect: TRect; destRect: TRect): TRect;
function RectCenterX (sourceRect: TRect; destRect: TRect): TRect; inline;
function RectCenterY (sourceRect: TRect; destRect: TRect): TRect; inline;
function RectFlip (sourceRect, destRect: TRect): TRect;

function RadiusForRect (rect: TRect): TScalar; inline;

function Trunc (rect: TRect): TRect; overload;

type
  TCircle = record
    public
      origin: TVec2;
      radius: TScalar;
    public
      class function Make (_origin: TVec2; _radius: TScalar): TCircle; static;
      class function Make (x, y: TScalar; _radius: TScalar): TCircle; static;
      class function Make (rect: TRect): TCircle; static;
    
      function Intersects (const circle: TCircle): boolean; overload;
      function Intersects (const circle: TCircle; out hitPoint: TVec2): boolean; overload; 
      function Intersects (const rect: TRect): boolean; overload;
      function Distance (const circle: TCircle; fromDiameter: boolean = true): TScalar;
      
      function ToStr: string;
      procedure Show;
  end;

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
function RGBA(white: TScalar; alpha: TScalar = 1.0): TColor;
function HexColorToRGB (hexValue: integer; alpha: TScalar = 1.0): TVec4;

function PolyContainsPoint (const points: TVec2Array; constref point: TVec2): boolean;
function PolyIntersectsRect(const vertices: TVec2Array; constref rect: TRect): boolean;
function PolyIntersectsPoly(const p1, p2: TVec2Array): boolean;

function PointOnSide (p, a, b: TVec2): integer;
function LineIntersectsRect (p1, p2: TVec2; rect: TRect): boolean;
function LineIntersectsCircle (p1, p2: TVec2; origin: TVec2; radius: single): boolean; 

implementation
uses
  Math, SysUtils;

//https://stackoverflow.com/questions/1560492/how-to-tell-whether-a-point-is-to-the-right-or-left-side-of-a-line
//It is 0 on the line, and +1 on one side, -1 on the other side.
function PointOnSide (p, a, b: TVec2): integer;
begin
  result := Sign(((b.x - a.x) * (p.y - a.y)) - ((b.y - a.y) * (p.x - a.x)));
end;

// http://jeffreythompson.org/collision-detection/poly-rect.php
// http://jeffreythompson.org/collision-detection/poly-poly.php
// http://jeffreythompson.org/collision-detection/poly-line.php

function LineLine(x1, y1, x2, y2, x3, y3, x4, y4: TScalar): boolean;
var
  uA, uB: TScalar;
begin
  // calculate the direction of the lines
  uA := ((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1));
  uB := ((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1));

  // if uA and uB are between 0-1, lines are colliding
  result := (uA >= 0) and (uA <= 1) and (uB >= 0) and (uB <= 1);
end;

function LineRect (x1, y1, x2, y2, rx, ry, rw, rh: TScalar): boolean;
var
  left,
  right,
  top,
  bottom: boolean;
begin
  // check if the line has hit any of the rectangle's sides
  // uses the Line/Line function below
  left := LineLine(x1,y1,x2,y2, rx,ry,rx, ry+rh);
  right := LineLine(x1,y1,x2,y2, rx+rw,ry, rx+rw,ry+rh);
  top := LineLine(x1,y1,x2,y2, rx,ry, rx+rw,ry);
  bottom := LineLine(x1,y1,x2,y2, rx,ry+rh, rx+rw,ry+rh);

  // if ANY of the above are true,
  // the line has hit the rectangle
  result := (left or right or top or bottom);
end;

function PolyLine(const vertices: TVec2Array; x1, y1, x2, y2: TScalar): boolean;
var
  next,
  current: integer;
  x3, y3, x4, y4: TScalar;
begin
  // go through each of the vertices, plus the next
  // vertex in the list
  next := 0;
  for current := 0 to high(vertices) do
    begin
      // get next vertex in list
      // if we've hit the end, wrap around to 0
      next := current+1;
      if (next = length(vertices)) then
        next := 0;

      // get the PVectors at our current position
      // extract X/Y coordinates from each
      x3 := vertices[current].x;
      y3 := vertices[current].y;
      x4 := vertices[next].x;
      y4 := vertices[next].y;

      // do a Line/Line comparison
      // if true, return 'true' immediately and
      // stop testing (faster)
      if LineLine(x1, y1, x2, y2, x3, y3, x4, y4) then
        exit(true);
    end;

  // never got a hit
  result := false;
end;

function LineIntersectsLine(constref a1, a2: TVec2; constref b1, b2: TVec2): boolean;
begin
  result := LineLine(a1.x, a1.y,
                     a2.x, a2.y,
                     b1.x, b1.y,
                     b2.x, b2.y);
end;

function PolyIntersectsPoly(const p1, p2: TVec2Array): boolean;
var
  next,
  current: integer;
  vc, vn: TVec2;
begin
  // go through each of the vertices, plus the next
  // vertex in the list
  next := 0;
  for current := 0 to high(p1) do
    begin
      // get next vertex in list
      // if we've hit the end, wrap around to 0
      next := current+1;
      if (next = length(p1)) then
        next := 0;

      // get the PVectors at our current position
      // this makes our if statement a little cleaner
      vc := p1[current];    // c for "current"
      vn := p1[next];       // n for "next"

      // now we can use these two points (a line) to compare
      // to the other polygon's vertices using polyLine()
      if PolyLine(p2,vc.x,vc.y,vn.x,vn.y) then
        exit(true);

      // optional: check if the 2nd polygon is INSIDE the first
      if PolyContainsPoint(p1, p2[0]) then
        exit(true);
    end;

  result := false;
end;

function PolyIntersectsRect(const vertices: TVec2Array; constref rect: TRect): boolean;
var
  next,
  current: integer;
  vc, vn: TVec2;
  rx, ry, rw, rh: TScalar;
begin
  rx := rect.x;
  ry := rect.y;
  rw := rect.w;
  rh := rect.h;

  // go through each of the vertices, plus the next
  // vertex in the list
  next := 0;
  for current := 0 to high(vertices) do
    begin
      // get next vertex in list
      // if we've hit the end, wrap around to 0
      next := current+1;
      if (next = length(vertices)) then
        next := 0;

      // get the PVectors at our current position
      // this makes our if statement a little cleaner
      vc := vertices[current];    // c for "current"
      vn := vertices[next];       // n for "next"

      // check against all four sides of the rectangle
      if lineRect(vc.x,vc.y,vn.x,vn.y, rx,ry,rw,rh) then
        exit(true);

      // optional: test if the rectangle is INSIDE the polygon
      // note that this iterates all sides of the polygon
      // again, so only use this if you need to
      if PolyContainsPoint(vertices, V2(rx,ry)) then
        exit(true);
    end;

  result := false;
end;


// http://stackoverflow.com/questions/99353/how-to-test-if-a-line-segment-intersects-an-axis-aligned-rectange-in-2d
function LineIntersectsRect (p1, p2: TVec2; rect: TRect): boolean;
var
  minX, maxY, minY, maxX: single;
  dx: single;
  tmp: single;
  a, b: single;
begin
  // Find min and max X for the segment
  minX := p1.x;
  maxX := p2.x;
  if (p1.x > p2.x) then
    begin
      minX := p2.x;
      maxX := p1.x;
    end;  

  // Find the intersection of the segment's and rectangle's x-projections
  if (maxX > rect.MaxX) then
    maxX := rect.MaxX;

  if (minX < rect.MinX) then
    minX := rect.MinX;

  if (minX > maxX) then // If their projections do not intersect return false
    exit(false);

  // Find corresponding min and max Y for min and max X we found before
  minY := p1.y;
  maxY := p2.y;
  dx := p2.x - p1.x;
  
  if Abs(dx) > 0.0000001 then
    begin
      a := (p2.y - p1.y) / dx;
      b := p1.y - a * p1.x;
      minY := a * minX + b;
      maxY := a * maxX + b;
    end;

  if (minY > maxY) then
    begin
      tmp := maxY;
      maxY := minY;
      minY := tmp;
    end;

  // Find the intersection of the segment's and rectangle's y-projections
  if (maxY > rect.MaxY) then
    maxY := rect.MaxY;

  if (minY < rect.MinY) then
    minY := rect.MinY;

  if (minY > maxY) then // If Y-projections do not intersect return false
    exit(false);

  result := true;
end;

//https://stackoverflow.com/questions/1073336/circle-line-segment-collision-detection-algorithm
function LineIntersectsCircle (p1, p2: TVec2; origin: TVec2; radius: single): boolean; 
var
  d, f: TVec2;
  a, b, c: single;
  discriminant: single;
  t1, t2: single;
begin
  d := p2 - p1; // Direction vector of ray, from start to end
  f := p1 - origin; // Vector from center sphere to ray start
  a := d.Dot(d);
  b := 2*f.Dot(d);
  c := f.Dot(f) - radius*radius;
  discriminant := b*b-4*a*c;
  if( discriminant < 0 ) then
    exit(false) // no intersection
  else
    begin
      // ray didn't totally miss sphere,
      // so there is a solution to
      // the equation.
      discriminant := Sqrt(discriminant);

      // either solution may be on or off the ray so need to test both
      // t1 is always the smaller value, because BOTH discriminant and
      // a are nonnegative.
      t1 := (-b - discriminant)/(2*a);
      t2 := (-b + discriminant)/(2*a);

      // 3x HIT cases:
      //          -o->             --|-->  |            |  --|->
      // Impale(t1 hit,t2 hit), Poke(t1 hit,t2>1), ExitWound(t1<0, t2 hit), 

      // 3x MISS cases:
      //       ->  o                     o ->              | -> |
      // FallShort (t1>1,t2>1), Past (t1<0,t2<0), CompletelyInside(t1<0, t2>1)

      if (t1 >= 0) and (t1 <= 1) then
        begin
          // t1 is the intersection, and it's closer than t2
          // (since t1 uses -b - discriminant)
          // Impale, Poke
          exit(true);
        end;

      // here t1 didn't intersect so we are either started
      // inside the sphere or completely past it
      if (t2 >= 0) and (t2 <= 1) then
        begin
          // ExitWound
          exit(true);
        end;

      // no intn: FallShort, Past, CompletelyInside
      exit(false)
    end;
  
end;

function RGBA(r, g, b, a: TScalar): TColor;
begin
  result := V4(r, g, b, a);
end;

function RGBA(white: TScalar; alpha: TScalar = 1.0): TColor;
begin
  result := V4(white, white, white, alpha);
end;

function HexColorToRGB (hexValue: integer; alpha: TScalar = 1.0): TVec4;
begin
  result.r := ((hexValue shr 16) and $FF) / 255.0;  // Extract the RR byte
  result.g := ((hexValue shr 8) and $FF) / 255.0;   // Extract the GG byte
  result.b := ((hexValue) and $FF) / 255.0;         // Extract the BB byte
  result.a := alpha;
end;

function PolyContainsPoint (const points: TVec2Array; constref point: TVec2): boolean;
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

class function TCircle.Make (_origin: TVec2; _radius: TScalar): TCircle;
begin
  result.origin := _origin;
  result.radius := _radius;
end;

class function TCircle.Make (x, y: TScalar; _radius: TScalar): TCircle;
begin
  result.origin.x := x;
  result.origin.y := y;
  result.radius := _radius;
end;

class function TCircle.Make (rect: TRect): TCircle;
begin
  result.origin := rect.Center;
  result.radius := rect.Min.Distance(rect.Max) / 2;
end;


// http://stackoverflow.com/questions/21089959/detecting-collision-of-rectangle-with-circle
function TCircle.Intersects (const rect: TRect): boolean; 
var
  distX, distY: TScalar;
  dx, dy: TScalar;
begin
  distX := Abs(origin.x - rect.origin.x - rect.size.width / 2);
  distY := Abs(origin.y - rect.origin.y - rect.size.height / 2);
  
  if (distX > (rect.size.width / 2 + radius)) then
    exit(false);
  
  if (distY > (rect.size.height / 2 + radius)) then
    exit(false);
    
  if (distX <= (rect.size.width / 2)) then
    exit(true);
  
  if (distY <= (rect.size.height / 2)) then
    exit(true); 
  
  dx := distX - rect.size.width / 2;
  dy := distY - rect.size.height / 2;
  result := (dx * dx + dy * dy <= (radius * radius));
end;

function TCircle.Intersects (const circle: TCircle): boolean; 
var
  dx, dy: TScalar;
  radii: TScalar;
begin 
  dx := circle.origin.x - origin.x;
  dy := circle.origin.y - origin.y;
  radii := radius + circle.radius;
  result := (dx * dx) + (dy * dy) <= (radii * radii);
end;

function TCircle.Intersects (const circle: TCircle; out hitPoint: TVec2): boolean; 
begin 
  result := Intersects(circle);
    
  //https://gamedevelopment.tutsplus.com/tutorials/when-worlds-collide-simulating-circle-circle-collisions--gamedev-769
  if result then
    begin
      if self.radius = circle.radius then
        begin
          hitPoint.x := (self.origin.x + circle.origin.x) / 2;
          hitPoint.y := (self.origin.y + circle.origin.y) / 2;
        end
      else
        begin
          hitPoint.x := ((self.origin.x * circle.radius) + (circle.origin.x * self.radius)) / (self.radius + circle.radius);
          hitPoint.y := ((self.origin.y * circle.radius) + (circle.origin.y * self.radius)) / (self.radius + circle.radius);
        end;
    end;
end;

// distance from diameter
function TCircle.Distance (const circle: TCircle; fromDiameter: boolean = true): TScalar; 
begin 
  if fromDiameter then
    result := origin.Distance(circle.origin) - (radius + circle.radius)
  else
    result := origin.Distance(circle.origin);
end;

function TCircle.ToStr: string;
begin
  result := origin.ToStr+', r='+FloatToStr(radius);
end;

procedure TCircle.Show; 
begin
  writeln(ToStr);
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

procedure TSizeHelper.AddWidth(by: TScalar);
begin
  x += by;
end;

procedure TSizeHelper.AddHeight(by: TScalar);
begin
  y += by;
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

function RectCenterX (sourceRect: TRect; destRect: TRect): TRect;
begin
  result := sourceRect;
  
  if destRect.Width >= sourceRect.Width then
    result.origin.x += (destRect.Width / 2) - (sourceRect.Width / 2)
  else
    result.origin.x := destRect.MidX - (sourceRect.Width / 2);
end;

function RectCenterY (sourceRect: TRect; destRect: TRect): TRect;
begin
  result := sourceRect;
  
  if destRect.Height >= sourceRect.Height then
    result.origin.y := destRect.MinY + ((destRect.Height / 2) - (sourceRect.Height / 2))
  else
    result.origin.y := destRect.MidY - (sourceRect.Height / 2);
end;

function RectCenter (sourceRect: TRect; destRect: TRect): TRect;
begin
  result.size := sourceRect.size;
  result.origin := destRect.origin;
  
  result := RectCenterX(result, destRect);
  result := RectCenterY(result, destRect);
end;

function RectFlip (sourceRect, destRect: TRect): TRect;
begin
  result := sourceRect;
  result.origin.y := destRect.MaxY - (result.MinY + result.Height);
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

function TRect.IsEmpty: boolean;
begin
  result := (width = 0) and (height = 0);
end;

procedure TRect.Show;
begin
  writeln(ToStr);
end;

function TRect.ToStr: string;
begin
  result := '{'+origin.ToStr+','+size.ToStr+'}';
end;

function TRect.GetPoint(index: integer): TVec2;
begin
  case index of
    0:
      result := TopLeft;
    1:
      result := TopRight;
    2:
      result := BottomLeft;
    3:
      result := BottomRight;
  end;
end;

constructor TRect.Create(inX, inY: TScalar; inWidth, inHeight: TScalar);
begin
  self.origin.x := inX;
  self.origin.y := inY;
  self.size.width := inWidth;
  self.size.height := inHeight;
end;

function TRect.ContainsPoint (point: TVec2): boolean;
begin
  result := (point.x >= MinX) and (point.y >= MinY) and (point.x <= MaxX) and (point.y <= MaxY);
end;

function TRect.ContainsRect (rect: TRect): boolean;
begin
  result := (rect.MinX >= MinX) and (rect.MinY >= MinY) and (rect.MaxX <= MaxX) and (rect.MaxY <= MaxY);
end;

function TRect.Union (rect: TRect): TRect;
var
  aabb: TAABB;
begin
  result := self;
  
  if result.MinX < rect.MinX then
    aabb.x := result.MinX
  else
    aabb.x := rect.MinX;
  
  if result.MinY < rect.MinY then
    aabb.y := result.MinY
  else
    aabb.y := rect.MinY;
  
  if result.MaxX > rect.MaxX then
    aabb.right := result.MaxX
  else
    aabb.right := rect.MaxX;
  
  if result.MaxY > rect.MaxY then
    aabb.bottom := result.MaxY
  else
    aabb.bottom := rect.MaxY;
  
  result := aabb;
end;

function TRect.Inset (byX, byY: TScalar): TRect;
begin
  result := RectMake(origin.x + byX, origin.y + byY, size.width - (byX * 2), size.height - (byY * 2));
end;

function TRect.Inset (amount: TScalar): TRect;
begin
  result := Inset(amount, amount);
end;

function TRect.IntersectsRect (rect: TRect): boolean;
begin
  result := (MinX < rect.MaxX) and 
            (MaxX > rect.MinX) and 
            (MinY < rect.MaxY) and 
            (MaxY > rect.MinY);
end;

function TRect.Min: TVec2;
begin
  result := origin;
end;

function TRect.Max: TVec2;
begin
  result := V2(MaxX, MaxY);
end;

function TRect.Center: TVec2;
begin
  result := V2(MidX, MidY);
end;

function TRect.TopLeft: TVec2;
begin
  result := V2(MinX, MinY);
end;

function TRect.TopRight: TVec2;
begin
  result := V2(MaxX, MinY);
end;

function TRect.BottomLeft: TVec2;
begin
  result := V2(MinX, MaxY);
end;

function TRect.BottomRight: TVec2;
begin
  result := V2(MaxX, MaxY);
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

class operator TRect.:= (right: TScalar): TRect;
begin
  result.origin := right;
  result.size := right;
end;


class operator TRect.:= (right: array of TScalar): TRect;
begin
  result.origin.x := right[0];
  result.origin.y := right[1];
  result.size.x := right[2];
  result.size.y := right[3];
end;

class operator TRect.+ (left, right: TRect): TRect;
begin
  result := RectMake(left.origin.x + right.origin.x, left.origin.y + right.origin.y, left.size.width + right.size.width, left.size.height + right.size.height);
end;

class operator TRect.- (left, right: TRect): TRect;
begin
  result := RectMake(left.origin.x - right.origin.x, left.origin.y - right.origin.y, left.size.width - right.size.width, left.size.height - right.size.height);
end;

class operator TRect.* (left, right: TRect): TRect; 
begin
  result := RectMake(left.origin.x * right.origin.x, left.origin.y * right.origin.y, left.size.width * right.size.width, left.size.height * right.size.height);
end;

class operator TRect./ (left, right: TRect): TRect; 
begin
  result := RectMake(left.origin.x / right.origin.x, left.origin.y / right.origin.y, left.size.width / right.size.width, left.size.height / right.size.height);
end;

class operator TRect.= (left, right: TRect): boolean; 
begin
  result := (left.origin = right.origin) and (left.size = right.size);
end;

class operator TRect.+ (left: TRect; right: TScalar): TRect;
begin
  result := RectMake(left.origin.x + right, left.origin.y + right, left.size.width + right, left.size.height + right);
end;

class operator TRect.- (left: TRect; right: TScalar): TRect;
begin
  result := RectMake(left.origin.x - right, left.origin.y +- right, left.size.width - right, left.size.height - right);
end;

class operator TRect.* (left: TRect; right: TScalar): TRect;
begin
  result := RectMake(left.origin.x * right, left.origin.y * right, left.size.width * right, left.size.height * right);
end;

class operator TRect./ (left: TRect; right: TScalar): TRect;
begin
  result := RectMake(left.origin.x / right, left.origin.y / right, left.size.width / right, left.size.height / right);
end;

function RadiusForRect (rect: TRect): TScalar;
begin
  result := rect.Min.Distance(rect.Max) / 2;
end;

function Trunc (rect: TRect): TRect;
begin
  result := RectMake(trunc(rect.origin.x), trunc(rect.origin.y), trunc(rect.size.x), trunc(rect.size.y));
end;

procedure TAABB.Show;
begin
  writeln(ToStr);
end;

function TAABB.ToStr: string;
begin
  result := '{'+FloatToStr(left)+','+FloatToStr(top)+','+FloatToStr(right)+','+FloatToStr(bottom)+'}';
end;

constructor TAABB.Create(l, t, r, b: TScalar);
begin
  left := l;
  top := t;
  right := r;
  bottom := b;
end;

function TAABB.Width: TScalar;
begin
  result := right - left;
end;

function TAABB.Height: TScalar;
begin
  result := bottom - top;
end;

operator := (left: TAABB): TRect;
begin
  result := TRect.Create(left.x, left.y, left.width, left.height);
end;

operator := (left: TRect): TAABB;
begin
  result := TAABB.Create(left.MinX, left.MinY, left.MaxX, left.MaxY);
end;

function AABB(rect: TRect): TAABB;
begin
  result := TAABB.Create(rect.MinX, rect.MinY, rect.MaxX, rect.MaxY);
end;

function AABB(left, top, right, bottom: TScalar): TAABB;
begin
  result := TAABB.Create(left, top, right, bottom);
end;

end.