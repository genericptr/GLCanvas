{
    Copyright (c) 2022 by Ryan Joseph

    GLCanvas Test #22
    
    Test multiple line text drawing
}
{$mode objfpc}
{$modeswitch implicitfunctionspecialization}

program Test22;
uses
  SysUtils, GLCanvas;

const
  window_margin = 0;
  window_size_width = 500;
  window_size_height = 500;
  column_scroll = 10;

var
  ColumnWidth: Integer;

generic procedure Inc<T>(var value: T; amount, max: T); inline;
begin
  value += amount;
  if value > max then
    value := max;
end;

generic procedure Dec<T>(var value: T; amount, min: T); inline;
begin
  value -= amount;
  if value < min then
    value := min;
end;

procedure EventCallback(event: TEvent);
begin
  PollSystemInput(@event.RawEvent);

  case event.EventType of
    TEventType.KeyDown:
      case event.KeyCode of
        KEY_LEFT:
          Dec(ColumnWidth, column_scroll, column_scroll * 2);
        KEY_RIGHT:
          Inc(ColumnWidth, column_scroll, window_size_width + column_scroll * 2);
      end;
  end;
end;

var
  font: IFont;
  text: AnsiString;
begin
  SetupCanvas(window_size_width + window_margin * 2, window_size_height + window_margin * 2, @EventCallback);
  
  font := CreateFont('Monaco.ttf', 15);
  ColumnWidth := window_size_width - window_margin * 2;

  ColumnWidth -= column_scroll * 4;

  //ColumnWidth := window_size_width - window_margin * 2;
  ColumnWidth := 140;

  SetWindowTitle('Use left/right arrows keys to move page width');

  while IsRunning do
    begin
      ClearBackground;
      // TODO: can we render to a vertex buffer for caching? Running this every frame is nasty
      // we already render the default buffer but maybe we can push a new one and wrap draw calls
      {
        if buffer = nil then
          begin
            buffer := CreateVertexBuffer;
            buffer.Push; -- flush old buffer
            DrawText('hello world');
            buffer.Pop; -- flush new buffer
          end;
      }

      text := 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.';
      //text := 'Lorem ipsum dolor sit amet'+#10+
      //        'consectetur adipiscing elit'+#10+
      //        'sed do eiusmod tempor incididunt'+#10+
      //        'ut labore et dolore magna aliqua.';
      //text := 'consectetur consectetur';

      DrawText(font, 
        text, 
        TTextAlignment.Left,
        RectMake(window_margin, window_margin, ColumnWidth, MaxInt),
        TColor.Black);
      //halt;

      DrawLine(V2(ColumnWidth, GetViewPort.MinY), V2(ColumnWidth, GetViewPort.MaxY), TColor.Blue);

      //DrawText(font, 'Page width: '+ColumnWidth.ToString, V2(window_margin, window_margin), TColor.Black);

      SwapBuffers;
    end;

  QuitApp;
end.