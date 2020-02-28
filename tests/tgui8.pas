{$mode objfpc}
{$modeswitch advancedrecords}
{$assertions on}

program tgui8;
uses
  CThreads, FreeTypeH, FGL, GLFreeTypeFont, SysUtils, VectorMath, GeometryTypes,
  GLCanvas, GLGUI, GLPT, GL;

procedure EventCallback(event: pGLPT_MessageRec);
begin
  if PollWindowEvents(event) then
    exit;
end; 

var
  sliderTrack: TTextureSheet;
  sliderThumb: TTexture;


type
  TDataItem = record
    name: string;
    id: integer;
    class operator = (left: TDataItem; right: TDataItem): boolean;
  end;
  PDataItem = ^TDataItem;
  TDataItemList = specialize TFPGList<TDataItem>;

class operator TDataItem.= (left: TDataItem; right: TDataItem): boolean;
begin
  result := left.name = right.name;
end;

type
  TTableDataSource = class (ITableViewDataSource)
    public
      constructor Create;
    private
      items: TDataItemList;
      function TableViewValueForRow (tableView: TTableView; column: TTableColumn; row: integer): pointer;
      function TableViewNumberOfRows (tableView: TTableView): integer;
  end;

constructor TTableDataSource.Create;
begin
  items := TDataItemList.Create;
end;

function TTableDataSource.TableViewValueForRow (tableView: TTableView; column: TTableColumn; row: integer): pointer;
var
  item: PDataItem;
begin
  item := TFPSList(items)[row];

  if column.id = 100 then
    result := pointer(ansistring(item^.name))
  else
    result := pointer(ansistring(IntToStr(item^.id)));
end;

function TTableDataSource.TableViewNumberOfRows (tableView: TTableView): integer;
begin
  result := items.Count;
end;

type
  TCustomScroller = class (TScroller)
    function GetHandleFrame: TRect; override;
    procedure DrawHandle(rect: TRect); override;
    procedure DrawTrack(rect: TRect); override;
  end;

function TCustomScroller.GetHandleFrame: TRect;
begin
  result := inherited;
  result.size := sliderThumb.GetSize;
end;

procedure TCustomScroller.DrawHandle(rect: TRect);
begin
  DrawTexture(sliderThumb, rect);
  if IsDragging then
    FillRect(rect, RGBA(0, 0, 1, 0.3));
end;

procedure TCustomScroller.DrawTrack(rect: TRect);
begin
  Draw9PartImage(sliderTrack, rect);
end;

var
  font: TGLFreeTypeFont;

procedure LoadFreeType;
var
  lib: PFT_Library;
begin
  Assert(FT_Init_FreeType(lib) = 0, 'FT_Init_FreeType');
  font := TGLFreeTypeFont.Create(lib, '/System/Library/Fonts/Geneva.dfont');
  font.Render(12);
  FT_Done_FreeType(lib);
end;

procedure SetupGUI;
var
  window: TWindow;
  scrollView: TScrollView;
  tableView: TTableView;
  dataSource: TTableDataSource;
  item: TDataItem;
  i: integer;
begin
  LoadFreeType;

  sliderTrack := TTextureSheet.Create('scroller_track.png', V2(4, 4));
  sliderThumb := TTexture.Create('scroller_thumb.png');

  // TODO: how should we do this??
  MainPlatformWindow := GLCanvasState.window;  

  window := TWindow.Create(TWindow.ScreenRect);
  window.SetMoveableByBackground(false);
  window.MakeKeyAndOrderFront;

  dataSource := TTableDataSource.Create;
  for i := 0 to 20 - 1 do
    begin
      item.name := 'My Text Cell'+IntToStr(i);
      item.id := i * 100;
      dataSource.items.Add(item);
    end;

  tableView := TTableView.Create(RectMake(0, 0, 130, 300));
  tableView.SetCellClass(TTextAndImageCell);
  tableView.SetCellFont(font);
  tableView.SetCellSpacing(2);
  tableView.SetCellHeight(18);
  tableView.SetSelectionType(TTableViewSelection.Multiple);
  tableView.SetEnableDragSelection(true);
  tableView.SetLastColumnTracksWidth(true);
  tableView.AddColumn(100, 'Name');
  tableView.AddColumn(200, 'ID');
  tableView.SetDataSource(dataSource);

  scrollView := TScrollView.Create(RectMake(50, 200, 200, 200));
  scrollView.SetHorizontalScroller(TCustomScroller.Create);
  scrollView.SetVerticalScroller(TCustomScroller.Create);
  scrollView.SetContentView(tableView);
  window.AddSubview(scrollView);
end;

begin
  SetupCanvas(480, 640, @EventCallback);
  SetupGUI;

  while IsRunning do
    begin
      ClearBackground;
      UpdateWindows;
      SwapBuffers;
    end;

  QuitApp;
end.