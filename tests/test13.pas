{
    Copyright (c) 2021 by Ryan Joseph

    GLCanvas Test #13
    
    Testing bin packer
}
{$mode objfpc}

program Test13;
uses
  CThreads, GeometryTypes, FGL, RectangleBinPack,
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
  node: TNode;
  nodes: TNodeList;
  i: integer;
  time: double;
begin
  SetupCanvas(window_size_width, window_size_height);

  packer := TBinPacker.Create(window_size_width, window_size_height, false);
  nodes := TNodeList.Create;

  time := GetTime;
  for i := 0 to 256 - 1 do
    begin
      node := TNode.Create;
      node.rect := packer.Insert(Rand(16, 64), Rand(16, 64));
      node.color := RGBA(FRand(0, 1), FRand(0, 1), FRand(0, 1), 1);
      nodes.Add(node);
    end;
  writeln('pack time: ', Trunc(GetTime - time) * 1000, 'ms');

  while IsRunning do
    begin
      ClearBackground;

      for node in nodes do
        FillRect(node.rect, node.color);
      
      for node in nodes do
        StrokeRect(node.rect, TColor.Black);

      SwapBuffers;
    end;

  packer.Free;
  nodes.Free;

  QuitApp;
end.