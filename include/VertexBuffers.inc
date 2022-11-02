{$ifdef INTERFACE}

type
  TVertexAttributeKind = (
    GL_BYTE,
    GL_UNSIGNED_BYTE,
    GL_SHORT,
    GL_UNSIGNED_SHORT,
    GL_INT,
    GL_UNSIGNED_INT,
    GL_FLOAT,
    GL_2_BYTES,
    GL_3_BYTES,
    GL_4_BYTES,
    GL_DOUBLE
  );

type
  TVertexAttribute = record
    public
      constructor Create(name: string; kind: GLenum; count: integer);
      constructor Create(name: string; kind: TVertexAttributeKind; count: integer);
    public
      name: string;
    private
      kind: GLenum;
      count: integer;
  end;
  TVertexAttributes = array of TVertexAttribute;

type
  generic TVertexBuffer<TVertex> = class
    private type
      TVertexArray = array[0..0] of TVertex;
      TVertexList = specialize TFPGList<TVertex>;
    private
      list: TVertexList;
      bufferID: GLuint;
      vertexArrayObject: GLuint;
      attributes: TVertexAttributes;
      vertexCount: integer;
      staticDraw: boolean;
      function GetVertex(index: integer): TVertex; inline;
      procedure SetVertex(index: integer; vertex: TVertex); inline;
      function SizeofAttribute(kind: GLuint): integer;
      procedure EnableVertexAttributes; 
    public
      { Constructors }
      constructor Create(_attributes: TVertexAttributes; _static: boolean = false);
      destructor Destroy; override;
      { Methods }
      procedure Add(constref vertex: TVertex); overload; inline;
      procedure Add(constref verticies: array of TVertex); overload;
      function Count: integer;
      procedure Draw(mode: GLenum = GL_TRIANGLES);
      procedure Clear;
      procedure Flush(mode: GLenum = GL_TRIANGLES);
      { Properties }
      property Verticies[index: integer]: TVertex read GetVertex write SetVertex; default; 
  end;

{$endif}

{$ifdef IMPLEMENTATION}

constructor TVertexAttribute.Create(name: string; kind: GLenum; count: integer);
begin
  self.name := name;
  self.kind := kind;
  self.count := count;
end;

constructor TVertexAttribute.Create(name: string; kind: TVertexAttributeKind; count: integer);
begin
  self.name := name;
  case kind of
    TVertexAttributeKind.GL_BYTE: self.kind := GL.GL_BYTE;
    TVertexAttributeKind.GL_UNSIGNED_BYTE: self.kind := GL.GL_UNSIGNED_BYTE;
    TVertexAttributeKind.GL_SHORT: self.kind := GL.GL_SHORT;
    TVertexAttributeKind.GL_UNSIGNED_SHORT: self.kind := GL.GL_UNSIGNED_SHORT;
    TVertexAttributeKind.GL_INT: self.kind := GL.GL_INT;
    TVertexAttributeKind.GL_UNSIGNED_INT: self.kind := GL.GL_UNSIGNED_INT;
    TVertexAttributeKind.GL_FLOAT: self.kind := GL.GL_FLOAT;
    TVertexAttributeKind.GL_2_BYTES: self.kind := GL.GL_2_BYTES;
    TVertexAttributeKind.GL_3_BYTES: self.kind := GL.GL_3_BYTES;
    TVertexAttributeKind.GL_4_BYTES: self.kind := GL.GL_4_BYTES;
    TVertexAttributeKind.GL_DOUBLE: self.kind := GL.GL_DOUBLE;
  end;
  self.count := count;
end;

function TVertexBuffer.SizeofAttribute(kind: GLuint): integer;
begin
  case kind of
    GL_FLOAT:
      result := sizeof(single);
    GL_UNSIGNED_BYTE:
      result := sizeof(byte);
    otherwise
      Assert(false, 'unsupported attribute kind '+IntToStr(kind));
  end;
end;

procedure TVertexBuffer.Add(constref vertex: TVertex);
begin
  list.Add(vertex);
end;

procedure TVertexBuffer.Add(constref verticies: array of TVertex);
var
  i: integer;
begin
  for i := 0 to high(verticies) do
    list.Add(verticies[i]);
end;

function TVertexBuffer.Count: integer;
begin
  result := list.Count;
end;

procedure TVertexBuffer.EnableVertexAttributes; 
var
  offset: pointer;
  attribute: TVertexAttribute;
  i: integer;
begin
  if vertexArrayObject = 0 then
    begin
      glGenBuffers(1, @bufferID);
      glBindBuffer(GL_ARRAY_BUFFER, bufferID);

      glGenVertexArrays(1, @vertexArrayObject);
      glBindVertexArray(vertexArrayObject);
      offset := nil;
      for i := 0 to high(attributes) do
        begin
          attribute := attributes[i];
          glEnableVertexAttribArray(i);
          glVertexAttribPointer(i, attribute.count, attribute.kind, GL_FALSE, sizeof(TVertex), offset);
          Inc(offset, SizeofAttribute(attribute.kind) * attribute.count);
        end;
    end
  else
    begin
      glBindBuffer(GL_ARRAY_BUFFER, bufferID);
      glBindVertexArray(vertexArrayObject);
    end;
end;

{ Draws the buffer and clears data }
procedure TVertexBuffer.Flush(mode: GLenum);
begin
  if Count > 0 then
    begin
      Draw;
      Clear;
    end;
end;

procedure TVertexBuffer.Draw(mode: GLenum);
begin
  EnableVertexAttributes;
  if staticDraw then
    begin
      // clear the local memory buffer once it's written to the GPU
      if list.Count > 0 then
        begin
          glBufferData(GL_ARRAY_BUFFER, sizeof(TVertex) * list.Count, TFPSList(list).First, GL_STATIC_DRAW);
          GLAssert('glBufferData');
          vertexCount := list.Count;
          list.Clear;
        end;
      glDrawArrays(mode, 0, vertexCount);
      GLAssert('glDrawArrays');
    end
  else
    begin
      glBufferData(GL_ARRAY_BUFFER, sizeof(TVertex) * list.Count, TFPSList(list).First, GL_DYNAMIC_DRAW);
      GLAssert('glBufferData');
      glDrawArrays(mode, 0, list.Count);
      GLAssert('glDrawArrays');
    end;
  glBindVertexArray(0);
end;

function TVertexBuffer.GetVertex(index: integer): TVertex;
begin
  result := list[index];
end;

procedure TVertexBuffer.SetVertex(index: integer; vertex: TVertex);
begin
  list[index] := vertex;
end;

procedure TVertexBuffer.Clear;
begin
  list.Count := 0;
end;

destructor TVertexBuffer.Destroy;
begin
  glDeleteBuffers(1, @bufferID);
  glDeleteVertexArrays(1, @vertexArrayObject);
  list.Free;
end;

constructor TVertexBuffer.Create(_attributes: TVertexAttributes; _static: boolean = false);
begin
  attributes := _attributes;
  staticDraw := _static;
  list := TVertexList.Create;
end;

{$endif}