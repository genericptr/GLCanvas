{$mode objfpc}
{$modeswitch advancedrecords}
{$modeswitch multihelpers}
{$scopedenums on}

unit GeometryTypes;
interface
uses
  Math, SysUtils, VectorMath, FGL;

type
  TRectEdge = ( MinX, 
                MinY,
                MaxX,
                MaxY,
                Any
                );
  TAxis = ( Both, X, Y );

type
  TRect = record
    private
      function GetPoint(index: integer): TVec2;
    public
      origin: TVec2;
      size: TVec2;
    public
      class function Infinite: TRect; static; inline;

      constructor Create(inX, inY: TScalar; inWidth, inHeight: TScalar);

      property X: TScalar read origin.x write origin.x;
      property Y: TScalar read origin.y write origin.y;
      property Width: TScalar read size.x write size.x;
      property Height: TScalar read size.y write size.y;
      property W: TScalar read size.x write size.x;
      property H: TScalar read size.y write size.y;
      
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
      function Mid: TVec2; inline;
      function Max: TVec2; inline;

      procedure SetMidX (newValue: TScalar); inline;
      procedure SetMidY (newValue: TScalar); inline;
      procedure SetMaxX (newValue: TScalar); inline;
      procedure SetMaxY (newValue: TScalar); inline;

      property Points[index: integer]: TVec2 read GetPoint;

      function IsEmpty: boolean; inline;
      function Contains(point: TVec2): boolean; overload; inline;
      function Contains(rect: TRect): boolean; overload; inline;
      function Intersects(rect: TRect): boolean; inline;
      function Inset(byX, byY: TScalar): TRect; overload; inline;
      function Inset(amount: TScalar): TRect; overload; inline;
      function Inset(by: TVec2): TRect; overload; inline;
      function Offset(by: TVec2): TRect; overload; inline;
      function Offset(byX, byY: TScalar): TRect; overload; inline;
      function Union(rect: TRect): TRect;

      procedure Show;
      function ToStr(places: integer = -1): string;
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
  PRect = ^TRect;
  TRectList = specialize TFPGList<TRect>;

type
  generic TGRect<TComponent> = record
    private type
      TComponent2 = specialize TGVec2<TComponent>;
    public
      origin: TComponent2;
      size: TComponent2;
    public
      property X: TComponent read origin.x write origin.x;
      property Y: TComponent read origin.y write origin.y;
      property Width: TComponent read size.x write size.x;
      property Height: TComponent read size.y write size.y;
      property W: TComponent read size.x write size.x;
      property H: TComponent read size.y write size.y;
      
      function Min: TComponent2; inline;
      function Max: TComponent2; inline;

      property MinX: TComponent read origin.x;
      property MinY: TComponent read origin.y;

      function MaxX: TComponent; inline;
      function MidX: TComponent; inline;
      function MaxY: TComponent; inline;
      function MidY: TComponent; inline;

      procedure Show;
      function ToStr: string;
    public
      class operator := (left: TRect): TGRect;
      class operator := (left: TGRect): TRect;
      class operator = (left, right: TGRect): boolean; 
  end;

type
  TRecti = specialize TGRect<Integer>;
  PRecti = ^TRecti;

type
  generic TGAABB<TComponent> = record
    public
      left: TComponent;
      top: TComponent;
      right: TComponent;
      bottom: TComponent;
    public
      constructor Create(l, t, r, b: TComponent);

      function Width: TComponent; inline;
      function Height: TComponent; inline;

      property X: TComponent read left write left;
      property Y: TComponent read top write top;
      property MinX: TComponent read left write left; 
      property MinY: TComponent read top write top;
      property MaxX: TComponent read right write right;
      property MaxY: TComponent read bottom write bottom;

      procedure Show;
      function ToStr: string;
  end;
  TAABB = specialize TGAABB<TScalar>;
  TAABBi = specialize TGAABB<Integer>;

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

type
  TSize3Helper = record helper for TVec3
    procedure SetWidth(newValue: TScalar); inline;
    procedure SetHeight(newValue: TScalar); inline;
    procedure SetDepth(newValue: TScalar); inline;
    function GetWidth: TScalar; inline;
    function GetHeight: TScalar; inline;
    function GetDepth: TScalar; inline;
    property Width: TScalar read GetWidth write SetWidth;
    property Height: TScalar read GetHeight write SetHeight;
    property Depth: TScalar read GetDepth write SetDepth;
  end;

function RectMake(x, y: TScalar; width, height: TScalar): TRect; overload; inline;
function RectMake(origin, size: TVec2): TRect; overload; inline;
function RectMake(origin: TVec2; width, height: TScalar): TRect; overload; inline;
function RectMake(x, y: TScalar; size: TVec2): TRect; overload; inline;

function RectCenter(sourceRect: TRect; destRect: TRect): TRect;
function RectCenterX(sourceRect: TRect; destRect: TRect): TRect; inline;
function RectCenterY(sourceRect: TRect; destRect: TRect): TRect; inline;
function RectFlipX(rect: TRect): TRect;
function RectFlipY(rect: TRect): TRect;
function RectFlipY(sourceRect, destRect: TRect): TRect;
function RectScaleToFit(source, dest: TVec2): TRect;
function RectUnion(p1, p2: TVec2): TRect;

function RadiusForRect(rect: TRect): TScalar; inline;

function Trunc(rect: TRect): TRect; overload;

type
  TCircle = record
    public
      origin: TVec2;
      radius: TScalar;
    public
      class function Create(_origin: TVec2; _radius: TScalar): TCircle; static; inline;
      class function Create(x, y: TScalar; _radius: TScalar): TCircle; static; inline;
      class function Create(rect: TRect): TCircle; static; inline;
    
      function Intersects(constref circle: TCircle): boolean; inline; overload;
      function Intersects(constref circle: TCircle; out hitPoint: TVec2): boolean; inline; overload; 
      function Intersects(constref rect: TRect): boolean; inline; overload;
      function Distance(constref circle: TCircle; fromDiameter: boolean = true): TScalar;
      function BoundingRect: TRect;

      function ToStr: string;
      procedure Show;
  end;

type
  TCube = record
    public
      origin: TVec3;
      size: TVec3;
    public

      { Constructors }
      class function Create(x, y, z, width, height, depth: TScalar): TCube; overload; static;
      class function Create(_origin, _size: TVec3): TCube; overload; static;
      class function Create(rect: TRect): TCube; overload; static;
        
      { Accessors }
      function Min: TVec3; inline;
      function Mid: TVec3; inline;
      function Max: TVec3; inline;
    
      function MinX: TScalar; inline;
      function MidX: TScalar; inline;
      function MaxX: TScalar; inline;
    
      function MinY: TScalar; inline;
      function MidY: TScalar; inline;
      function MaxY: TScalar; inline;
    
      function MinZ: TScalar; inline;
      function MidZ: TScalar; inline;
      function MaxZ: TScalar; inline;
    
      function Width: TScalar; inline;
      function Height: TScalar; inline;
      function Depth: TScalar; inline;
    
      function Center: TVec3; inline;
        
      { Methods }
      procedure Show;
      function ToStr: string; 
      function Rect2D: TRect; 
      function IsEmpty: boolean;
      function Inset(x, y, z: TScalar): TCube;
      function Intersects(rect: TCube): boolean;
      function ContainsPoint(point: TVec3): boolean;
  end;

function CubeMake(x, y, z, width, height, depth: TScalar): TCube; overload; inline;
function CubeMake(origin, size: TVec3): TCube; overload; inline;

type
  TCylinder = record
    public
      pos: TVec3;
      depth: Float;
      radius: Float;
    public
      { Constructors }
      class function Create(_pos: TVec3; _depth, _radius: Float): TCylinder; overload; static;
  end;

{ Operators }
operator explicit(right: TRect): TCircle; inline;
operator in(left: TVec2; right: TRect): boolean;

{ Circles }
function CircleIntersectsRect(origin: TVec2; radius: TScalar; constref rect: TRect): boolean; 
function CircleIntersectsCircle(originA: TVec2; radiusA: TScalar; originB: TVec2; radiusB: TScalar): boolean; overload;
function CircleIntersectsCircle(rectA, rectB: TRect): boolean; overload; inline;
function CircleIntersectsCircle(originA: TVec2; radiusA: TScalar; originB: TVec2; radiusB: TScalar; out hitPoint: TVec2): boolean; 

{ Cylinders }
function CylinderIntersectsCylinder(originA: TVec3; radiusA, depthA: TScalar; originB: TVec3; radiusB, depthB: TScalar): boolean;

{ Polygons }
function PolyContainsPoint(const points: TVec2Array; constref point: TVec2): boolean;
function PolyIntersectsRect(const vertices: TVec2Array; constref rect: TRect): boolean;
function PolyIntersectsPoly(const p1, p2: TVec2Array): boolean;

{ Lines }
function PointOnSide(p, a, b: TVec2): integer;
function LineIntersectsRect(p1, p2: TVec2; rect: TRect): boolean; overload; inline;
function LineIntersectsRect(p1, p2: TVec2; bmin, bmax: TVec2): boolean; overload;
function LineIntersectsCircle(p1, p2: TVec2; origin: TVec2; radius: single): boolean;
function LineIntersectsLine(constref a1, a2: TVec2; constref b1, b2: TVec2): boolean;
function RectIntersection(src, dest: TRect; axis: TAxis = TAxis.Both): TRect;

{ Cubes }
function LineIntersectsCube(p1, p2: TVec3; cube: TCube): boolean; inline;
function LineIntersectsBox(b1, b2, l1, l2: TVec3; out hit: TVec3): boolean; inline;

{ Triangles }
function InterpolateTriangle(p1, p2, p3: TVec3; pos: TVec2): float; 
function Barycentric(a, b, c, p: TVec3): float; 

implementation

operator in(left: TVec2; right: TRect): boolean;
begin
  result := right.Contains(left);
end;

function InterpolateTriangle(p1, p2, p3: TVec3; pos: TVec2): float; 
var
  det, l1, l2, l3: float;
begin
  det := (p2.z - p3.z) * (p1.x - p3.x) + (p3.x - p2.x) * (p1.z - p3.z);
  l1 := ((p2.z - p3.z) * (pos.x - p3.x) + (p3.x - p2.x) * (pos.y - p3.z)) / det;
  l2 := ((p3.z - p1.z) * (pos.x - p3.x) + (p1.x - p3.x) * (pos.y - p3.z)) / det;
  l3 := 1.0 - l1 - l2;
  result := l1 * p1.y + l2 * p2.y + l3 * p3.y;
end;

function Barycentric(a, b, c, p: TVec3): float; 
var
  d00, d01, d11, d20, d21, denom: float;
  v0,v1,v2: TVec3;
  v, w, u: float;
begin
  v0 := b - a;
  v1 := c - a;
  v2 := p - a;
  d00 := v0.Dot(v0);
  d01 := v0.Dot(v1);
  d11 := v1.Dot(v1);
  d20 := v2.Dot(v0);
  d21 := v2.Dot(v1);
  denom := d00 * d11 - d01 * d01;
  v := (d11 * d20 - d01 * d21) / denom;
  w := (d00 * d21 - d01 * d20) / denom;
  u := 1.0 - v - w;
  result :=  u;
end;

{ returns true if line (L1, L2) intersects with the box (B1, B2)
  returns intersection point in Hit
  http://www.3dkingdoms.com/weekly/weekly.php?a=3 }

function LineIntersectsBox(B1, B2, L1, L2: TVec3; out hit: TVec3): boolean;

  function GetIntersection(fDst1, fDst2: float; P1, P2: TVec3; out hit: TVec3): boolean; inline;
  begin
    if ( (fDst1 * fDst2) >= 0.0) then exit(false);
    if ( fDst1 = fDst2) then exit(false); 
    Hit := P1 + (P2-P1) * ( -fDst1/(fDst2-fDst1) );
    result := true;
  end;

  function InBox(Hit, B1, B2: TVec3; const axis: integer): boolean; inline;
  begin
    if ( (Axis=1) and (Hit.z > B1.z) and (Hit.z < B2.z) and (Hit.y > B1.y) and (Hit.y < B2.y)) then exit(true);
    if ( (Axis=2) and (Hit.z > B1.z) and (Hit.z < B2.z) and (Hit.x > B1.x) and (Hit.x < B2.x)) then exit(true);
    if ( (Axis=3) and (Hit.x > B1.x) and (Hit.x < B2.x) and (Hit.y > B1.y) and (Hit.y < B2.y)) then exit(true);
    result := false;
  end;

begin
  if ((L2.x < B1.x) and (L1.x < B1.x)) then exit(false);
  if ((L2.x > B2.x) and (L1.x > B2.x)) then exit(false);
  if ((L2.y < B1.y) and (L1.y < B1.y)) then exit(false);
  if ((L2.y > B2.y) and (L1.y > B2.y)) then exit(false);
  if ((L2.z < B1.z) and (L1.z < B1.z)) then exit(false);
  if ((L2.z > B2.z) and (L1.z > B2.z)) then exit(false);
  if ((L1.x > B1.x) and (L1.x < B2.x) and
      (L1.y > B1.y) and (L1.y < B2.y) and
      (L1.z > B1.z) and (L1.z < B2.z)) then
      begin
        Hit := L1; 
        exit(true);
      end;
  if ( (GetIntersection( L1.x-B1.x, L2.x-B1.x, L1, L2, Hit) and InBox( Hit, B1, B2, 1))
    or (GetIntersection( L1.y-B1.y, L2.y-B1.y, L1, L2, Hit) and InBox( Hit, B1, B2, 2)) 
    or (GetIntersection( L1.z-B1.z, L2.z-B1.z, L1, L2, Hit) and InBox( Hit, B1, B2, 3)) 
    or (GetIntersection( L1.x-B2.x, L2.x-B2.x, L1, L2, Hit) and InBox( Hit, B1, B2, 1)) 
    or (GetIntersection( L1.y-B2.y, L2.y-B2.y, L1, L2, Hit) and InBox( Hit, B1, B2, 2)) 
    or (GetIntersection( L1.z-B2.z, L2.z-B2.z, L1, L2, Hit) and InBox( Hit, B1, B2, 3))) then
    exit(true);

  result := false;
end;

function LineIntersectsCube(p1, p2: TVec3; cube: TCube): boolean;
var
  hit: TVec3;
begin
  result := LineIntersectsBox(cube.min, cube.max, p1, p2, hit);
end;

{ Returns an intersection (inclusion/inner) between the two rects. }
function RectIntersection(src, dest: TRect; axis: TAxis = TAxis.Both): TRect;
var
  box: TAABB;
begin

  case axis of
    TAxis.Both:
      begin
        // test if we're outside on either axis
        if ((src.minY > dest.maxY) or (src.maxY < dest.minY)) or
          ((src.minX > dest.maxX) or (src.maxX < dest.minX)) then
         begin
           exit(0);
         end;

        // top
        if src.y < dest.y then
          box.top := dest.y
        else
          box.top := src.y;
          
        // left
        if src.x < dest.x then
          box.left := dest.x
        else
          box.left := src.x;

        // bottom
        if src.maxY > dest.maxY then
          box.bottom := dest.maxY
        else
          box.bottom := src.maxY;

        // right
        if src.maxX > dest.maxX then
          box.right := dest.maxX
        else
          box.right := src.maxX;
      end;
    TAxis.X:
      begin
        // test if we're outside on either axis
        if (src.minX > dest.maxX) or (src.maxX < dest.minX) then
         begin
           exit(0);
         end;

        // top
        box.top := src.y;
          
        // left
        if src.x < dest.x then
          box.left := dest.x
        else
          box.left := src.x;

        // bottom
        box.bottom := src.maxY;

        // right
        if src.maxX > dest.maxX then
          box.right := dest.maxX
        else
          box.right := src.maxX;
      end;
    TAxis.Y:
      begin
        // test if we're outside on either axis
        if (src.minY > dest.maxY) or (src.maxY < dest.minY) then
         begin
           exit(0);
         end;

        // top
        if src.y < dest.y then
          box.top := dest.y
        else
          box.top := src.y;
          
        // left
        box.left := src.x;

        // bottom
        if src.maxY > dest.maxY then
          box.bottom := dest.maxY
        else
          box.bottom := src.maxY;

        // right
        box.right := src.maxX;
      end;
  end;

  result := box;
end;

//https://stackoverflow.com/questions/1560492/how-to-tell-whether-a-point-is-to-the-right-or-left-side-of-a-line
//It is 0 on the line, and +1 on one side, -1 on the other side.
function PointOnSide(p, a, b: TVec2): integer;
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

function LineRect(x1, y1, x2, y2, rx, ry, rw, rh: TScalar): boolean;
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

{ Convex/Concave polygon intersection }
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
      if LineRect(vc.x,vc.y,vn.x,vn.y, rx,ry,rw,rh) then
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


function LineIntersectsRect(p1, p2: TVec2; rect: TRect): boolean;
begin
  result := LineIntersectsRect(p1, p2, rect.min, rect.max);
end;

function LineIntersectsRect(p1, p2: TVec2; bmin, bmax: TVec2): boolean;
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
  if (maxX > bmax.x) then
    maxX := bmax.x;

  if (minX < bmin.x) then
    minX := bmin.x;

  if minX > maxX then // If their projections do not intersect return false
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
  if (maxY > bmax.y) then
    maxY := bmax.y;

  if (minY < bmin.y) then
    minY := bmin.y;

  if (minY > maxY) then // If Y-projections do not intersect return false
    exit(false);

  result := true;
end;

//https://stackoverflow.com/questions/1073336/circle-line-segment-collision-detection-algorithm
function LineIntersectsCircle(p1, p2: TVec2; origin: TVec2; radius: single): boolean; 
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


{
  https://www.youtube.com/watch?v=7Ik2vowGcU0
  https://github.com/OneLoneCoder/olcPixelGameEngine/blob/master/Videos/OneLoneCoder_PGE_PolygonCollisions1.cpp
}

function PolyIntersectionSAT(const r1, r2: TVec2Array): boolean;
var
  poly1, poly2: PVec2Array;
  i, a, b, p: integer;
  axisProj: TVec2;
  d, q: float;
  min_r1, max_r1: float;
  min_r2, max_r2: float;
begin
  poly1 := @r1;
  poly2 := @r2;
  for i := 0 to 1 do
    begin
      // swap testing order
      if i = 1 then
        begin
          poly1 := @r2;
          poly2 := @r1;
        end;
      for a := 0 to Length(poly1^) - 1 do
        begin

          // calculate axis project vector
          b := (a + 1) mod Length(poly1^);
          axisProj := V2(-(poly1^[b].y - poly1^[a].y), poly1^[b].x - poly1^[a].x);

          d := Sqrt(axisProj.x * axisProj.x + axisProj.y * axisProj.y);
          axisProj := V2(axisProj.x / d, axisProj.y / d);

          // work out min and max 1D points for r1
          min_r1 := INFINITY;
          max_r1 := -INFINITY;
          for p := 0 to Length(poly1^) - 1 do
            begin
              q := (poly1^[p].x * axisProj.x + poly1^[p].y * axisProj.y);
              min_r1 := min(min_r1, q);
              max_r1 := max(max_r1, q);
            end;

          // work out min and max 1D points for r2
          min_r2 := INFINITY;
          max_r2 := -INFINITY;
          for p := 0 to Length(poly2^) - 1 do
            begin
              q := (poly2^[p].x * axisProj.x + poly2^[p].y * axisProj.y);
              min_r2 := min(min_r2, q);
              max_r2 := max(max_r2, q);
            end;

          // check for axis separation
          if not ((max_r2 >= min_r1) and (max_r1 >= min_r2)) then
            exit(false);
        end;
    end;
  result := true;
end;


function PolyContainsPoint(const points: TVec2Array; constref point: TVec2): boolean;
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

{*****************************************************************************
 *                                    TCylinder
 *****************************************************************************}

class function TCylinder.Create(_pos: TVec3; _depth, _radius: Float): TCylinder;
begin
  result.pos := _pos;
  result.depth := _depth;
  result.radius := _radius;
end;

function CylinderIntersectsCylinder(originA: TVec3; radiusA, depthA: TScalar; originB: TVec3; radiusB, depthB: TScalar): boolean;
var
  dx, dy: TScalar;
  radii: TScalar;
begin
  if (originA.z + depthA < originB.z) or
    (originA.z > originB.z + depthB) then
    exit(false);
  dx := originB.x - originA.x;
  dy := originB.y - originA.y;
  radii := radiusB + radiusA;
  result := (dx * dx) + (dy * dy) <= (radii * radii);
end;

{*****************************************************************************
 *                                    TCube
 *****************************************************************************}

function CubeMake(x, y, z, width, height, depth: TScalar): TCube;
begin
  result.origin := V3(x, y, z);
  result.size := V3(width, height, depth);
end;

function CubeMake(origin, size: TVec3): TCube;
begin
  result.origin := origin;
  result.size := size;
end;

class function TCube.Create(rect: TRect): TCube;
begin
  result.origin.x := rect.origin.x;
  result.origin.y := rect.origin.y;
  result.origin.z := 0;
  result.size.width := rect.size.width;
  result.size.height := rect.size.height;
  result.size.depth := 0;
end;

class function TCube.Create(x, y, z, width, height, depth: TScalar): TCube;
begin
  result.origin.x := x;
  result.origin.y := y;
  result.origin.z := z;
  result.size.width := width;
  result.size.height := height;
  result.size.depth := depth;
end;

class function TCube.Create(_origin, _size: TVec3): TCube;
begin
  result.origin := _origin;
  result.size := _size;
end;

function TCube.Min: TVec3;
begin
  result := origin;
end;

function TCube.Max: TVec3;
begin
  result := V3(MaxX, MaxY, MaxZ);
end;

function TCube.Mid: TVec3;
begin
  result := V3(MidX, MidY, MidZ);
end;

function TCube.MinX: TScalar;
begin
  result := origin.x;
end;

function TCube.MidX: TScalar;
begin
  result := origin.x + (size.width / 2);
end;

function TCube.MaxX: TScalar;
begin
  result := origin.x + size.width;
end;

function TCube.MinY: TScalar;
begin
  result := origin.y;
end;

function TCube.MidY: TScalar;
begin
  result := origin.y + (size.height / 2);
end;

function TCube.MaxY: TScalar;
begin
  result := origin.y + size.height;
end;

function TCube.MinZ: TScalar;
begin
  result := origin.z;
end;

function TCube.MidZ: TScalar;
begin
  result := origin.z + (size.depth / 2);
end;

function TCube.MaxZ: TScalar;
begin
  result := origin.z + size.depth;
end;

function TCube.Width: TScalar;
begin
  result := size.width;
end;

function TCube.Height: TScalar;
begin
  result := size.height;
end;

function TCube.Depth: TScalar;
begin
  result := size.depth;
end;

function TCube.Center: TVec3;
begin
  result := V3(origin.x + (size.width / 2), origin.y + (size.height / 2), origin.z + (size.depth / 2));
end;

procedure TCube.Show;
begin
  writeln(ToStr);
end;

function TCube.ToStr: string;
begin
  result := '{'+origin.ToStr+', '+size.ToStr+'}';
end;

function TCube.Inset(x, y, z: TScalar): TCube;
begin
  result := CubeMake(origin.x + x, origin.y + y, origin.z + z, size.width - (x * 2), size.height - (y * 2), size.depth - (z * 2));
end;

function TCube.Intersects(rect: TCube): boolean;
begin
  result := (rect.MinX < MaxX) and 
            (rect.MaxX > MinX) and 
            (rect.MinY < MaxY) and 
            (rect.MaxY > MinY) and
            (rect.MinZ < MaxZ) and 
            (rect.MaxZ > MinZ);
end;

function TCube.ContainsPoint(point: TVec3): boolean;
begin
  result := (point.x >= MinX) and 
            (point.y >= MinY) and 
            (point.z >= MinZ) and 
            (point.x <= MaxX) and 
            (point.y <= MaxY) and
            (point.z <= MaxZ);
end;

function TCube.IsEmpty: boolean;
begin
  result := size.IsZero;
end;

function TCube.Rect2D: TRect;
begin
  result := RectMake(origin.x, origin.y, size.width, size.height);
end;

{*****************************************************************************
 *                                TCircle
 *****************************************************************************}

operator explicit(right: TRect): TCircle;
begin
  result := TCircle.Create(right);
end;

function CircleIntersectsRect(origin: TVec2; radius: TScalar; constref rect: TRect): boolean; 
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

function CircleIntersectsCircle(rectA, rectB: TRect): boolean;
begin
  result := TCircle(rectA).Intersects(TCircle(rectB));
end;

function CircleIntersectsCircle(originA: TVec2; radiusA: TScalar; originB: TVec2; radiusB: TScalar): boolean;
var
  dx, dy: TScalar;
  radii: TScalar;
begin
  dx := originB.x - originA.x;
  dy := originB.y - originA.y;
  radii := radiusB + radiusA;
  result := (dx * dx) + (dy * dy) <= (radii * radii);
end;

{ Circle intersection with point of intersection
  https://gamedevelopment.tutsplus.com/tutorials/when-worlds-collide-simulating-circle-circle-collisions--gamedev-769}

function CircleIntersectsCircle(originA: TVec2; radiusA: TScalar; originB: TVec2; radiusB: TScalar; out hitPoint: TVec2): boolean; 
begin 
  result := CircleIntersectsCircle(originA, radiusA, originB, radiusB);
  if result then
    begin
      if radiusA = radiusB then
        begin
          hitPoint.x := (originA.x + originB.x) / 2;
          hitPoint.y := (originA.y + originB.y) / 2;
        end
      else
        begin
          hitPoint.x := ((originA.x * radiusB) + (originB.x * radiusA)) / (radiusA + radiusB);
          hitPoint.y := ((originA.y * radiusB) + (originB.y * radiusA)) / (radiusA + radiusB);
        end;
    end;
end;

class function TCircle.Create(_origin: TVec2; _radius: TScalar): TCircle;
begin
  result.origin := _origin;
  result.radius := _radius;
end;

class function TCircle.Create(x, y: TScalar; _radius: TScalar): TCircle;
begin
  result.origin.x := x;
  result.origin.y := y;
  result.radius := _radius;
end;

class function TCircle.Create(rect: TRect): TCircle;
begin
  result.origin := rect.Center;
  result.radius := rect.Min.Distance(rect.Max) / 2;
end;


// http://stackoverflow.com/questions/21089959/detecting-collision-of-rectangle-with-circle
function TCircle.Intersects(constref rect: TRect): boolean; 
begin
  result := CircleIntersectsRect(origin, radius, rect);
end;

function TCircle.Intersects(constref circle: TCircle): boolean; 
begin
  result := CircleIntersectsCircle(origin, radius, circle.origin, circle.radius);
end;

function TCircle.Intersects(constref circle: TCircle; out hitPoint: TVec2): boolean; 
begin 
  result := CircleIntersectsCircle(origin, radius, circle.origin, circle.radius);
end;

// distance from diameter
function TCircle.Distance(constref circle: TCircle; fromDiameter: boolean = true): TScalar; 
begin 
  if fromDiameter then
    result := origin.Distance(circle.origin) - (radius + circle.radius)
  else
    result := origin.Distance(circle.origin);
end;

function TCircle.BoundingRect: TRect;
begin
  result := RectMake(origin.x - radius, origin.y - radius, radius * 2, radius * 2);
end;

function TCircle.ToStr: string;
begin
  result := origin.ToStr+', r='+FloatToStr(radius);
end;

procedure TCircle.Show; 
begin
  writeln(ToStr);
end;

{*****************************************************************************
 *                               TSizeHelper
 *****************************************************************************}

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

{*****************************************************************************
 *                              TSize3Helper
 *****************************************************************************}

procedure TSize3Helper.SetWidth(newValue: TScalar);
begin
  x := newValue;
end;

procedure TSize3Helper.SetHeight(newValue: TScalar);
begin
  y := newValue;  
end;

procedure TSize3Helper.SetDepth(newValue: TScalar);
begin
  z := newValue;  
end;

function TSize3Helper.GetWidth: TScalar;
begin
  result := x;
end;

function TSize3Helper.GetHeight: TScalar;
begin
  result := y;
end;

function TSize3Helper.GetDepth: TScalar;
begin
  result := z;
end;

{*****************************************************************************
 *                                TRect
 *****************************************************************************}

function RectCenterX(sourceRect: TRect; destRect: TRect): TRect;
begin
  result := sourceRect;
  
  if destRect.Width >= sourceRect.Width then
    result.origin.x += (destRect.Width / 2) - (sourceRect.Width / 2)
  else
    result.origin.x := destRect.MidX - (sourceRect.Width / 2);
end;

function RectCenterY(sourceRect: TRect; destRect: TRect): TRect;
begin
  result := sourceRect;
  
  if destRect.Height >= sourceRect.Height then
    result.origin.y := destRect.MinY + ((destRect.Height / 2) - (sourceRect.Height / 2))
  else
    result.origin.y := destRect.MidY - (sourceRect.Height / 2);
end;

function RectCenter(sourceRect: TRect; destRect: TRect): TRect;
begin
  result.size := sourceRect.size;
  result.origin := destRect.origin;
  
  result := RectCenterX(result, destRect);
  result := RectCenterY(result, destRect);
end;

function RectFlipX(rect: TRect): TRect;
begin
  result.origin.x := rect.origin.x + rect.size.x;
  result.origin.y := rect.origin.y;
  result.size.x := -rect.size.x;
  result.size.y := rect.size.y;
end;

function RectFlipY(rect: TRect): TRect;
begin
  result.origin.x := rect.origin.x;
  result.origin.y := rect.origin.y + rect.size.y;
  result.size.x := rect.size.x;
  result.size.y := -rect.size.y;
end;

function RectFlipY(sourceRect, destRect: TRect): TRect;
begin
  result := sourceRect;
  result.origin.y := destRect.MaxY - (result.MinY + result.Height);
end;

function RectScaleToFit(source, dest: TVec2): TRect;
var
  aspectRatio: float;
  newSize,
  newOrigin: TVec2;
begin
  aspectRatio := dest.min / source.min;

  newOrigin := 0;
  newSize := source * aspectRatio;
  if dest.width > newSize.width then
    newOrigin.x := (dest.width / 2) - (newSize.width / 2);
  if dest.height > newSize.height then
    newOrigin.y := (dest.height / 2) - (newSize.height / 2);

  result := RectMake(newOrigin, newSize);
end;

{ Returns a rect union of the two points }
function RectUnion(p1, p2: TVec2): TRect;
var
  box: TAABB;
begin
  if p1.x < p2.x then
    box.left := p1.x
  else
    box.left := p2.x;
    
  if p1.y < p2.y then
    box.top := p1.y
  else
    box.top := p2.y;

  if p1.x > p2.x then
    box.right := p1.x
  else
    box.right := p2.x;
    
  if p1.y > p2.y then
    box.bottom := p1.y
  else
    box.bottom := p2.y;

  result := box;
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

function TRect.ToStr(places: integer = -1): string;
begin
  result := '{'+origin.ToStr(places)+','+size.ToStr(places)+'}';
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

class function TRect.Infinite: TRect;
begin
  result := RectMake(MaxInt, -MaxInt);
end;

constructor TRect.Create(inX, inY: TScalar; inWidth, inHeight: TScalar);
begin
  self.origin.x := inX;
  self.origin.y := inY;
  self.size.width := inWidth;
  self.size.height := inHeight;
end;

function TRect.Contains(point: TVec2): boolean;
begin
  result := (point.x >= MinX) and (point.y >= MinY) and (point.x <= MaxX) and (point.y <= MaxY);
end;

function TRect.Contains(rect: TRect): boolean;
begin
  result := (rect.MinX >= MinX) and (rect.MinY >= MinY) and (rect.MaxX <= MaxX) and (rect.MaxY <= MaxY);
end;

procedure TRect.SetMidX (newValue: TScalar);
begin
  origin.x := MidX + newValue;
end;

procedure TRect.SetMidY (newValue: TScalar);
begin
  origin.y := MidY + newValue;
end;

procedure TRect.SetMaxX (newValue: TScalar);
begin
  size.width := newValue - origin.x;
end;

procedure TRect.SetMaxY (newValue: TScalar);
begin
  size.height := newValue - origin.y;
end;

function TRect.Union(rect: TRect): TRect;
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

function TRect.Offset(by: TVec2): TRect;
begin
  result := Offset(by.x, by.y);
end;

function TRect.Offset(byX, byY: TScalar): TRect;
begin
  result.origin.x := origin.x + byX;
  result.origin.y := origin.y + byY;
  result.size := size;
end;

function TRect.Inset(byX, byY: TScalar): TRect;
begin
  result := RectMake(origin.x + byX, origin.y + byY, size.width - (byX * 2), size.height - (byY * 2));
end;

function TRect.Inset(amount: TScalar): TRect;
begin
  result := Inset(amount, amount);
end;

function TRect.Inset(by: TVec2): TRect;
begin
  result := Inset(by.x, by.y);
end;

function TRect.Intersects(rect: TRect): boolean;
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

function TRect.Mid: TVec2;
begin
  result := V2(MidX, MidY);
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

function RadiusForRect(rect: TRect): TScalar;
begin
  result := rect.Min.Distance(rect.Max) / 2;
end;

function Trunc(rect: TRect): TRect;
begin
  result := RectMake(trunc(rect.origin.x), trunc(rect.origin.y), trunc(rect.size.x), trunc(rect.size.y));
end;

{*****************************************************************************
 *                                TAABB
 *****************************************************************************}

procedure TGAABB.Show;
begin
  writeln(ToStr);
end;

function TGAABB.ToStr: string;
begin
  result := '{'+left.ToString+','+top.ToString+','+right.ToString+','+bottom.ToString+'}';
end;

constructor TGAABB.Create(l, t, r, b: TComponent);
begin
  left := l;
  top := t;
  right := r;
  bottom := b;
end;

function TGAABB.Width: TComponent;
begin
  result := right - left;
end;

function TGAABB.Height: TComponent;
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

{ TGRect }

class operator TGRect.:= (left: TRect): TGRect;
begin
  result.origin.x := Trunc(left.origin.x);
  result.origin.y := Trunc(left.origin.y);
  result.size.x := Trunc(left.size.x);
  result.size.y := Trunc(left.size.y);
end;

class operator TGRect.:= (left: TGRect): TRect;
begin
  result.origin.x := left.origin.x;
  result.origin.y := left.origin.y;
  result.size.x := left.size.x;
  result.size.y := left.size.y;
end;

class operator TGRect.= (left, right: TGRect): boolean; 
begin
  result := (left.origin = right.origin) and (left.size = right.size);
end;

function TGRect.Min: TComponent2;
begin
  result := origin;
end;

function TGRect.Max: TComponent2;
begin
  result.x := MaxX;
  result.y := MaxY;
end;

function TGRect.MaxX: TComponent;
begin
  result := MinX + Width;
end;

function TGRect.MidX: TComponent;
begin
  result := MinX + Width div 2;
end;

function TGRect.MaxY: TComponent;
begin
  result := MinY + Height;
end;

function TGRect.MidY: TComponent;
begin
  result := MinY + Height div 2;
end;

procedure TGRect.Show;
begin
  writeln(ToStr);
end;

function TGRect.ToStr: string;
begin
  result := '{'+origin.ToStr+','+size.ToStr+'}';
end;

end.