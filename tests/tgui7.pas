{$mode objfpc}
{$assertions on}

program tgui7;
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
  backgroundImage: TTexture;

type
  TCustomScroller = class (TScroller)
    function GetHandleFrame: TRect; override;
    procedure DrawHandle(rect: TRect); override;
    procedure DrawTrack(rect: TRect); override;
  end;

function TCustomScroller.GetHandleFrame: TRect;
begin
  result := inherited;
  result.size := sliderThumb.GetSize;
end;

procedure TCustomScroller.DrawHandle(rect: TRect);
begin
  DrawTexture(sliderThumb, rect);
  if IsDragging then
    FillRect(rect, RGBA(0, 0, 1, 0.3));
end;

procedure TCustomScroller.DrawTrack(rect: TRect);
begin
  Draw9PartImage(sliderTrack, rect);
end;

procedure SetupGUI;
var
  window: TWindow;
  scrollView: TScrollView;
begin
  sliderTrack := TTextureSheet.Create('scroller_track.png', V2(4, 4));
  sliderThumb := TTexture.Create('scroller_thumb.png');
  backgroundImage := TTexture.Create('iso-64x64-outside.png');

  // TODO: how should we do this??
  MainPlatformWindow := GLCanvasState.window;  

  window := TWindow.Create(TWindow.ScreenRect);
  window.SetMoveableByBackground(false);
  window.MakeKeyAndOrderFront;

  scrollView := TScrollView.Create(RectMake(50, 50, 300, 300));
  scrollView.SetHorizontalScroller(TCustomScroller.Create);
  scrollView.SetVerticalScroller(TCustomScroller.Create);
  scrollView.SetContentView(
    TImageView.Create(RectMake(0, 0, backgroundImage.GetSize), backgroundImage)
  );

  window.AddSubview(scrollView);
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