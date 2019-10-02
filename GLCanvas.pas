{$mode objfpc}
{$modeswitch advancedrecords}
{$modeswitch typehelpers}
{$interfaces CORBA}
{$assertions on}

unit GLCanvas;
interface
uses
  FGL, VectorMath, Classes, GLPT, GL, GLExt;

{$define INTERFACE}
{$include include/Textures.inc}
{$include include/BitmapFont.inc}
{$undef INTERFACE}

{ Window }
procedure SetupCanvas(inWidth, inHeight: integer; eventCallback: GLPT_EventCallback); 
function IsRunning: boolean;
procedure QuitApp;

{ Shapes }
procedure FillRect (constref rect: TRect; constref color: TColor);
procedure StrokeRect (constref rect: TRect; constref color: TColor; lineWidth: single = 1.0);
procedure FillOval (constref rect: TRect; constref color: TColor; segments: single = 32); 
procedure StrokeOval (constref rect: TRect; constref color: TColor; segments: TScalar = 32; lineWidth: TScalar = 1.0); 

{ Textures }
procedure DrawTexture (texture: TTexture; x, y: TScalar); overload;
procedure DrawTexture (texture: TTexture; constref rect: TRect); overload;

{ Buffers }
procedure FlushDrawing;
procedure ClearBackground;
procedure SwapBuffers;

procedure SetViewTransform(x, y, scale: TScalar);
procedure SetViewPort (inWidth, inHeight: integer);

{ Utilities }
function Rand(min, max: longint): longint;
function TimeSinceNow: longint;

implementation
uses
  BeRoPNG,
  Contnrs, Variants, CTypes,
  SysUtils, DOM, XMLRead, Strings;

{$define IMPLEMENTATION}
{$include include/Textures.inc}
{$include include/BitmapFont.inc}
{$undef IMPLEMENTATION}

const
  TWOPI = 3.14159 * 2;

{ Utils }
function TimeSinceNow: longint;
begin
  result := round(TimeStampToMSecs(DateTimeToTimeStamp(Now)));
end;    

function Rand(min, max: longint): longint;
var
  zero: boolean = false;
begin
  if min = 0 then 
    begin
      //Fatal('GetRandomNumber 0 min value is invalid.');
      min += 1;
      max += 1;
      zero := true;
    end;
    
  if (min < 0) and (max > 0) then
    max += abs(min);
  
  result := System.Random(max) mod ((max - min) + 1);
  
  if result < 0 then
    result := abs(result);
    
  if zero then
    min -= 1;
  result += min;
end;

{ Types }
type
  TVertex3 = record
    pos: TVec2;
    texCoord: TVec2;
    color: TVec4;
    uv: byte;
    constructor Create(inPos: TVec2; inTexCoord: TVec2; inColor: TVec4; inUV: byte);
    class operator = (constref a, b: TVertex3): boolean;
  end;

constructor TVertex3.Create(inPos: TVec2; inTexCoord: TVec2; inColor: TVec4; inUV: byte);
begin
  pos := inPos;
  texCoord := inTexCoord;
  color := inColor;
  uv := inUV;
end;

class operator TVertex3.= (constref a, b: TVertex3): boolean;
begin
  result := (@a = @b);
end;

{ Quads }
type
  generic TTexturedQuad<T> = record
    v: array[0..5] of T;
    // TODO: this should be absolute coords
    procedure SetPosition (x, y, w, h: TScalar); inline;
    procedure SetColor (r, g, b, a: TScalar); inline;
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

procedure TTexturedQuad.SetColor (r, g, b, a: TScalar);
begin
  v[0].color := RGBA(r, g, b, a);
  v[1].color := RGBA(r, g, b, a);
  v[2].color := RGBA(r, g, b, a);
  v[3].color := RGBA(r, g, b, a);
  v[4].color := RGBA(r, g, b, a);
  v[5].color := RGBA(r, g, b, a);
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
                          'layout (location=2) in vec4 inColor;'+
                          'layout (location=3) in float inUV;'+
                          'out vec2 vertexTexCoord;'+
                          'out vec4 vertexColor;'+
                          'out float vertexUV;'+
                          'uniform mat4 projTransform;'+
                          'uniform mat4 viewTransform;'+
                          'void main() {'+
                          '  gl_Position = projTransform * viewTransform * vec4(position, 0.0, 1.0);'+
                          '  vertexTexCoord = inTexCoord;'+
                          '  vertexUV = inUV;'+
                          '  vertexColor = inColor;'+
                          '}'#0;
  FragmentShader: pchar = '#version 330 core'+#10+
                          'uniform sampler2D textures[8];'+
                          'out vec4 fragColor;'+
                          'in vec2 vertexTexCoord;'+
                          'in vec4 vertexColor;'+
                          'in float vertexUV;'+
                          'void main() {'+
                          '  if (vertexUV < 8) {'+
                          '    fragColor = texture(textures[int(vertexUV)], vertexTexCoord.st);'+
                          '    if (vertexColor.a < fragColor.a) {'+
                          '      fragColor.a = vertexColor.a;'+
                          '    }'+
                          '  } else {'+
                          '    fragColor = vertexColor;'+
                          '  }'+
                          '}'#0;

{ Globals }
type
  TGLDrawState = record
    bufferPrimitiveType: GLint;
    lineWidth: single;
  end;

var
  width, height: integer;
  window: pGLPTWindow;
  context: GLPT_Context;
  projTransform: TMat4;
  viewTransform: TMat4;
  shader: GLuint;
  vertexBuffer: TVertex3List;
  textureUnits: array[0..7] of GLint = (0, 1, 2, 3, 4, 5, 6, 7);
  drawState: TGLDrawState;

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

function IsRunning: boolean;
begin
  result := not GLPT_WindowShouldClose(window);
end;

procedure QuitApp;
begin
  GLPT_DestroyWindow(window);
  GLPT_Terminate;
end;

procedure Prepare;
const
  kFarNearPlane = 100000;
begin
  glClearColor(1, 1, 1, 1);
  glEnable(GL_BLEND); 
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  shader := CreateShader(VertexShader, FragmentShader);
  glUseProgram(shader);

  projTransform := TMat4.Ortho(0, width, height, 0, -kFarNearPlane, kFarNearPlane);
  viewTransform := TMat4.Identity;

  glUniformMatrix4fv(glGetUniformLocation(shader, 'projTransform'), 1, GL_FALSE, projTransform.Ptr);
  glUniformMatrix4fv(glGetUniformLocation(shader, 'viewTransform'), 1, GL_FALSE, viewTransform.Ptr);

  glUniform1iv(glGetUniformLocation(shader, 'textures'), 8, @textureUnits);
end;

procedure Load; 
var
  offset: pointer;
  bufferID: GLuint;
  vao: GLuint;
begin
  vertexBuffer := TVertex3List.Create;

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

  // color
  glEnableVertexAttribArray(2);
  glVertexAttribPointer(2, 4, GL_FLOAT, GL_FALSE, sizeof(TVertex3), offset);
  Inc(offset, sizeof(TScalar) * 4);

  // UV
  glEnableVertexAttribArray(3);
  glVertexAttribPointer(3, 1, GL_UNSIGNED_BYTE, GL_FALSE, sizeof(TVertex3), offset);
  Inc(offset, sizeof(byte) * 1);
end;

procedure SetViewTransform(x, y, scale: TScalar);
begin
  viewTransform := TMat4.Identity
                   * TMat4.Translate(x, y, 1)
                   * TMat4.Scale(scale, scale, 1);

  glUniformMatrix4fv(glGetUniformLocation(shader, 'viewTransform'), 1, GL_FALSE, viewTransform.Ptr);
end;

procedure SetViewPort (inWidth, inHeight: integer);
begin
  width := inWidth;
  height := inHeight;
  glViewPort(0, 0, width, height);
end;

procedure error_callback(error: integer; description: string);
begin
  writeln(stderr, description);
  halt(-1);
end;

procedure SetupCanvas(inWidth, inHeight: integer; eventCallback: GLPT_EventCallback); 
begin
  GLPT_SetErrorCallback(@error_callback);

  if not GLPT_Init then
    halt(-1);

  width := inWidth;
  height := inHeight;

  context := GLPT_GetDefaultContext;
  context.majorVersion := 3;
  context.minorVersion := 2;
  context.profile := GLPT_CONTEXT_PROFILE_CORE;
  context.vsync := true;

  window := GLPT_CreateWindow(GLPT_WINDOW_POS_CENTER, GLPT_WINDOW_POS_CENTER, width, height, '', context);
  if window = nil then
    begin
      GLPT_Terminate;
      halt(-1);
    end;

  window^.event_callback := eventCallback;

  if not Load_GL_VERSION_3_2 then
    Halt(-1);

  writeln('OpenGL version: ', glGetString(GL_VERSION));
  writeln('GLPT version: ', GLPT_GetVersionString);

  // note: clear an opengl error
  glGetError();

  SetViewPort(width, height);
  Prepare;
  Load;
end;

procedure ChangePrimitiveType (typ: GLint); 
begin
  if vertexBuffer.Count > 0 then
    //Assert(drawState.bufferPrimitiveType = typ, 'must flush drawing before changing primitive type');
    FlushDrawing;
  drawState.bufferPrimitiveType := typ;
end;

procedure FillOval (constref rect: TRect; constref color: TColor; segments: TScalar = 32); 
var
  t: single = 0;
  x, y, w, h: single;
begin 
  ChangePrimitiveType(GL_TRIANGLE_FAN);

  w := rect.width / 2;
  h := rect.height / 2;
  x := rect.x - w;
  y := rect.y - h;
  x += rect.width;
  y += rect.height;
  
  while t <= TWOPI do
    begin
      vertexBuffer.Add(TVertex3.Create(V2(w * Cos(t) + x, h * Sin(t) + y), V2(0, 0), color, 255));
      t += TWOPI/segments;
    end;

  // TODO: we don't need to flush each time
  // https://stackoverflow.com/questions/31723405/line-graph-with-gldrawarrays-and-gl-line-strip-from-vector
  FlushDrawing;
end;  

procedure StrokeOval (constref rect: TRect; constref color: TColor; segments: TScalar = 32; lineWidth: TScalar = 1.0); 
var
  t: TScalar = 0;
  x, y, w, h, s: TScalar;
  texCoord: TPoint;
begin 
  ChangePrimitiveType(GL_LINE_LOOP);

  if drawState.lineWidth <> lineWidth then
    begin
      Assert(vertexBuffer.Count = 0, 'must flush drawing before changing line width');
      glLineWidth(lineWidth);
      drawState.lineWidth := lineWidth;
    end;

  w := rect.width / 2;
  h := rect.height / 2;
  x := rect.x - w;
  y := rect.y - h;
  x += rect.width;
  y += rect.height;
  s := TWOPI/segments;

  texCoord := PointMake(0, 0);

  while t <= TWOPI do
    begin
      vertexBuffer.Add(TVertex3.Create(PointMake(w * Cos(t) + x, h * Sin(t) + y), texCoord, color, 255));
      t += s;
    end;

  // TODO: we don't need to flush each time
  // https://stackoverflow.com/questions/31723405/line-graph-with-gldrawarrays-and-gl-line-strip-from-vector
  FlushDrawing;
end;

(*
procedure FillPolygon_Buffer (constref poly: TPolygon; r, g, b, a: TFloat);
var
  i: integer;
  vertex: TGLTexVertex;
begin
  for i := 0 to poly.High do
    begin
      vertex.vert := TGLVec2f.Make(poly[i].x, poly[i].y);
      vertex.texCoord := TGLVec2f.Make(0, 0);
      vertex.color := TGLRGBAb.Make(r, g, b, a);
      vertex.uv := 0;
      TexturedVertexBuffer.AppendData(vertex);
    end;

  TexturedVertexBuffer.Draw(GL_TRIANGLE_FAN);
  TexturedVertexBuffer.Reset;
end;

procedure StrokePolygon_Buffer (constref poly: TPolygon; r, g, b, a: TFloat; lineWidth: TFloat = 1.0);
var
  i: integer;
begin
  for i := 0 to poly.High do
    TexturedVertexBuffer.AppendData(TGLTexVertex.Make(poly[i].x, poly[i].y, r, g, b, a));

  TexturedVertexBuffer.Draw(GL_LINE_LOOP, lineWidth);
  TexturedVertexBuffer.Reset;
end;
*)

procedure FillRect (constref rect: TRect; constref color: TColor);
var
  quad: TVertex3Quad;
begin
  ChangePrimitiveType(GL_TRIANGLES);

  quad.SetPosition(rect.x, rect.y, rect.width, rect.height);
  quad.SetColor(color.r, color.g, color.b, color.a);
  quad.SetUV(255);

  vertexBuffer.Add(quad.v[0]);
  vertexBuffer.Add(quad.v[1]);
  vertexBuffer.Add(quad.v[2]);
  vertexBuffer.Add(quad.v[3]);
  vertexBuffer.Add(quad.v[4]);
  vertexBuffer.Add(quad.v[5]);
end;

procedure StrokeRect (constref rect: TRect; constref color: TColor; lineWidth: single = 1.0);
var
  texCoord: TPoint;
begin
  ChangePrimitiveType(GL_LINE_LOOP);

  if drawState.lineWidth <> lineWidth then
    begin
      Assert(vertexBuffer.Count = 0, 'must flush drawing before changing line width');
      glLineWidth(lineWidth);
      drawState.lineWidth := lineWidth;
    end;

  texCoord := PointMake(0, 0);
  vertexBuffer.Add(TVertex3.Create(PointMake(rect.MinX, rect.MinY), texCoord, color, 255));
  vertexBuffer.Add(TVertex3.Create(PointMake(rect.MaxX, rect.MinY), texCoord, color, 255));
  vertexBuffer.Add(TVertex3.Create(PointMake(rect.MaxX, rect.MaxY), texCoord, color, 255));
  vertexBuffer.Add(TVertex3.Create(PointMake(rect.MinX, rect.MaxY), texCoord, color, 255));

  // TODO: we don't need to flush each time
  // https://stackoverflow.com/questions/31723405/line-graph-with-gldrawarrays-and-gl-line-strip-from-vector
  FlushDrawing;
end;

procedure DrawTexture (texture: TTexture; constref rect: TRect);
var
  quad: TVertex3Quad;
begin
  Assert(texture <> nil, 'texture must not be nil');
  ChangePrimitiveType(GL_TRIANGLES);

  quad.SetColor(1, 1, 1, 1);
  quad.SetPosition(rect.x, rect.y, rect.width, rect.height);
  quad.SetTexture(texture.GetTextureFrame);
  quad.SetUV(texture.GetTextureUnit);

  vertexBuffer.Add(quad.v[0]);
  vertexBuffer.Add(quad.v[1]);
  vertexBuffer.Add(quad.v[2]);
  vertexBuffer.Add(quad.v[3]);
  vertexBuffer.Add(quad.v[4]);
  vertexBuffer.Add(quad.v[5]);
end;

procedure DrawTexture (texture: TTexture; x, y: TScalar);
var
  quad: TVertex3Quad;
begin
  Assert(texture <> nil, 'texture must not be nil');
  ChangePrimitiveType(GL_TRIANGLES);

  quad.SetColor(1, 1, 1, 1);
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

procedure ClearBackground;
begin
  glClear(GL_COLOR_BUFFER_BIT);
end;

procedure FlushDrawing;
begin
  glBufferData(GL_ARRAY_BUFFER, sizeof(TVertex3) * vertexBuffer.Count, TFPSList(vertexBuffer).first, GL_DYNAMIC_DRAW);
  Assert(glGetError() = 0, 'glBufferData error '+IntToStr(glGetError()));
  glDrawArrays(drawState.bufferPrimitiveType, 0, vertexBuffer.Count);
  Assert(glGetError() = 0, 'glDrawArrays error '+IntToStr(glGetError()));
  
  // TODO: clear shrinks capacity!
  vertexBuffer.Clear;
end;

procedure SwapBuffers;
begin
  FlushDrawing;
  GLPT_SwapBuffers(window);
  GLPT_PollEvents;
end;

begin
  FillChar(textureSlots, sizeof(TGLTextureID) * 64, 0);
  System.Randomize;
end.