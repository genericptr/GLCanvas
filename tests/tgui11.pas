{$mode objfpc}

program tgui11;
uses
  CThreads, FreeTypeH, FGL, GLFreeTypeFont, SysUtils, VectorMath, GeometryTypes,
  GLCanvas, GLGUI, GLPT, GL;

procedure EventCallback(event: pGLPT_MessageRec);
begin
  if PollWindowEvents(event) then
    exit;
end; 

var
  texture: TTextureComposite;
  button: TTextureSheet;
  x, y: integer;
begin
  SetupCanvas(480, 480, @EventCallback);

  // create composite texture using images
  texture := TTextureComposite.Create(128, ['scroller_thumb.png', 'button.png']);
 
  // subdivide sub texture into sheet 
  button := texture['button'].Subdivide(8);

  while IsRunning do
    begin
      ClearBackground;
      DrawTexture(texture, 0, 0);

      // composite
      DrawTexture(texture['scroller_thumb'], 100, 100);
      DrawTexture(texture['button'], 150, 100);

      // button
      for y := 0 to button.tableSize.y - 1 do
      for x := 0 to button.tableSize.x - 1 do
        DrawTexture(button[x, y], 100 + x * 16, 150 + y * 16);

      UpdateWindows;
      SwapBuffers;
    end;

  QuitApp;
end.