{
    Copyright (c) 2023 by Ryan Joseph

    GLCanvas Test #26
    
    Tests updating free type fonts
}
{$mode objfpc}
{$modeswitch multihelpers}

program Test26;
uses
  GLCanvas;

const
  window_size_width = 512;
  window_size_height = 512;

begin
  SetupCanvas(window_size_width, window_size_height);

  // TODO: test updating font with new characters if they don't exist
  
  // TODO: bonus make emojis work
  // https://gist.github.com/jokertarot/7583938

  font := CreateFont('xxxx');
  font.Update('🔴');
  font.Update('∆');
  font.Update('∂');

  while IsRunning do
    begin
      FillRect(GetViewPort, TColor.Red);
      DrawTexture(output, GetViewPort.FlipY);
      SwapBuffers;
    end;

  QuitApp;
end.