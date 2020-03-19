{$mode objfpc}
{$modeswitch advancedrecords}
{$modeswitch autoderef}
{$include targetos}

program Test5;
uses
  CThreads, GeometryTypes, VectorMath, Math, FGL,
  GLPT, GLCanvas;

const
  window_size_width = 600;
  window_size_height = 600;

type
  TSprite = class
    private
      m_position: TVec2;
      m_scale: single;
      m_rotation: single;
      procedure SetPosition(newValue: TVec2);
      procedure SetScale(newValue: single);
      procedure SetRotation(newValue: single);
      procedure UpdateTransform;
    public
      size: TVec2;
      anchor: TVec2;
      bounds: TRect;
      frame: TRect;
      transform: TMat4;
      constructor Create(texture: TTexture);
      procedure Draw;
      property Position: TVec2 read m_position write SetPosition;
      property Rotation: single read m_rotation write SetRotation;
      property Scale: single read m_scale write SetScale;
      property Width: single read size.x;
      property Height: single read size.y;
    private
      class var originalScale: single;
      class var originalPosition: TVec2;
      class var originalRotation: single;
    private
      texture: TTexture;
  end;
  TSpriteList = specialize TFPGList<TSprite>;

var
  Sprites: TSpriteList;
  Texture: TTexture;
  mouse: TVec2;

constructor TSprite.Create(texture: TTexture);
begin
  self.texture := texture;
  size := texture.GetSize;
  scale := 1;
  rotation := 0;
  position := V2(100, 100);
  anchor := V2(0.5, 0.5);
end;

procedure TSprite.SetPosition(newValue: TVec2);
begin
  m_position := newValue;
  UpdateTransform;
end;

procedure TSprite.SetScale(newValue: single);
begin
  m_scale := newValue;
  UpdateTransform;
end;

procedure TSprite.SetRotation(newValue: single);
begin
  m_rotation := newValue;
  UpdateTransform;
end;

procedure TSprite.UpdateTransform;
begin
  transform := TMat4.Translate(position.x, position.y, 1) * 
               TMat4.RotateZ(rotation) *
               TMat4.Scale(scale, scale, 1);
end;


procedure TSprite.Draw; 
begin
  // set the bounding frame in local (model) coordinates
  bounds := RectMake(-size.width * anchor.x, -size.height * anchor.y, size);

  PushModelTransform(transform);

  if Sprites.Last = self then
    FillRect(bounds.Inset(-4, -4), RGBA(0, 1));

  DrawTexture(texture, bounds);
  PopModelTransform;

  // set frame in screen coordinates
  frame.origin := position + bounds.origin;
  frame.size := bounds.size;
end;

type
   GLPT_MessageRecHelper = record helper for GLPT_MessageRec
     function TouchLocation: TVec2i;
     function GestureLocation: TVec2i;
   end; 

function GLPT_MessageRecHelper.TouchLocation: TVec2i;
begin
  result := V2i(params.touch.x, params.touch.y);
end;

function GLPT_MessageRecHelper.GestureLocation: TVec2i;
begin
  result := V2i(params.gesture.x, params.gesture.y);
end;

function PointIsInRotatedRectangle(rect: TRect; rotation: single; point: TVec2): boolean;
var
  local: TVec2;
  transform: TMat4;
begin
  transform := TMat4.RotateZ(-rotation);
  local := point - rect.origin;
  result := rect.ContainsPoint((transform * local) + rect.origin);
end;

function FindSprite(at: TVec2): TSprite;
var
  sprite: TSprite;
begin
  result := nil;
  for sprite in sprites do
    if PointIsInRotatedRectangle(sprite.frame, sprite.rotation, at) then
      exit(sprite);
end;

procedure EventCallback(event: pGLPT_MessageRec);
var
  sprite: TSprite;
begin
  case event^.mcode of
    //GLPT_MESSAGE_TOUCH_DOWN:
    //  writeln('touch down ', event.TouchLocation.tostr, ' tapCount=', event.params.touch.tapCount);
    //GLPT_MESSAGE_TOUCH_UP:
    //  writeln('touch up ', event.TouchLocation.tostr);
    //GLPT_MESSAGE_TOUCH_MOTION:
    //  writeln('touch motion ', event.TouchLocation.tostr);
    GLPT_MESSAGE_GESTURE_TAP:
      begin
        sprite := FindSprite(event.GestureLocation);
        if sprite = nil then
          begin
            sprite := TSprite.Create(texture);
            sprite.position := event.GestureLocation;
            sprites.Add(sprite);
          end
        else
          begin
            sprites.Remove(sprite);
            sprites.Add(sprite);
          end;
      end;
    GLPT_MESSAGE_GESTURE_PINCH:
      begin
        sprite := sprites.Last;
        case event.params.gesture.state of
          gsBegan:
            sprite.originalScale := sprite.scale;
          gsChanged:
            sprite.scale := sprite.originalScale * event.params.gesture.scale;
          gsEnded:
            ;
        end;
      end;
    GLPT_MESSAGE_GESTURE_SWIPE:
     begin
       writeln('swipe ', event.GestureLocation.tostr, 
               ' direction=', event.params.gesture.direction);
     end;
    GLPT_MESSAGE_GESTURE_PAN:
      begin
        sprite := sprites.Last;
        case event.params.gesture.state of
          gsBegan:
            sprite.originalPosition := sprite.position;
          gsChanged:
            sprite.position := sprite.originalPosition + V2(event.params.gesture.translationX, event.params.gesture.translationY);
          gsEnded:
            ;
        end;
      end;
    GLPT_MESSAGE_GESTURE_ROTATE:
      begin
        sprite := sprites.Last;
        case event.params.gesture.state of
          gsBegan:
            sprite.originalRotation := sprite.rotation;
          gsChanged:
            sprite.rotation := sprite.originalRotation + event.params.gesture.rotation;
          gsEnded:
            ;
        end;
      end;
    GLPT_MESSAGE_GESTURE_LONG_PRESS:
      begin
        //writeln('long press');
      end;
  end;
end; 

var
  sprite: TSprite;
begin
  SetupCanvas(window_size_width, window_size_height, @EventCallback);

  Sprites := TSpriteList.Create;

  {$ifdef target_os_mac}
  Chdir(GLPT_GetBasePath+'/tests');
  texture := TTexture.Create('deer.png');
  {$else}
  texture := TTexture.Create('deer.png');
  {$endif}

  sprite := TSprite.Create(texture);
  sprites.Add(sprite);

  while IsRunning do
    begin
      ClearBackground;
      for sprite in sprites do
        begin
          sprite.Draw;
          StrokeRect(sprite.frame, RGBA(0,0,1,1));
        end;
      SwapBuffers;
    end;

  QuitApp;
end.