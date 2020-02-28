{$mode objfpc}
{$assertions on}

program tgui6;
uses
  CThreads, SysUtils, VectorMath, GeometryTypes,
  GLCanvas, GLGUI, GLPT, GL;

procedure EventCallback(event: pGLPT_MessageRec);
begin
  if PollWindowEvents(event) then
    exit;
end; 

var
  sliderTrack: TTextureSheet;
  sliderThumb: TTexture;

type
  TCustomSlider = class (TSlider)
    function GetHandleFrame: TRect; override;
    procedure DrawHandle(rect: TRect); override;
    procedure DrawTrack(rect: TRect); override;
  end;

function TCustomSlider.GetHandleFrame: TRect;
begin
  result := inherited;
  result.size := sliderThumb.GetSize;
end;

procedure TCustomSlider.DrawHandle(rect: TRect);
begin
  DrawTexture(sliderThumb, rect);
  if IsDragging then
    FillRect(rect, RGBA(0, 0, 1, 0.3));
end;

procedure TCustomSlider.DrawTrack(rect: TRect);
begin
  Draw9PartImage(sliderTrack, rect);
end;

procedure SetupGUI;
var
  window: TWindow;
  slider: TCustomSlider;
begin
  sliderTrack := TTextureSheet.Create(GLPT_GetBasePath+'/scroller_track.png', V2(4, 4));
  sliderThumb := TTexture.Create(GLPT_GetBasePath+'/scroller_thumb.png');

  // TODO: how should we do this??
  MainPlatformWindow := GLCanvasState.window;  

  window := TWindow.Create(TWindow.ScreenRect);
  window.SetMoveableByBackground(false);
  window.MakeKeyAndOrderFront;

  // horizontal
  slider := TCustomSlider.Create(0, 100, RectMake(50, 50, 120, sliderThumb.GetHeight));
  slider.SetCurrentValue(20);
  window.AddSubview(slider);

  // vertical
  slider := TCustomSlider.Create(0, 100, RectMake(50, 100, sliderThumb.GetWidth, 120));
  slider.SetCurrentValue(20);
  window.AddSubview(slider);
end;

begin
  SetupCanvas(480, 480, @EventCallback);
  SetupGUI;

  while IsRunning do
    begin
      ClearBackground;
      UpdateWindows;
      SwapBuffers;
    end;

  QuitApp;
end.