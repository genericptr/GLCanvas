{$mode objfpc}
{$modeswitch advancedrecords}
{$assertions on}

program CoreGL_Minimal;
uses
  VectorMath, GLPT, GL, GLExt;

{ Types }
type
  TVertex3 = record
    pos: TVec2;
    col: TVec3;
  end;

{ Quads }
type
  generic TQuad<T> = record
    public
      v: array[0..5] of T;
    public
      procedure SetPosition (x, y, w, h: TScalar); overload;
  end;

procedure TQuad.SetPosition (x, y, w, h: TScalar);
begin
  v[0].pos.x := x;
  v[0].pos.y := y; 
  v[1].pos.x := x + w;
  v[1].pos.y := y; 
  v[2].pos.x := x;
  v[2].pos.y := y + h; 
  v[3].pos.x := x;
  v[3].pos.y := y + h; 
  v[4].pos.x := x + w;
  v[4].pos.y := y + h; 
  v[5].pos.x := x + w;
  v[5].pos.y := y; 
end;

type
  TVertex3Quad = specialize TQuad<TVertex3>;

{ Shaders }
const
  VertexShader: pchar =   '#version 330 core'+#10+
                          'layout (location=0) in vec2 position;'+
                          'layout (location=1) in vec3 in_color;'+
                          'out vec3 vertex_color;'+
                          'uniform mat4 projTransform;'+
                          'uniform mat4 modelTransform;'+
                          'void main() {'+
                          '  gl_Position = projTransform * modelTransform * vec4(position, 0.0, 1.0);'+
                          '  vertex_color = in_color;'+
                          '}'#0;
  FragmentShader: pchar = '#version 330 core'+#10+
                          'out vec4 final_color;'+
                          'in vec3 vertex_color;'+
                          'void main() {'+
                          '  final_color = vec4(vertex_color, 1.0);'+
                          '}'#0;

{ Globals }
type
  TSprite = class
    bufferID: GLuint;
    vao: GLuint;
    quad: TVertex3Quad;
    x, y, w, h: single;
  end;

var
  width, height: integer;
  window: pGLPTWindow;
  context: GLPT_Context;
  projTransform: TMat4;
  shader: GLuint;
  mainSprite: TSprite;

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

function GetDataFile (name: string): string; inline;
begin
  result := GLPT_GetBasePath+name;
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
const
  kFarNearPlane = 100000;
begin
  glClearColor(1, 1, 1, 1);
  glEnable(GL_BLEND); 
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  shader := CreateShader(vertexShader, fragmentShader);
  glUseProgram(shader);

  projTransform := TMat4.Ortho(0, width, height, 0, -kFarNearPlane, kFarNearPlane);

  glUniformMatrix4fv(glGetUniformLocation(shader, 'projTransform'), 1, GL_FALSE, projTransform.Ptr);
end;

procedure Load; 
var
  offset: pointer;
begin
  mainSprite := TSprite.Create;

  glGenVertexArrays(1, @mainSprite.vao);
  glBindVertexArray(mainSprite.vao);

  mainSprite.quad.SetPosition(100, 100, 32, 64);

  // bind vertex array buffer
  glGenBuffers(1, @mainSprite.bufferID);
  glBindBuffer(GL_ARRAY_BUFFER, mainSprite.bufferID);
  glBufferData(GL_ARRAY_BUFFER, sizeof(TVertex3Quad), @mainSprite.quad, GL_DYNAMIC_DRAW);

  // position
  offset := nil;
  glEnableVertexAttribArray(0);
  glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, sizeof(TVertex3), offset);
  Inc(offset, sizeof(TVec2));

  // color
  glEnableVertexAttribArray(1);
  glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, sizeof(TVertex3), offset);

  glBindBuffer(GL_ARRAY_BUFFER, 0);
  glBindVertexArray(0);
end;

procedure Draw;
var
  modelTransform: TMat4;
begin
  glBindVertexArray(mainSprite.vao);
  glBindBuffer(GL_ARRAY_BUFFER, mainSprite.bufferID);
  modelTransform := TMat4.Translate(mainSprite.x - (mainSprite.w / 2), mainSprite.y - mainSprite.h, 0);
  glUniformMatrix4fv(glGetUniformLocation(shader, 'modelTransform'), 1, GL_FALSE, modelTransform.Ptr);
  glDrawArrays(GL_TRIANGLES, 0, 6);
  glBindBuffer(GL_ARRAY_BUFFER, 0);
  glBindVertexArray(0);
end;

procedure Reshape;
begin
  glViewPort(0, 0, width, height);
end;

begin
  if not GLPT_Init then
    halt(-1);

  width := 400;
  height := 400;

  context := GLPT_GetDefaultContext;
  context.majorVersion := 3;
  context.minorVersion := 2;
  context.profile := GLPT_CONTEXT_PROFILE_CORE;
  context.vsync := true;

  window := GLPT_CreateWindow(GLPT_WINDOW_POS_CENTER, GLPT_WINDOW_POS_CENTER, width, height, '', context);
  window^.event_callback := @EventCallback;

  if not Load_GL_VERSION_3_2 then
  if not Load_GL_VERSION_3_1 then
  if not Load_GL_VERSION_3_0 then
    Halt(-1);

  writeln('OpenGL version: ', glGetString(GL_VERSION));
  glGetError();

  Reshape;
  Prepare;
  Load;

  while not GLPT_WindowShouldClose(window) do
    begin
      glClear(GL_COLOR_BUFFER_BIT);
      Draw;
      GLPT_SwapBuffers(window);
      GLPT_PollEvents;
    end;

  GLPT_DestroyWindow(window);
  GLPT_Terminate;
end.