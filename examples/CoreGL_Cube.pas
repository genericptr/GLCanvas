{$mode objfpc}
{$modeswitch advancedrecords}
{$assertions on}

program CoreGL_Cube;
uses
  CThreads,
  GLPT, GL, GLExt,
  VectorMath;


{ positions }
type
  TCubeVerticies = array[0..107] of float;
  PCubeVerticies = ^TCubeVerticies;
const
  TVertex3Size = sizeof(float) * 3;
 
var
 CubeVertices: TCubeVerticies = (
  -0.5, -0.5, -0.5,
   0.5, -0.5, -0.5,
   0.5,  0.5, -0.5,
   0.5,  0.5, -0.5,
  -0.5,  0.5, -0.5,
  -0.5, -0.5, -0.5,

  -0.5, -0.5,  0.5,
   0.5, -0.5,  0.5,
   0.5,  0.5,  0.5,
   0.5,  0.5,  0.5,
  -0.5,  0.5,  0.5,
  -0.5, -0.5,  0.5,

  -0.5,  0.5,  0.5,
  -0.5,  0.5, -0.5,
  -0.5, -0.5, -0.5,
  -0.5, -0.5, -0.5,
  -0.5, -0.5,  0.5,
  -0.5,  0.5,  0.5,

   0.5,  0.5,  0.5,
   0.5,  0.5, -0.5,
   0.5, -0.5, -0.5,
   0.5, -0.5, -0.5,
   0.5, -0.5,  0.5,
   0.5,  0.5,  0.5,

  -0.5, -0.5, -0.5,
   0.5, -0.5, -0.5,
   0.5, -0.5,  0.5,
   0.5, -0.5,  0.5,
  -0.5, -0.5,  0.5,
  -0.5, -0.5, -0.5,

  -0.5,  0.5, -0.5,
   0.5,  0.5, -0.5,
   0.5,  0.5,  0.5,
   0.5,  0.5,  0.5,
  -0.5,  0.5,  0.5,
  -0.5,  0.5, -0.5
  );    

{ Shaders }
const
  VertexShader: pchar =   '#version 330 core'+#10+
                          'layout (location=0) in vec3 pos;'+
                          'uniform mat4 projTransform;'+
                          'uniform mat4 viewTransform;'+
                          'uniform mat4 modelTransform;'+
                          'void main() {'+
                          '  gl_Position = projTransform * viewTransform * modelTransform * vec4(pos, 1.0);'+
                          '}'#0;
  FragmentShader: pchar = '#version 330 core'+#10+
                          'out vec4 fragColor;'+
                          'void main() {'+
                          '  fragColor = vec4(0, 1, 0, 1);'+
                          '}'#0;
type
  TCube = class
    bufferID: GLuint;
    vao: GLuint;
    verts: PCubeVerticies;
    rot: TVec3;
    constructor Create;
    procedure Load; 
    procedure Draw;
  end;

{ Globals }
var
  width, height: integer;
  window: pGLPTWindow;
  context: GLPT_Context;
  projTransform: TMat4;
  viewTransform: TMat4;
  shader: GLuint;
  cube: TCube = nil;

constructor TCube.Create;
begin
  verts := @CubeVertices;
  rot := V3(0, 0, 0);
  glGenVertexArrays(1, @vao);
  glGenBuffers(1, @bufferID);
end;

procedure TCube.Load; 
begin
  // bind vertex array buffer
  glBindVertexArray(vao);
  glBindBuffer(GL_ARRAY_BUFFER, bufferID);
  glBufferData(GL_ARRAY_BUFFER, sizeof(verts^), verts, GL_STATIC_DRAW);

  // position
  glEnableVertexAttribArray(0);
  glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, TVertex3Size, nil);

  glBindBuffer(GL_ARRAY_BUFFER, 0);
  glBindVertexArray(0);
end;

procedure TCube.Draw;
var
  modelTransform: TMat4;
begin
  rot += 0.5;

  modelTransform := TMat4.Identity *
                    //TMat4.Translate(rot.x, 1, 1) *
                    TMat4.Scale(0.25, 0.25, 0.25) *
                    TMat4.RotateX(rot.x) * TMat4.RotateY(rot.y) * TMat4.RotateZ(rot.z);

  glBindVertexArray(vao);
  //glBindBuffer(GL_ARRAY_BUFFER, bufferID);
  glUniformMatrix4fv(glGetUniformLocation(shader, 'projTransform'), 1, GL_FALSE, projTransform.Ptr);
  glUniformMatrix4fv(glGetUniformLocation(shader, 'viewTransform'), 1, GL_FALSE, viewTransform.Ptr);
  glUniformMatrix4fv(glGetUniformLocation(shader, 'modelTransform'), 1, GL_FALSE, modelTransform.Ptr);
  glDrawArrays(GL_TRIANGLES, 0, Length(TCubeVerticies) div 3);
  //glBindBuffer(GL_ARRAY_BUFFER, 0);
  glBindVertexArray(0);
end;

function CreateShader (vertexShaderSource, fragmentShaderSource: pchar): GLuint;
var
  programID: GLuint;
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

  result := programID;
end;

procedure EventCallback(event: pGLPT_MessageRec);
begin
  case event^.mcode of
    GLPT_MESSAGE_KEYPRESS:
      begin
        if event^.params.keyboard.keycode = GLPT_KEY_ESCAPE then
          GLPT_SetWindowShouldClose(event^.win, True);
      end;
  end;
end;

procedure Prepare;
begin
  glClearColor(1, 1, 1, 1);
  glEnable(GL_DEPTH_TEST); 
  //glEnable(GL_BLEND); 
  //glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  projTransform := TMat4.PerspectiveGL(60.0, width / height, 0.1, 1000);
  //projTransform := TMat4.Ortho(0, width, height, 0, -10000, 10000);
  viewTransform := TMat4.Identity;

  shader := CreateShader(vertexShader, fragmentShader);
  glUseProgram(shader);

  glUniformMatrix4fv(glGetUniformLocation(shader, 'projTransform'), 1, GL_FALSE, projTransform.Ptr);
  glUniformMatrix4fv(glGetUniformLocation(shader, 'viewTransform'), 1, GL_FALSE, viewTransform.Ptr);
end;

procedure Reshape;
begin
  glViewPort(0, 0, width, height);
end;

begin
  if not GLPT_Init then
    halt(-1);

  width := 640;
  height := 480;

  context := GLPT_GetDefaultContext;
  context.majorVersion := 3;
  context.minorVersion := 3;
  context.profile := GLPT_CONTEXT_PROFILE_CORE;
  context.vsync := true;

  window := GLPT_CreateWindow(GLPT_WINDOW_POS_CENTER, GLPT_WINDOW_POS_CENTER, width, height, '', context);
  window^.event_callback := @EventCallback;

  if not Load_GL_VERSION_3_3 then
  if not Load_GL_VERSION_3_2 then
    Halt(-1);

  writeln('OpenGL version: ', glGetString(GL_VERSION));

  Reshape;
  Prepare;
  
  cube := TCube.Create;
  cube.Load;

  while not GLPT_WindowShouldClose(window) do
    begin
      glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
      cube.Draw;
      GLPT_SwapBuffers(window);
      GLPT_PollEvents;
    end;

  GLPT_DestroyWindow(window);
  GLPT_Terminate;
end.