{$mode objfpc}
{$assertions on}

program tgui15;
uses
  CThreads, FGL, SysUtils, VectorMath, GeometryTypes,
  GLCanvas, GLGUI, OS8Theme, GLPT, GL;

procedure EventCallback(event: pGLPT_MessageRec);
begin
  if PollWindowEvents(event) then
    exit;
end; 

procedure SetupGUI;
var
  window: TWindow;
  scrollView: TScrollView;
  tableView: TTableView;
  cells: TCellList;
  cell: TTextAndImageCell;
  cellImage: TTextureSheet;
  i: integer;
begin
  LoadOS8Theme;

  cellImage := TTextureSheet.Create('iso-64x64-building.png', V2(64, 64));

  // TODO: how should we do this??
  MainPlatformWindow := GLCanvasState.window;  

  window := TWindow.Create;
  window.MakeKeyAndOrderFront;

  cells := TCellList.Create;
  for i := 0 to 50 - 1 do
    begin
      cell := TTextAndImageCell.Create;
      cell.SetStringValue('My Text Cell ---> '+IntToStr(i));
      cell.SetImageValue(cellImage[i]);
      cell.SetImageTitleMargin(4);
      cell.SetFont(FontForControlSize(TControlSize.Small));
      cells.Add(cell);
    end;

  tableView := TTableView.Create(RectMake(0, 0, 300, 300));
  tableView.SetCells(cells);
  tableView.SetCellSpacing(1);
  tableView.SetCellHeight(32);
  tableView.SetLastColumnTracksWidth(true);
  tableView.SetSelectionType(TTableViewSelection.Single);
  tableView.SetEnableDragSelection(true);

  scrollView := TScrollView.Create(RectMake(50, 50, 300, 300));
  scrollView.SetHorizontalScroller(TScroller.Create);
  scrollView.SetVerticalScroller(TScroller.Create);
  scrollView.SetContentView(tableView);

  window.AddSubview(scrollView);
end;

begin
  SetupCanvas(480, 480, @EventCallback);
  SetupGUI;

  while IsRunning do
    begin
      ClearBackground;
      UpdateWindows;
      SwapBuffers;
    end;

  QuitApp;
end.