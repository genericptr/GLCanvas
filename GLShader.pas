{$mode objfpc}
{$modeswitch advancedrecords}
{$assertions on}

unit GLShader;
interface
uses
  Contnrs, GL, GLExt;

type
  TShaderAttribute = record
    kind: GLenum;
    count: integer;
    constructor Create(_kind: GLenum; _count: integer);
  end;
  TShaderAttributes = array of TShaderAttribute;

type
  generic TShader<T> = class
    public type
      TVertexType = T;
    private
      programID: GLuint;
      vertexArrayObject: GLuint;
      bufferID: GLuint;
      shaderAttributes: TShaderAttributes;
      function SizeofAttribute(kind: GLuint): integer;
      procedure Use;
    public
      constructor Create (vertexShaderSource, fragmentShaderSource: pchar; attributes: TShaderAttributes);
      procedure EnableVertexAttributes; 
      procedure Push;
      procedure Pop;
      function GetUniformLocation(name: pchar): integer;
      destructor Destroy; override;
  end;

var
  ShaderStack: TObjectList;

implementation
uses
  SysUtils;


constructor TShaderAttribute.Create(_kind: GLenum; _count: integer);
begin
  kind := _kind;
  count := _count;
end;

constructor TShader.Create (vertexShaderSource, fragmentShaderSource: pchar; attributes: TShaderAttributes);
var
  vertexShaderID: GLuint;
  fragmentShaderID: GLuint;
var
  success: GLint;
  logLength: GLint;
  logArray: array of GLChar;
  i: integer;
begin 
  shaderAttributes := attributes;

  // create shader
  vertexShaderID := glCreateShader(GL_VERTEX_SHADER);
  fragmentShaderID := glCreateShader(GL_FRAGMENT_SHADER);

  // shader source
  glShaderSource(vertexShaderID, 1, @vertexShaderSource, nil);
  glShaderSource(fragmentShaderID, 1, @fragmentShaderSource, nil);  

  // compile shader
  glCompileShader(vertexShaderID);
  glGetShaderiv(vertexShaderID, GL_COMPILE_STATUS, @success);
  glGetShaderiv(vertexShaderID, GL_INFO_LOG_LENGTH, @logLength);
  if success = GL_FALSE then
    begin
      SetLength(logArray, logLength+1);
      glGetShaderInfoLog(vertexShaderID, logLength, nil, @logArray[0]);
      for i := 0 to logLength do
        write(logArray[i]);
      Assert(success = GL_TRUE, 'Vertex shader failed to compile');
    end;
  
  glCompileShader(fragmentShaderID);
  glGetShaderiv(fragmentShaderID, GL_COMPILE_STATUS, @success);
  glGetShaderiv(fragmentShaderID, GL_INFO_LOG_LENGTH, @logLength);
  if success = GL_FALSE then
    begin
      SetLength(logArray, logLength+1);
      glGetShaderInfoLog(fragmentShaderID, logLength, nil, @logArray[0]);
      for i := 0 to logLength do
        write(logArray[i]);
      Assert(success = GL_TRUE, 'Fragment shader failed to compile');
    end;
    
  // create program
  programID := glCreateProgram();
  glAttachShader(programID, vertexShaderID);
  glAttachShader(programID, fragmentShaderID);

  // link
  glLinkProgram(programID);
  glGetProgramiv(programID, GL_LINK_STATUS, @success);
  Assert(success = GL_TRUE, 'Error with linking shader program'); 
end;

function TShader.SizeofAttribute(kind: GLuint): integer;
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

procedure TShader.EnableVertexAttributes; 
var
  offset: pointer;
  attribute: TShaderAttribute;
  i: integer;
begin
  if vertexArrayObject = 0 then
    begin
      glGenVertexArrays(1, @vertexArrayObject);
      glBindVertexArray(vertexArrayObject);

      glGenBuffers(1, @bufferID);
      glBindBuffer(GL_ARRAY_BUFFER, bufferID);

      offset := nil;
      for i := 0 to high(shaderAttributes) do
        begin
          attribute := shaderAttributes[i];
          glEnableVertexAttribArray(i);
          glVertexAttribPointer(i, attribute.count, attribute.kind, GL_FALSE, sizeof(TVertexType), offset);
          Inc(offset, SizeofAttribute(attribute.kind) * attribute.count);
        end;
    end
  else
    begin
      glBindVertexArray(vertexArrayObject);
      glBindBuffer(GL_ARRAY_BUFFER, bufferID);
    end;
end;

procedure TShader.Push;
begin
  if ShaderStack = nil then
    ShaderStack := TObjectList.Create(false);
  ShaderStack.Add(self);
  Use;
  EnableVertexAttributes;
end;

procedure TShader.Pop;
begin
  if ShaderStack = nil then
    ShaderStack := TObjectList.Create(false);
  ShaderStack.Delete(ShaderStack.Count - 1);
  Assert(ShaderStack.Count > 0, 'attempting to pop empty shader stack.');
  TShader(ShaderStack.Last).Use;
  TShader(ShaderStack.Last).EnableVertexAttributes;
end;

procedure TShader.Use;
begin
  glUseProgram(programID);
  //writeln('use shader ', programID);
end;

function TShader.GetUniformLocation(name: pchar): integer;
begin
  result := glGetUniformLocation(programID, name);
end;

destructor TShader.Destroy;
begin
  glDeleteShader(programID);
end;

end.