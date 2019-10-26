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
  waitForKey: pGLPT_Semaphore;

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

        GLPT_SemaphorePost(waitForKey);
      end;
  end;
end; 

{
  World.pas unit

  everything for drawing and transforms
}
type
  TWorld = record
    mapOffset: TVec2;
    tileWidth: integer;
    tileHeight: integer;
    tileDepth: integer;
    halfTileWidth: integer;
    halfTileHeight: integer;
    mapWidth: integer;
    mapHeight: integer;
    mapDepth: integer;
    drawSize: integer;
    drawScale: single;
  end;
var
  World: TWorld;

{ world tile coord to view point }
function WorldToView (x, y, z: integer; tileWidth, tileHeight, tileDepth: integer): TVec2; 
var
  halfTileWidth, halfTileHeight: TScalar;
  tileCoord: TVec2;
begin
  x *= tileHeight;
  y *= tileHeight;

  halfTileWidth := tileWidth / 2;
  halfTileHeight := tileHeight / 2;
  
  // convert pixel coords to tile coords
  tileCoord := V2(x / tileHeight, y / tileHeight);
  
  // convert tile coord to screen coords
  result.x := (tileCoord.x - tileCoord.y) * halfTileWidth;
  result.y := (tileCoord.x + tileCoord.y) * halfTileHeight;
  result.y -= (z * tileDepth);
end;

// http://clintbellanger.net/articles/isometric_math/
function ViewToWorld (x, y: integer; tileWidth, tileHeight: integer): TVec2;
var
  halfTileWidth, halfTileHeight: TScalar;
begin  
  halfTileWidth := tileWidth / 2;
  halfTileHeight := tileHeight / 2;

  x -= trunc(halfTileWidth);
    
  result.x := (((x / halfTileWidth) + (y / halfTileHeight)) / 2) * halfTileWidth;
  result.y := (((y / halfTileHeight) - (x / halfTileWidth)) / 2) * tileHeight; 
end;

function IsoPolyAtWorld (x, y, z: integer; tileWidth, tileHeight, tileDepth: integer): TVec2Array;
var
  pt: TVec2;
  halfTileWidth, halfTileHeight: TScalar;
begin  
  halfTileWidth := tileWidth / 2;
  halfTileHeight := tileHeight / 2;

  SetLength(result, 4);

  pt := WorldToView(x, y, z, tileWidth, tileHeight, tileDepth);
  x := trunc(pt.x);
  y := trunc(pt.y);
  Y += tileDepth;

  result[0] := V2(x + halfTileWidth, y);
  result[1] := V2(result[0].x + halfTileWidth, result[0].y + tileDepth);
  result[2] := V2(result[1].x - halfTileWidth, result[1].y + tileDepth);
  result[3] := V2(result[2].x - halfTileWidth, result[2].y - tileDepth);
end;

// TODO: rect to draw texture, bottom aligned
function BoundingViewRect(x, y, z, depth: single): TRect;
begin
  
end;

const
  window_size_width = 800;
  window_size_height = 600;

var
  mapTexture: TTextureSheet;
  i, x, y, z: integer;
  startTime: longint;
var
  texture: TTexture;
  font: TBitmapFont;
  pt: TVec2;
  rect: TRect;
  s: ansistring;
  tileID,
  mapWidth,
  mapHeight,
  mapDepth,
  tileWidth,
  tileHeight,
  tileDepth,
  drawSize: integer;
  drawScale: single;
  json: TJSONObject;
  game: integer;
  poly: array of TVec2;
begin
  SetupCanvas(window_size_width, window_size_height, @EventCallback);
  SetViewTransform(0, 0, 1.0);


  // TODO: if we change V2 to SizeMake get an error
  //Assembling (pipe) /Users/ryanjoseph/Developer/Projects/FPC/GLCanvas/console.debug.ppcx64/CoreGL_Iso.s
  //<stdin>:889:12: error: invalid operand for instruction
  //        movd    %rdx,-824(%rbp)
  mapTexture := TTextureSheet.Create(GLPT_GetBasePath+'/syndicate_map_2.png', V2(64, 48));
  font := TBitmapFont.Create(GLPT_GetBasePath+'/coders_crux');

  json := TJSONObject(GetJSON(ReadFile('/Users/ryanjoseph/Desktop/maps2.json')));

  game := 0;
  map.tiles := json.FindObject(['maps', game, 'tiles']) as TJSONArray;
  map.minX := json.FindValue(['maps', game, 'minX']);
  map.minY := json.FindValue(['maps', game, 'minY']);
  map.maxX := json.FindValue(['maps', game, 'maxX']);
  map.maxY := json.FindValue(['maps', game, 'maxY']);
  map.country := json.FindValue(['maps', game, 'country']);

  writeln(map.country);
  mapOffset := V2({map.minX, map.minY}0,0);

  waitForKey := GLPT_CreateSemaphore();

  // TODO: no generics for integer vectors! damn it already
  mapWidth := 128;
  mapHeight := 96;
  // TODO: search max z from tiles
  mapDepth := 12;
  drawSize := 20;
  drawScale := 1.00;

  // TODO: we need to make some concrete types going in or everything will fall apart later....
  // tile dimensions
  tileWidth := 64;
  tileHeight := 32;
  tileDepth := 16;

  while IsRunning do
    begin
      ClearBackground;

      pt := WorldToView(0, 0, 0, tileWidth, tileHeight, tileDepth);
      DrawTexture(mapTexture[40], RectMake(pt.x * drawScale, pt.y * drawScale, mapTexture.cellSize.width * drawScale, mapTexture.cellSize.height * drawScale));
      
      pt := WorldToView(3, 0, 0, tileWidth, tileHeight, tileDepth);
      DrawTexture(mapTexture[41], RectMake(pt.x * drawScale, pt.y * drawScale, mapTexture.cellSize.width * drawScale, mapTexture.cellSize.height * drawScale));

      // tile coord bounding box
      pt := WorldToView(1, 0, 0, tileWidth, tileHeight, tileDepth);
      rect := RectMake(pt.x * drawScale, pt.y * drawScale, mapTexture.cellSize.width * drawScale, mapTexture.cellSize.height * drawScale);
      // TODO: align to bottom
      // TODO: our rect is going to make this not possible .... damn it
      rect.origin.y -= rect.height - tileHeight + tileDepth;
      //rect.height -= rect.height - tileHeight + tileDepth;
      StrokeRect(rect, V4(0, 0, 1, 1));


      //for z := 0 to mapDepth - 1 do
      //for y := trunc(mapOffset.y) to (trunc(mapOffset.y) + drawSize) - 1 do
      //for x := trunc(mapOffset.x) to (trunc(mapOffset.x) + drawSize) - 1 do
      //  begin
      //    i := (x + y * mapWidth) + (z * mapWidth * mapHeight);
      //    if i > map.tiles.Count - 1 then
      //      continue;
      //    tileID := map.tiles[i].value;
      //    if tileID = 0 then
      //      continue;

      //    // TODO: make new general functions
      //    // mouse picking
      //    // screen pixel to iso pixel for scrolling
      //    // https://www.youtube.com/watch?v=ukkbNKTgf5U
      //    pt := WorldToView(x - trunc(mapOffset.x), y - trunc(mapOffset.y), z, tileWidth, tileHeight, tileDepth);
      //    // align to center of window
      //    //pt.x += (window_size_width / 2) - (tileWidth / 2);

      //    //pt.x -= 32;
      //    //pt.y -= 16;

      //    DrawTexture(mapTexture[tileID], RectMake(pt.x * drawScale, pt.y * drawScale, mapTexture.cellSize.width * drawScale, mapTexture.cellSize.height * drawScale));
      //  end;
      
      DrawText(font, mapOffset.ToStr, V2(120, 20));

      pt := ViewToWorld(trunc(mouse.x), trunc(mouse.y), tileWidth, tileHeight);
      DrawText(font, pt.ToStr+' '+trunc(pt / 32).ToStr, V2(120, 40));
      
      pt := trunc(pt / 32);
      pt := WorldToView(trunc(pt.x), trunc(pt.y), z, tileWidth, tileHeight, tileDepth);
      rect := RectMake(pt.x * drawScale, pt.y * drawScale, mapTexture.cellSize.width * drawScale, mapTexture.cellSize.height * drawScale);
      StrokeRect(rect, V4(1, 0, 0, 1));

      //pt := WorldToView(trunc(pt.x), trunc(pt.y), 0, tileWidth, tileHeight, tileDepth);
      //pt := trunc(mouse / mapTexture.cellSize);
      //DrawText(font, pt.ToStr, V2(20, 40));

      //pt := WorldToView(0, 0, 0, tileWidth, tileHeight, tileDepth);
      //StrokeRect(RectMake(trunc(pt.x) * mapTexture.cellSize.width, trunc(pt.y) * mapTexture.cellSize.height, mapTexture.cellSize.width, mapTexture.cellSize.height), V4(1, 0, 0, 1));

      //poly := [V2(100, 100), V2(100, 150), V2(250, 300)];
      poly := IsoPolyAtWorld(0, 0, 0, tileWidth, trunc(tileHeight / 2), tileDepth);
      if PolyContainsPoint(poly, mouse) then
        StrokePolygon(poly, V4(0, 1, 0, 1))
      else
        StrokePolygon(poly, V4(1, 0, 0, 1));

      SwapBuffers;

      // TODO: blocks main thread and we can't get key down
      // maybe we need to make a new thread for polling events?
      // make a new example program

      //Sleep(100);
      //GLPT_SemaphoreWait(waitForKey);
    end;

  QuitApp;
end.