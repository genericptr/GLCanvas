{$mode objfpc}
{$modeswitch advancedrecords}
{$assertions on}
{$include targetos}

unit GLShader;
interface
uses
  {$ifdef API_OPENGL}
  GL, GLext,
  {$endif}
  {$ifdef API_OPENGLES}
  GLES30,
  {$endif}
  GLVertexBuffer, VectorMath,
  FGL;

type
  TShader = class
    private
      programID: GLuint;
      procedure Use;
    public
      constructor Create (vertexShaderSource, fragmentShaderSource: pchar);
      procedure Push;
      procedure Pop;
      function IsActive: boolean;
      function GetUniformLocation(name: pchar): integer;
      procedure SetUniformMat4(name: pchar; constref mat: TMat4);
      procedure SetUniformInts(name: pchar; count: integer; ints: PInteger);
      procedure SetUniformInt(name: pchar; value: integer);
      procedure SetUniformFloat(name: pchar; value: float);
      destructor Destroy; override;
  end;
  TShaderObjectList = specialize TFPGObjectList<TShader>;

var
  ShaderStack: TShaderObjectList;

implementation
uses
  GLUtils, SysUtils;

constructor TShader.Create (vertexShaderSource, fragmentShaderSource: pchar);
var
  vertexShaderID: GLuint;
  fragmentShaderID: GLuint;
var
  success: GLint;
  logLength: GLint;
  logArray: array of GLChar;
  i: integer;
begin 
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

procedure TShader.Push;
begin
  if ShaderStack = nil then
    ShaderStack := TShaderObjectList.Create(false);
  ShaderStack.Add(self);
  Use;
end;

procedure TShader.Pop;
begin
  if ShaderStack = nil then
    ShaderStack := TShaderObjectList.Create(false);
  ShaderStack.Delete(ShaderStack.Count - 1);
  Assert(ShaderStack.Count > 0, 'attempting to pop empty shader stack.');
  ShaderStack.Last.Use;
end;

procedure TShader.Use;
begin
  glUseProgram(programID);
	GLAssert('glUseProgram '+IntToStr(programID));
  //writeln('use shader ', programID);
end;

function TShader.IsActive: boolean;
begin
  result := ShaderStack.Last = self;
end;

procedure TShader.SetUniformMat4(name: pchar; constref mat: TMat4);
begin
  Assert(IsActive, 'shader must be active before setting uniforms.');
  glUniformMatrix4fv(GetUniformLocation(name), 1, GL_FALSE, mat.Ptr);
  GLAssert('glUniformMatrix4fv '+name);
end;

procedure TShader.SetUniformFloat(name: pchar; value: float);
begin
  Assert(IsActive, 'shader must be active before setting uniforms.');
  glUniform1f(GetUniformLocation(name), value);
  GLAssert('glUniform1f '+name);
end;

procedure TShader.SetUniformInt(name: pchar; value: integer);
begin
  Assert(IsActive, 'shader must be active before setting uniforms.');
  glUniform1i(GetUniformLocation(name), value);
  GLAssert('glUniform1i '+name);
end;

procedure TShader.SetUniformInts(name: pchar; count: integer; ints: PInteger);
begin
  Assert(IsActive, 'shader must be active before setting uniforms.');
  glUniform1iv(GetUniformLocation(name), count, ints);
  GLAssert('glUniform1iv '+name);
end;

function TShader.GetUniformLocation(name: pchar): integer;
begin
  result := glGetUniformLocation(programID, name);
  GLAssert('glGetUniformLocation '+name);
end;

destructor TShader.Destroy;
begin
  glDeleteShader(programID);
end;

end.
