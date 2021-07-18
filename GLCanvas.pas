
{$mode objfpc}
{$modeswitch advancedrecords}
{$modeswitch typehelpers}
{$modeswitch autoderef}
{$modeswitch multihelpers}
{$modeswitch nestedprocvars}
{$modeswitch arrayoperators}

{$interfaces corba}
{$implicitexceptions off}
// bug fix: https://bugs.freepascal.org/view.php?id=35821
{$varpropsetter on}

{$include include/targetos.inc}

{$if not defined(PLATFORM_SDL) and not defined(PLATFORM_GLPT) }
  {$define PLATFORM_GLPT}
{$endif}

{$ifdef PLATFORM_SDL}
{$linklib libSDL2.dylib}
{$endif}

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
  GLVertexBuffer, GLFrameBuffer, GLShader,
  {$ifdef PLATFORM_GLPT}
  GLPT, GLPT_Threads
  {$endif}
  {$ifdef PLATFORM_SDL}
  SDL
  {$endif}
  ;

{$scopedenums on}

{$define INTERFACE}
{$include include/ExtraTypes.inc}
{$include include/WebColors.inc}
{$include include/Images.inc}
{$include include/Textures.inc}
{$include include/Text.inc}
{$include include/BitmapFont.inc}
{$include include/Utils.inc}
{$include include/Input.inc}
{$include include/Shaders.inc}
{$undef INTERFACE}

type
  TCanvasOption = (VSync,
                   FullScreen,
                   WaitForEvents
    );
  TCanvasOptions = set of TCanvasOption;

const
  DefaultCanvasOptions = [TCanvasOption.VSync];

{ Window }
{$ifdef PLATFORM_SDL}
type
  SDL_EventCallback = procedure(event: PSDL_Event);

procedure SetupCanvas(width, height: integer; eventCallback: SDL_EventCallback = nil; options: TCanvasOptions = DefaultCanvasOptions); 
{$endif}
{$ifdef PLATFORM_GLPT}
procedure SetupCanvas(width, height: integer; eventCallback: GLPT_EventCallback = nil; options: TCanvasOptions = DefaultCanvasOptions); 
{$endif}
function IsRunning: boolean;
procedure QuitApp;

{ Input }
function CanvasMousePosition(mouse: TVec2i): TVec2i;

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
procedure DrawTexture(texture: ITexture; quad: TDefaultVertexQuad); inline;

procedure DrawQuad(constref quad: TDefaultVertexQuad); inline;
procedure DrawTiledTexture(texture: TTexture; rect: TRect);

{ Text }
function MeasureText(font: IFont; text: TFontString; maximumWidth: integer = MaxInt): TVec2;
function WrapText(font: IFont; text: TFontString; maximumWidth: integer): TStringList;

function DrawText(text: TFontString; textAlignment: TTextAlignment; bounds: TRect; color: TColor): TVec2; overload; inline;
function DrawText(text: TFontString; textAlignment: TTextAlignment; bounds: TRect): TVec2; overload; inline;
procedure DrawText(text: TFontString; where: TVec2; color: TColor; scale: single = 1.0); overload; inline;
procedure DrawText(text: TFontString; where: TVec2; scale: single = 1.0); overload; inline;

function DrawText(font: IFont; text: TFontString; textAlignment: TTextAlignment; bounds: TRect; color: TColor): TVec2; overload;
function DrawText(font: IFont; text: TFontString; textAlignment: TTextAlignment; bounds: TRect): TVec2; overload;
procedure DrawText(font: IFont; text: TFontString; where: TVec2; color: TColor; scale: single = 1.0; textAlignment: TTextAlignment = TTextAlignment.Left); overload; inline;
procedure DrawText(font: IFont; text: TFontString; where: TVec2; scale: single = 1.0); overload;

procedure LayoutText(var options: TTextLayoutOptions);

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
procedure ResizeCanvas(width, height: integer); overload;
procedure ResizeCanvas(nativeSize: TVec2; respectNative: boolean; destRect: TRect); overload;
procedure SetViewPort(rect: TRect); overload;
procedure SetViewPort(offsetX, offsetY, inWidth, inHeight: integer); overload;
procedure SetViewPort(inWidth, inHeight: integer); overload;
function GetViewPort: TRect; inline;

{ Window }
function GetWindowSize: TVec2i;
procedure SetWindowTitle(title: string);

{ Display }
function GetDisplaySize: TVec2i;

{ Canvas State }
procedure SetClearColor(color: TColor);

function GetFPS: longint; inline;
function GetDeltaTime: double; inline;
function GetDefaultShaderAttributes: TVertexAttributes;
function IsVertexBufferEmpty: boolean; inline;
function GetResourcecDirectory: ansistring;

type
  TCanvasState = class
    private
      viewTransformStack: TMat4List;
      modelTransformStack: TMat4List;
      clipRectStack: TRectList;
      sampleTime: double;
      frameCount: longint;
      fps: longint;
    public
      {$ifdef PLATFORM_SDL}
      window: PSDL_Window;
      context: PSDL_GLContext;
      eventCallback: SDL_EventCallback;
      wantsClose: boolean;
      {$endif}

      {$ifdef PlATFORM_GLPT}
      window: PGLPTWindow;          // reference to the GLPT window
      context: GLPT_Context;
      {$endif}

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
    public
      procedure FlushDrawing; virtual;
      procedure SwapBuffers; virtual;
      procedure ClearBackground; virtual;
      procedure FinalizeSetup;
  end;

var
  CanvasState: TCanvasState = nil;

implementation
uses
  GLUtils,
  Variants, CTypes,
  SysUtils, DOM, XMLRead, Strings;

{ IMPORTANT: if you change the texture unit count then
  you need to update the default shaders in Shaders.inc also }
  
const
  DEFAULT_SHADER_TEXTURE_UNITS = 8;

var
  DefaultTextureColor: TColor;
  DefaultTextureUnits: array[0..DEFAULT_SHADER_TEXTURE_UNITS - 1] of GLint = (0, 1, 2, 3, 4, 5, 6, 7);

{$define IMPLEMENTATION}
{$include include/ExtraTypes.inc}
{$include include/WebColors.inc}
{$include include/Images.inc}
{$include include/Textures.inc}
{$include include/Text.inc}
{$include include/BitmapFont.inc}
{$include include/Utils.inc}
{$include include/Input.inc}
{$include include/Shaders.inc}
{$undef IMPLEMENTATION}

const
  TWOPI = 3.14159 * 2;


{ Globals }
type
  TGLDrawState = record
    bufferPrimitiveType: GLint;
    lineWidth: single;
  end;

var
  defaultShader: TShader = nil;
  vertexBuffer: TDefaultVertexBuffer = nil;
  drawState: TGLDrawState;

function IsRunning: boolean;
begin
  {$ifdef PLATFORM_SDL}
  result := not CanvasState.wantsClose;
  {$endif}

  {$ifdef PlATFORM_GLPT}
  result := not GLPT_WindowShouldClose(CanvasState.window);
  {$endif}
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
  defaultShader.SetUniformMat4('projTransform', CanvasState.projTransform);
end;

procedure SetProjectionTransform(x, y, width, height: integer);
begin
  SetProjectionTransform(TMat4.Ortho(x, width, height, y, -MaxInt, MaxInt));
end;

procedure SetViewTransform(constref mat: TMat4);
begin
  CanvasState.viewTransform := mat;
  Assert(ShaderStack.Last = defaultShader, 'active shader must be default.');
  defaultShader.SetUniformMat4('viewTransform', CanvasState.viewTransform);
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

{ Call ResizeCanvas in response to GLPT_MESSAGE_RESIZE to change the canvas size }

procedure ResizeCanvas(width, height: integer);
begin
  CanvasState.viewPortRatio := V2(1, 1);
  CanvasState.projTransform := TMat4.Ortho(0, width, height, 0, -MaxInt, MaxInt);
  CanvasState.viewTransform := TMat4.Identity;

  defaultShader.SetUniformMat4('projTransform', CanvasState.projTransform);
  defaultShader.SetUniformMat4('viewTransform', CanvasState.viewTransform);
  defaultShader.SetUniformInts('textures', DefaultTextureUnits);

  SetViewPort(width, height);
end;

procedure ResizeCanvas(nativeSize: TVec2; respectNative: boolean; destRect: TRect);
var
  width, height: integer;
begin
  width := trunc(destRect.width);
  height := trunc(destRect.height);

  SetViewPort(destRect);

  if respectNative then
    begin
      CanvasState.viewPortRatio := V2(1, 1);
      CanvasState.projTransform := TMat4.Ortho(0, width, height, 0, -MaxInt, MaxInt);
    end
  else
    begin
      CanvasState.viewPortRatio := destRect.Size / nativeSize;
      CanvasState.projTransform := TMat4.Ortho(0, width, height, 0, -MaxInt, MaxInt) * 
                                   TMat4.Scale(CanvasState.viewPortRatio, 1);
    end;

  CanvasState.viewTransform := TMat4.Identity;

  defaultShader.SetUniformMat4('projTransform', CanvasState.projTransform);
  defaultShader.SetUniformMat4('viewTransform', CanvasState.viewTransform);
  defaultShader.SetUniformInts('textures', DefaultTextureUnits);
end;

procedure SetWindowTitle(title: string);
begin
  {$ifdef PLATFORM_SDL}
  title := title+#0;
  SDL_SetWindowTitle(CanvasState.window, @title[1]);
  {$endif}

  {$ifdef PlATFORM_GLPT}
  CanvasState.window^.ref.setTitle(NSSTR(title));
  {$endif}
end;

function GetWindowSize: TVec2i;
begin
  {$ifdef PLATFORM_SDL}
  SDL_GetWindowSize(CanvasState.window, result.x, result.y);
  {$endif}

  {$ifdef PlATFORM_GLPT}
  GLPT_GetFrameBufferSize(CanvasState.window, result.x, result.y);
  {$endif}
end;


{$ifdef PLATFORM_SDL}
function GetDisplaySize: TVec2i;
var
  rect: TSDL_Rect;
begin
  SDL_GetDisplayBounds(SDL_GetWindowDisplayIndex(CanvasState.window), rect);
  result.width := rect.w;
  result.height := rect.h;
end;
{$endif}

{$ifdef PlATFORM_GLPT}
function GetDisplaySize: TVec2i;
var
  displayCoords: GLPTRect;
begin
  GLPT_GetDisplayCoords(displayCoords);
  result.width := displayCoords.right - displayCoords.left;
  result.height := displayCoords.bottom - displayCoords.top;
end;
{$endif}


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
  {$ifdef PLATFORM_SDL}
  SDL_DestroyWindow(CanvasState.window);
  SDL_Quit;
  {$endif}

  {$ifdef PlATFORM_GLPT}
  GLPT_DestroyWindow(CanvasState.window);
  GLPT_Terminate;
  {$endif}
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

  {$ifdef GL_LINE_WIDTH}
  if drawState.lineWidth <> lineWidth then
    begin
      Assert(vertexBuffer.Count = 0, 'must flush drawing before changing line width');
      glLineWidth(lineWidth);
      drawState.lineWidth := lineWidth;
    end;
  {$endif}
  
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

  ChangePrimitiveType(GL_LINE_LOOP);

  // TODO: line width doesn't work now???
  // https://stackoverflow.com/questions/3484260/opengl-line-width
  {$ifdef GL_LINE_WIDTH}
  if drawState.lineWidth <> lineWidth then
    begin
      Assert(vertexBuffer.Count = 0, 'must flush drawing before changing line width');
      glLineWidth(lineWidth);
      drawState.lineWidth := lineWidth;
    end;
  {$endif}

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

procedure DrawQuad(constref quad: TDefaultVertexQuad);
begin
  ChangePrimitiveType(GL_TRIANGLES);
  vertexBuffer.Add(quad.v);
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

procedure DrawTexture(texture: ITexture; quad: TDefaultVertexQuad);
begin
  Assert(texture <> nil, 'texture must not be nil');
  quad.SetUV(PushTexture(texture));
  ChangePrimitiveType(GL_TRIANGLES);
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

procedure DrawTiledTexture(texture: TTexture; rect: TRect);
var
  tiles: TVec2;
  frac: TVec2;
  origin: TVec2i;
  part: TRect;
  x, y: integer;
begin
  tiles := rect.size / texture.GetSize;

  frac.x := tiles.x - trunc(tiles.x);
  frac.y := tiles.y - trunc(tiles.y);

  origin := trunc(tiles);

  for y := 0 to origin.y do
  for x := 0 to origin.x do
    begin
      if (x = origin.x) and (y = origin.y) then
        begin
          if (frac.x = 0) or (frac.y = 0) then
            break;
          part.origin := V2(rect.x + texture.GetWidth * x, rect.y + texture.GetHeight * y);
          part.size := texture.GetSize * frac;
          DrawTexture(texture, part, texture.SubTextureFrame(0, 0, frac.x, frac.y));
        end
      else if x = origin.x then
        begin
          if frac.x = 0 then
            break;
          part.origin := V2(rect.x + texture.GetWidth * x, rect.y + texture.GetHeight * y);
          part.size := texture.GetSize * V2(frac.x, 1);
          DrawTexture(texture, part, texture.SubTextureFrame(0, 0, frac.x, 1));
        end
      else if y = origin.y then
        begin
          if frac.y = 0 then
            break;
          part.origin := V2(rect.x + texture.GetWidth * x, rect.y + texture.GetHeight * y);
          part.size := texture.GetSize * V2(1, frac.y);
          DrawTexture(texture, part, texture.SubTextureFrame(0, 0, 1, frac.y));
        end
      else
        DrawTexture(texture, V2(rect.x + texture.GetWidth * x, rect.y + texture.GetHeight * y));
    end;
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

function CanvasMousePosition(mouse: TVec2i): TVec2i;
begin
  result := mouse;
  result -= CanvasState.viewport.origin;
  result /= CanvasState.viewPortRatio;
end;

function GetResourcecDirectory: ansistring;
const
  kResourceDirectoryName = 'Resources';
var
  name: string;
begin
  {$ifdef PLATFORM_SDL}
  result := SDL_GetBasePath;
  {$endif}

  {$ifdef PlATFORM_GLPT}
  result := GLPT_GetBasePath;
  {$endif}

  // if the base path is the correct location then force the change
  name := ExtractFileName(ExcludeTrailingPathDelimiter(result));
  if AnsiCompareFileName(name, kResourceDirectoryName) <> 0 then
    result += kResourceDirectoryName;

  if not DirectoryExists(result) then
    begin
      writeln('Resource directory "',result,'" doesn''t exist.');
      halt(-1);
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
  {$ifdef PLATFORM_SDL}
  event: TSDL_Event;
  {$endif}
begin
  self.FlushDrawing;

  {$ifdef PLATFORM_SDL}
  SDL_GL_SwapWindow(window);
  SDL_PollEvent(event);
  case event.type_ of
    SDL_QUIT_EVENT:
      wantsClose := true;
    SDL_WINDOW_EVENT:
      begin
        case event.window.event of
          SDL_WINDOWEVENT_CLOSE:
            wantsClose := true;
          SDL_WINDOWEVENT_RESIZED:
            ;//Reshape(event.window.data1, event.window.data2);
        end;
      end;
  end;
  PollSystemInput(@event);
  if eventCallback <> nil then
    eventCallback(@event);
  {$endif}

  {$ifdef PlATFORM_GLPT}
  GLPT_SwapBuffers(window);
  GLPT_PollEvents;
  // TODO: return message from GLPT_PollEvents and send to PollSystemInput
  {$endif}

  now := GetTime;

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

procedure TCanvasState.FinalizeSetup;
var
  windowSize: TVec2i;
begin
  {$ifdef API_OPENGL}
  if not Load_GL_VERSION_3_2 then
    Halt(-1);
  {$endif}

  writeln('OpenGL version: ', glGetString(GL_VERSION));
  {$ifdef PLATFORM_GLPT}
  writeln('GLPT version: ', GLPT_GetVersionString);
  {$endif}
  {$ifdef PLATFORM_SDL}
  writeln('SDL version: ???');
  {$endif}
  writeln('Maximum Texture Units: ', GetMaximumTextureUnits);
  writeln('Maximum Texture Size: ', GetMaximumTextureSize);
  writeln('Maximum Verticies: ', GetMaximumVerticies);

  // the default shader imposes a texture limit we must follow
  SetMaximumTextureUnits(DEFAULT_SHADER_TEXTURE_UNITS);

  // note: clear an opengl error
  glGetError();

  // set the view port to the actual size of the window
  windowSize := GetWindowSize;
  SetViewPort(0, 0, windowSize.width, windowSize.height);

  glClearColor(1, 1, 1, 1);
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glDisable(GL_DEPTH_TEST);

  clipRectStack := TRectList.Create;
  viewTransformStack := TMat4List.Create;
  modelTransformStack := TMat4List.Create;

  viewPortRatio := V2(1, 1);
  projTransform := TMat4.Ortho(0, windowSize.width, windowSize.height, 0, -MaxInt, MaxInt);
  viewTransform := TMat4.Identity;

  vertexBuffer := TDefaultVertexBuffer.Create([TVertexAttribute.Create('position', GL_FLOAT, 2),
                                               TVertexAttribute.Create('inTexCoord', GL_FLOAT, 2),
                                               TVertexAttribute.Create('inColor', GL_FLOAT, 4),
                                               TVertexAttribute.Create('inUV', GL_UNSIGNED_BYTE, 1)
                                               ]);
  
  defaultShader := CreateShader(DefaultVertexShader, DefaultFragmentShader);
end;

{$ifdef PLATFORM_SDL}
procedure SetupCanvas(width, height: integer; eventCallback: SDL_EventCallback; options: TCanvasOptions); 
begin
  if SDL_Init(SDL_INIT_VIDEO) < 0 then
    begin
      writeln('SDL could not initialize! ',SDL_GetError);
      Halt(-1);
    end;

  SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
  SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);

  // allocate the default canvas
  if CanvasState = nil then
    CanvasState := TCanvasState.Create;
  
  CanvasState.eventCallback := eventCallback;

  with CanvasState do
    begin
      window := SDL_CreateWindow('', SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width, height, SDL_WINDOW_SHOWN + SDL_WINDOW_OPENGL);
      if window = nil then
        begin
          writeln('Window could not be created! ', SDL_GetError);
          Halt(-1);
        end
      else
        begin
          context := SDL_GL_CreateContext(window);
          SDL_GL_MakeCurrent(window, context);
          if TCanvasOption.VSync in options then
            SDL_GL_SetSwapInterval(1)
          else
            SDL_GL_SetSwapInterval(0);
        end;

      FinalizeSetup;
    end;
end;
{$endif}

{$ifdef PlATFORM_GLPT}
procedure SetupCanvas(width, height: integer; eventCallback: GLPT_EventCallback; options: TCanvasOptions); 
var
  flags: longint;
  displayCoords: GLPTRect;
  windowSize: TVec2i;
begin
  GLPT_SetErrorCallback(@error_callback);

  if not GLPT_Init then
    halt(-1);

  if TCanvasOption.WaitForEvents in options then
    begin
      //Exclude(options, TCanvasOption.VSync);
      writeln('GLPT presentation mode enabled');
      GLPT_PresentationMode := true;
    end;

  // allocate the default canvas
  if CanvasState = nil then
    CanvasState := TCanvasState.Create;

  with CanvasState do
    begin
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

      FinalizeSetup;
    end;
end;
{$endif}

begin
  DefaultTextureColor := RGBA(1, 1, 1, 1);
  FillChar(TextureSlots, sizeof(TextureSlots), 0);
  System.Randomize;
  ChDir(GetResourcecDirectory);
  InputManager := TInputManager.Create;
end.