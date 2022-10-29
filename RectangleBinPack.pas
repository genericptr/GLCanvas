{
    Copyright (c) 2021 by Ryan Joseph
  
    Based on the Public Domain MaxRectsBinPack.cpp source by Jukka Jylänki
    https://github.com/juj/RectangleBinPack/
}

{$mode objfpc}
{$modeswitch autoderef}

unit RectangleBinPack;
interface
uses
  GLCanvas, Math, FGL;

type
  TBinPacker = class
    public type
      TRect = TRecti;
      TRectList = specialize TFPGList<TRect>;
      TChoiceHeuristic = (
          RectBestShortSideFit,   // BSSF: Positions the rectangle against the short side of a free rectangle into which it fits the best.
          RectBestLongSideFit,    // BLSF: Positions the rectangle against the long side of a free rectangle into which it fits the best.
          RectBestAreaFit,        // BAF: Positions the rectangle into the smallest free rect into which it fits.
          RectBottomLeftRule,     // BL: Does the Tetris placement.
          RectContactPointRule    // CP: Choosest the placement where the rectangle touches other rects as much as possible.
      );
    private
      binWidth: integer;
      binHeight: integer;
      allowRotations: boolean;
      procedure PlaceRect(node: TRect);
      function ScoreRect(width, height: integer; method: TChoiceHeuristic; out score1, score2: integer): TRect;
      function FindPositionForNewNodeBottomLeft(width, height: integer; var bestY, bestX: integer): TRect;
      function FindPositionForNewNodeBestShortSideFit(width, height: integer; var bestShortSideFit, bestLongSideFit: integer): TRect;
      function FindPositionForNewNodeBestLongSideFit(width, height: integer; var bestShortSideFit, bestLongSideFit: integer): TRect;
      function FindPositionForNewNodeBestAreaFit(width, height: integer; var bestAreaFit, bestShortSideFit: integer): TRect;
      function CommonIntervalLength(i1start, i1end, i2start, i2end: integer): integer;
      function ContactPointScoreNode(x, y, width, height: integer): integer;
      function FindPositionForNewNodeContactPoint(width, height: integer; var bestContactScore: integer): TRect;
      function SplitFreeNode(freeNode: TRect; var usedNode: TRect): boolean;
      procedure PruneFreeList; 
      function IsContainedIn(a, b: TRect): boolean; inline;
    public
      usedRectangles: TRectList;
      freeRectangles: TRectList;
    public
      { Constructors }
      constructor Create(width, height: integer; rotations: boolean = true);
      destructor Destroy; override;
      { Methods }
      function Insert(width, height: integer; method: TChoiceHeuristic = RectBestShortSideFit): TRect;
      procedure Insert(rects, dst: TRectList; method: TChoiceHeuristic = RectBestShortSideFit);
      function Occupancy: float;
  end;

implementation

function TBinPacker.Insert(width, height: integer; method: TChoiceHeuristic): TRect;
var
  newNode: TRect;
  i,
  score1,
  score2,
  numRectanglesToProcess: integer;
begin
  score1 := 0;
  score2 := 0;

  case method of
    RectBestShortSideFit: 
      newNode := FindPositionForNewNodeBestShortSideFit(width, height, score1, score2);
    RectBottomLeftRule: 
      newNode := FindPositionForNewNodeBottomLeft(width, height, score1, score2);
    RectContactPointRule: 
      newNode := FindPositionForNewNodeContactPoint(width, height, score1);
    RectBestLongSideFit: 
      newNode := FindPositionForNewNodeBestLongSideFit(width, height, score2, score1);
    RectBestAreaFit: 
      newNode := FindPositionForNewNodeBestAreaFit(width, height, score1, score2);
  end;

  if newNode.height = 0 then
    exit(newNode);

  numRectanglesToProcess := freeRectangles.Count;
  i := 0;
  while i < numRectanglesToProcess do
    begin
      if SplitFreeNode(freeRectangles[i], newNode) then
        begin
          freeRectangles.Delete(i);
          Dec(i);
          Dec(numRectanglesToProcess);
        end;
      Inc(i);
    end;

  PruneFreeList;

  usedRectangles.Add(newNode);

  result := newNode;
end;

procedure TBinPacker.Insert(rects, dst: TRectList; method: TChoiceHeuristic); 
var
  bestScore1: integer = MaxInt;
  bestScore2: integer = MaxInt;
  bestRectIndex: integer = -1;
  bestNode: TRect;
  i,
  score1,
  score2: integer;
  newNode: TRect;
begin
  dst.Clear;

  while rects.Count > 0 do
    begin
      for i := 0 to rects.Count - 1 do
        begin
          score1 := 0;
          score2 := 0;
          newNode := ScoreRect(rects[i].width, rects[i].height, method, score1, score2);

          if (score1 < bestScore1) or ((score1 = bestScore1) and (score2 < bestScore2)) then
            begin
              bestScore1 := score1;
              bestScore2 := score2;
              bestNode := newNode;
              bestRectIndex := i;
            end;
        end;
      
      if bestRectIndex = -1 then
        exit;

      PlaceRect(bestNode);
      rects.Delete(bestRectIndex);
    end;
end;

procedure TBinPacker.PlaceRect(node: TRect); 
var
  numRectanglesToProcess: integer;
  i: integer;
begin
  numRectanglesToProcess := freeRectangles.Count;
  i := 0;
  while i < numRectanglesToProcess do
    begin
      if SplitFreeNode(freeRectangles[i], node) then
        begin
          freeRectangles.Delete(i);
          Dec(i);
          Dec(numRectanglesToProcess);
        end
      else
        Inc(i);
    end;

  PruneFreeList;
  usedRectangles.Add(node);
end;

function TBinPacker.ScoreRect(width, height: integer; method: TChoiceHeuristic; out score1, score2: integer): TRect;
var
  newNode: TRect;
begin
  score1 := MaxInt;
  score2 := MaxInt;

  case method of
    RectBestShortSideFit:
      newNode := FindPositionForNewNodeBestShortSideFit(width, height, score1, score2);
    RectBottomLeftRule:
      newNode := FindPositionForNewNodeBottomLeft(width, height, score1, score2);
    RectContactPointRule:
      begin
        newNode := FindPositionForNewNodeContactPoint(width, height, score1);
        score1 := -score1; // Reverse since we are minimizing, but for contact point score bigger is better.
      end;
    RectBestLongSideFit:
      newNode := FindPositionForNewNodeBestLongSideFit(width, height, score2, score1);
    RectBestAreaFit:
      newNode := FindPositionForNewNodeBestAreaFit(width, height, score1, score2);
  end;

  // Cannot fit the current rectangle.
  if newNode.height = 0 then
    begin
      score1 := MaxInt;
      score2 := MaxInt;
    end;

  result := newNode;
end;

{ Computes the ratio of used surface area. }
function TBinPacker.Occupancy: float;
var
  usedSurfaceArea: longint;
  i: integer;
begin
  usedSurfaceArea := 0;
  for i := 0 to usedRectangles.Count - 1 do
    usedSurfaceArea += usedRectangles[i].width * usedRectangles[i].height;
  result := usedSurfaceArea / (binWidth * binHeight);
end;

function TBinPacker.FindPositionForNewNodeBottomLeft(width, height: integer; var bestY, bestX: integer): TRect;
var
  i,
  topSideY: integer;
  bestNode: TRect;
begin
  bestY := MaxInt;
  for i := 0 to freeRectangles.Count - 1 do
    begin
      // Try to place the rectangle in upright (non-flipped) orientation.
      if (freeRectangles[i].width >= width) and (freeRectangles[i].height >= height) then
        begin
          topSideY := freeRectangles[i].y + height;
          if (topSideY < bestY) or ((topSideY = bestY) and (freeRectangles[i].x < bestX)) then
            begin
              bestNode.x := freeRectangles[i].x;
              bestNode.y := freeRectangles[i].y;
              bestNode.width := width;
              bestNode.height := height;
              bestY := topSideY;
              bestX := freeRectangles[i].x;
            end;
        end;
      if allowRotations and (freeRectangles[i].width >= height) and (freeRectangles[i].height >= width) then
        begin
          topSideY := freeRectangles[i].y + width;
          if (topSideY < bestY) or ((topSideY = bestY) and (freeRectangles[i].x < bestX)) then
            begin
              bestNode.x := freeRectangles[i].x;
              bestNode.y := freeRectangles[i].y;
              bestNode.width := height;
              bestNode.height := width;
              bestY := topSideY;
              bestX := freeRectangles[i].x;
            end;
        end;
    end;
  result := bestNode;
end;

function TBinPacker.FindPositionForNewNodeBestShortSideFit(width, height: integer; var bestShortSideFit, bestLongSideFit: integer): TRect;
var
  bestNode: TRect;
  i,
  leftoverHoriz,
  leftoverVert,
  shortSideFit,
  longSideFit,
  flippedLeftoverHoriz,
  flippedLeftoverVert,
  flippedShortSideFit,
  flippedLongSideFit: integer;
begin
  bestShortSideFit := MaxInt;
  for i := 0 to freeRectangles.Count - 1 do
    begin
      // Try to place the rectangle in upright (non-flipped) orientation.
      if (freeRectangles[i].width >= width) and (freeRectangles[i].height >= height) then
        begin
          leftoverHoriz := Abs(freeRectangles[i].width - width);
          leftoverVert := Abs(freeRectangles[i].height - height);
          shortSideFit := Min(leftoverHoriz, leftoverVert);
          longSideFit := Max(leftoverHoriz, leftoverVert);

          if (shortSideFit < bestShortSideFit) or ((shortSideFit = bestShortSideFit) and (longSideFit < bestLongSideFit)) then
            begin
              bestNode.x := freeRectangles[i].x;
              bestNode.y := freeRectangles[i].y;
              bestNode.width := width;
              bestNode.height := height;
              bestShortSideFit := shortSideFit;
              bestLongSideFit := longSideFit;
            end;
        end;

      if allowRotations and (freeRectangles[i].width >= height) and (freeRectangles[i].height >= width) then
        begin
          flippedLeftoverHoriz := Abs(freeRectangles[i].width - height);
          flippedLeftoverVert := Abs(freeRectangles[i].height - width);
          flippedShortSideFit := Min(flippedLeftoverHoriz, flippedLeftoverVert);
          flippedLongSideFit := Max(flippedLeftoverHoriz, flippedLeftoverVert);

          if (flippedShortSideFit < bestShortSideFit) or ((flippedShortSideFit = bestShortSideFit) and (flippedLongSideFit < bestLongSideFit)) then
            begin
              bestNode.x := freeRectangles[i].x;
              bestNode.y := freeRectangles[i].y;
              bestNode.width := height;
              bestNode.height := width;
              bestShortSideFit := flippedShortSideFit;
              bestLongSideFit := flippedLongSideFit;
            end;
        end;
    end;
  result := bestNode;
end;

function TBinPacker.FindPositionForNewNodeBestLongSideFit(width, height: integer; var bestShortSideFit, bestLongSideFit: integer): TRect;
var
  bestNode: TRect;
  i: integer;
  leftoverHoriz,
  leftoverVert,
  shortSideFit,
  longSideFit: integer;
begin
  bestLongSideFit := MaxInt;

  for i := 0 to freeRectangles.Count - 1 do
    begin
      // Try to place the rectangle in upright (non-flipped) orientation.
      if (freeRectangles[i].width >= width) and (freeRectangles[i].height >= height) then
        begin
          leftoverHoriz := Abs(freeRectangles[i].width - width);
          leftoverVert := Abs(freeRectangles[i].height - height);
          shortSideFit := Min(leftoverHoriz, leftoverVert);
          longSideFit := Max(leftoverHoriz, leftoverVert);

          if (longSideFit < bestLongSideFit) or ((longSideFit = bestLongSideFit) and (shortSideFit < bestShortSideFit)) then
            begin
              bestNode.x := freeRectangles[i].x;
              bestNode.y := freeRectangles[i].y;
              bestNode.width := width;
              bestNode.height := height;
              bestShortSideFit := shortSideFit;
              bestLongSideFit := longSideFit;
            end;
        end;

      if allowRotations and (freeRectangles[i].width >= height) and (freeRectangles[i].height >= width) then
        begin
          leftoverHoriz := Abs(freeRectangles[i].width - height);
          leftoverVert := Abs(freeRectangles[i].height - width);
          shortSideFit := Min(leftoverHoriz, leftoverVert);
          longSideFit := Max(leftoverHoriz, leftoverVert);

          if (longSideFit < bestLongSideFit) or ((longSideFit = bestLongSideFit) and (shortSideFit < bestShortSideFit)) then
            begin
              bestNode.x := freeRectangles[i].x;
              bestNode.y := freeRectangles[i].y;
              bestNode.width := height;
              bestNode.height := width;
              bestShortSideFit := shortSideFit;
              bestLongSideFit := longSideFit;
            end;
        end;
    end;

  result := bestNode;
end;

function TBinPacker.FindPositionForNewNodeBestAreaFit(width, height: integer; var bestAreaFit, bestShortSideFit: integer): TRect;
var
  bestNode: TRect;
  i,
  areaFit,
  leftoverHoriz,
  leftoverVert,
  shortSideFit: integer;
begin
  bestAreaFit := MaxInt;

  for i := 0 to freeRectangles.Count - 1 do
    begin
      areaFit := freeRectangles[i].width * freeRectangles[i].height - width * height;

      // Try to place the rectangle in upright (non-flipped) orientation.
      if (freeRectangles[i].width >= width) and (freeRectangles[i].height >= height) then
        begin
          leftoverHoriz := Abs(freeRectangles[i].width - width);
          leftoverVert := Abs(freeRectangles[i].height - height);
          shortSideFit := Min(leftoverHoriz, leftoverVert);

          if (areaFit < bestAreaFit) or ((areaFit = bestAreaFit) and (shortSideFit < bestShortSideFit)) then
            begin
              bestNode.x := freeRectangles[i].x;
              bestNode.y := freeRectangles[i].y;
              bestNode.width := width;
              bestNode.height := height;
              bestShortSideFit := shortSideFit;
              bestAreaFit := areaFit;
            end;
        end;

      if allowRotations and (freeRectangles[i].width >= height) and (freeRectangles[i].height >= width) then
        begin
          leftoverHoriz := Abs(freeRectangles[i].width - height);
          leftoverVert := Abs(freeRectangles[i].height - width);
          shortSideFit := Min(leftoverHoriz, leftoverVert);

          if (areaFit < bestAreaFit) or ((areaFit = bestAreaFit) and (shortSideFit < bestShortSideFit)) then
            begin
              bestNode.x := freeRectangles[i].x;
              bestNode.y := freeRectangles[i].y;
              bestNode.width := height;
              bestNode.height := width;
              bestShortSideFit := shortSideFit;
              bestAreaFit := areaFit;
          end;
        end;
    end;

  result := bestNode;
end;

function TBinPacker.CommonIntervalLength(i1start, i1end, i2start, i2end: integer): integer;
begin
  if (i1end < i2start) or (i2end < i1start) then
    exit(0);
  result := Min(i1end, i2end) - Max(i1start, i2start);
end;

function TBinPacker.ContactPointScoreNode(x, y, width, height: integer): integer;
var
  i,
  score: integer;
begin
  score := 0;

  if (x = 0) or (x + width = binWidth) then
    score += height;
  if (y = 0) or (y + height = binHeight) then
    score += width;

  for i := 0 to usedRectangles.Count - 1 do
    begin
      if (usedRectangles[i].x = x + width) or (usedRectangles[i].x + usedRectangles[i].width = x) then
        score += CommonIntervalLength(usedRectangles[i].y, usedRectangles[i].y + usedRectangles[i].height, y, y + height);
      if (usedRectangles[i].y = y + height) or (usedRectangles[i].y + usedRectangles[i].height = y) then
        score += CommonIntervalLength(usedRectangles[i].x, usedRectangles[i].x + usedRectangles[i].width, x, x + width);
    end;
 
  result := score;
end;

function TBinPacker.FindPositionForNewNodeContactPoint(width, height: integer; var bestContactScore: integer): TRect;
var
  bestNode: TRect;
  i,
  score: integer;
begin
  bestContactScore := -1;
  for i := 0 to freeRectangles.Count - 1 do
    begin
      // Try to place the rectangle in upright (non-flipped) orientation.
      if (freeRectangles[i].width >= width) and (freeRectangles[i].height >= height) then
        begin
          score := ContactPointScoreNode(freeRectangles[i].x, freeRectangles[i].y, width, height);
          if (score > bestContactScore) then
            begin
              bestNode.x := freeRectangles[i].x;
              bestNode.y := freeRectangles[i].y;
              bestNode.width := width;
              bestNode.height := height;
              bestContactScore := score;
            end;
        end;
      if allowRotations and (freeRectangles[i].width >= height) and (freeRectangles[i].height >= width) then
        begin
          score := ContactPointScoreNode(freeRectangles[i].x, freeRectangles[i].y, height, width);
          if (score > bestContactScore) then
            begin
              bestNode.x := freeRectangles[i].x;
              bestNode.y := freeRectangles[i].y;
              bestNode.width := height;
              bestNode.height := width;
              bestContactScore := score;
            end;
        end;
    end;
  result := bestNode;
end;

function TBinPacker.SplitFreeNode(freeNode: TRect; var usedNode: TRect): boolean;
var
  newNode: TRect;
begin
  // Test with SAT if the rectangles even intersect.
  if (usedNode.x >= freeNode.x + freeNode.width) or (usedNode.x + usedNode.width <= freeNode.x) or
    (usedNode.y >= freeNode.y + freeNode.height) or (usedNode.y + usedNode.height <= freeNode.y) then
      exit(false);

  if (usedNode.x < freeNode.x + freeNode.width) and (usedNode.x + usedNode.width > freeNode.x) then
    begin
      // New node at the top side of the used node.
      if (usedNode.y > freeNode.y) and (usedNode.y < freeNode.y + freeNode.height) then
        begin
          newNode := freeNode;
          newNode.height := usedNode.y - newNode.y;
          freeRectangles.Add(newNode);
        end;

      // New node at the bottom side of the used node.
      if usedNode.y + usedNode.height < freeNode.y + freeNode.height then
        begin
          newNode := freeNode;
          newNode.y := usedNode.y + usedNode.height;
          newNode.height := freeNode.y + freeNode.height - (usedNode.y + usedNode.height);
          freeRectangles.Add(newNode);
        end;
    end;

  if (usedNode.y < freeNode.y + freeNode.height) and (usedNode.y + usedNode.height > freeNode.y) then
    begin
      // New node at the left side of the used node.
      if (usedNode.x > freeNode.x) and (usedNode.x < freeNode.x + freeNode.width) then
        begin
          newNode := freeNode;
          newNode.width := usedNode.x - newNode.x;
          freeRectangles.Add(newNode);
        end;

      // New node at the right side of the used node.
      if (usedNode.x + usedNode.width < freeNode.x + freeNode.width) then
        begin
          newNode := freeNode;
          newNode.x := usedNode.x + usedNode.width;
          newNode.width := freeNode.x + freeNode.width - (usedNode.x + usedNode.width);
          freeRectangles.Add(newNode);
        end;
    end;

  result := true;
end;

procedure TBinPacker.PruneFreeList;
var
  i, j: integer;
begin
  i := 0;
  while i < freeRectangles.Count do
    begin
      j := i + 1;
      while j < freeRectangles.Count do
        begin
          if (IsContainedIn(freeRectangles[i], freeRectangles[j])) then
            begin
              freeRectangles.Delete(i);
              Dec(i);
              break;
            end;
          if (IsContainedIn(freeRectangles[j], freeRectangles[i])) then
            begin
              freeRectangles.Delete(j);
              Dec(j);
            end;
          Inc(j);
        end;
      Inc(i);
    end;
end;

function TBinPacker.IsContainedIn(a, b: TRect): boolean;
begin
  result := (a.x >= b.x) and 
            (a.y >= b.y) and 
            (a.x + a.width <= b.x + b.width) and 
            (a.y + a.height <= b.y + b.height);
end;

destructor TBinPacker.Destroy; 
begin
  usedRectangles.Free;
  freeRectangles.Free;
  inherited;
end;

constructor TBinPacker.Create(width, height: integer; rotations: boolean);
begin
  binWidth := width;
  binHeight := height;
  allowRotations := rotations;
  usedRectangles := TRectList.Create;
  freeRectangles := TRectList.Create;
  freeRectangles.Add(RectMake(0, 0, width, height));
end;

end.