
{$ifdef INTERFACE}


type
  TImageKind = (
      Stretched,
      Tiled,
      ScaledTwoAxis,
      ScaledAnyAxis
    );

type
  TImage = class
    kind: TImageKind;
    parts: array[0..32] of pointer; {TTexture}
  end;

{
  TButton (
    background: image/color
    border-color: color
    border-width: int
    text-size: 100%
    padding: 10px;
  )
}
{ Styles }
type
  TStyle = record
    backgroundColor: TColor;
    backgroundImage: TImage;
    borderColor: TColor;
    borderWidth: single;
    textSize: single; // 0..1
    padding: single;
  end;
  TStyles = specialize TFPGMap<String, TStyle>;

{$endif}

{$ifdef IMPLEMENTATION}

procedure Draw3PartImage(parts: TTextureArray; frame: TRect; vertical: boolean = false); 
var
  rect: TRect;
begin
  if vertical then
    begin
      rect := RectMake(frame.MinX, frame.MinY, parts[0].GetWidth, parts[0].GetHeight);
      DrawTexture(parts[0], rect);

      rect.origin.y += parts[0].GetHeight;
      rect.size.height := frame.Height - (parts[0].GetHeight + parts[2].GetHeight);
      DrawTexture(parts[1], rect);

      rect.origin.y := rect.MaxY;
      rect.size.height := parts[2].GetHeight;
      DrawTexture(parts[2], rect);
    end
  else
    begin
      rect := RectMake(frame.MinX, frame.MinY, parts[0].GetWidth, {parts[0].GetHeight}frame.Height);
      DrawTexture(parts[0], rect);

      rect.origin.x += parts[0].GetWidth;
      rect.size.width := frame.Width - (parts[0].GetWidth + parts[2].GetWidth);
      DrawTexture(parts[1], rect);

      rect.origin.x := rect.MaxX;
      rect.size.width := parts[2].GetWidth;
      DrawTexture(parts[2], rect);
    end;
end;

procedure Draw9PartImage(parts: TTextureSheet; frame: TRect); 
var
  texture: TTexture;
  rect: TRect;
  cornerSize: float;
begin
  cornerSize := parts[0].GetSize.Max;

  // corners
  texture := parts[0];
  rect.size := V2(cornerSize, cornerSize);
  rect.origin := V2(frame.MinX, frame.MinY);
  DrawTexture(texture, rect);

  texture := parts[2];
  rect.size := V2(cornerSize, cornerSize);
  rect.origin := V2(frame.MaxX - cornerSize, frame.MinY);
  DrawTexture(texture, rect);

  texture := parts[8];
  rect.size := V2(cornerSize, cornerSize);
  rect.origin := V2(frame.MaxX - cornerSize, frame.MaxY - cornerSize);
  DrawTexture(texture, rect);

  texture := parts[6];
  rect.size := V2(cornerSize, cornerSize);
  rect.origin := V2(frame.MinX, frame.MaxY - cornerSize);
  DrawTexture(texture, rect);

  // middles
  texture := parts[1];
  rect.size := V2(frame.Width - (cornerSize * 2), cornerSize);
  rect.origin := V2(frame.MinX + cornerSize, frame.MinY);
  DrawTexture(texture, rect);

  texture := parts[7];
  rect.size := V2(frame.Width - (cornerSize * 2), cornerSize);
  rect.origin := V2(frame.MinX + cornerSize, frame.MaxY - cornerSize);
  DrawTexture(texture, rect);

  texture := parts[3];
  rect.size := V2(cornerSize, frame.Height - (cornerSize * 2));
  rect.origin := V2(frame.MinX, frame.MinY + cornerSize);
  DrawTexture(texture, rect);

  texture := parts[5];
  rect.size := V2(cornerSize, frame.Height - (cornerSize * 2));
  rect.origin := V2(frame.MaxX - cornerSize, frame.MinY + cornerSize);
  DrawTexture(texture, rect);

  // center
  texture := parts[4];
  rect.size := V2(frame.Width - (cornerSize * 2), frame.Height - (cornerSize * 2));
  rect.origin := V2(frame.MinX + cornerSize, frame.MinY + cornerSize);
  DrawTexture(texture, rect);
end;


{$endif}
