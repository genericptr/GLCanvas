
{$ifdef INTERFACE}

type
	TMap = specialize TFPGMap<String, Variant>;

type
	generic TFPGMatrix<T> = class(specialize TFPGList<T>)
		public
			width, height: integer;
			constructor Create (inWidth, inHeight: integer);
			function GetRef(x, y: integer): T;
			procedure SetRef(x, y: integer; value: T);
			function IndexAt(x, y: integer): integer; inline;
			property Values[x, y: integer]: T read GetRef write SetRef; default;
	end;

type
	generic TFPGObjectList<T: TObject> = class(specialize TFPGList<T>)
		public
			constructor Create(freeObjects: boolean);
			destructor Destroy; override;
		private
			m_freeObjects: boolean;
	end;

type
	generic TFPGObjectMap<T: TObject> = class(specialize TFPGMap<String, T>)
		public
			constructor Create(freeObjects: boolean);
			destructor Destroy; override;
		private
			m_freeObjects: boolean;
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

constructor TFPGObjectList.Create(freeObjects: boolean);
begin
	m_freeObjects := freeObjects;
	inherited Create;
end;

destructor TFPGObjectList.Destroy;
var
	i: integer;
begin
	if m_freeObjects then
		for i := 0 to Count - 1 do
			if assigned(Items[i]) then
				Items[i].Free;

	inherited Destroy;
end;

constructor TFPGObjectMap.Create(freeObjects: boolean);
begin
	m_freeObjects := freeObjects;
	inherited Create;
end;

destructor TFPGObjectMap.Destroy;
var
	i: integer;
begin
	if m_freeObjects then
		for i := 0 to Count - 1 do
			if assigned(Items[i]) then
				TObject(Items[i]).Free;

	inherited Destroy;
end;




{$endif}
