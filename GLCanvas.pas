
{$mode objfpc}
{$modeswitch advancedrecords}
{$modeswitch typehelpers}
{$modeswitch autoderef}
{$modeswitch multihelpers}
{$modeswitch nestedprocvars}

{$interfaces corba}
{$implicitexceptions off}

{$include include/targetos.inc}

unit GLCanvas;
interface
uses
  {$ifdef API_OPENGL}
  GL, GLext,
  {$endif}
  {$ifdef API_OPENGLES}
  GLES30,
  {$endif}
  Contnrs, FGL, Classes, Math,
  BeRoPNG, VectorMath, GeometryTypes,
  GLVertexBuffer, GLFrameBuffer, GLShader, GLPT, GLPT_Threads;


{$define INTERFACE}
{$include include/ExtraTypes.inc}
{$include include/Textures.inc}
{$include include/Text.inc}
{$include include/BitmapFont.inc}
{$include include/FileUtils.inc}
{$include include/Input.inc}
{$undef INTERFACE}

{$scopedenums on}
type
  TCanvasOption = (VSync,
                   FullScreen
    );
  TCanvasOptions = set of TCanvasOption;
{$scopedenums off}

const
  DefaultCanvasOptions = [TCanvasOption.VSync];

{ Window }
procedure SetupCanvas(width, height: integer; eventCallback: GLPT_EventCallback = nil; options: TCanvasOptions = DefaultCanvasOptions); 
function IsRunning: boolean;
procedure QuitApp;

function CanvasMousePosition(event: pGLPT_MessageRec): TVec2i;

{ Shapes }
procedure FillRect(constref rect: TRect; constref color: TColor);
procedure StrokeRect(constref rect: TRect; constref color: TColor; lineWidth: single = 1.0);
procedure FillOval(constref rect: TRect; constref color: TColor; segments: single = 32); 
procedure StrokeOval(constref rect: TRect; constref color: TColor; segments: single = 32; lineWidth: single = 1.0); 
procedure FillPolygon(points: array of TVec2; constref color: TColor);
procedure StrokePolygon(points: array of TVec2; constref color: TColor; connectPoints: boolean = true);
procedure DrawLine(p1, p2: TVec2; constref color: TColor; thickness: single = 1); inline;
procedure DrawLine(points: array of TVec2; count: integer; constref color: TColor; thickness: single = 1);
procedure DrawPoint(constref point: TVec2; constref color: TColor);

{ Textures }
function CreateTexture(path: ansistring): TTexture;
function CreateTextureSheet(path: ansistring; cellSize: TVec2i): TTextureSheet;
function CreateTextureSheet(path: ansistring; cellSize, tableSize: TVec2i): TTextureSheet;
function CreateTexturePack(path: ansistring): TTexturePack;

procedure DrawTexture(texture: ITexture; x, y: single); overload; inline;
procedure DrawTexture(texture: ITexture; point: TVec2); overload; inline;
procedure DrawTexture(texture: ITexture; point: TVec2; constref color: TVec4); overload; inline;

procedure DrawTexture(texture: ITexture; constref rect: TRect); overload; inline;
procedure DrawTexture(texture: ITexture; constref rect: TRect; constref textureFrame: TRect); overload;
procedure DrawTexture(texture: ITexture; constref rect: TRect; constref textureFrame: TRect; constref color: TVec4); overload;
procedure DrawTexture(texture: ITexture; constref rect: TRect; constref color: TVec4); overload; inline;

{ Text }
function MeasureText(font: IFont; text: ansistring; maximumWidth: integer = MaxInt): TVec2;
function WrapText(font: IFont; text: ansistring; maximumWidth: integer): TStringList;

function DrawText(text: ansistring; textAlignment: TTextAlignment; bounds: TRect; color: TColor): TVec2; overload; inline;
function DrawText(text: ansistring; textAlignment: TTextAlignment; bounds: TRect): TVec2; overload; inline;
procedure DrawText(text: ansistring; where: TVec2; color: TColor; scale: single = 1.0); overload; inline;
procedure DrawText(text: ansistring; where: TVec2; scale: single = 1.0); overload; inline;

function DrawText(font: IFont; text: ansistring; textAlignment: TTextAlignment; bounds: TRect; color: TColor): TVec2; overload;
function DrawText(font: IFont; text: ansistring; textAlignment: TTextAlignment; bounds: TRect): TVec2; overload;
procedure DrawText(font: IFont; text: ansistring; where: TVec2; color: TColor; scale: single = 1.0; textAlignment: TTextAlignment = TTextAlignment.Left); overload;
procedure DrawText(font: IFont; text: ansistring; where: TVec2; scale: single = 1.0); overload;

{ Clip Rects }
procedure PushClipRect(rect: TRect); 
procedure PopClipRect; 

{ Shaders }
function CreateShader(vertexSource, fragmentSource: pchar): TShader;

{ Buffers }
procedure FlushDrawing; inline;
procedure SwapBuffers; inline;
procedure ClearBackground;

{ Fonts }
procedure SetActiveFont(newValue: IFont);
function GetActiveFont: IFont;

{ Transforms }
procedure SetProjectionTransform(constref mat: TMat4);
procedure SetProjectionTransform(x, y, width, height: integer);

procedure SetViewTransform(x, y, scale: single);
procedure PushViewTransform(constref mat: TMat4);
procedure PushViewTransform(x, y, scale: single);  
procedure PopViewTransform; 

procedure PushModelTransform(constref mat: TMat4); 
procedure PopModelTransform; 

{ Viewport }
procedure SetViewPort(rect: TRect); overload;
procedure SetViewPort(offsetX, offsetY, inWidth, inHeight: integer); overload;
procedure SetViewPort(inWidth, inHeight: integer); overload;
function GetViewPort: TRect; inline;
function GetWindowSize: TVec2i;

{ Canvas State }
procedure SetClearColor(color: TColor);

function GetFPS: longint; inline;
function GetDeltaTime: double; inline;
function GetDefaultShaderAttributes: TVertexAttributes;
function IsVertexBufferEmpty: boolean; inline;

{ Utilities }
function FRand: single;
function FRand(min, max: single): single;
function FRand(min, max: single; decimal: integer): single;
function Rand(min, max: longint): longint;
function Rand(max: longint): longint;
function RandBool(probability: single = 0.5): boolean;
function TimeSinceNow: longint;

type
  TCanvasState = class
    public
      window: PGLPTWindow;          // reference to the GLPT window
      activeFont: IFont;            // default font for DrawText(...) if no font is specified
      clearColor: TColor;           // color used for ClearBackground 
      bindTextureCount: longint;    // count of bind texture calls for each SwapBuffers call
      drawCalls: longint;           // count of FlushDrawing calls for each SwapBuffers call
      deltaTime: double;            // elapsed time since last SwapBuffers
      lastFrameTime: double;        // absolute time of last SwapBuffers
      projTransform: TMat4;         // orthographic transform set with SetProjectionTransform
      viewTransform: TMat4;         // view transform set with SetViewTransform
      viewPortRatio: TVec2;         // if the viewport/transform is not 1:1 this is the ratio
      viewPort: TRect;              // rect set by SetViewPort
      fullScreen: boolean;          // the window was created in fullscreen mode
      totalFrameCount: longint;     // frame count for each SwapBuffers call 
    private
      viewTransformStack: TMat4List;
      modelTransformStack: TMat4List;
      clipRectStack: TRectList;
      sampleTime: double;
      frameCount: longint;
      fps: longint;
    public
      procedure FlushDrawing; virtual;
      procedure SwapBuffers; virtual;
      procedure ClearBackground; virtual;
  end;

var
  CanvasState: TCanvasState = nil;

implementation
uses
  GLUtils,
  Variants, CTypes,
  SysUtils, DOM, XMLRead, Strings;

const
  DEFAULT_SHADER_TEXTURE_UNITS = 8;

var
  DefaultTextureColor: TColor;
  DefaultTextureUnits: array[0..DEFAULT_SHADER_TEXTURE_UNITS - 1] of GLint = (0, 1, 2, 3, 4, 5, 6, 7);

{$define IMPLEMENTATION}
{$include include/ExtraTypes.inc}
{$include include/Textures.inc}
{$include include/Text.inc}
{$include include/BitmapFont.inc}
{$include include/FileUtils.inc}
{$include include/Input.inc}
{$undef IMPLEMENTATION}

const
  TWOPI = 3.14159 * 2;
  
{ Utils }
function TimeSinceNow: longint;
begin
  result := round(GLPT_GetTime * 1000);
end;    

{ Returns a number larger or equal to 'min' and less than or equal to 'max'. }

function FRand(min, max: single): single;
begin
  result := FRand(min, max, 100);
end;

function FRand(min, max: single; decimal: integer): single;
begin
  result := Rand(trunc(min * decimal), trunc(max * decimal)) / decimal;
end;

{ Returns a real number between 0 and 1 is returned (0 included, 1 excluded). }
function FRand: single;
begin
  result := System.Random;
end;

{ Returns a random number larger or equal to 0 and strictly less than 'max'.  }
function Rand(max: longint): longint;
begin
  result := System.Random(max);
end;

{ Returns a number larger or equal to 'min' and less than or equal to 'max'. }
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

function RandBool(probability: single = 0.5): boolean;
begin
  result := System.Random >= probability;
end;

{ Types }
type
  TDefaultVertex = record
    pos: TVec2;
    texCoord: TVec2;
    color: TVec4;
    uv: byte;
    constructor Create(inPos: TVec2; inTexCoord: TVec2; inColor: TVec4; inUV: byte);
    class operator = (constref a, b: TDefaultVertex): boolean;
  end;

constructor TDefaultVertex.Create(inPos: TVec2; inTexCoord: TVec2; inColor: TVec4; inUV: byte);
begin
  pos := inPos;
  texCoord := inTexCoord;
  color := inColor;
  uv := inUV;
end;

class operator TDefaultVertex.= (constref a, b: TDefaultVertex): boolean;
begin
  result := (@a = @b);
end;

{ Quads }
type
  generic TTexturedQuad<T> = record
    v: array[0..5] of T;
    procedure SetPosition(minX, minY, maxX, maxY: single); inline;
    procedure SetPosition(constref rect: TRect);
    procedure SetColor(r, g, b, a: single); inline;
    procedure SetTexture(rect: TRect); inline;
    procedure SetUV(id: byte); inline;
    procedure Transform(constref mat: TMat4); inline;
  end;

procedure TTexturedQuad.Transform(constref mat: TMat4); 
begin
  v[0].pos := mat * v[0].pos;
  v[1].pos := mat * v[1].pos;
  v[2].pos := mat * v[2].pos;
  v[3].pos := mat * v[3].pos;
  v[4].pos := mat * v[4].pos;
  v[5].pos := mat * v[5].pos;
end;

procedure TTexturedQuad.SetPosition(constref rect: TRect);
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

procedure TTexturedQuad.SetPosition(minX, minY, maxX, maxY: single);
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

procedure TTexturedQuad.SetColor(r, g, b, a: single);
begin
  v[0].color := RGBA(r, g, b, a);
  v[1].color := RGBA(r, g, b, a);
  v[2].color := RGBA(r, g, b, a);
  v[3].color := RGBA(r, g, b, a);
  v[4].color := RGBA(r, g, b, a);
  v[5].color := RGBA(r, g, b, a);
end;

procedure TTexturedQuad.SetTexture(rect: TRect);
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

procedure TTexturedQuad.SetUV(id: byte);
begin
  v[0].uv := id;
  v[1].uv := id;
  v[2].uv := id;
  v[3].uv := id;
  v[4].uv := id;
  v[5].uv := id;
end;

type
  TDefaultVertexQuad = specialize TTexturedQuad<TDefaultVertex>;
  TDefaultVertexList = specialize TFPGList<TDefaultVertex>;
  TDefaultVertexBuffer = specialize TVertexBuffer<TDefaultVertex>;

{$include include/Shaders.inc}

{ Globals }
type
  TGLDrawState = record
    bufferPrimitiveType: GLint;
    lineWidth: single;
  end;

var
  context: GLPT_Context;
  defaultShader: TShader = nil;
  vertexBuffer: TDefaultVertexBuffer = nil;
  drawState: TGLDrawState;

function IsRunning: boolean;
begin
  result := not GLPT_WindowShouldClose(CanvasState.window);
end;

procedure error_callback(error: integer; description: string);
begin
  writeln(stderr, description);
  raise Exception.Create(description);
  //halt(-1);
end;

procedure SetActiveFont(newValue: IFont);
begin
  CanvasState.activeFont := newValue;
end;

function GetActiveFont: IFont;
begin
  result := CanvasState.activeFont;
end;

procedure SetProjectionTransform(constref mat: TMat4);
begin
  CanvasState.projTransform := mat;
  Assert(ShaderStack.Last = defaultShader, 'active shader must be default.');
  glUniformMatrix4fv(defaultShader.GetUniformLocation('projTransform'), 1, GL_FALSE, CanvasState.projTransform.Ptr);
end;

procedure SetProjectionTransform(x, y, width, height: integer);
begin
  SetProjectionTransform(TMat4.Ortho(x, width, height, y, -MaxInt, MaxInt));
end;

procedure SetViewTransform(constref mat: TMat4);
begin
  CanvasState.viewTransform := mat;
  Assert(ShaderStack.Last = defaultShader, 'active shader must be default.');
  glUniformMatrix4fv(defaultShader.GetUniformLocation('viewTransform'), 1, GL_FALSE, CanvasState.viewTransform.Ptr);
end;

procedure SetViewTransform(x, y, scale: single);
begin
  SetViewTransform( TMat4.Translate(x, y, 1) *
                    TMat4.Scale(scale, scale, 1)
                    );
end;

procedure PushViewTransform(x, y, scale: single); 
begin
  PushViewTransform( TMat4.Translate(x, y, 1) *
                     TMat4.Scale(scale, scale, 1)
                     );
end;

procedure PushViewTransform(constref mat: TMat4); 
begin
  with CanvasState do
    begin
      SetViewTransform(mat);
      viewTransformStack.Add(mat);
    end;
end;

procedure PopViewTransform; 
var
  mat: TMat4;
begin
  with CanvasState do
    begin
      viewTransformStack.Delete(viewTransformStack.Count - 1);
      if viewTransformStack.Count > 0 then
        begin
          mat := viewTransformStack.Last;
          SetViewTransform(mat);
        end;
    end;
end;

procedure PushModelTransform(constref mat: TMat4); 
begin
  with CanvasState do
    begin
      modelTransformStack.Add(mat);
    end;
end;

procedure PopModelTransform; 
begin
  with CanvasState do
    begin
      modelTransformStack.Delete(modelTransformStack.Count - 1);
    end;
end;

procedure SetViewPort(rect: TRect);
begin
  SetViewPort(trunc(rect.minX), trunc(rect.minY), trunc(rect.width), trunc(rect.height));
end;

procedure SetViewPort(offsetX, offsetY, inWidth, inHeight: integer);
begin
  with CanvasState do
    begin
      viewPort := RectMake(offsetX, offsetY, inWidth, inHeight);
      glViewPort(offsetX, offsetY, inWidth, inHeight);
    end;
end;

procedure SetViewPort(inWidth, inHeight: integer);
begin
  SetViewPort(0, 0, inWidth, inHeight);
end;

function GetViewPort: TRect;
//var
//  viewPort: array[0..3] of GLint;
begin
  //glGetIntegerv(GL_VIEWPORT, @viewPort);
  //result := RectMake(viewPort[0], viewPort[1], viewPort[2], viewPort[3]);
  result := CanvasState.viewPort;
end;

function GetWindowSize: TVec2i;
begin
  GLPT_GetFrameBufferSize(CanvasState.window, result.x, result.y);
end;

function GetDefaultShaderAttributes: TVertexAttributes;
begin
  result := vertexBuffer.attributes;
end;

function IsVertexBufferEmpty: boolean;
begin
  result := vertexBuffer.Count = 0;
end;

procedure SetClearColor(color: TColor); 
begin
  CanvasState.clearColor := color;
  glClearColor(color.r, color.b, color.g, color.a);
end;

function GetFPS: longint;
begin
  result := CanvasState.fps;
end;

function GetDeltaTime: double;
begin
  result := CanvasState.deltaTime;
end;

procedure QuitApp;
begin
  GLPT_DestroyWindow(CanvasState.window);
  GLPT_Terminate;
end;

procedure ChangePrimitiveType(typ: GLint); 
begin
  if (vertexBuffer.Count > 0) and (drawState.bufferPrimitiveType <> typ) then
    FlushDrawing;
  drawState.bufferPrimitiveType := typ;
end;

procedure FillOval(constref rect: TRect; constref color: TColor; segments: single = 32); 
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
      vertexBuffer.Add(TDefaultVertex.Create(V2(w * Cos(t) + x, h * Sin(t) + y), V2(0, 0), color, 255));
      t += TWOPI/segments;
    end;

  // TODO: we don't need to flush each time
  // https://stackoverflow.com/questions/31723405/line-graph-with-gldrawarrays-and-gl-line-strip-from-vector
  FlushDrawing;
end;  

procedure StrokeOval(constref rect: TRect; constref color: TColor; segments: single = 32; lineWidth: single = 1.0); 
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
      vertexBuffer.Add(TDefaultVertex.Create(V2(w * Cos(t) + x, h * Sin(t) + y), texCoord, color, 255));
      t += s;
    end;

  // TODO: we don't need to flush each time
  // https://stackoverflow.com/questions/31723405/line-graph-with-gldrawarrays-and-gl-line-strip-from-vector
  FlushDrawing;
end;

procedure FillPolygon(points: array of TVec2; constref color: TColor);
  
  type
    TSquarePolygonPoints = array[0..3] of TVec2;

  procedure FillSquare(points: TSquarePolygonPoints; constref color: TColor);
  var
    quad: TDefaultVertexQuad;
  begin
    ChangePrimitiveType(GL_TRIANGLES);

    quad.v[0].pos := points[0];
    quad.v[1].pos := points[1];
    quad.v[2].pos := points[3];
    quad.v[3].pos := points[3];
    quad.v[4].pos := points[2];
    quad.v[5].pos := points[1];

    quad.SetColor(color.r, color.g, color.b, color.a);
    quad.SetUV(255);

    if CanvasState.modelTransformStack.Count > 0 then
      quad.Transform(CanvasState.modelTransformStack.Last);

    vertexBuffer.Add(quad.v);
  end;

var
  i: integer;
begin
  Assert(length(points) > 2, 'FillPolygon request at least 3 points');

  if length(points) = 4 then
    begin
      FillSquare(points, color);
      exit;
    end;
  ChangePrimitiveType(GL_TRIANGLE_FAN);

  for i := 0 to high(points) do
    vertexBuffer.Add(TDefaultVertex.Create(points[i], 0, color, 255));

  // TODO: we don't need to flush each time
  // https://stackoverflow.com/questions/31723405/line-graph-with-gldrawarrays-and-gl-line-strip-from-vector
  FlushDrawing;
end;

procedure StrokePolygon(points: array of TVec2; constref color: TColor; connectPoints: boolean = true);
var
  i: integer;
begin
  if connectPoints then
    ChangePrimitiveType(GL_LINE_LOOP)
  else  
    ChangePrimitiveType(GL_LINES);
  for i := 0 to high(points) do
    vertexBuffer.Add(TDefaultVertex.Create(points[i], V2(0, 0), color, 255));
  // TODO: we don't need to flush each time
  FlushDrawing;
end;

procedure DrawPoint(constref point: TVec2; constref color: TColor);
begin
  ChangePrimitiveType(GL_POINTS);
  vertexBuffer.Add(TDefaultVertex.Create(point, V2(0, 0), color, 255));
  // TODO: we don't need to flush each time
  FlushDrawing;
end;

procedure DrawLine(p1, p2: TVec2; constref color: TColor; thickness: single = 1);
var
  points: array[0..1] of TVec2;
begin
  points[0] := p1;
  points[1] := p2;
  DrawLine(points, 2, color, thickness);
end;

procedure DrawLine(points: array of TVec2; count: integer; constref color: TColor; thickness: single = 1);
var
  v: array[0..3] of TDefaultVertex;
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
          //    vertexBuffer.Add(TDefaultVertex.Create(points[i - 1], V2(0, 0), V4(0, 0, 0, 1), 255));
          //    vertexBuffer.Add(TDefaultVertex.Create(points[i], V2(0, 0), V4(0, 0, 0, 1), 255));
          //  end;
          vertexBuffer.Add(TDefaultVertex.Create(points[i], V2(0, 0), color, 255));
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
              v[0] := TDefaultVertex.Create(points[i] + n.Rotate(a + PI * 0.25) * r, V2(0, 0), color, 255);
              v[1] := TDefaultVertex.Create(points[i] + n.Rotate(a + PI * 1.25) * r, V2(0, 0), color, 255);
            end;
          
          v[2] := TDefaultVertex.Create(points[i + 1] + n.Rotate(a + PI * 0.25) * r, V2(0, 0), color, 255);
          v[3] := TDefaultVertex.Create(points[i + 1] + n.Rotate(a + PI * 1.25) * r, V2(0, 0), color, 255);

          vertexBuffer.Add(v[0]);
          vertexBuffer.Add(v[1]);
          vertexBuffer.Add(v[3]);

          vertexBuffer.Add(v[3]);
          vertexBuffer.Add(v[2]);
          vertexBuffer.Add(v[0]);

          i += 2;
        end;
    end;
end;

procedure FillRect(constref rect: TRect; constref color: TColor);
var
  quad: TDefaultVertexQuad;
begin
  ChangePrimitiveType(GL_TRIANGLES);

  quad.SetPosition(rect);
  quad.SetColor(color.r, color.g, color.b, color.a);
  quad.SetUV(255);

  if CanvasState.modelTransformStack.Count > 0 then
    quad.Transform(CanvasState.modelTransformStack.Last);

  vertexBuffer.Add(quad.v);
end;

procedure StrokeRect(constref rect: TRect; constref color: TColor; lineWidth: single = 1.0);
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
  vertexBuffer.Add(TDefaultVertex.Create(V2(rect.MinX, rect.MinY), texCoord, color, 255));
  vertexBuffer.Add(TDefaultVertex.Create(V2(rect.MaxX, rect.MinY), texCoord, color, 255));
  vertexBuffer.Add(TDefaultVertex.Create(V2(rect.MaxX, rect.MaxY), texCoord, color, 255));
  vertexBuffer.Add(TDefaultVertex.Create(V2(rect.MinX, rect.MaxY), texCoord, color, 255));

  // TODO: we don't need to flush each time
  // https://stackoverflow.com/questions/31723405/line-graph-with-gldrawarrays-and-gl-line-strip-from-vector
  FlushDrawing;
end;

function CreateTexture(path: ansistring): TTexture;
begin
  result := TTexture.Create(path);
end;

function CreateTextureSheet(path: ansistring; cellSize: TVec2i): TTextureSheet;
begin
  result := TTextureSheet.Create(path, cellSize);
end;

function CreateTextureSheet(path: ansistring; cellSize, tableSize: TVec2i): TTextureSheet;
begin
  result := TTextureSheet.Create(path, cellSize, tableSize);
end;

function CreateTexturePack(path: ansistring): TTexturePack;
begin
  result := TTexturePack.Create(path);
end;

procedure DrawTexture(texture: ITexture; constref rect: TRect; constref textureFrame: TRect; constref color: TVec4);
var
  quad: TDefaultVertexQuad;
  textureUnit: integer;
begin
  Assert(texture <> nil, 'texture must not be nil');
  textureUnit := PushTexture(texture);
  ChangePrimitiveType(GL_TRIANGLES);

  quad.SetColor(color.r, color.g, color.b, color.a);
  // TODO: take a transform param
  quad.SetPosition(rect);
  quad.SetTexture(textureFrame);
  quad.SetUV(textureUnit);

  if CanvasState.modelTransformStack.Count > 0 then
    quad.Transform(CanvasState.modelTransformStack.Last);

  vertexBuffer.Add(quad.v);
end;

procedure DrawTexture(texture: ITexture; constref rect: TRect; constref color: TVec4);
begin
  DrawTexture(texture, rect, texture.GetFrame.Texture, color);
end;

procedure DrawTexture(texture: ITexture; constref rect: TRect; constref textureFrame: TRect);
begin
  DrawTexture(texture, rect, textureFrame, DefaultTextureColor);
end;

procedure DrawTexture(texture: ITexture; constref rect: TRect);
begin
  DrawTexture(texture, rect, texture.GetFrame.Texture);
end;

procedure DrawTexture(texture: ITexture; x, y: single);
begin
  DrawTexture(texture, RectMake(x, y, texture.GetFrame.Size));
end;

procedure DrawTexture(texture: ITexture; point: TVec2);
begin
  DrawTexture(texture, RectMake(point, texture.GetFrame.Size));
end;

procedure DrawTexture(texture: ITexture; point: TVec2; constref color: TVec4);
begin
  DrawTexture(texture, RectMake(point, texture.GetFrame.Size), color);
end;

procedure PushClipRect(rect: TRect); 
begin
  with CanvasState do
    begin
      if clipRectStack.Count = 0 then
        glEnable(GL_SCISSOR_TEST);
      //rect := RectFlip(rect, GetViewPort);
      // TODO: if the new rect is outside of the previous than don't clip
      if clipRectStack.Count > 0 then
        begin
          if clipRectStack.Last.Contains(rect) then
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
  with CanvasState do
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


procedure TCanvasState.FlushDrawing;
begin
  if not assigned(vertexBuffer) or (vertexBuffer.Count = 0) then
    exit;
  //Assert(ShaderStack.Last = defaultShader, 'active shader must be default.');
  drawCalls += 1;
  vertexBuffer.Draw(drawState.bufferPrimitiveType);
  vertexBuffer.Clear;
end;

procedure TCanvasState.SwapBuffers;
var
  now: double;
begin
  self.FlushDrawing;
  GLPT_SwapBuffers(window);
  GLPT_PollEvents;

  now := GLPT_GetTime;
  deltaTime := now - lastFrameTime;
  lastFrameTime := now;
  drawCalls := 0;
  bindTextureCount := 0;

  inc(totalFrameCount);
  inc(frameCount);

  if now - sampleTime > 1.0 then
    begin
      fps := frameCount;
      sampleTime := now;
      frameCount := 0;
    end;
end;

procedure TCanvasState.ClearBackground;
begin
  glClear(GL_COLOR_BUFFER_BIT);
end;

procedure ClearBackground;
begin
  CanvasState.ClearBackground;
end;

procedure FlushDrawing;
begin
  CanvasState.FlushDrawing;
end;

procedure SwapBuffers;
begin
  CanvasState.SwapBuffers;
end;

function CreateShader(vertexSource, fragmentSource: pchar): TShader;
begin
  result := TShader.Create(vertexSource, fragmentSource);
  result.Push;
  result.SetUniformMat4('projTransform', CanvasState.projTransform);
  result.SetUniformMat4('viewTransform', CanvasState.viewTransform);
  result.SetUniformInts('textures', DefaultTextureUnits);

  // don't pop the default shader
  if defaultShader <> nil then
    result.Pop;
end;

function CanvasMousePosition(event: pGLPT_MessageRec): TVec2i;
begin
  result := V2i(event^.params.mouse.x, event^.params.mouse.y);
  result -= CanvasState.viewport.origin;
  result /= CanvasState.viewPortRatio;
end;

procedure SetupCanvas(width, height: integer; eventCallback: GLPT_EventCallback = nil; options: TCanvasOptions = DefaultCanvasOptions); 
var
  flags: longint;
  displayCoords: GLPTRect;
begin
  GLPT_SetErrorCallback(@error_callback);

  if not GLPT_Init then
    halt(-1);

  // allocate the default canvas
  if CanvasState = nil then
    CanvasState := TCanvasState.Create;

  with CanvasState do
    begin      
      clipRectStack := TRectList.Create;
      viewTransformStack := TMat4List.Create;
      modelTransformStack := TMat4List.Create;

      context := GLPT_GetDefaultContext;
      {$ifdef API_OPENGL}
      context.majorVersion := 3;
      context.minorVersion := 2;
      context.profile := GLPT_CONTEXT_PROFILE_CORE;
      {$endif}
      {$ifdef API_OPENGLES}
      context.glesVersion := 3;
      {$endif}

      context.vsync := TCanvasOption.VSync in options;

      flags := GLPT_WINDOW_TITLED + GLPT_WINDOW_CLOSABLE + GLPT_WINDOW_RESIZABLE;

      if TCanvasOption.FullScreen in options then
        begin
          fullScreen := true;
          flags += GLPT_WINDOW_FULLSCREEN;
          GLPT_GetDisplayCoords(displayCoords);
          width := displayCoords.right - displayCoords.left;
          height := displayCoords.bottom - displayCoords.top;
        end;

      window := GLPT_CreateWindow(GLPT_WINDOW_POS_CENTER, GLPT_WINDOW_POS_CENTER, width, height, '', context, flags);
      if window = nil then
        begin
          GLPT_Terminate;
          halt(-1);
        end;

      window^.event_callback := eventCallback;

      {$ifdef API_OPENGL}
      if not Load_GL_VERSION_3_2 then
        Halt(-1);
      {$endif}

      writeln('OpenGL version: ', glGetString(GL_VERSION));
      writeln('GLPT version: ', GLPT_GetVersionString);
      writeln('Maximum Texture Units: ', GetMaximumTextureUnits);
      writeln('Maximum Texture Size: ', GetMaximumTextureSize);
      writeln('Maximum Verticies: ', GetMaximumVerticies);

      // the default shader imposes a texture limit we must follow
      SetMaximumTextureUnits(DEFAULT_SHADER_TEXTURE_UNITS);

      // note: clear an opengl error
      glGetError();

      // set the view port to the actual size of the window
      GLPT_GetFrameBufferSize(window, width, height);
      SetViewPort(0, 0, width, height);

      glClearColor(1, 1, 1, 1);
      glEnable(GL_BLEND);
      glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
      glDisable(GL_DEPTH_TEST);

      with CanvasState do
        begin
          viewPortRatio := V2(1, 1);
          projTransform := TMat4.Ortho(0, width, height, 0, -MaxInt, MaxInt);
          viewTransform := TMat4.Identity;

          vertexBuffer := TDefaultVertexBuffer.Create([TVertexAttribute.Create('position', GL_FLOAT, 2),
                                                       TVertexAttribute.Create('inTexCoord', GL_FLOAT, 2),
                                                       TVertexAttribute.Create('inColor', GL_FLOAT, 4),
                                                       TVertexAttribute.Create('inUV', GL_UNSIGNED_BYTE, 1)
                                                       ]);
          
          defaultShader := CreateShader(DefaultVertexShader, DefaultFragmentShader);
        end;
    end;
end;


begin
  DefaultTextureColor := RGBA(1, 1, 1, 1);
  FillChar(TextureSlots, sizeof(TextureSlots), 0);
  System.Randomize;
  ChDir(GLPT_GetBasePath);
  InputManager := TInputManager.Create;
end.