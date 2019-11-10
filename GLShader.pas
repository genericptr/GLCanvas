{$mode objfpc}
{$modeswitch advancedrecords}
{$assertions on}

unit GLShader;
interface
uses
  Contnrs, VectorMath, GL, GLExt;

type
  TShader = class
    private
      programID: GLuint;
      procedure Use;
    public
      constructor Create (vertexShaderSource, fragmentShaderSource: pchar);
      procedure Push;
      procedure Pop;
      function GetUniformLocation(name: pchar): integer;
      procedure SetUniformMatrix4fv(name: pchar; constref mat: TMat4);
      procedure SetUniform1iv(name: pchar; count: integer; ints: PInteger);
      destructor Destroy; override;
  end;

var
  ShaderStack: TObjectList;

implementation
uses
  SysUtils;

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
    ShaderStack := TObjectList.Create(false);
  ShaderStack.Add(self);
  Use;
end;

procedure TShader.Pop;
begin
  if ShaderStack = nil then
    ShaderStack := TObjectList.Create(false);
  ShaderStack.Delete(ShaderStack.Count - 1);
  Assert(ShaderStack.Count > 0, 'attempting to pop empty shader stack.');
  TShader(ShaderStack.Last).Use;
end;

procedure TShader.Use;
begin
  glUseProgram(programID);
  //writeln('use shader ', programID);
end;

procedure TShader.SetUniformMatrix4fv(name: pchar; constref mat: TMat4);
begin
  glUniformMatrix4fv(GetUniformLocation(name), 1, GL_FALSE, mat.Ptr);
end;

procedure TShader.SetUniform1iv(name: pchar; count: integer; ints: PInteger);
begin
  glUniform1iv(GetUniformLocation(name), count, ints);
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