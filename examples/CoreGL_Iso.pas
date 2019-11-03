{$mode objfpc}
{$assertions on}
{$modeswitch multihelpers}

program CoreGL_Iso;
uses
  CThreads, FGL, Contnrs, Classes, BaseUnix, FPJSON, JSONParser, SysUtils,
  GLPT, GLCanvas, VectorMath;

type
  TJSONObjectHelper = class helper for TJSONObject
    function FindValue(keys: array of const): Variant;
    function FindObject(keys: array of const): TJSONData;
  end;

function TJSONObjectHelper.FindValue(keys: array of const): Variant;
type
  TJSONDataClass = class of TJSONData;
var
  i: integer;
  next: TJSONData;
begin
  next := self;
  for i := 0 to high(keys) do
    begin
      case keys[i].vtype of
        vtInteger:
          next := TJSONArray(next)[keys[i].vinteger];
        vtString:
          next := TJSONObject(next)[keys[i].vstring^];
        vtAnsiString:
           next := TJSONObject(next)[ansistring(keys[i].vansistring)];
        vtChar:
          next := TJSONObject(next)[keys[i].vchar];
        otherwise
          raise exception.create('key #'+IntToStr(i)+' type '+IntToStr(keys[i].vtype)+' is invalid.');
      end;
      if i = high(keys) then
        result := next.value;
    end;
end;

function TJSONObjectHelper.FindObject(keys: array of const): TJSONData;
type
  TJSONDataClass = class of TJSONData;
var
  i: integer;
  next: TJSONData;
begin
  next := self;
  for i := 0 to high(keys) do
    begin
      case keys[i].vtype of
        vtInteger:
          next := TJSONArray(next)[keys[i].vinteger];
        vtString:
          next := TJSONObject(next)[keys[i].vstring^];
        vtAnsiString:
           next := TJSONObject(next)[ansistring(keys[i].vansistring)];
        vtChar:
          next := TJSONObject(next)[keys[i].vchar];
        otherwise
          raise exception.create('key #'+IntToStr(i)+' type '+IntToStr(keys[i].vtype)+' is invalid.');
      end;
      if i = high(keys) then
        result := next;
    end;
end;

type
  TWorld = record
    tileWidth: integer;       // pixel width of tile image
    tileHeight: integer;      // pixel height of tile image
    tileDepth: integer;       // world depth (z dimension) of tile
    tileSize: integer;        // world tile size (square)
    halfTileWidth: integer;
    halfTileHeight: integer;
    screenWidth: integer;
    screenHeight: integer;
    mapWidth: integer;
    mapHeight: integer;
    mapDepth: integer;
    drawSize: integer;
    drawScale: TScalar;
  end;

var
  World: TWorld;

function WorldToView (x, y, z: TScalar): TVec2; 
var
  tileCoord: TVec3;
begin
  with World do
    begin
      // convert pixel coords to tile coords
      tileCoord := V3(x / tileHeight, y / tileHeight, z / tileDepth);
      
      // convert tile coord to screen coords
      result.x := (tileCoord.x - tileCoord.y) * halfTileWidth;
      result.y := (tileCoord.x + tileCoord.y) * halfTileHeight;
      result.y -= (tileCoord.z * tileDepth);

      // offset to top-left of bottom
      result.x += halfTileWidth;
      result.y += tileDepth;

      // center in screen
      result.x += (screenWidth / 2) - (halfTileWidth);
    end;
end;

function ViewToWorld (x, y: TScalar): TVec2;
begin  
  with World do
    begin
      // offset view point to top-left of tile
      x -= halfTileWidth;
      y -= tileDepth;

      x -= (World.screenWidth / 2) - (World.halfTileWidth);

      result.x := x / tileWidth + y / tileHeight;
      result.y := y / tileHeight - x / tileWidth;

      // translate from tile coords
      result *= tileSize;
    end;
end;

function WorldPoly (x, y, z: TScalar): TVec2Array;
begin  
  SetLength(result, 4);
  with World do
    begin
      result[0] := WorldToView(x, y, z);
      result[1] := WorldToView(x + tileSize, y, z);
      result[2] := WorldToView(x + tileSize, y + tileSize, z);
      result[3] := WorldToView(x, y + tileSize, z);
    end;
end;

function BoundingViewRect(x, y, z: TScalar; constref imageSize: TVec2): TRect;
var
  pt: TVec2;
begin
  pt := WorldToView(x, y, z);
  result := RectMake(pt.x, pt.y, imageSize.width, imageSize.height);

  // align bottom of image to point
  result.origin.x -= imageSize.width / 2;
  result.origin.y -= imageSize.height - imageSize.width / 2;
end;

type
  TMap = record
    tiles: TJSONArray;
    minX: byte;
    minY: byte;
    maxX: byte;
    maxY: byte;
    country: string;
  end;

var
  map: TMap;
  mapOffset: TVec2;
  mouse: TVec2;

procedure EventCallback(event: pGLPT_MessageRec);
begin
  case event^.mcode of
    GLPT_MESSAGE_MOUSEMOVE:
      begin
        mouse := V2(event^.params.mouse.x, event^.params.mouse.y);
      end;
    GLPT_MESSAGE_KEYPRESS:
      begin
        case event^.params.keyboard.keycode of
          GLPT_KEY_UP:
            mapOffset.y -= 1;
          GLPT_KEY_DOWN:
            mapOffset.y += 1;
          GLPT_KEY_LEFT:
            mapOffset.x -= 1;
          GLPT_KEY_RIGHT:
            mapOffset.x += 1;
          GLPT_KEY_ESCAPE:
            GLPT_SetWindowShouldClose(event^.win, true);
        end;

        if mapOffset.x < 0 then
          mapOffset.x := 0;
        if mapOffset.y < 0 then
          mapOffset.y := 0;

        if mapOffset.x > map.maxX - map.minX then
          mapOffset.x := map.maxX - map.minX;
        if mapOffset.y > map.maxY - map.minY then
          mapOffset.y := map.maxY - map.minY;
      end;
  end;
end; 

var
  font: TBitmapFont;

procedure DrawDebug;
var
  pt: TVec2;
begin
  // map offset text
  DrawText(font, mapOffset.ToStr, V2(120, 20));

  // mouse world position
  pt := ViewToWorld(trunc(mouse.x), trunc(mouse.y));
  DrawText(font, Trunc(pt / World.tileSize).ToStr, V2(120, 40));
end;

const
  window_size_width = 800;
  window_size_height = 600;

var
  mapTexture: TTextureSheet;
  textures: array[0..0] of TTexture;
  i, x, y, z: integer;
  startTime: longint;
var
  texture: TTexture;
  pt: TVec2;
  rect: TRect;
  tileX,
  tileY,
  tileZ: float;
  s: ansistring;
  tileID: integer;
  json: TJSONObject;
  game: integer;
  poly: array of TVec2;
begin
  SetupCanvas(window_size_width, window_size_height, @EventCallback);
  SetViewTransform(0, 0, 1.0);

  mapTexture := TTextureSheet.Create(GLPT_GetBasePath+'/syndicate_map_2.png', V2(64, 48));
  font := TBitmapFont.Create(GLPT_GetBasePath+'/coders_crux');

  json := TJSONObject(GetJSON(ReadFile(GLPT_GetBasePath+'/maps1.json')));

  game := 0;
  map.tiles := json.FindObject(['maps', game, 'tiles']) as TJSONArray;
  map.minX := json.FindValue(['maps', game, 'minX']);
  map.minY := json.FindValue(['maps', game, 'minY']);
  map.maxX := json.FindValue(['maps', game, 'maxX']);
  map.maxY := json.FindValue(['maps', game, 'maxY']);
  map.country := json.FindValue(['maps', game, 'country']);

  writeln(map.country);
  mapOffset := V2(68, 31);

  World.mapWidth := 128;
  World.mapHeight := 96;
  World.mapDepth := 12;   // TODO: search max z from tiles
  World.drawSize := 16;
  World.drawScale := 1.00;
  World.tileWidth := 64;
  World.tileHeight := 32;
  World.tileDepth := 16;
  World.tileSize := 32;
  World.halfTileWidth := trunc(world.tileWidth / 2);
  World.halfTileHeight := trunc(world.tileHeight / 2);
  World.screenWidth := window_size_width;
  World.screenHeight := window_size_height;

  while IsRunning do
    begin
      ClearBackground;
      
      for z := 0 to World.mapDepth - 1 do
      for y := trunc(mapOffset.y) to (trunc(mapOffset.y) + World.drawSize) - 1 do
      for x := trunc(mapOffset.x) to (trunc(mapOffset.x) + World.drawSize) - 1 do
        begin
          i := (x + y * World.mapWidth) + (z * World.mapWidth * World.mapHeight);
          if i > map.tiles.Count - 1 then
            continue;
          tileID := map.tiles[i].value;
          if tileID = 0 then
            continue;

          tileX := (x - trunc(mapOffset.x)) * World.tileSize;
          tileY := (y - trunc(mapOffset.y)) * World.tileSize;
          tileZ := z * World.tileDepth;
          rect := BoundingViewRect(tileX, tileY, tileZ, mapTexture.cellSize);
          DrawTexture(mapTexture[tileID], rect * World.drawScale);
        end;

      DrawDebug;      
      SwapBuffers;
    end;

  QuitApp;
end.