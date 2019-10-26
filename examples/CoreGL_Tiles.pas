{$mode objfpc}
{$modeswitch advancedrecords}
{$assertions on}

program CoreGL_Tiles;
uses
  TileMap, FGL, Contnrs,
  SysUtils, GLCanvas, GLPT;

function GetDataFile (name: string): string; inline;
begin
  result := GLPT_GetBasePath+name;
end;

procedure EventCallback(event: pGLPT_MessageRec);
begin
  //GLPT_MESSAGE_KEYPRESS = 4;
  //GLPT_MESSAGE_KEYRELEASE = 5;
  //GLPT_MESSAGE_KEYCHAR = 6;
  //GLPT_MESSAGE_MOUSEDOWN = 7;
  //GLPT_MESSAGE_MOUSEUP = 8;
  //GLPT_MESSAGE_MOUSEMOVE = 9;
  //GLPT_MESSAGE_DOUBLECLICK = 10;
  //GLPT_MESSAGE_MOUSEENTER = 11;
  //GLPT_MESSAGE_MOUSEEXIT = 12;
  //GLPT_MESSAGE_CLOSE = 13;
  //GLPT_MESSAGE_SCROLL = 14;
  //GLPT_MESSAGE_RESIZE = 15;
  //GLPT_MESSAGE_MOVE = 16;
  case event^.mcode of
    GLPT_MESSAGE_RESIZE:
      begin
        SetViewPort(event^.params.rect.width, event^.params.rect.height);
      end;
    GLPT_MESSAGE_KEYPRESS:
      begin
        if event^.params.keyboard.keycode = GLPT_KEY_ESCAPE then
          GLPT_SetWindowShouldClose(event^.win, true);
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

var
  MapTextures: array[0..3] of TTextureSheet;

type
  TSprite = class
    private
      texture: TTexture;
      frame: TRect;
    public
      constructor Create(obj: TTMXObject);
      procedure Draw;
  end;

constructor TSprite.Create(obj: TTMXObject);
begin
  texture := MapTextures[obj.tileset.index][obj.tileID];
  frame := obj.frame;
end;

procedure TSprite.Draw;
begin
  DrawTexture(texture, frame);
end;

const
  window_size_width = 600;
  window_size_height = 600;

var
  sheet: TTextureSheet;
  textures: array[0..3] of TTexture;
  font: TBitmapFont;
  i, x, y: integer;
  startTime: longint;
var
  texture: TTexture;
  tileset: TTMXTileSet;
  tile: TTMXTile;
  map: TTMXFile;
  layer: TTMXLayer;
  obj: TTMXObject;
  sprite: TSprite;
  sprites: TObjectList;
begin
  // TODO: options - resize changes viewport
  SetupCanvas(window_size_width, window_size_height, @EventCallback);
  SetViewTransform(0, 0, 1.0);

  sprites := TObjectList.Create(true);
  font := TBitmapFont.Create('/Developer/Projects/FPC/NewEngine/Resources/fonts/coders_crux');

  map := TTMXFile.Create('/Users/ryanjoseph/Documents/metroid/metroid_map_multiple.tmx');
  for tileset in map.tilesets do
    MapTextures[tileset.index] := TTextureSheet.Create(tileset.image.fullPath, tileset.tileSize);

  // TODO: we can't get object layers by name yet
  for i := 0 to map.objectGroups[0].Count - 1 do
    begin
      sprite := TSprite.Create(map.objectGroups[0][i]);
      sprites.Add(sprite);
    end;

  while IsRunning do
    begin
      //PrintFPS;
      ClearBackground;

      for layer in map.layers do
      for x := 0 to map.mapWidth - 1 do
      for y := 0 to map.mapHeight - 1 do
        begin
          tile := layer[x, y];
          if tile.tileID <> kInvalidGID then
            begin
              DrawTexture(mapTextures[tile.tileset.index][tile.tileID], map.TileRectMake(x, y));
            end;
        end;
      
      // TODO: we can't cast iterators anymore! find a better solution
      for sprite in sprites do
        sprite.Draw;

      SwapBuffers;
    end;

  QuitApp;
end.