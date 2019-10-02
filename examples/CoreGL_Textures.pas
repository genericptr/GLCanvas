{$mode objfpc}
{$modeswitch advancedrecords}
{$assertions on}

program CoreGL_Textures;
uses
  Textures, FGL, VectorMath, GLPT, GL, GLExt;
 
{ Types }
type
  TVertex3 = record
    pos: TVec2;
    texCoord: TVec2;
    uv: byte;
    class operator = (constref a, b: TVertex3): boolean;
  end;

class operator TVertex3.= (constref a, b: TVertex3): boolean;
begin
  result := (@a = @b);
end;

{ Quads }
type
  generic TTexturedQuad<T> = record
    v: array[0..5] of T;
    procedure SetPosition (x, y, w, h: TScalar); inline;
    procedure SetTexture (rect: TRect); inline;
    procedure SetUV (id: byte); inline;
  end;

procedure TTexturedQuad.SetPosition (x, y, w, h: TScalar);
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

procedure TTexturedQuad.SetTexture (rect: TRect);
begin
  v[0].texCoord.x := rect.MinX;
  v[0].texCoord.y := rect.MinY;
  v[1].texCoord.x := rect.MaxX;
  v[1].texCoord.y := rect.MinY; 
  v[2].texCoord.x := rect.MinX;
  v[2].texCoord.y := rect.MaxY; 
  v[3].texCoord.x := rect.MinX;
  v[3].texCoord.y := rect.MaxY; 
  v[4].texCoord.x := rect.MaxX;
  v[4].texCoord.y := rect.MaxY; 
  v[5].texCoord.x := rect.MaxX;
  v[5].texCoord.y := rect.MinY; 
end;

procedure TTexturedQuad.SetUV (id: byte);
begin
  v[0].uv := id;
  v[1].uv := id;
  v[2].uv := id;
  v[3].uv := id;
  v[4].uv := id;
  v[5].uv := id;
end;

type
  TVertex3Quad = specialize TTexturedQuad<TVertex3>;
  TVertex3List = specialize TFPGList<TVertex3>;

{ Shaders }
const
  VertexShader: pchar =   '#version 330 core'+#10+
                          'layout (location=0) in vec2 position;'+
                          'layout (location=1) in vec2 inTexCoord;'+
                          'layout (location=2) in float inUV;'+
                          'out vec2 vertexTexCoord;'+
                          'out float vertexUV;'+
                          'uniform mat4 projTransform;'+
                          'void main() {'+
                          '  gl_Position = projTransform * vec4(position, 0.0, 1.0);'+
                          '  vertexTexCoord = inTexCoord;'+
                          '  vertexUV = inUV;'+
                          '}'#0;
  FragmentShader: pchar = '#version 330 core'+#10+
                          'uniform sampler2D textures[8];'+
                          'out vec4 fragColor;'+
                          'in vec2 vertexTexCoord;'+
                          'in float vertexUV;'+
                          'void main() {'+
                          '  fragColor = texture(textures[int(vertexUV)], vertexTexCoord.st);'+
                          '  if (fragColor.a < fragColor.a) {'+
                          '    fragColor.a = fragColor.a;'+
                          '  }'+
                          '}'#0;

{ Globals }
var
  width, height: integer;
  window: pGLPTWindow;
  context: GLPT_Context;
  projTransform: TMat4;
  shader: GLuint;
  vertexBuffer: TVertex3List;
  textures: array[0..3] of TTexture;
  textureUnits: array[0..7] of GLint = (0, 1, 2, 3, 4, 5, 6, 7);

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

  writeln('projTransform:',glGetUniformLocation(shader, 'projTransform'));
  writeln('textures:',glGetUniformLocation(shader, 'textures'));

  glUniformMatrix4fv(glGetUniformLocation(shader, 'projTransform'), 1, GL_FALSE, projTransform.Ptr);
  glUniform1iv(glGetUniformLocation(shader, 'textures'), 8, @textureUnits);
end;

procedure DrawTexture (texture: TTexture; x, y: TScalar);
var
  quad: TVertex3Quad;
begin
  quad.SetPosition(x, y, texture.GetWidth, texture.GetHeight);
  quad.SetTexture(texture.GetTextureFrame);
  quad.SetUV(texture.GetTextureUnit);

  // TODO: can we make a patch to add a block of memory?
  vertexBuffer.Add(quad.v[0]);
  vertexBuffer.Add(quad.v[1]);
  vertexBuffer.Add(quad.v[2]);
  vertexBuffer.Add(quad.v[3]);
  vertexBuffer.Add(quad.v[4]);
  vertexBuffer.Add(quad.v[5]);
end;

procedure Load; 
var
  offset: pointer;
  sheet: TTextureSheet;
  bufferID: GLuint;
  vao: GLuint;
begin
  vertexBuffer := TVertex3List.Create;

  // TODO: how are plain textures loaded? right now nothing happens
  //textures[0] := TTexture.Create(GetDataFile('bird.png'));
  //textures[1] := TTexture.Create(GetDataFile('cat.png'));

  // TODO: can we make an "atlas" which is both sheet/pack?
  sheet := TTextureSheet.Create('/Users/ryanjoseph/Documents/metroid/zero.png', SizeMake(16, 16));
  textures[2] := sheet[0, 0];
  textures[3] := sheet[0, 1];

  glGenVertexArrays(1, @vao);
  glBindVertexArray(vao);

  // bind vertex array buffer
  glGenBuffers(1, @bufferID);
  glBindBuffer(GL_ARRAY_BUFFER, bufferID);

  // position
  offset := nil;
  glEnableVertexAttribArray(0);
  glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, sizeof(TVertex3), offset);
  Inc(offset, sizeof(TScalar) * 2);

  // textureCoord
  glEnableVertexAttribArray(1);
  glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, sizeof(TVertex3), offset);
  Inc(offset, sizeof(TScalar) * 2);

  // UV
  glEnableVertexAttribArray(2);
  glVertexAttribPointer(2, 1, GL_UNSIGNED_BYTE, GL_FALSE, sizeof(TVertex3), offset);
  Inc(offset, sizeof(byte) * 1);
end;

procedure FlushDrawing;
begin
  glClear(GL_COLOR_BUFFER_BIT);
  glBufferData(GL_ARRAY_BUFFER, sizeof(TVertex3) * vertexBuffer.Count, TFPSList(vertexBuffer).first, GL_DYNAMIC_DRAW);
  glDrawArrays(GL_TRIANGLES, 0, vertexBuffer.Count);
  // TODO: clear shrinks capacity!
  vertexBuffer.Clear;
end;

procedure Reshape;
begin
  glViewPort(0, 0, width, height);
end;

procedure Setup; 
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
end;

begin
  Setup;
  Reshape;
  Prepare;
  Load;

  while not GLPT_WindowShouldClose(window) do
    begin
      DrawTexture(textures[2], 100, 100);
      FlushDrawing;
      GLPT_SwapBuffers(window);
      GLPT_PollEvents;
    end;

  GLPT_DestroyWindow(window);
  GLPT_Terminate;
end.