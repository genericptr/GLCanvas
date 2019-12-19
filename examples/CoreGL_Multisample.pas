{$mode objfpc}
{$modeswitch advancedrecords}
{$assertions on}

// https://learnopengl.com/Advanced-OpenGL/Anti-Aliasing

program CoreGL_Multisample;
uses
  CThreads, Math,
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
  TexturedVertexShader: pchar = '#version 330 core'+#10+
                                'layout (location=0) in vec2 aPos;'+
                                'layout (location=1) in vec2 aTexCoords;'+
                                'out vec2 TexCoords;'+
                                'void main()'+
                                '{'+
                                '    TexCoords = aTexCoords;'+
                                '    gl_Position = vec4(aPos.x, aPos.y, 0.0, 1.0); '+
                                '}'#0;

  TexturedFragmentShader: pchar = '#version 330 core'+#10+
                                  'out vec4 FragColor;'+
                                  'in vec2 TexCoords;'+
                                  'uniform sampler2D screenTexture;'+
                                  'void main()'+
                                  '{'+
                                  '    vec3 col = texture(screenTexture, TexCoords).rgb;'+
                                  '    float grayscale = 0.2126 * col.r + 0.7152 * col.g + 0.0722 * col.b;'+
                                  '    FragColor = vec4(vec3(grayscale), 1.0);'+
                                  '}'#0;

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
    pos: TVec2;
    rot: float;
  end;

var
  width, height: integer;
  window: pGLPTWindow;
  context: GLPT_Context;
  projTransform: TMat4;
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

var
  QuadVertices: array[0..23] of float = (
      // vertex attributes for a quad that fills the entire screen in Normalized Device Coordinates.
      // positions   // texCoords
      -1.0,  1.0,  0.0, 1.0,
      -1.0, -1.0,  0.0, 0.0,
       1.0, -1.0,  1.0, 0.0,

      -1.0,  1.0,  0.0, 1.0,
       1.0, -1.0,  1.0, 0.0,
       1.0,  1.0,  1.0, 1.0
    );

var
  framebuffer, 
  textureColorBufferMultiSampled,
  rbo,
  intermediateFBO,
  screenTexture,
  quadVAO, 
  quadVBO: GLuint;
var
  shader,
  screenShader: GLuint;

procedure SetupBuffers(SCR_WIDTH, SCR_HEIGHT: integer); 
const
  MULTI_SAMPLES = 4;
var
  offset: pointer;
begin
  // configure MSAA framebuffer
  // --------------------------
  glGenFramebuffers(1, @framebuffer);
  glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
  // create a multisampled color attachment texture
  glGenTextures(1, @textureColorBufferMultiSampled);
  glBindTexture(GL_TEXTURE_2D_MULTISAMPLE, textureColorBufferMultiSampled);
  glTexImage2DMultisample(GL_TEXTURE_2D_MULTISAMPLE, MULTI_SAMPLES, GL_RGB, SCR_WIDTH, SCR_HEIGHT, GL_TRUE);
  //glBindTexture(GL_TEXTURE_2D_MULTISAMPLE, 0);
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D_MULTISAMPLE, textureColorBufferMultiSampled, 0);
  // create a (also multisampled) renderbuffer object for depth and stencil attachments
  glGenRenderbuffers(1, @rbo);
  glBindRenderbuffer(GL_RENDERBUFFER, rbo);
  glRenderbufferStorageMultisample(GL_RENDERBUFFER, MULTI_SAMPLES, GL_DEPTH24_STENCIL8, SCR_WIDTH, SCR_HEIGHT);
  //glBindRenderbuffer(GL_RENDERBUFFER, 0);
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_RENDERBUFFER, rbo);

  Assert(glCheckFramebufferStatus(GL_FRAMEBUFFER) = GL_FRAMEBUFFER_COMPLETE, 'Frame buffer is not complete');
  //glBindFramebuffer(GL_FRAMEBUFFER, 0);

  // configure second post-processing framebuffer
  glGenFramebuffers(1, @intermediateFBO);
  glBindFramebuffer(GL_FRAMEBUFFER, intermediateFBO);
  // create a color attachment texture
  glGenTextures(1, @screenTexture);
  glBindTexture(GL_TEXTURE_2D, screenTexture);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, SCR_WIDTH, SCR_HEIGHT, 0, GL_RGB, GL_UNSIGNED_BYTE, nil);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, screenTexture, 0);  // we only need a color buffer

  Assert(glCheckFramebufferStatus(GL_FRAMEBUFFER) = GL_FRAMEBUFFER_COMPLETE, 'Intermediate frame buffer is not complete');
  
  // setup screen VAO
  glGenVertexArrays(1, @quadVAO);
  glGenBuffers(1, @quadVBO);
  glBindVertexArray(quadVAO);
  glBindBuffer(GL_ARRAY_BUFFER, quadVBO);
  glBufferData(GL_ARRAY_BUFFER, sizeof(QuadVertices), @QuadVertices, GL_STATIC_DRAW);
  glEnableVertexAttribArray(0);
  offset := nil;
  glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), offset);
  inc(offset, 2 * sizeof(float));
  glEnableVertexAttribArray(1);
  glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), offset);

  // restore bindings to default state
  glBindTexture(GL_TEXTURE_2D, 0);
  glBindTexture(GL_TEXTURE_2D_MULTISAMPLE, 0);
  glBindRenderbuffer(GL_RENDERBUFFER, 0);
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
  glBindBuffer(GL_ARRAY_BUFFER, 0);
end;

procedure Prepare;
const
  kFarNearPlane = 100000;
begin
  glClearColor(1, 1, 1, 1);

  shader := CreateShader(VertexShader, FragmentShader);  
  glUseProgram(shader);
  projTransform := TMat4.Ortho(0, width, height, 0, -kFarNearPlane, kFarNearPlane);
  glUniformMatrix4fv(glGetUniformLocation(shader, 'projTransform'), 1, GL_FALSE, projTransform.Ptr);

  screenShader := CreateShader(TexturedVertexShader, TexturedFragmentShader);
end;

procedure LoadSprite; 
var
  offset: pointer;
begin
  mainSprite := TSprite.Create;

  mainSprite.pos := V2(100, 100);

  glGenVertexArrays(1, @mainSprite.vao);
  glBindVertexArray(mainSprite.vao);

  mainSprite.quad.SetPosition(0, 0, 64, 64);

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

procedure DrawShape;
var
  modelTransform: TMat4;
begin
  mainSprite.rot += 0.5;
  modelTransform := TMat4.Translate(mainSprite.pos.x, mainSprite.pos.y, 0) * TMat4.RotateZ(DegToRad(mainSprite.rot));
  glUniformMatrix4fv(glGetUniformLocation(shader, 'modelTransform'), 1, GL_FALSE, modelTransform.Ptr);

  glBindVertexArray(mainSprite.vao);
  glBindBuffer(GL_ARRAY_BUFFER, mainSprite.bufferID);
  glDrawArrays(GL_TRIANGLES, 0, 6);
  glBindBuffer(GL_ARRAY_BUFFER, 0);
  glBindVertexArray(0);
end;

procedure DrawScene(SCR_WIDTH, SCR_HEIGHT: integer);
begin
  glDisable(GL_DEPTH_TEST);

  // 1. draw scene as normal in multisampled buffers
  // ----------------------------
  glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
  glClearColor(1, 1, 1, 1);
  glClear(GL_COLOR_BUFFER_BIT);
  glUseProgram(shader);
  DrawShape;

  // 2. now blit multisampled buffer(s) to normal colorbuffer of intermediate FBO. Image is stored in screenTexture
  // ----------------------------
  glBindFramebuffer(GL_READ_FRAMEBUFFER, framebuffer);
  glBindFramebuffer(GL_DRAW_FRAMEBUFFER, intermediateFBO);
  glBlitFramebuffer(0, 0, SCR_WIDTH, SCR_HEIGHT, 0, 0, SCR_WIDTH, SCR_HEIGHT, GL_COLOR_BUFFER_BIT, GL_NEAREST);

  // 3. now render quad with scene's visuals as its texture image
  // ----------------------------
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
  glClearColor(1, 1, 1, 1);
  glClear(GL_COLOR_BUFFER_BIT);

  // draw Screen quad
  glUseProgram(screenShader);
  glBindVertexArray(quadVAO);
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, screenTexture); // use the now resolved color attachment as the quad's texture
  glDrawArrays(GL_TRIANGLES, 0, 6);
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
  context.multisamples := 0;

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
  SetupBuffers(width, height);
  LoadSprite;

  while not GLPT_WindowShouldClose(window) do
    begin
      DrawScene(width, height);
      GLPT_SwapBuffers(window);
      GLPT_PollEvents;
    end;

  GLPT_DestroyWindow(window);
  GLPT_Terminate;
end.