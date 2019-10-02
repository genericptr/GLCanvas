
{$ifdef INTERFACE}

type
	TRect = TVec4;
	TSize = TVec2;
	TPoint = TVec2;
	TColor = TVec4;

// TODO: when advancedobjects get merged then change these to subclasses
type
	TSizeHelper = record helper for TVec2
		constructor Create(width, height: TScalar);
		function GetWidth: TScalar; inline;
		function GetHeight: TScalar; inline;
		procedure SetWidth(newValue: TScalar); inline;
		procedure SetHeight(newValue: TScalar); inline;
		property Width: TScalar read GetWidth write SetWidth;
		property Height: TScalar read GetHeight write SetHeight;
		function Min: TScalar; inline;
		function Max: TScalar; inline;
	end;

type
	TRectHelper = record helper for TVec4
		private
			function GetOrigin: TPoint; inline;
			procedure SetOrigin(newValue: TPoint); inline;
			function GetSize: TSize; inline;
			procedure SetSize(newValue: TSize); inline;
			procedure SetAxisX(newValue: TScalar); inline;
			procedure SetAxisY(newValue: TScalar); inline;
		public
			constructor Create(inX, inY: TScalar; width, height: TScalar);
			function Width: TScalar; inline;
			function Height: TScalar; inline;
			function MinX: TScalar; inline;
			function MaxX: TScalar; inline;
			function MidX: TScalar; inline;
			function MinY: TScalar; inline;
			function MaxY: TScalar; inline;
			function MidY: TScalar; inline;
			property Origin: TPoint read GetOrigin write SetOrigin;
			property Size: TSize read GetSize write SetSize;
			property AxisX: TScalar read MinX write SetAxisX;
			property AxisY: TScalar read MinY write SetAxisY;
	end;

function RectMake(x, y: TScalar; width, height: TScalar): TRect; overload; inline;
function RectMake(origin: TPoint; size: TSize): TRect; overload; inline;
function RectMake(origin: TPoint; width, height: TScalar): TRect; overload; inline;
function SizeMake(width, height: TScalar): TSize; inline;
function PointMake(x, y: TScalar): TPoint; inline;
function RGBA(r, g, b, a: TScalar): TColor; inline;

{$endif}

{$ifdef IMPLEMENTATION}

function PointMake(x, y: TScalar): TPoint;
begin
	result.x := x;
	result.y := y;
end;

function RectMake(origin: TPoint; size: TSize): TRect;
begin
	result := TRect.Create(origin.x, origin.y, size.width, size.height);
end;

function RectMake(x, y: TScalar; width, height: TScalar): TRect;
begin
	result := TRect.Create(x, y, width, height);
end;

function RectMake(origin: TPoint; width, height: TScalar): TRect;
begin
	result := TRect.Create(origin.x, origin.y, width, height);
end;

function SizeMake(width, height: TScalar): TSize;
begin
	result := TSize.Create(width, height);
end;

function RGBA(r, g, b, a: TScalar): TColor;
begin
	result := V4(r, g, b, a);
end;

constructor TSizeHelper.Create(width, height: TScalar);
begin
	self.x := width;
	self.y := height;
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

constructor TRectHelper.Create(inX, inY: TScalar; width, height: TScalar);
begin
	self.x := inX;
	self.y := inY;
	self.z := inX + width;
	self.w := inY + height;
end;

function TRectHelper.Width: TScalar;
begin
	result := MaxX - MinX;
end;

function TRectHelper.Height: TScalar;
begin
	result := MaxY - MinY;
end;

function TRectHelper.MinX: TScalar;
begin
	result := v[0];
end;

function TRectHelper.MaxX: TScalar;
begin
	result := v[2]
end;

function TRectHelper.MidX: TScalar;
begin
	result := MinX + (Width / 2);
end;

function TRectHelper.MinY: TScalar;
begin
	result := v[1];
end;

function TRectHelper.MaxY: TScalar;
begin
	result := v[3];
end;

function TRectHelper.MidY: TScalar;
begin
	result := MinY + (Height / 2);
end;

function TRectHelper.GetOrigin: TPoint;
begin
	result := PointMake(MinX, MinY);
end;

procedure TRectHelper.SetOrigin(newValue: TPoint);
begin
	x := newValue.x;
	y := newValue.y;
end;

function TRectHelper.GetSize: TSize;
begin
	result := SizeMake(Width, Height);
end;

procedure TRectHelper.SetSize(newValue: TSize);
begin
	v[2] := newValue.width;
	v[3] := newValue.height;
end;

procedure TRectHelper.SetAxisX(newValue: TScalar);
begin
	v[0] += newValue;
	v[2] += newValue;
end;

procedure TRectHelper.SetAxisY(newValue: TScalar);
begin
	v[1] += newValue;
	v[3] += newValue;
end;

{$endif}
