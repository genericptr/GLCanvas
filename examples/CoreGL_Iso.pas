{$mode objfpc}
{$assertions on}

program CoreGL_Iso;
uses
  CThreads, TileMap, FGL, Contnrs,
  SysUtils, GLCanvas, VectorMath, GLPT;

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

{ world tile coord to view point }
function WorldToView (x, y: integer; map: TTMXFile): TVec2; 
var
  halfTileWidth, halfTileHeight: TScalar;
  tileCoord: TPoint;
begin
  x *= map.tileHeight;
  y *= map.tileHeight;

  halfTileWidth := map.tileWidth / 2;
  halfTileHeight := map.tileHeight / 2;
  
  // convert pixel coords to tile coords
  tileCoord := PointMake(x / map.tileHeight, y / map.tileHeight);
  
  // convert tile coord to screen coords
  result.x := (tileCoord.x - tileCoord.y) * halfTileWidth;
  result.y := (tileCoord.x + tileCoord.y) * halfTileHeight;
  
  // align to fit
  result.x += ((map.mapWidth * map.tileWidth) / 2) - halfTileWidth;
end;

const
  window_size_width = 600;
  window_size_height = 600;

var
  MapTextures: array[0..3] of TTextureSheet;
  sheet: TTextureSheet;
  textures: array[0..3] of TTexture;
  i, x, y: integer;
  startTime: longint;
var
  texture: TTexture;
  tileset: TTMXTileSet;
  tile: TTMXTile;
  map: TTMXFile;
  layer: TTMXLayer;
  obj: TTMXObject;
  pt: TVec2;
begin
  SetupCanvas(window_size_width, window_size_height, @EventCallback);
  SetViewTransform(0, 0, 1.0);

  map := TTMXFile.Create('/Developer/Projects/FPC/NewEngine/Resources/iso/iso-map.tmx');
  for tileset in map.tilesets do
    MapTextures[tileset.index] := TTextureSheet.Create(tileset.image.fullPath, tileset.tileSize);

  while IsRunning do
    begin
      ClearBackground;

      //pt := WorldToView(0, 0, map);
      //DrawTexture(mapTextures[0][0], RectMake(pt.x, pt.y, 64, 64));
      //pt := WorldToView(1, 0, map);
      //DrawTexture(mapTextures[0][0], RectMake(pt.x, pt.y, 64, 64));

      for layer in map.layers do
        begin
          if not layer.visible then
            continue;
          for x := 0 to map.mapWidth - 1 do
          for y := 0 to map.mapHeight - 1 do
            begin
              tile := layer[x, y];
              if tile.tileID <> kInvalidGID then
                begin
                  pt := WorldToView(x, y, map);
                  DrawTexture(mapTextures[tile.tileset.index][tile.tileID], RectMake(pt.x, pt.y, 64, 64));
                end;
            end;
        end;
      
      SwapBuffers;
    end;

  QuitApp;
end.