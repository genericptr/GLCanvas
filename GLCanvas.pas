{$mode objfpc}
{$modeswitch advancedrecords}
{$modeswitch typehelpers}
{$modeswitch autoderef}
{$modeswitch multihelpers}
{$modeswitch nestedprocvars}
{$modeswitch arrayoperators}
{$modeswitch implicitfunctionspecialization}

{$interfaces corba}
{$implicitexceptions off}
// bug fix: https://bugs.freepascal.org/view.php?id=35821
{$varpropsetter on}
{$scopedenums on}
{$codepage utf8}

{$include include/targetos.inc}

{$ifdef TARGET_OS_MAC}
  {$modeswitch objectivec1}
{$endif}

{
  GLPT supports the following platform macros:

    1) PLATFORM_SDL
    2) PLATFORM_GLPT
    3) PLATFORM_NONE

  If neither is specified then GLCanvas will default to PLATFORM_GLPT.
}

{$if not defined(PLATFORM_SDL) and not defined(PLATFORM_GLPT) and not defined(PLATFORM_NONE) }
  {$define PLATFORM_GLPT}
{$endif}

{$ifdef PLATFORM_SDL}
  {$ifdef TARGET_OS_MAC}
    {$linkframework SDL2}
  {$endif}
  {$ifdef TARGET_OS_IPHONE}
    {$linklib libfreetype.a}
    {$linkframework SDL2}
    {$pascalmainname SDL_main}
  {$endif}
  {$ifdef TARGET_OS_WINDOWS}
    // linking is dynamic on Windows
  {$endif}
{$endif}

{$ifdef PLATFORM_GLPT}
  {$ifdef TARGET_OS_IPHONE}
    {$linklib libfreetype.a}
    {$pascalmainname GLPT_Main}
  {$endif}
{$endif}

unit GLCanvas;
interface
uses
  { OpenGL }
  {$ifdef API_OPENGL}GL, GLext,{$endif}
  {$ifdef API_OPENGLES}GLES30,{$endif}
  { Platform Specific }
  {$ifdef DARWIN}CWString,{$endif}
  {$ifdef TARGET_OS_MAC}CocoaAll,{$endif}
  { RTL }
  Contnrs, FGL, Classes, Math, FreeTypeH,
  { 3rd Party }
  BeRoPNG
  { Platforms }
  {$ifdef PLATFORM_GLPT},GLPT{$endif}
  {$ifdef PLATFORM_SDL},SDL{$endif}
  ;

{$define INTERFACE}
{$include include/VectorMath.inc}
{$include include/GeometryTypes.inc}
{$include include/ExtraTypes.inc}
{$include include/WebColors.inc}
{$include include/Utils.inc}
{$include include/Images.inc}
{$include include/Textures.inc}
{$include include/FrameBuffers.inc}
{$include include/VertexBuffers.inc}
{$include include/Text.inc}
{$include include/BitmapFont.inc}
{$include include/Shader.inc}
{$include include/DefaultShader.inc}
{$include include/FreeType.inc}
{$include include/Keys.inc}
{$include include/Event.inc}
{$undef INTERFACE}

type
  TCanvasOption = (VSync,
                   FullScreen,
                   Resizable
                  );
  TCanvasOptions = set of TCanvasOption;

const
  DefaultCanvasOptions = [TCanvasOption.VSync];

{ Window }

{$ifdef PLATFORM_NONE}
procedure SetupCanvas(width, height: integer; options: TCanvasOptions = DefaultCanvasOptions); 
{$else}
type
  TEventCallback = procedure(event: TEvent);

procedure SetupCanvas(width, height: integer; eventCallback: TEventCallback = nil; options: TCanvasOptions = DefaultCanvasOptions); 
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
function MeasureText(font: IFont; text: TFontString; maximumWidth: integer = MaxInt): TVec2; overload;
function MeasureText(font: IFont; lines: array of TFontString): TVec2; overload;
function CalculateTextWidth(font: IFont; text: TFontString): integer;
function WrapText(font: IFont; text: TFontString; maximumWidth: integer): TStringList;

function DrawText(text: TFontString; textAlignment: TTextAlignment; bounds: TRect; color: TColor): TVec2; overload; inline;
function DrawText(text: TFontString; textAlignment: TTextAlignment; bounds: TRect): TVec2; overload; inline;
procedure DrawText(text: TFontString; where: TVec2; color: TColor; scale: single = 1.0); overload; inline;
procedure DrawText(text: TFontString; where: TVec2; scale: single = 1.0); overload; inline;

function DrawText(font: IFont; text: TFontString; textAlignment: TTextAlignment; bounds: TRect; color: TColor): TVec2; overload;
function DrawText(font: IFont; text: TFontString; textAlignment: TTextAlignment; bounds: TRect): TVec2; overload;
procedure DrawText(font: IFont; text: TFontString; where: TVec2; color: TColor; scale: single = 1.0; textAlignment: TTextAlignment = TTextAlignment.Left); overload; inline;
procedure DrawText(font: IFont; text: TFontString; where: TVec2; scale: single = 1.0); overload;
procedure DrawText(font: IFont; lines: array of TFontString; bounds: TRect; color: TColor; textAlignment: TTextAlignment = TTextAlignment.Left); overload;

procedure LayoutText(var options: TTextLayoutOptions);

{ Fonts }
function CreateFont(name: ansistring; pixelSize: integer): TGLFreeTypeFont;

{ Clip Rects }
procedure PushClipRect(rect: TRect); 
procedure PopClipRect; 

{ Shaders }
function CreateShader(shaderClass: TShaderClass; const vertexSource, fragmentSource: pchar): TShader; overload;
function CreateShader(const vertexSource, fragmentSource: pchar): TShader; overload;

{ Buffers }
function CreateVertexBuffer(static: boolean = false): TDefaultVertexBuffer;
procedure PushVertexBuffer(buffer: TDefaultVertexBuffer);
procedure PopVertexBuffer;
procedure DrawBuffer(buffer: TDefaultVertexBuffer);

{ Drawing }
procedure FlushDrawing; inline;
procedure SwapBuffers; inline;
procedure ClearBackground;

{ Blend Mode }
type
  TBlendingFactor = (
    ZERO,
    ONE,
    SRC_COLOR,
    ONE_MINUS_SRC_COLOR,
    SRC_ALPHA,
    ONE_MINUS_SRC_ALPHA,
    DST_ALPHA,
    ONE_MINUS_DST_ALPHA,
    DST_COLOR,
    ONE_MINUS_DST_COLOR,
    SRC_ALPHA_SATURATE
  );

procedure PushBlendMode(source, destination: TBlendingFactor);
procedure PopBlendMode;

{ Fonts }
procedure SetActiveFont(newValue: IFont);
function GetActiveFont: IFont;

{ Transforms }
procedure SetProjectionTransform(constref mat: TMat4);
procedure SetProjectionTransform(x, y, width, height: integer);
procedure PushProjectionTransform(constref mat: TMat4); 
procedure PushProjectionTransform(width, height: integer); 
procedure PushProjectionTransform(x, y, width, height: integer); 
procedure PopProjectionTransform; 

procedure SetViewTransform(x, y, scale: single);
procedure SetViewTransform(constref mat: TMat4);
procedure PushViewTransform(constref mat: TMat4);
procedure PushViewTransform(x, y, scale: single);
procedure PopViewTransform; 

procedure PushModelTransform(constref mat: TMat4); 
procedure PopModelTransform; 

function GetProjectionTransform: TMat4;
function GetViewTransform: TMat4;
function GetModelTransform: TMat4;

{ Viewport }
procedure ResizeCanvas(width, height: integer); overload;
procedure ResizeCanvas(newSize: TVec2i); overload;
procedure ResizeCanvas(nativeSize: TVec2; respectNative: boolean; destRect: TRect); overload;
procedure SetViewPort(rect: TRect); overload;
procedure SetViewPort(size: TVec2i); overload;
procedure SetViewPort(offsetX, offsetY, inWidth, inHeight: integer); overload;
procedure SetViewPort(inWidth, inHeight: integer); overload;
function GetViewPort: TRect; inline;

{ Window }
function GetWindowSize: TVec2i;
procedure SetWindowTitle(title: string);
procedure SetWindowFullScreen(newValue: boolean);
function IsFullScreen: boolean;

{ Display }
function GetDisplaySize: TVec2i;

{ Canvas State }
procedure SetClearColor(color: TColor);
procedure SetDepthTest(enabled: Boolean);
procedure SetTargetFrameRate(newValue: Integer);

{ Time }
function GetFPS: longint; inline;
function GetDeltaTime: double; inline;
function GetFrameCount: longint; inline;
function GetFrameClock: double; inline;
function GetFrameDelta: double; inline;
procedure AdvanceFrameClock; 

function GetDefaultShaderAttributes: TVertexAttributes;
function IsVertexBufferEmpty: boolean; inline;
function GetResourceDirectory: ansistring;

type
  TCanvasState = class
    private type
      TBlendModeState = class
        private
          source: GLenum;
          destination: GLenum;
        public
          constructor Create(src, dest: TBlendingFactor);
      end;
      TBlendModeList = specialize TFPGObjectList<TBlendModeState>;
    private
      viewTransformStack: TMat4List;
      projectionTransformStack: TMat4List;
      modelTransformStack: TMat4List;
      clipRectStack: TRectList;
      vertexBufferList: TDefaultVertexBufferList;
      blendModeList: TBlendModeList;
      sampleTime: double;
      frameCount: longint;
      fps: longint;
      m_activeFont: IFont;            // default font for DrawText(...) if no font is specified
      function GetActiveFont: IFont;
    public
      {$if defined(PLATFORM_SDL)}
      window: PSDL_Window;
      context: PSDL_GLContext;
      wantsClose: boolean;
      eventCallback: TEventCallback;
      {$elseif defined(PlATFORM_GLPT)}
      window: PGLPTWindow;
      context: GLPT_Context;
      eventCallback: TEventCallback;
      {$else}
      window: pointer;
      {$endif}

      clearColor: TColor;           // color used for ClearBackground 
      bufferPrimitiveType: GLint;
      lineWidth: single;
      bindTextureCount: longint;    // count of bind texture calls for each SwapBuffers call
      drawCalls: longint;           // count of FlushDrawing calls for each SwapBuffers call
      deltaTime: double;            // elapsed time since last SwapBuffers
      lastFrameTime: double;        // absolute time of last SwapBuffers
      targetFrameTime: double;      // frame time adjusted to meet target frame rate
      projTransform: TMat4;         // orthographic transform set with SetProjectionTransform
      viewTransform: TMat4;         // view transform set with SetViewTransform
      viewPortRatio: TVec2;         // if the viewport/transform is not 1:1 this is the ratio
      viewPort: TRect;              // rect set by SetViewPort
      fullScreen: boolean;          // the window was created in fullscreen mode
      totalFrameCount: longint;     // frame count for each SwapBuffers call 
      targetFrameRate: integer;     // frame rate which which is the basis for time calculations
    public
      property ActiveFont: IFont read GetActiveFont;
    public
      procedure FlushDrawing; virtual;
      procedure SwapBuffers; virtual;
      procedure ClearBackground; virtual;
      procedure FinalizeSetup(windowSize: TVec2i);
  end;

var
  CanvasState: TCanvasState = nil;

implementation
uses
  GLUtils, RectangleBinPack,
  Variants, CTypes, SysUtils, DOM, XMLRead, Strings;

{ IMPORTANT: if you change the texture unit count then
  you need to update the default shaders in Shaders.inc also }
  
const
  DEFAULT_SHADER_TEXTURE_UNITS = 8;

var
  DefaultTextureColor: TColor;
  DefaultTextureUnits: array[0..DEFAULT_SHADER_TEXTURE_UNITS - 1] of GLint = (0, 1, 2, 3, 4, 5, 6, 7);

{$define IMPLEMENTATION}
{$include include/VectorMath.inc}
{$include include/GeometryTypes.inc}
{$include include/ExtraTypes.inc}
{$include include/WebColors.inc}
{$include include/Utils.inc}
{$include include/Images.inc}
{$include include/Textures.inc}
{$include include/FrameBuffers.inc}
{$include include/VertexBuffers.inc}
{$include include/Text.inc}
{$include include/BitmapFont.inc}
{$include include/Shader.inc}
{$include include/DefaultShader.inc}
{$include include/FreeType.inc}
{$include include/Keys.inc}
{$include include/Event.inc}
{$undef IMPLEMENTATION}

const
  TWOPI = 3.14159 * 2;
  Z_NEAR = -10000;
  Z_FAR = 10000;

{ Globals }

var
  DefaultShader: TShader = nil;
  VertexBuffer: TDefaultVertexBuffer = nil;

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
end;

procedure SetActiveFont(newValue: IFont);
begin
  CanvasState.m_activeFont := newValue;
end;

function GetActiveFont: IFont;
begin
  result := CanvasState.activeFont;
end;

type
  TBlendModeState = TCanvasState.TBlendModeState;

function ConvertBlendingFactor(fac: TBlendingFactor): GLenum; inline;
begin
  case fac of
    TBlendingFactor.ZERO: result := GL_ZERO;
    TBlendingFactor.ONE: result := GL_ONE;
    TBlendingFactor.SRC_COLOR: result := GL_SRC_COLOR;
    TBlendingFactor.ONE_MINUS_SRC_COLOR: result := GL_ONE_MINUS_SRC_COLOR;
    TBlendingFactor.SRC_ALPHA: result := GL_SRC_ALPHA;
    TBlendingFactor.ONE_MINUS_SRC_ALPHA: result := GL_ONE_MINUS_SRC_ALPHA;
    TBlendingFactor.DST_ALPHA: result := GL_DST_ALPHA;
    TBlendingFactor.ONE_MINUS_DST_ALPHA: result := GL_ONE_MINUS_DST_ALPHA;
    TBlendingFactor.DST_COLOR: result := GL_DST_COLOR;
    TBlendingFactor.ONE_MINUS_DST_COLOR: result := GL_ONE_MINUS_DST_COLOR;
    TBlendingFactor.SRC_ALPHA_SATURATE: result := GL_SRC_ALPHA_SATURATE;
  end;
end;

constructor TBlendModeState.Create(src, dest: TBlendingFactor);
begin
  source := ConvertBlendingFactor(src);
  destination := ConvertBlendingFactor(dest);
end;

procedure SetBlendMode(mode: TBlendModeState);
begin
  glBlendFunc(mode.source, mode.destination);
end;

procedure PushBlendMode(source, destination: TBlendingFactor);
var
  mode: TBlendModeState;
begin
  with CanvasState do
    begin
      mode := TBlendModeState.Create(source, destination);
      SetBlendMode(mode);
      blendModeList.Add(mode);
    end;
end;

procedure PopBlendMode;
begin
  with CanvasState do
    begin
      blendModeList.Delete(blendModeList.Count - 1);
      if blendModeList.Count > 0 then
        SetBlendMode(blendModeList.Last);
    end;
end;

procedure SetProjectionTransform(constref mat: TMat4);
begin
  CanvasState.projTransform := mat;
  Assert(ShaderStack.Last.GetUniformLocation('projTransform') <> -1, 'active shader must have "projTransform" uniform.');
  ShaderStack.Last.SetUniformMat4('projTransform', CanvasState.projTransform);
end;

procedure SetProjectionTransform(x, y, width, height: integer);
begin
  SetProjectionTransform(TMat4.Ortho(x, width, height, y, Z_NEAR, Z_FAR));
end;

procedure PushProjectionTransform(constref mat: TMat4); 
begin
  with CanvasState do
    begin
      SetProjectionTransform(mat);
      projectionTransformStack.Add(mat);
    end;
end;

procedure PushProjectionTransform(width, height: integer); 
begin
  PushProjectionTransform(0, 0, width, height);
end;

procedure PushProjectionTransform(x, y, width, height: integer); 
begin
  PushProjectionTransform(TMat4.Ortho(x, width, height, y, Z_NEAR, Z_FAR));
end;

procedure PopProjectionTransform; 
var
  mat: TMat4;
begin
  FlushDrawing;
  
  with CanvasState do
    begin
      projectionTransformStack.Delete(projectionTransformStack.Count - 1);
      if projectionTransformStack.Count > 0 then
        begin
          mat := projectionTransformStack.Last;
          SetProjectionTransform(mat);
        end;
    end;
end;

procedure SetViewTransform(constref mat: TMat4);
begin
  CanvasState.viewTransform := mat;
  Assert(ShaderStack.Last.GetUniformLocation('viewTransform') <> -1, 'active shader must have "viewTransform" uniform.');
  ShaderStack.Last.SetUniformMat4('viewTransform', CanvasState.viewTransform);
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
  FlushDrawing;

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

function GetProjectionTransform: TMat4;
begin
  result := CanvasState.projectionTransformStack.Last;
end;

function GetViewTransform: TMat4;
begin
  result := CanvasState.viewTransformStack.Last;
end;

function GetModelTransform: TMat4;
begin
  result := CanvasState.modelTransformStack.Last;
end;


procedure PushVertexBuffer(buffer: TDefaultVertexBuffer); 
begin
  FlushDrawing;
  
  with CanvasState do
    begin
      VertexBuffer := buffer;
      vertexBufferList.Add(buffer);
    end;
end;

procedure PopVertexBuffer;
begin
  FlushDrawing;

  with CanvasState do
    begin
      vertexBufferList.Delete(vertexBufferList.Count - 1);
      if vertexBufferList.Count > 0 then
        VertexBuffer := vertexBufferList.Last;
    end;
end;

procedure DrawBuffer(buffer: TDefaultVertexBuffer); 
begin
  FlushDrawing;
  buffer.Draw(GL_TRIANGLES);
end;

procedure SetViewPort(size: TVec2i); overload;
begin
  SetViewPort(size.width, size.height);
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
begin
  result := CanvasState.viewPort;
end;

{ Call ResizeCanvas in response to GLPT_MESSAGE_RESIZE to change the canvas size }

procedure ResizeCanvas(width, height: integer);
begin
  CanvasState.viewPortRatio := V2(1, 1);
  CanvasState.projTransform := TMat4.Ortho(0, width, height, 0, Z_NEAR, Z_FAR);
  CanvasState.viewTransform := TMat4.Identity;

  DefaultShader.SetUniformMat4('projTransform', CanvasState.projTransform);
  DefaultShader.SetUniformMat4('viewTransform', CanvasState.viewTransform);
  DefaultShader.SetUniformInts('textures', DefaultTextureUnits);

  SetViewPort(width, height);
end;

procedure ResizeCanvas(newSize: TVec2i);
begin
  ResizeCanvas(newSize.width, newSize.height);
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
      CanvasState.projTransform := TMat4.Ortho(0, width, height, 0, Z_NEAR, Z_FAR);
    end
  else
    begin
      CanvasState.viewPortRatio := destRect.Size / nativeSize;
      CanvasState.projTransform := TMat4.Ortho(0, width, height, 0, Z_NEAR, Z_FAR) * 
                                   TMat4.Scale(CanvasState.viewPortRatio, 1);
    end;

  CanvasState.viewTransform := TMat4.Identity;

  DefaultShader.SetUniformMat4('projTransform', CanvasState.projTransform);
  DefaultShader.SetUniformMat4('viewTransform', CanvasState.viewTransform);
  DefaultShader.SetUniformInts('textures', DefaultTextureUnits);
end;

{$ifdef PLATFORM_SDL}
const
  // SDL_WINDOW_FULLSCREEN_DESKTOP is normal macOS fullscreen mode
  // while SDL_WINDOW_FULLSCREEN changes the screen resolution
  SDL_WINDOW_FULLSCREEN_MODE = {SDL_WINDOW_FULLSCREEN}SDL_WINDOW_FULLSCREEN_DESKTOP;
{$endif}

function IsFullScreen: boolean;
var
  flags: LongWord;
begin
  {$ifdef PLATFORM_SDL}
  flags := SDL_GetWindowFlags(CanvasState.window);
  result := flags = (flags or SDL_WINDOW_FULLSCREEN_MODE);
  {$else}
  result := GLPT_IsWindowFullscreen(CanvasState.window);
  {$endif}
end;

procedure SetWindowFullScreen(newValue: boolean);
begin
  {$ifdef PLATFORM_SDL}
  if newValue then
    SDL_SetWindowFullscreen(CanvasState.window, SDL_WINDOW_FULLSCREEN_MODE)
  else
    SDL_SetWindowFullscreen(CanvasState.window, 0);
  {$endif}

  {$ifdef PlATFORM_GLPT}
  GLPT_SetWindowFullscreen(CanvasState.window, newValue);
  {$endif}
end;

procedure SetWindowTitle(title: string);
begin
  {$ifdef PLATFORM_SDL}
  title := title+#0;
  SDL_SetWindowTitle(CanvasState.window, @title[1]);
  {$endif}

  {$ifdef PlATFORM_GLPT}
  GLPT_SetWindowTitle(CanvasState.window, title);
  {$endif}
end;

function GetWindowSize: TVec2i;
begin
  // the window is not available yet
  if (CanvasState = nil) or (CanvasState.window = nil) then
    exit(0);

  {$ifdef PLATFORM_SDL}
  SDL_GetWindowSize(CanvasState.window, result.x, result.y);
  {$endif}

  {$ifdef PlATFORM_GLPT}
  GLPT_GetFrameBufferSize(CanvasState.window, result.x, result.y);
  {$endif}

  {$ifdef PlATFORM_NONE}
  Assert(false, 'GetWindowSize not implemented for platform');
  {$endif}
end;

function GetDisplaySize: TVec2i;
{$if defined(PLATFORM_SDL)}
var
  rect: TSDL_Rect;
{$elseif defined(PlATFORM_GLPT)}
var
  displayCoords: GLPTRect;
{$endif}
begin
  {$if defined(PLATFORM_SDL)}
  SDL_GetDisplayBounds(SDL_GetWindowDisplayIndex(CanvasState.window), rect);
  result.width := rect.w;
  result.height := rect.h;
  {$elseif defined(PlATFORM_GLPT)}
  GLPT_GetDisplayCoords(displayCoords);
  result.width := displayCoords.right - displayCoords.left;
  result.height := displayCoords.bottom - displayCoords.top;
  {$elseif defined(PlATFORM_NONE)}
  Assert(false, 'GetDisplaySize not implemented for platform');
  {$endif}
end;

function GetDefaultShaderAttributes: TVertexAttributes;
begin
  result := VertexBuffer.attributes;
end;

function IsVertexBufferEmpty: boolean;
begin
  result := VertexBuffer.Count = 0;
end;

procedure SetClearColor(color: TColor); 
begin
  CanvasState.clearColor := color;
  glClearColor(color.r, color.b, color.g, color.a);
end;

procedure SetDepthTest(enabled: Boolean);
begin
  if enabled then
    glEnable(GL_DEPTH_TEST)
  else
    glDisable(GL_DEPTH_TEST);
end;

procedure SetTargetFrameRate(newValue: Integer);
begin
  CanvasState.targetFrameRate := newValue;
end;

function GetFPS: longint;
begin
  result := CanvasState.fps;
end;

function GetDeltaTime: double;
begin
  result := CanvasState.deltaTime;
end;

function GetFrameCount: longint;
begin
  result := CanvasState.totalFrameCount;
end;

function GetFrameClock: double;
begin
  result := CanvasState.targetFrameTime / CanvasState.targetFrameRate;
end;

function GetFrameDelta: double;
begin
  result := CanvasState.deltaTime * CanvasState.targetFrameRate;
end;

{ Call once per frame to advance the frame clock }
procedure AdvanceFrameClock; 
begin
  with CanvasState do
    targetFrameTime += deltaTime * targetFrameRate;
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
  if (VertexBuffer.Count > 0) and (CanvasState.bufferPrimitiveType <> typ) then
    FlushDrawing;
  CanvasState.bufferPrimitiveType := typ;
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
      VertexBuffer.Add(TDefaultVertex.Create(V2(w * Cos(t) + x, h * Sin(t) + y), V2(0, 0), color, 255));
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
  if CanvasState.lineWidth <> lineWidth then
    begin
      Assert(VertexBuffer.Count = 0, 'must flush drawing before changing line width');
      glLineWidth(lineWidth);
      CanvasState.lineWidth := lineWidth;
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
      VertexBuffer.Add(TDefaultVertex.Create(V2(w * Cos(t) + x, h * Sin(t) + y), texCoord, color, 255));
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

    VertexBuffer.Add(quad.v);
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
    VertexBuffer.Add(TDefaultVertex.Create(points[i], 0, color, 255));

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
    VertexBuffer.Add(TDefaultVertex.Create(points[i], V2(0, 0), color, 255));
  // TODO: we don't need to flush each time
  FlushDrawing;
end;

procedure DrawPoint(constref point: TVec2; constref color: TColor);
begin
  ChangePrimitiveType(GL_POINTS);
  VertexBuffer.Add(TDefaultVertex.Create(point, V2(0, 0), color, 255));
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
      //if count = 2 then
      //  ChangePrimitiveType(GL_LINES)
      //else
      //  ChangePrimitiveType(GL_LINE_STRIP);
      ChangePrimitiveType(GL_LINES);
      
      for i := 0 to count - 1 do
        begin
          // connect points between segments
          //if (i mod 2 = 0) and (i > 0) then
          //  begin
          //    VertexBuffer.Add(TDefaultVertex.Create(points[i - 1], V2(0, 0), V4(0, 0, 0, 1), 255));
          //    VertexBuffer.Add(TDefaultVertex.Create(points[i], V2(0, 0), V4(0, 0, 0, 1), 255));
          //  end;
          VertexBuffer.Add(TDefaultVertex.Create(points[i], V2(0, 0), color, 255));
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

          VertexBuffer.Add(v[0]);
          VertexBuffer.Add(v[1]);
          VertexBuffer.Add(v[3]);

          VertexBuffer.Add(v[3]);
          VertexBuffer.Add(v[2]);
          VertexBuffer.Add(v[0]);

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

  VertexBuffer.Add(quad.v);
end;

procedure StrokeRect(constref rect: TRect; constref color: TColor; lineWidth: single = 1.0);
var
  texCoord: TVec2;
begin
  ChangePrimitiveType(GL_LINE_LOOP);

  // TODO: line width doesn't work now???
  // https://stackoverflow.com/questions/3484260/opengl-line-width
  {$ifdef GL_LINE_WIDTH}
  if CanvasState.lineWidth <> lineWidth then
    begin
      Assert(VertexBuffer.Count = 0, 'must flush drawing before changing line width');
      glLineWidth(lineWidth);
      CanvasState.lineWidth := lineWidth;
    end;
  {$endif}

  texCoord := V2(0, 0);
  VertexBuffer.Add(TDefaultVertex.Create(V2(rect.MinX - 0.5 { bias to connect lines }, rect.MinY), texCoord, color, 255));
  VertexBuffer.Add(TDefaultVertex.Create(V2(rect.MaxX, rect.MinY), texCoord, color, 255));
  VertexBuffer.Add(TDefaultVertex.Create(V2(rect.MaxX, rect.MaxY), texCoord, color, 255));
  VertexBuffer.Add(TDefaultVertex.Create(V2(rect.MinX, rect.MaxY), texCoord, color, 255));

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
  VertexBuffer.Add(quad.v);
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
  quad.SetPosition(rect);
  quad.SetTexture(textureFrame);
  quad.SetUV(textureUnit);

  if CanvasState.modelTransformStack.Count > 0 then
    quad.Transform(CanvasState.modelTransformStack.Last);

  VertexBuffer.Add(quad.v);
end;

procedure DrawTexture(texture: ITexture; quad: TDefaultVertexQuad);
begin
  Assert(texture <> nil, 'texture must not be nil');
  quad.SetUV(PushTexture(texture));
  ChangePrimitiveType(GL_TRIANGLES);
  VertexBuffer.Add(quad.v);
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

function CreateShader(shaderClass: TShaderClass; const vertexSource, fragmentSource: pchar): TShader;
begin
  result := shaderClass.Create(vertexSource, fragmentSource);
  result.Push;
  result.SetUniformMat4('projTransform', CanvasState.projTransform);
  result.SetUniformMat4('viewTransform', TMat4.Identity);
  result.SetUniformInts('textures', DefaultTextureUnits);

  // don't pop the default shader
  if DefaultShader <> nil then
    result.Pop;
end;

function CreateShader(const vertexSource, fragmentSource: pchar): TShader;
begin
  result := CreateShader(TShader, vertexSource, fragmentSource);
end;

function CreateVertexBuffer(static: boolean): TDefaultVertexBuffer;
begin
  result := TDefaultVertexBuffer.Create([TVertexAttribute.Create('position', GL_FLOAT, 2),
                                         TVertexAttribute.Create('inTexCoord', GL_FLOAT, 2),
                                         TVertexAttribute.Create('inColor', GL_FLOAT, 4),
                                         TVertexAttribute.Create('inUV', GL_UNSIGNED_BYTE, 1)
                                        ],
                                        static);
end;

function CanvasMousePosition(mouse: TVec2i): TVec2i;
begin
  result := mouse;
  result -= CanvasState.viewport.origin;
  result /= CanvasState.viewPortRatio;
end;

function GetResourceDirectory: ansistring;
const
  {$ifdef TARGET_OS_IPHONE}
  // the name resources is reserved on iphone otherwise code signing will fail
  kResourceDirectoryName = 'GameResources';
  {$else}
  kResourceDirectoryName = 'Resources';
  {$endif}
var
  name: string;
begin
  {$ifdef PLATFORM_SDL}
  result := SDL_GetBasePath;
  {$endif}

  {$ifdef PlATFORM_GLPT}
  result := GLPT_GetBasePath;
  {$endif}

  {$ifdef PlATFORM_NONE}
  Assert(false, 'GetResourceDirectory not implemented for platform');
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

function TCanvasState.GetActiveFont: IFont;
begin
  if m_activeFont = nil then
    begin
      // find a default system font
      {$ifdef DARWIN}
      m_activeFont := CreateFont('SFNS.ttf', 14);
      {$endif}
      {$ifdef WINDOWS}
      m_activeFont := CreateFont('Verdana.ttf', 14);
      {$endif}
    end;
  result := m_activeFont;
end;


procedure TCanvasState.FlushDrawing;
begin
  if not assigned(VertexBuffer) or (VertexBuffer.Count = 0) then
    exit;
  //Assert(ShaderStack.Last = DefaultShader, 'active shader must be default.');
  drawCalls += 1;
  VertexBuffer.Draw(CanvasState.bufferPrimitiveType);
  VertexBuffer.Clear;
end;

procedure TCanvasState.SwapBuffers;
var
  now: double;
  {$ifdef PLATFORM_SDL}
  event: TSDL_Event;
  _event: TEvent;
  {$endif}
begin
  self.FlushDrawing;

  {$ifdef PLATFORM_SDL}
  SDL_GL_MakeCurrent(window, context);
  SDL_GL_SwapWindow(window);

  while SDL_PollEvent(event) > 0 do
    begin
      case event.type_ of
        SDL_QUIT_EVENT:
          wantsClose := true;
        SDL_WINDOW_EVENT:
          case event.window.event of
            SDL_WINDOWEVENT_CLOSE:
              wantsClose := true;
          end;
      end;
      PollSystemInput(@event);
      if eventCallback <> nil then
        begin
          _event := TEvent.Create(event);
          eventCallback(_event);
          _event.Free;
        end;
    end;
  {$endif}

  {$ifdef PlATFORM_GLPT}
  GLPT_SwapBuffers(window);
  GLPT_PollEvents;
  {$endif}

  now := GetTime;
  deltaTime := now - lastFrameTime;
  lastFrameTime := now;
  drawCalls := 0;
  bindTextureCount := 0;

  inc(totalFrameCount);
  inc(frameCount);

  if now - sampleTime >= 1.0 then
    begin
      fps := frameCount;
      sampleTime := now;
      frameCount := 0;
    end;
end;

procedure TCanvasState.ClearBackground;
begin
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
end;

procedure TCanvasState.FinalizeSetup(windowSize: TVec2i);
{$ifdef PLATFORM_SDL}
var
  version: TSDL_Version;
{$endif}
begin
  {$ifdef API_OPENGL}
  if not Load_GL_VERSION_3_2 then
    Halt(-1);
  {$endif}

  writeln('OpenGL version: ', glGetString(GL_VERSION));
  writeln('GLSL version: ', glGetString(GL_SHADING_LANGUAGE_VERSION));
  {$ifdef PLATFORM_GLPT}
  writeln('GLPT version: ', GLPT_GetVersionString);
  {$endif}
  {$ifdef PLATFORM_SDL}
  SDL_GetVersion(version);
  writeln('SDL version: ', version.major, '.', version.minor, '.', version.patch);
  {$endif}
  writeln('Maximum Texture Units: ', GetMaximumTextureUnits);
  writeln('Maximum Texture Size: ', GetMaximumTextureSize);
  writeln('Maximum Verticies: ', GetMaximumVerticies);

  // the default shader imposes a texture limit we must follow
  SetMaximumTextureUnits(DEFAULT_SHADER_TEXTURE_UNITS);

  // clear any opengl errors (they shoud be handled here if any exist)
  glGetError();

  // set the view port to the actual size of the window
  SetViewPort(windowSize);

  glClearColor(1, 1, 1, 1);
  glDisable(GL_DEPTH_TEST);
  glEnable(GL_BLEND);

  clipRectStack := TRectList.Create;
  viewTransformStack := TMat4List.Create;
  modelTransformStack := TMat4List.Create;
  projectionTransformStack := TMat4List.Create;
  vertexBufferList := TDefaultVertexBufferList.Create;
  blendModeList := TCanvasState.TBlendModeList.Create;
  targetFrameRate := 60;

  viewPortRatio := V2(1, 1);

  // create global vertex buffer and shader
  VertexBuffer := CreateVertexBuffer;
  DefaultShader := CreateShader(DefaultVertexShader, DefaultFragmentShader);

  PushProjectionTransform(TMat4.Ortho(0, windowSize.width, windowSize.height, 0, Z_NEAR, Z_FAR));
  PushViewTransform(TMat4.Identity);
  PushBlendMode(TBlendingFactor.SRC_ALPHA, TBlendingFactor.ONE_MINUS_SRC_ALPHA);
  PushVertexBuffer(VertexBuffer);
end;

{$ifdef PLATFORM_SDL}
procedure SetupCanvas(width, height: integer; eventCallback: TEventCallback; options: TCanvasOptions);
var
  flags: longint;
begin
  if SDL_Init(SDL_INIT_VIDEO + SDL_INIT_JOYSTICK) < 0 then
    begin
      writeln('SDL could not initialize! ',SDL_GetError);
      Halt(-1);
    end;

  SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);
  SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
  SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 16);

  // multi-samples
  //SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 1);
  //SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 4);

  // allocate the default canvas
  if CanvasState = nil then
    CanvasState := TCanvasState.Create;
  
  CanvasState.eventCallback := eventCallback;

  with CanvasState do
    begin
      flags := SDL_WINDOW_SHOWN + SDL_WINDOW_OPENGL;

      if TCanvasOption.Resizable in options then
        flags += SDL_WINDOW_RESIZABLE;

      if TCanvasOption.FullScreen in options then
        begin
          fullScreen := true;
          flags += SDL_WINDOW_FULLSCREEN_MODE;
        end;

      window := SDL_CreateWindow('', SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width, height, flags);
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

      FinalizeSetup(V2i(width, height));
    end;
end;
{$endif}

{$ifdef PlATFORM_GLPT}

procedure MainEventCallback(event: pGLPT_MessageRec); 
var
  _event: TEvent;
begin
  PollSystemInput(event);

  if CanvasState.eventCallback <> nil then
    begin
      _event := TEvent.Create(event^);
      CanvasState.eventCallback(_event);
      _event.Free;
    end;
end;

procedure SetupCanvas(width, height: integer; eventCallback: TEventCallback; options: TCanvasOptions); 
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

  CanvasState.eventCallback := eventCallback;

  with CanvasState do
    begin
      context := GLPT_GetDefaultContext;
      {$ifdef API_OPENGL}
      context.majorVersion := 3;
      context.minorVersion := 2;
      context.profile := GLPT_CONTEXT_PROFILE_CORE;
      {
        TODO: high res context
        https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/OpenGL-MacProgGuide/EnablingOpenGLforHighResolution/EnablingOpenGLforHighResolution.html

        NSRect backingBounds = [self convertRectToBacking:[self bounds]];
        GLsizei backingPixelWidth  = (GLsizei)(backingBounds.size.width),
                backingPixelHeight = (GLsizei)(backingBounds.size.height);
        glViewport(0, 0, backingPixelWidth, backingPixelHeight);
      }
      //context.bestResolution := true;
      {$endif}
      {$ifdef API_OPENGLES}
      context.glesVersion := 3;
      {$endif}

      context.vsync := TCanvasOption.VSync in options;

      flags := GLPT_WINDOW_TITLED + GLPT_WINDOW_CLOSABLE;
      
      if TCanvasOption.Resizable in options then
        flags += GLPT_WINDOW_RESIZABLE;

      {$ifdef TARGET_OS_IPHONE}
      // Iphone must set window size since we don't know the screen size of our device before launch
      GLPT_GetDisplayCoords(displayCoords);
      width := displayCoords.right - displayCoords.left;
      height := displayCoords.bottom - displayCoords.top;
      {$else}
      if TCanvasOption.FullScreen in options then
        begin
          fullScreen := true;
          flags += GLPT_WINDOW_FULLSCREEN;
          GLPT_GetDisplayCoords(displayCoords);
          width := displayCoords.right - displayCoords.left;
          height := displayCoords.bottom - displayCoords.top;
        end;
      {$endif}

      window := GLPT_CreateWindow(GLPT_WINDOW_POS_CENTER, GLPT_WINDOW_POS_CENTER, width, height, '', context, flags);
      if window = nil then
        begin
          GLPT_Terminate;
          halt(-1);
        end;

      window^.event_callback := @MainEventCallback;

      FinalizeSetup(V2i(width, height));
    end;
end;
{$endif}

{$ifdef PlATFORM_NONE}
procedure SetupCanvas(width, height: integer; options: TCanvasOptions); 
begin
  // allocate the default canvas
  if CanvasState = nil then
    CanvasState := TCanvasState.Create;

  with CanvasState do
    begin
      FinalizeSetup(V2i(width, height));
    end;
end;
{$endif}

{$if defined(PLATFORM_GLPT) and defined(TARGET_OS_IPHONE)}
// when we define main with $pascalmainname (-XM) we need to declare the rea main function
function main(argc: cint; argv: pchar): cint; cdecl; public;
begin
  result := GLPT_InitializeMain(argc, argv);
end;
{$endif}

begin
  DefaultTextureColor := RGBA(1, 1, 1, 1);
  FillChar(TextureSlots, sizeof(TextureSlots), 0);
  System.Randomize;
  
  {$ifndef PLATFORM_NONE}
  ChDir(GetResourceDirectory);
  InputManager := TInputManager.Create;
  {$endif}
end.
