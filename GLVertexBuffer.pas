{$mode objfpc}
{$modeswitch advancedrecords}
{$include targetos}

unit GLVertexBuffer;
interface
uses
  {$ifdef API_OPENGL}
  GL, GLext,
  {$endif}
  {$ifdef API_OPENGLES}
  GLES30,
  {$endif}
  FGL;

type
  TVertexAttribute = record
    public
      constructor Create(name: string; kind: GLenum; count: integer);
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
      PVertex = ^TVertex;
      TVertexArray = array[0..0] of TVertex;
      PVertexArray = ^TVertexArray;
      TVertexList = specialize TFPGList<TVertex>;
    private
      list: TVertexList;
      bufferID: GLuint;
      vertexArrayObject: GLuint;
      attributes: TVertexAttributes;
      function SizeofAttribute(kind: GLuint): integer;
      procedure EnableVertexAttributes; 
    public
      constructor Create(_attributes: TVertexAttributes);
      procedure Add(constref vertex: TVertex); inline;
      procedure AddQuad(quad: PVertexArray);
      function Count: integer;
      procedure Draw(mode: GLenum = GL_TRIANGLES);
      procedure Clear;
      destructor Destroy; override;
  end;

implementation
uses
  GLUtils, SysUtils;

constructor TVertexAttribute.Create(name: string; kind: GLenum; count: integer);
begin
  self.name := name;
  self.kind := kind;
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

procedure TVertexBuffer.AddQuad(quad: PVertexArray);
begin
  list.Add(quad^[0]);
  list.Add(quad^[1]);
  list.Add(quad^[2]);
  list.Add(quad^[3]);
  list.Add(quad^[4]);
  list.Add(quad^[5]);
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

procedure TVertexBuffer.Draw(mode: GLenum);
begin
  EnableVertexAttributes;
  glBufferData(GL_ARRAY_BUFFER, sizeof(TVertex) * list.Count, TFPSList(list).First, GL_DYNAMIC_DRAW);
  GLAssert('glBufferData');
  glDrawArrays(mode, 0, list.Count);
  GLAssert('glDrawArrays');
end;

procedure TVertexBuffer.Clear;
begin
  // TODO: clear shrinks capacity! make our own arrays?
  list.Clear;
end;

destructor TVertexBuffer.Destroy;
begin
  glDeleteBuffers(1, @bufferID);
  glDeleteVertexArrays(1, @vertexArrayObject);
  list.Free;
end;

constructor TVertexBuffer.Create(_attributes: TVertexAttributes);
begin
  attributes := _attributes;
  list := TVertexList.Create;
end;

end.