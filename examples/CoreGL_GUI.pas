{$mode objfpc}
{$modeswitch nestedprocvars}
{$assertions on}

program CoreGL_GUI;
uses
  CThreads, SysUtils, VectorMath, GeometryTypes, GLCanvas, GLGUI, GLPT;

var
  window: TGLWindow;
  button: TGLButton;
  font: TBitmapFont;

procedure EventCallback(event: pGLPT_MessageRec);
var
  newFrame: TRect;
  delta: TVec2;
begin
  if PollWindowEvents(event) then
    exit;

  case event^.mcode of
    GLPT_MESSAGE_SCROLL:
      begin
        delta := V2(event^.params.mouse.deltaX, event^.params.mouse.deltaY);
        newFrame := window.GetFrame;
        newFrame.size += delta;
        window.SetFrame(newFrame);
        window.LayoutSubviews;
      end;
    GLPT_MESSAGE_KEYPRESS:
      begin
        case event^.params.keyboard.keycode of
          GLPT_KEY_RIGHT:
            begin
              newFrame := window.GetFrame;
              newFrame.size.x += 8;
              window.SetFrame(newFrame);
              window.LayoutSubviews;
            end;
          GLPT_KEY_LEFT:
            begin
              newFrame := window.GetFrame;
              newFrame.size.x -= 8;
              window.SetFrame(newFrame);
              window.LayoutSubviews;
            end;
          GLPT_KEY_UP:
            begin
              newFrame := window.GetFrame;
              newFrame.size.y -= 8;
              window.SetFrame(newFrame);
              window.LayoutSubviews;
            end;
          GLPT_KEY_DOWN:
            begin
              newFrame := window.GetFrame;
              newFrame.size.y += 8;
              window.SetFrame(newFrame);
              window.LayoutSubviews;
            end;
          GLPT_KEY_ESCAPE:
            GLPT_SetWindowShouldClose(event^.win, true);
        end;
      end;
  end;
end; 

var
  nbFrames: integer = 0;
  lastTime: double = 0;

procedure PrintFPS;
var
  currentTime: double;
  fps: string;
begin
  currentTime := GLPT_GetTime;
  inc(nbFrames);
  if currentTime - lastTime >= 1 then
    begin
      fps := format('[FPS: %3.0f]', [nbFrames / (currentTime - lastTime)]);
      writeln(fps);
      nbFrames := 0;
      lastTime := GLPT_GetTime;
    end;
end;

procedure SetupGUI; 
  procedure PressedButton(params: TInvocationParams);
  var
    button: TGLButton absolute params;
  begin
    writeln('clicked button ', button.classname);
  end; 

begin

  // TODO: we need to set MainPlatformWindow
  //InitGUI(GLCanvasState.window);
  font := TBitmapFont.Create(GLPT_GetBasePath+'/coders_crux');

  // TODO: make an overload that uses the global font (removes first param)
  // and make SetDefaultFont(font) function
  //DrawText(font, input, 0, RectMake(20, 20, window_size_width - 20 * 2, 10000));

  // TODO: windows have no title??
  window := TGLWindow.Create(RectMake(20, 20, 200, 120){, 'My Window'});
  window.OrderFront;

  // TODO: buttons titles in constructor
  button := TGLButton.Create(RectMake(20, 20, 60, 22));
  button.SetAutoresizingOptions([ 
                                  TAutoresizingOption.MinXMargin,
                                  TAutoresizingOption.MinYMargin,

                                  TAutoresizingOption.WidthSizable,
                                  TAutoresizingOption.MaxXMargin,

                                  TAutoresizingOption.HeightSizable,
                                  TAutoresizingOption.MaxYMargin

                                  ]);
  button.SetAction(TInvocation.Create(@PressedButton));
  window.AddSubview(button);

  button := TGLButton.Create(RectMake(window.GetWidth - (60 + 10), window.GetHeight - (22 + 10), 60, 22));
  button.SetAutoresizingOptions([ TAutoresizingOption.MaxXMargin,
                                  TAutoresizingOption.MaxYMargin
                                  ]);
  button.SetAction(TInvocation.Create(@PressedButton));
  window.AddSubview(button);



  //controls.Add(window);
end;

const
  window_size_width = 640;
  window_size_height = 480;

begin
  
  // TODO: options - resize changes viewport
  SetupCanvas(window_size_width, window_size_height, @EventCallback);
  SetViewTransform(0, 0, 1.0);

  SetupGUI;

  while IsRunning do
    begin
      //PrintFPS;
      ClearBackground;
      UpdateWindows;
      SwapBuffers;
    end;

  QuitApp;
end.