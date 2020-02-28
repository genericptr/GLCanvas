{$mode objfpc}
{$assertions on}

program tgui10;
uses
  CThreads, FGL, SysUtils, VectorMath, GeometryTypes,
  GLCanvas, GLGUI, OS8Theme, GLPT, GL;

procedure EventCallback(event: pGLPT_MessageRec);
begin
  if PollWindowEvents(event) then
    exit;
end; 

type
  TCustomCell = class (TTextAndImageCell)
    protected
      procedure Initialize; override;
      procedure LayoutSubviews; override;  
    private
      labelView: TTextView;
      button: TButton;
  end;

procedure TCustomCell.Initialize;
begin
  inherited;

  labelView := TTextView.Create;
  labelView.SetFont(FontForControlSize(TControlSize.Mini));
  labelView.SetStringValue('My text label');
  labelView.SetWidthTracksContainer(true);
  labelView.SetTextColor(RGBA(0.2, 1));
  AddSubview(labelView);

  button := TButton.Create('Click Me', 0, TControlSize.Small);
  AddSubview(button);
end;

procedure TCustomCell.LayoutSubviews;
var
  newFrame: TRect;
begin
  inherited;

  if textView.IsReadyToLayout then
    begin
      // set text view frame
      newFrame := textView.GetFrame;
      newFrame.origin.y -= 8;
      textView.SetFrame(newFrame);

      // set label frame
      newFrame := textView.GetFrame;
      newFrame.origin.y := newFrame.MaxY + 4;
      labelView.SetFrame(newFrame);

      // button
      button.LayoutSubviews;
      newFrame := RectMake(GetWidth - (button.GetContainerFrame.width + 10), 0, 0, 20);
      newFrame := RectCenterY(newFrame, GetBounds);
      button.SetFrame(newFrame);
    end;
end;

procedure SetupGUI;
var
  window: TWindow;
  scrollView: TScrollView;
  tableView: TTableView;
  cells: TCellList;
  cell: TCustomCell;
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
      cell := TCustomCell.Create;
      cell.SetStringValue('My Text Cell ---> '+IntToStr(i));
      cell.SetImageValue(cellImage[i]);
      cell.SetImageTitleMargin(4);
      cell.SetFont(FontForControlSize(TControlSize.Small));

      cell.labelView.SetStringValue('Label cell #'+IntToStr(i));
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