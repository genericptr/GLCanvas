{
    Copyright (c) 2021 by Ryan Joseph

    GLCanvas Test #13
    
    Testing bin packer
}
{$mode objfpc}

program Test13;
uses
  FGL, RectangleBinPack,
  GLCanvas;

const
  window_size_width = 512;
  window_size_height = 512;

type
  TNode = class
    rect: TRect;
    color: TColor;
  end;
  TNodeList = specialize TFPGObjectList<TNode>;

var
  packer: TBinPacker;
  nodes: TNodeList;

procedure AddRect(min: integer = 128; max: integer = 512);
var
  node: TNode;
begin
  node := TNode.Create;
  node.rect := packer.Insert(Rand(min, max), Rand(min, max));
  // TODO: if the height is 0 we can't find a place
  node.rect.show;
  node.color := RGBA(FRand(0, 1), FRand(0, 1), FRand(0, 1), 1);
  nodes.Add(node);
end;

procedure EventCallback(event: TEvent);
begin
  if event.EventType = TEventType.KeyDown then
    AddRect;
end; 

var
  node: TNode;
  i: integer;
  time: double;
begin
  SetupCanvas(window_size_width, window_size_height, @EventCallback);

  packer := TBinPacker.Create(1024 * 8, 1024 * 8, false);
  nodes := TNodeList.Create;

  time := GetTime;
  for i := 1 to 15 do
    AddRect;
  writeln('pack time: ', Trunc((GetTime - time) * 1000), 'ms');

  SetViewTransform(0, 0, 0.1);
  SetWindowTitle('Press any key to add rectangles');
  
  while IsRunning do
    begin
      ClearBackground;

      for node in nodes do
        begin
          FillRect(node.rect, node.color);
          StrokeRect(node.rect, TColor.Black);
        end;

      SwapBuffers;
    end;

  packer.Free;
  nodes.Free;

  QuitApp;
end.