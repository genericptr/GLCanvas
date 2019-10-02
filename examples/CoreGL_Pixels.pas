{$mode objfpc}
{$assertions on}

program CoreGL_Pixels;
uses
  TileMap, FGL, Contnrs,
  SysUtils, GLCanvas, VectorMath, GLPT;

{
  Pixel Buffer
}

type
  TPixelBuffer = class
    private type
      TRGBMatrix = specialize TFPGMatrix<TVec3>; 
    public
      pixels: TRGBMatrix;
      textureID: integer;
      constructor Create(size: integer);
      procedure Reload;
  end;

var
  buffer: specialize TFPGMatrix<TPixelBuffer>;


procedure TPixelBuffer.Reload;
begin
  if textureID = 0 then
   GenerateTexture(textureID);
  LoadTexture2D(pixels.width, pixels.height, pixels.data, []);
end;

constructor TPixelMap.Create(size: integer);
begin
  pixels := TRGBMatrix.Create(size, size);
end;

function GetDataFile (name: string): string; inline;
begin
  result := GLPT_GetBasePath+name;
end;

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

var
  i, x, y: integer;
  startTime: longint;
begin

  while IsRunning do
    begin
      ClearBackground;
      SwapBuffers;
    end;

  QuitApp;
end.