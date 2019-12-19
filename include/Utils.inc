
{$ifdef INTERFACE}

type
	TMap = specialize TFPGMap<String, Variant>;

type
	generic TFPGMatrix<T> = class(specialize TFPGList<T>)
		public
			width, 
			height: integer;
		public
			constructor Create (inWidth, inHeight: integer);
			function GetRef(x, y: integer): T;
			procedure SetRef(x, y: integer; value: T);
			function IndexAt(x, y: integer): integer; inline;
			property Values[x, y: integer]: T read GetRef write SetRef; default;
	end;

{$endif}

{$ifdef IMPLEMENTATION}

constructor TFPGMatrix.Create (inWidth, inHeight: integer);
begin
	inherited Create;
	width := inWidth;
	height := inHeight;
	Count := width * height;
end;

function TFPGMatrix.IndexAt(x, y: integer): integer;
begin
	result := x + y * width;
end;

function TFPGMatrix.GetRef(x, y: integer): T;
begin
	result := items[IndexAt(x, y)];
end;

procedure TFPGMatrix.SetRef(x, y: integer; value: T);
begin
	items[IndexAt(x, y)] := value;
end;

{$endif}
