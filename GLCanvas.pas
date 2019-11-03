{$mode objfpc}
{$modeswitch advancedrecords}
{$modeswitch typehelpers}
{$modeswitch autoderef}
{$interfaces CORBA}
{$assertions on}

unit GLCanvas;
interface
uses
  GL, GLExt, FGL, Classes, 
  GLPT, VectorMath;

{$define INTERFACE}
{$include include/Textures.inc}
{$include include/BitmapFont.inc}
{$include include/FileUtils.inc}
{$undef INTERFACE}

type
  TVec2Array = array[0..0] of TVec2;
  PVec2Array = ^TVec2Array;

{ Window }
procedure SetupCanvas(inWidth, inHeight: integer; eventCallback: GLPT_EventCallback); 
function IsRunning: boolean;
procedure QuitApp;

{ Shapes }
procedure FillRect (constref rect: TRect; constref color: TColor);
procedure StrokeRect (constref rect: TRect; constref color: TColor; lineWidth: single = 1.0);
procedure FillOval (constref rect: TRect; constref color: TColor; segments: single = 32); 
procedure StrokeOval (constref rect: TRect; constref color: TColor; segments: single = 32; lineWidth: single = 1.0); 
procedure FillPolygon(points: array of TVec2; constref color: TColor);
procedure StrokePolygon(points: array of TVec2; constref color: TColor; lineWidth: single = 1.0);
procedure DrawLine(p1, p2: TVec2; thickness: single = 1); inline;
procedure DrawLine(points: PVec2Array; count: integer; thickness: single = 1);
procedure DrawPoint(constref point: TVec2; constref color: TColor);

{ Textures }
procedure DrawTexture (texture: TTexture; x, y: single); overload;
procedure DrawTexture (texture: TTexture; constref rect: TRect); overload; inline;
procedure DrawTexture (texture: TTexture; constref rect: TRect; constref textureFrame: TRect); overload;

{ Buffers }
procedure FlushDrawing;
procedure ClearBackground;
procedure SwapBuffers;

procedure SetViewTransform(x, y, scale: single);
procedure SetViewPort (inWidth, inHeight: integer);

{ Utilities }
function Rand(min, max: longint): longint;
function TimeSinceNow: longint;

type
  TGLCanvasState = record
    width, height: integer;
    window: PGLPTWindow;
    projTransform: TMat4;
    viewTransform: TMat4;
  end;

var
  GLCanvasState: TGLCanvasState;

implementation
uses
  BeRoPNG, GLShader,
  Contnrs, Variants, CTypes,
  SysUtils, DOM, XMLRead, Strings;

{$define IMPLEMENTATION}
{$include include/Textures.inc}
{$include include/BitmapFont.inc}
{$include include/FileUtils.inc}
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
  TVertex3Shader = specialize TShader<TVertex3>;

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
    procedure SetPosition (minX, minY, maxX, maxY: single); inline;
    procedure SetPosition (constref rect: TRect);
    procedure SetColor (r, g, b, a: single); inline;
    procedure SetTexture (rect: TRect); inline;
    procedure SetUV (id: byte); inline;
  end;

procedure TTexturedQuad.SetPosition (constref rect: TRect);
begin
  v[0].pos.x := rect.MinX;
  v[0].pos.y := rect.MinY;
  v[1].pos.x := rect.MaxX;
  v[1].pos.y := rect.MinY; 
  v[2].pos.x := rect.MinX;
  v[2].pos.y := rect.MaxY; 
  v[3].pos.x := rect.MinX;
  v[3].pos.y := rect.MaxY; 
  v[4].pos.x := rect.MaxX;
  v[4].pos.y := rect.MaxY; 
  v[5].pos.x := rect.MaxX;
  v[5].pos.y := rect.MinY; 
end;

procedure TTexturedQuad.SetPosition (minX, minY, maxX, maxY: single);
begin
  v[0].pos.x := minX;
  v[0].pos.y := minY;
  v[1].pos.x := maxX;
  v[1].pos.y := minY;
  v[2].pos.x := minX;
  v[2].pos.y := maxY;
  v[3].pos.x := minX;
  v[3].pos.y := maxY;
  v[4].pos.x := maxX;
  v[4].pos.y := maxY;
  v[5].pos.x := maxX;
  v[5].pos.y := minY;
end;

procedure TTexturedQuad.SetColor (r, g, b, a: single);
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
  DefaultVertexShader: pchar =  '#version 330 core'+#10+
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
  DefaultFragmentShader: pchar = '#version 330 core'+#10+
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
  context: GLPT_Context;
  defaultShader: TVertex3Shader = nil;
  vertexBuffer: TVertex3List;
  textureUnits: array[0..7] of GLint = (0, 1, 2, 3, 4, 5, 6, 7);
  drawState: TGLDrawState;

function IsRunning: boolean;
begin
  result := not GLPT_WindowShouldClose(GLCanvasState.window);
end;

procedure QuitApp;
begin
  GLPT_DestroyWindow(GLCanvasState.window);
  GLPT_Terminate;
end;

procedure Prepare;
const
  kFarNearPlane = 100000;
begin
  glClearColor(1, 1, 1, 1);
  glEnable(GL_BLEND); 
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glDisable(GL_MULTISAMPLE);
  glDisable(GL_DEPTH_TEST);

  with GLCanvasState do
    begin
      projTransform := TMat4.Ortho(0, width, height, 0, -kFarNearPlane, kFarNearPlane);
      viewTransform := TMat4.Identity;

      defaultShader := TVertex3Shader.Create(DefaultVertexShader, 
                                             DefaultFragmentShader,  
                                             [TShaderAttribute.Create(GL_FLOAT, 2),         // position
                                              TShaderAttribute.Create(GL_FLOAT, 2),         // textureCoord
                                              TShaderAttribute.Create(GL_FLOAT, 4),         // color
                                              TShaderAttribute.Create(GL_UNSIGNED_BYTE, 1)  // UV
                                              ]);

      defaultShader.Push;
      glUniformMatrix4fv(defaultShader.GetUniformLocation('projTransform'), 1, GL_FALSE, projTransform.Ptr);
      glUniformMatrix4fv(defaultShader.GetUniformLocation('viewTransform'), 1, GL_FALSE, viewTransform.Ptr);
      glUniform1iv(defaultShader.GetUniformLocation('textures'), 8, @textureUnits);
    end;
end;

procedure Load; 
begin
  vertexBuffer := TVertex3List.Create;

  //with GLCanvasState do
  //  begin
  //    glGenVertexArrays(1, @vertexArrayObject);
  //    glBindVertexArray(vertexArrayObject);

  //    glGenBuffers(1, @bufferID);
  //    glBindBuffer(GL_ARRAY_BUFFER, bufferID);
  //  end;

  //shader.EnableVertexAttributes;
end;

procedure SetViewTransform(x, y, scale: single);
begin
  GLCanvasState.viewTransform := TMat4.Identity
                   * TMat4.Translate(x, y, 1)
                   * TMat4.Scale(scale, scale, 1);

  Assert(ShaderStack.Last = defaultShader, 'active shader must be default.');
  glUniformMatrix4fv(defaultShader.GetUniformLocation('viewTransform'), 1, GL_FALSE, GLCanvasState.viewTransform.Ptr);
end;

procedure SetViewPort (inWidth, inHeight: integer);
begin
  with GLCanvasState do
    begin
      width := inWidth;
      height := inHeight;
      glViewPort(0, 0, width, height);
    end;
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

  with GLCanvasState do
    begin
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
end;

procedure ChangePrimitiveType (typ: GLint); 
begin
  if vertexBuffer.Count > 0 then
    //Assert(drawState.bufferPrimitiveType = typ, 'must flush drawing before changing primitive type');
    FlushDrawing;
  drawState.bufferPrimitiveType := typ;
end;

procedure FillOval (constref rect: TRect; constref color: TColor; segments: single = 32); 
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

procedure StrokeOval (constref rect: TRect; constref color: TColor; segments: single = 32; lineWidth: single = 1.0); 
var
  t: single = 0;
  x, y, w, h, s: single;
  texCoord: TVec2;
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

  texCoord := V2(0, 0);

  while t <= TWOPI do
    begin
      vertexBuffer.Add(TVertex3.Create(V2(w * Cos(t) + x, h * Sin(t) + y), texCoord, color, 255));
      t += s;
    end;

  // TODO: we don't need to flush each time
  // https://stackoverflow.com/questions/31723405/line-graph-with-gldrawarrays-and-gl-line-strip-from-vector
  FlushDrawing;
end;

procedure FillPolygon(points: array of TVec2; constref color: TColor);
var
  i: integer;
begin
  ChangePrimitiveType(GL_TRIANGLE_FAN);
  for i := 0 to high(points) do
    vertexBuffer.Add(TVertex3.Create(points[i], V2(0, 0), color, 255));
  // TODO: we don't need to flush each time
  FlushDrawing;
end;

procedure StrokePolygon(points: array of TVec2; constref color: TColor; lineWidth: single = 1.0);
var
  i: integer;
begin
  ChangePrimitiveType(GL_LINE_LOOP);
  for i := 0 to high(points) do
    vertexBuffer.Add(TVertex3.Create(points[i], V2(0, 0), color, 255));
  // TODO: we don't need to flush each time
  FlushDrawing;
end;

procedure DrawPoint(constref point: TVec2; constref color: TColor);
begin
  ChangePrimitiveType(GL_POINTS);
  vertexBuffer.Add(TVertex3.Create(point, V2(0, 0), color, 255));
  // TODO: we don't need to flush each time
  FlushDrawing;
end;

procedure DrawLine(p1, p2: TVec2; thickness: single = 1);
var
  points: array[0..1] of TVec2;
begin
  points[0] := p1;
  points[1] := p2;
  DrawLine(@points[0], 2, thickness);
end;

procedure DrawLine(points: PVec2Array; count: integer; thickness: single = 1);
var
  v: array[0..3] of TVertex3;
  n: TVec2;
  r, a: single;
  i: integer;
begin
  Assert(thickness >= 1, 'line thickness must be >= 1.');

  // https://artgrammer.blogspot.com/2011/05/drawing-nearly-perfect-2d-line-segments.html
  // https://people.eecs.ku.edu/~jrmiller/Courses/OpenGL/DrawModes.html

  if thickness = 1 then
    begin
      ChangePrimitiveType(GL_LINE_STRIP);

      for i := 0 to count - 1 do
        begin
          // connect points between segments
          //if (i mod 2 = 0) and (i > 0) then
          //  begin
          //    vertexBuffer.Add(TVertex3.Create(points[i - 1], V2(0, 0), V4(0, 0, 0, 1), 255));
          //    vertexBuffer.Add(TVertex3.Create(points[i], V2(0, 0), V4(0, 0, 0, 1), 255));
          //  end;
          vertexBuffer.Add(TVertex3.Create(points[i], V2(0, 0), V4(0, 0, 0, 1), 255));
        end;
    end
  else if thickness > 1 then
    begin
      ChangePrimitiveType(GL_TRIANGLES);

      r := thickness / 2;
      a := (points[0] - points[1]).Angle;
      n := points[0].Normalize;

      i := 0;
      while i < count do
        begin
          // connect points between segments
          if (i mod 2 = 0) and (i > 0) then
            begin
            end;

          if i = 0 then
            begin
              v[0] := TVertex3.Create(points[i] + n.Rotate(a + PI * 0.25) * r, V2(0, 0), V4(0, 0, 0, 1), 255);
              v[1] := TVertex3.Create(points[i] + n.Rotate(a + PI * 1.25) * r, V2(0, 0), V4(0, 0, 0, 1), 255);
            end;
          
          v[2] := TVertex3.Create(points[i + 1] + n.Rotate(a + PI * 0.25) * r, V2(0, 0), V4(0, 0, 0, 1), 255);
          v[3] := TVertex3.Create(points[i + 1] + n.Rotate(a + PI * 1.25) * r, V2(0, 0), V4(0, 0, 0, 1), 255);

          vertexBuffer.Add(v[0]);
          vertexBuffer.Add(v[1]);
          vertexBuffer.Add(v[3]);

          vertexBuffer.Add(v[3]);
          vertexBuffer.Add(v[2]);
          vertexBuffer.Add(v[0]);

          i += 2;
        end;

      //v[0] := TVertex3.Create(points[0] + n.Rotate(a + PI * 0.25) * r, V2(0, 0), V4(0, 0, 0, 1), 255);
      //v[1] := TVertex3.Create(points[0] + n.Rotate(a + PI * 1.25) * r, V2(0, 0), V4(0, 0, 0, 1), 255);
      
      //v[2] := TVertex3.Create(points[1] + n.Rotate(a + PI * 0.25) * r, V2(0, 0), V4(0, 0, 0, 1), 255);
      //v[3] := TVertex3.Create(points[1] + n.Rotate(a + PI * 1.25) * r, V2(0, 0), V4(0, 0, 0, 1), 255);

      //vertexBuffer.Add(v[0]);
      //vertexBuffer.Add(v[1]);
      //vertexBuffer.Add(v[3]);

      //vertexBuffer.Add(v[3]);
      //vertexBuffer.Add(v[2]);
      //vertexBuffer.Add(v[0]);
    end;
end;

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
  texCoord: TVec2;
begin
  ChangePrimitiveType(GL_LINE_LOOP);

  if drawState.lineWidth <> lineWidth then
    begin
      Assert(vertexBuffer.Count = 0, 'must flush drawing before changing line width');
      glLineWidth(lineWidth);
      drawState.lineWidth := lineWidth;
    end;

  texCoord := V2(0, 0);
  vertexBuffer.Add(TVertex3.Create(V2(rect.MinX, rect.MinY), texCoord, color, 255));
  vertexBuffer.Add(TVertex3.Create(V2(rect.MaxX, rect.MinY), texCoord, color, 255));
  vertexBuffer.Add(TVertex3.Create(V2(rect.MaxX, rect.MaxY), texCoord, color, 255));
  vertexBuffer.Add(TVertex3.Create(V2(rect.MinX, rect.MaxY), texCoord, color, 255));

  // TODO: we don't need to flush each time
  // https://stackoverflow.com/questions/31723405/line-graph-with-gldrawarrays-and-gl-line-strip-from-vector
  FlushDrawing;
end;

procedure DrawTexture (texture: TTexture; constref rect: TRect; constref textureFrame: TRect);
var
  quad: TVertex3Quad;
  textureUnit: TGLTextureUnit;
begin
  Assert(texture <> nil, 'texture must not be nil');
  if texture.GetOwner <> nil then
    textureUnit := PushTexture(texture.GetOwner)
  else
    textureUnit := PushTexture(texture);
  ChangePrimitiveType(GL_TRIANGLES);
  //writeln('draw ', rect.tostr, ' = ', textureUnit);

  quad.SetColor(1, 1, 1, 1);
  quad.SetPosition(rect);
  quad.SetTexture(textureFrame);
  quad.SetUV(textureUnit);

  vertexBuffer.Add(quad.v[0]);
  vertexBuffer.Add(quad.v[1]);
  vertexBuffer.Add(quad.v[2]);
  vertexBuffer.Add(quad.v[3]);
  vertexBuffer.Add(quad.v[4]);
  vertexBuffer.Add(quad.v[5]);
end;

procedure DrawTexture (texture: TTexture; constref rect: TRect);
begin
  DrawTexture(texture, rect, texture.GetTextureFrame);
end;

procedure DrawTexture (texture: TTexture; x, y: single);
begin
  DrawTexture(texture, RectMake(x, y, texture.GetWidth, texture.GetHeight));
end;

procedure ClearBackground;
begin
  glClear(GL_COLOR_BUFFER_BIT);
end;

procedure FlushDrawing;
begin
  if vertexBuffer.Count = 0 then
    exit;

  Assert(ShaderStack.Last = defaultShader, 'active shader must be default.');

  glBufferData(GL_ARRAY_BUFFER, sizeof(TVertex3) * vertexBuffer.Count, TFPSList(vertexBuffer).First, GL_DYNAMIC_DRAW);
  Assert(glGetError() = 0, 'glBufferData error '+IntToStr(glGetError()));
  glDrawArrays(drawState.bufferPrimitiveType, 0, vertexBuffer.Count);
  Assert(glGetError() = 0, 'glDrawArrays error '+IntToStr(glGetError()));
  
  // TODO: clear shrinks capacity!
  vertexBuffer.Clear;
end;

procedure SwapBuffers;
begin
  FlushDrawing;
  GLPT_SwapBuffers(GLCanvasState.window);
  GLPT_PollEvents;
end;

var
  i: integer;
begin
  for i := 0 to 64 - 1 do
    TextureSlots[i] := nil;
  System.Randomize;
end.