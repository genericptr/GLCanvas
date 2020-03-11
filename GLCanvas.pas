{$mode objfpc}
{$modeswitch advancedrecords}
{$modeswitch typehelpers}
{$modeswitch autoderef}
{$modeswitch multihelpers}
{$interfaces CORBA}
{$assertions on}

unit GLCanvas;
interface
uses
  GL, GLExt, FGL, Classes, 
  BeRoPNG, GLPT, VectorMath, GeometryTypes;

{$define INTERFACE}
{$include include/Textures.inc}
{$include include/Text.inc}
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
procedure DrawLine(p1, p2: TVec2; constref color: TColor; thickness: single = 1); inline;
procedure DrawLine(points: PVec2Array; count: integer; constref color: TColor; thickness: single = 1);
procedure DrawPoint(constref point: TVec2; constref color: TColor);

{ Textures }
procedure DrawTexture (texture: ITexture; x, y: single); overload;
procedure DrawTexture (texture: ITexture; constref rect: TRect); overload; inline;
procedure DrawTexture (texture: ITexture; constref rect: TRect; constref textureFrame: TRect); overload;
procedure DrawTexture (texture: ITexture; constref rect: TRect; constref textureFrame: TRect; constref color: TVec4); overload;
procedure DrawTexture (texture: ITexture; constref rect: TRect; constref color: TVec4); overload; inline;

{ Clip Rects }
procedure PushClipRect (rect: TRect); 
procedure PopClipRect; 

{ Buffers }
procedure FlushDrawing;
procedure ClearBackground;
procedure SwapBuffers;

procedure SetActiveFont(newValue: IFont);
function GetActiveFont: IFont;
procedure SetViewTransform(x, y, scale: single);
procedure SetViewPort (inWidth, inHeight: integer);
function GetViewPort: TRect; inline;

{ Utilities }
function FRand (min, max: single): single;
function FRand (min, max: single; decimal: integer): single;
function Rand(min, max: longint): longint;
function TimeSinceNow: longint;

type
  TRectList = specialize TFPGList<TRect>;
  TGLCanvasState = record
    width, height: integer;
    window: PGLPTWindow;
    projTransform: TMat4;
    viewTransform: TMat4;
    clipRectStack: TRectList;
    activeFont: IFont;
    bindTextureCount: longint;
  end;

// TODO: we work with interfaces now so this doesn't work
type
  TTextureHelper = class helper for TTextureSource
    procedure Draw(x, y: single); overload;
    procedure Draw(constref rect: TRect); overload;
    procedure Draw(constref rect: TRect; constref color: TVec4); overload;
  end;

var
  GLCanvasState: TGLCanvasState;

implementation
uses
  GLShader, GLVertexBuffer, GLUtils,
  Contnrs, Variants, CTypes,
  SysUtils, DOM, XMLRead, Strings;

{$define IMPLEMENTATION}
{$include include/Textures.inc}
{$include include/Text.inc}
{$include include/BitmapFont.inc}
{$include include/FileUtils.inc}
{$undef IMPLEMENTATION}

const
  TWOPI = 3.14159 * 2;

{ Utils }
function TimeSinceNow: longint;
begin
  // TODO: replace with GLPT_Time
  result := round(TimeStampToMSecs(DateTimeToTimeStamp(Now)));
end;    

function FRand (min, max: single): single;
begin
  result := FRand(min, max, 100);
end;

function FRand (min, max: single; decimal: integer): single;
begin
  result := Rand(trunc(min * decimal), trunc(max * decimal)) / decimal;
end;

function Rand(min, max: longint): longint;
var
  zero: boolean = false;
begin
  Assert(max >= 0, 'Rand max ('+IntToStr(max)+') is negative.');

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

{ Texture Helper }

procedure TTextureHelper.Draw(x, y: single);
begin
  DrawTexture(self, x, y);
end;

procedure TTextureHelper.Draw(constref rect: TRect);
begin
  DrawTexture(self, rect);
end;

procedure TTextureHelper.Draw(constref rect: TRect; constref color: TVec4);
begin
  DrawTexture(self, rect, TextureFrame, color);
end;

{ Types }
// TODO: TVertex3 doesn't make sense. rename to TDefaultVertex to go with default shader
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
  TVertex3VertexBuffer = specialize TVertexBuffer<TVertex3>;

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
                                 '  fragColor.rgb = fragColor.rgb * vertexColor.rgb;'+
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
  defaultShader: TShader = nil;
  vertexBuffer: TVertex3VertexBuffer = nil;
  textureUnits: array[0..7] of GLint = (0, 1, 2, 3, 4, 5, 6, 7);
  drawState: TGLDrawState;

function IsRunning: boolean;
begin
  result := not GLPT_WindowShouldClose(GLCanvasState.window);
end;

procedure error_callback(error: integer; description: string);
begin
  writeln(stderr, description);
  halt(-1);
end;

procedure SetActiveFont(newValue: IFont);
begin
  GLCanvasState.activeFont := newValue;
end;

function GetActiveFont: IFont;
begin
  result := GLCanvasState.activeFont;
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

function GetViewPort: TRect;
//var
//  viewPort: array[0..3] of GLint;
begin
  //glGetIntegerv(GL_VIEWPORT, @viewPort);
  //result := RectMake(viewPort[0], viewPort[1], viewPort[2], viewPort[3]);
  result := RectMake(0, 0, GLCanvasState.width, GLCanvasState.height);
end;

procedure QuitApp;
begin
  GLPT_DestroyWindow(GLCanvasState.window);
  GLPT_Terminate;
end;

procedure ChangePrimitiveType (typ: GLint); 
begin
  if vertexBuffer.Count > 0 then
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

procedure DrawLine(p1, p2: TVec2; constref color: TColor; thickness: single = 1);
var
  points: array[0..1] of TVec2;
begin
  points[0] := p1;
  points[1] := p2;
  DrawLine(@points[0], 2, color, thickness);
end;

procedure DrawLine(points: PVec2Array; count: integer; constref color: TColor; thickness: single = 1);
var
  v: array[0..3] of TVertex3;
  n: TVec2;
  r, a: single;
  i: integer;
begin
  if thickness < 0 then
    thickness := 1;

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
          vertexBuffer.Add(TVertex3.Create(points[i], V2(0, 0), color, 255));
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
              v[0] := TVertex3.Create(points[i] + n.Rotate(a + PI * 0.25) * r, V2(0, 0), color, 255);
              v[1] := TVertex3.Create(points[i] + n.Rotate(a + PI * 1.25) * r, V2(0, 0), color, 255);
            end;
          
          v[2] := TVertex3.Create(points[i + 1] + n.Rotate(a + PI * 0.25) * r, V2(0, 0), color, 255);
          v[3] := TVertex3.Create(points[i + 1] + n.Rotate(a + PI * 1.25) * r, V2(0, 0), color, 255);

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

  quad.SetPosition(rect);
  quad.SetColor(color.r, color.g, color.b, color.a);
  quad.SetUV(255);

  vertexBuffer.AddQuad(@quad);
end;

procedure StrokeRect (constref rect: TRect; constref color: TColor; lineWidth: single = 1.0);
var
  texCoord: TVec2;
begin

  // TODO: line width doesn't work now???
  // https://stackoverflow.com/questions/3484260/opengl-line-width
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

procedure DrawTexture (texture: ITexture; constref rect: TRect; constref textureFrame: TRect; constref color: TVec4);
var
  quad: TVertex3Quad;
  textureUnit: TGLTextureUnit;
begin
  Assert(texture <> nil, 'texture must not be nil');
  textureUnit := PushTexture(texture);
  ChangePrimitiveType(GL_TRIANGLES);

  quad.SetColor(color.r, color.g, color.b, color.a);
  quad.SetPosition(rect);
  quad.SetTexture(textureFrame);
  quad.SetUV(textureUnit);

  vertexBuffer.AddQuad(@quad);
end;

procedure DrawTexture (texture: ITexture; constref rect: TRect; constref color: TVec4);
begin
  DrawTexture(texture, rect, texture.GetFrame.Texture, color);
end;

procedure DrawTexture (texture: ITexture; constref rect: TRect; constref textureFrame: TRect);
begin
  DrawTexture(texture, rect, textureFrame, RGBA(1, 1, 1, 1));
end;

procedure DrawTexture (texture: ITexture; constref rect: TRect);
begin
  DrawTexture(texture, rect, texture.GetFrame.Texture);
end;

procedure DrawTexture (texture: ITexture; x, y: single);
var
  size: TVec2;
begin
  size := texture.GetFrame.pixel.size;
  DrawTexture(texture, RectMake(x, y, size.width, size.height));
end;

procedure ClearBackground;
begin
  glClear(GL_COLOR_BUFFER_BIT);
end;

procedure PushClipRect (rect: TRect); 
begin
  with GLCanvasState do
    begin
      if clipRectStack.Count = 0 then
        glEnable(GL_SCISSOR_TEST);
      //rect := RectFlip(rect, GetViewPort);
      // TODO: if the new rect is outside of the previous than don't clip
      if clipRectStack.Count > 0 then
        begin
          if clipRectStack.Last.ContainsRect(rect) then
            glScissor(Trunc(rect.MinX), Trunc(rect.MinY), Trunc(rect.Width), Trunc(rect.Height));
        end
      else
        glScissor(Trunc(rect.MinX), Trunc(rect.MinY), Trunc(rect.Width), Trunc(rect.Height));
      clipRectStack.Add(rect);
    end;
end;

procedure PopClipRect; 
var
  rect: TRect;
begin
  with GLCanvasState do
    begin
      clipRectStack.Delete(clipRectStack.Count - 1);
      if clipRectStack.Count > 0 then
        begin
          rect := clipRectStack.Last;
          glScissor(Trunc(rect.MinX), Trunc(rect.MinY), Trunc(rect.Width), Trunc(rect.Height));
        end
      else
        glDisable(GL_SCISSOR_TEST);
    end;
end;

procedure FlushDrawing;
begin
  if not assigned(vertexBuffer) or (vertexBuffer.Count = 0) then
    exit;

  //Assert(ShaderStack.Last = defaultShader, 'active shader must be default.');

  vertexBuffer.Draw(drawState.bufferPrimitiveType);
  vertexBuffer.Clear;
end;

procedure SwapBuffers;
begin
  FlushDrawing;
  GLPT_SwapBuffers(GLCanvasState.window);
  GLPT_PollEvents;
end;

procedure Prepare;
const
  kFarNearPlane = 100000;
begin
  glClearColor(1, 1, 1, 1);
  glEnable(GL_BLEND); 
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  //glDisable(GL_MULTISAMPLE);
  //glEnable(GL_MULTISAMPLE_ARB);
  glEnable(GL_MULTISAMPLE);
  glDisable(GL_DEPTH_TEST);

  with GLCanvasState do
    begin
      projTransform := TMat4.Ortho(0, width, height, 0, -kFarNearPlane, kFarNearPlane);
      viewTransform := TMat4.Identity;

      vertexBuffer := TVertex3VertexBuffer.Create([TVertexAttribute.Create(GL_FLOAT, 2),         // position
                                                   TVertexAttribute.Create(GL_FLOAT, 2),         // textureCoord
                                                   TVertexAttribute.Create(GL_FLOAT, 4),         // color
                                                   TVertexAttribute.Create(GL_UNSIGNED_BYTE, 1)  // UV
                                                   ]);

      defaultShader := TShader.Create(DefaultVertexShader, DefaultFragmentShader);

      defaultShader.Push;
      defaultShader.SetUniformMat4('projTransform', projTransform);
      defaultShader.SetUniformMat4('viewTransform', viewTransform);
      defaultShader.SetUniformInts('textures', 8, @textureUnits);
    end;
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
      
      clipRectStack := TRectList.Create;

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
      writeln('Texture Units: ', GetMaximumTextureUnits);

      // note: clear an opengl error
      glGetError();

      SetViewPort(width, height);
      Prepare;
    end;
end;


begin
  FillChar(TextureSlots, sizeof(TextureSlots), 0);
  System.Randomize;
  ChDir(GLPT_GetBasePath);
end.