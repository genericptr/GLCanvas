{$mode objfpc}
{$assertions on}

program CoreGL_Empty;
uses
  CThreads, VectorMath, GLCanvas, GLPT;

procedure EventCallback(event: pGLPT_MessageRec);
begin
  case event^.mcode of
    GLPT_MESSAGE_KEYPRESS:
      begin
        if event^.params.keyboard.keycode = GLPT_KEY_ESCAPE then
          GLPT_SetWindowShouldClose(event^.win, true);
      end;
  end;
end; 

const
  window_size_width = 600;
  window_size_height = 600;

begin
  SetupCanvas(window_size_width, window_size_height, @EventCallback);
  SetViewTransform(0, 0, 1.0);

  while IsRunning do
    begin
      ClearBackground;
      { Do drawing here... }
      SwapBuffers;
    end;

  QuitApp;
end.