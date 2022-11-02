{$ifdef INTERFACE}

type
  TShader = class
    private
      programID: GLuint;
      procedure Use;
    public
      constructor Create(vertexShaderSource, fragmentShaderSource: pchar);
      destructor Destroy; override;
      procedure Push;
      procedure Pop;
      function IsActive: boolean;
      function GetUniformLocation(name: pchar): integer;
      procedure SetUniformMat4(name: pchar; constref mat: TMat4);
      procedure SetUniformInts(name: pchar; count: integer; ints: PInteger); overload;
      procedure SetUniformInts(name: pchar; ints: array of GLint); overload;
      procedure SetUniformInt(name: pchar; value: integer);
      procedure SetUniformFloat(name: pchar; value: float);
      procedure SetUniformBool(name: pchar; value: boolean);
      procedure SetUniformVec2(name: pchar; value: TVec2);
      procedure SetUniformVec3(name: pchar; value: TVec3);
      procedure SetUniformVec4(name: pchar; value: TVec4);
  end;
  TShaderClass = class of TShader;
  TShaderObjectList = specialize TFPGObjectList<TShader>;

var
  ShaderStack: TShaderObjectList;

{$endif}

{$ifdef IMPLEMENTATION}

constructor TShader.Create(vertexShaderSource, fragmentShaderSource: pchar);
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
  // TODO: assert if the 2d draw buffer is full so the user knows to flush first
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

procedure TShader.SetUniformBool(name: pchar; value: boolean);
begin
  Assert(IsActive, 'shader must be active before setting uniforms.');
  glUniform1ui(GetUniformLocation(name), GLuint(value));
  GLAssert('glUniform1f '+name);
end;

procedure TShader.SetUniformVec2(name: pchar; value: TVec2);
begin
  Assert(IsActive, 'shader must be active before setting uniforms.');
  glUniform2f(GetUniformLocation(name), value.x, value.y);
  GLAssert('glUniform2f '+name);
end;

procedure TShader.SetUniformVec3(name: pchar; value: TVec3);
begin
  Assert(IsActive, 'shader must be active before setting uniforms.');
  glUniform3f(GetUniformLocation(name), value.x, value.y, value.z);
  GLAssert('glUniform3f '+name);
end;

procedure TShader.SetUniformVec4(name: pchar; value: TVec4);
begin
  Assert(IsActive, 'shader must be active before setting uniforms.');
  glUniform4f(GetUniformLocation(name), value.x, value.y, value.z, value.w);
  GLAssert('glUniform4f '+name);
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

procedure TShader.SetUniformInts(name: pchar; ints: array of GLint);
begin
  Assert(IsActive, 'shader must be active before setting uniforms.');
  glUniform1iv(GetUniformLocation(name), length(ints), ints);
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

{$endif}