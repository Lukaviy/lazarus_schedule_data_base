unit UScheduleForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, mysql55conn, db, FileUtil, Forms, Controls,
  Graphics, Dialogs, Grids, DbCtrls, StdCtrls, ExtCtrls, Buttons, Math, UDBData,
  umetadata, UFilters, LCLIntf, LCLProc, ComCtrls, EditBtn,
  UExpandPanel, UScheduleGrid, USQLQueryCreator, UEditForm;

type

  { TScheduleForm }

  TLookupRecord = record
    Value: String;
    ID: Integer;
  end;

  TCellIndex = record
    Column: Integer;
    Row: Integer;
  end;

  TRects = array of TRect;

  TScheduleItem = object
    Fields: Strings;
    IsVisible: array of boolean;
    CellIndex: TCellIndex;
    BorderRect: TRect;
    Canvas: TCanvas;
    Height: Integer;
    Fill: boolean;
    procedure Draw();
    procedure Draw(aOffset: Integer);
  end;

  TScheduleItems = array of TScheduleItem;
  TStringsArr = array of Strings;

  TTargetHeight = record
    Row: Integer;
    Height: Integer;
  end;

  { TEditCellBtns }

  //TEditClickEvent: procedure(Sender: TObject; ItemIndex: Integer) of object;

  TEditCellBtns = class
  private
    FInsertBtn: TSpeedButton;
    FEditBtn: TSpeedButton;
    FDeleteBtn: TSpeedButton;
    FOwner: TWinControl;
    FTable: TTableInfo;
    FOnInsertClick: TNotifyEvent;
    FOnEditClick: TNotifyEvent;
    FOnDeleteClick: TNotifyEvent;
    FRect: TRect;
    procedure SetInsertClick(aEvent: TNotifyEvent);
    procedure SetEditClick(aEvent: TNotifyEvent);
    procedure SetDeleteClick(aEvent: TNotifyEvent);
    procedure SetRect(aRect: TRect);
  public
    constructor Create(aOwner: TWinControl);
    destructor Destroy();
    property OnInsertClick: TNotifyEvent read FOnInsertClick write SetInsertClick;
    property OnEditClick: TNotifyEvent read FOnEditClick write SetEditClick;
    property OnDeleteClick: TNotifyEvent read FOnDeleteClick write SetDeleteClick;
    property Rect: TRect read FRect write SetRect;
  end;

  TScheduleItemList = class
  private
    FItems: TScheduleItems;
    FCanvas: TCanvas;
    FStringsArr: TStringsArr;
    FScrollBar: TScrollBar;
    FHeight: Integer;
    FVertOffset: Integer;
    FRect: TRect;
    procedure InitItems();
    procedure Draw(Sender: TObject);
    function GetElemHeight(): Integer;
    procedure SetElemHeight(aHeight: Integer);
    function GetElemWidth(): Integer;
    procedure SetElemWidth(aWidth: Integer);
    procedure SetStringsArr(aStringsArr: TStringsArr);
  public
    constructor Create(aOwner: TWinControl);
    destructor Destroy(); override;
    procedure ShowItems();
    property Items: TScheduleItems read FItems write FItems;
    property StringsArr: TStringsArr read FStringsArr write SetStringsArr;
    property ElemHeight: Integer read GetElemHeight write SetElemHeight;
    property ElemWidth: Integer read GetElemWidth write SetElemWidth;
    property ElemRect: TRect read FRect write FRect;
    property Canvas: TCanvas read FCanvas write FCanvas;
  end;

  TLookupResult = array of TLookupRecord;

  TScheduleForm = class(TForm)
    AddFilterButton: TBitBtn;
    RefreshButton: TBitBtn;
    Grid: TScheduleGrid;
    ImageList: TImageList;
    Label3: TLabel;
    Label4: TLabel;
    MenuPanel: TPanel;
    OpenFilterPanelButton: TSpeedButton;
    OpenHideColumnsPanel: TSpeedButton;
    XColumnBox: TComboBox;
    YColumnBox: TComboBox;
    procedure AddFilterButtonClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure GridDblClick(Sender: TObject);
    procedure GridClick(Sender: TObject);
    procedure GridDrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect;
      aState: TGridDrawState);
    procedure OpenHideColumnsPanelClick(Sender: TObject);
    procedure RefreshButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure GridMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure GridMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure GridSelectCell(Sender: TObject; aCol, aRow: Integer;
      var CanSelect: Boolean);
    procedure CheckGroupClick(Sender: TObject; Index: Integer);
    procedure OpenFilterPanelButtonClick(Sender: TObject);
    procedure OnInsertBtnClick(Sender: TObject);
    procedure OnEditBtnClick(Sender: TObject);
    procedure OnDeleteBtnClick(Sender: TObject);
    procedure OnFilterAdd(Sender: TObject);
    procedure OnFilterDel(Sender: TObject);
    procedure OnFilterHeightChange(Sender: TObject);
    procedure XColumnBoxChange(Sender: TObject);
    procedure YColumnBoxChange(Sender: TObject);
    procedure SetDataIsActual();
    procedure SetDataIsNotActual();
  private
    FilterPanel: TExpandPanel;
    VisibleColsPanel: TExpandPanel;
    Table: TTableInfo;
    XTitles: TLookupResult;
    YTitles: TLookupResult;
    FilterList: TFilterList;
    SQLResult: array of array of array of array of String;
    EditCellBtns: TEditCellBtns;
    LastSelectedCell: TCellIndex;
    LastSelItemID: Integer;
    LastOpenedCell: TCellIndex;
    VisibleClmnsChkBox: TCheckGroup;
    VisibleColumns: array of boolean;
    FSomethingChanged: boolean;
    Query: TSQLQueryCreator;
    FColumns: TColumnInfos;
    procedure SetCaptions();
    procedure SetColumnCaptions();
    procedure SetRowCaptions();
    procedure SendQuery();
    procedure FillSQLResult();
    procedure FillXTitles();
    procedure FillYTitles();
    procedure FillLookupResults();
    function GetListHeight(aRow, aCol: Integer): Integer;
    function GetLookupResult(aColIndex: Integer): TLookupResult;
    function CreateLookupQuery(ColumnIndex: Integer): TSQLQueryCreator;
  public
    { public declarations }
  end;

var
  ScheduleForm: TScheduleForm;

implementation

const ElementHeight = 70;

{ TEditCellBtns }

procedure TEditCellBtns.SetInsertClick(aEvent: TNotifyEvent);
begin
  FInsertBtn.OnClick := aEvent;
end;

procedure TEditCellBtns.SetEditClick(aEvent: TNotifyEvent);
begin
  FEditBtn.OnClick := aEvent;
end;

procedure TEditCellBtns.SetDeleteClick(aEvent: TNotifyEvent);
begin
  FDeleteBtn.OnClick := aEvent;
end;

procedure TEditCellBtns.SetRect(aRect: TRect);
const
  Space = 7;
begin
  FRect := aRect;
  with FInsertBtn do begin
    Left := aRect.Right - (Width + Space)*3;
    Top := aRect.Top;
  end;

  with FEditBtn do begin
    Left := aRect.Right - (Width + Space)*2;
    Top := aRect.Top;
  end;

  with FDeleteBtn do begin
    Left := aRect.Right - (Width + Space);
    Top := aRect.Top;
  end;
end;

constructor TEditCellBtns.Create(aOwner: TWinControl);
const
  BtnSize = 20;
begin
  FOwner := aOwner;
  FInsertBtn := TSpeedButton.Create(aOwner);
  with FInsertBtn do begin
    Parent := aOwner;
    Height := BtnSize;
    Width := BtnSize;
  end;

  FEditBtn := TSpeedButton.Create(aOwner);
  with FEditBtn do begin
    Parent := aOwner;
    Height := BtnSize;
    Width := BtnSize;
  end;

  FDeleteBtn := TSpeedButton.Create(aOwner);
  with FDeleteBtn do begin
    Parent := aOwner;
    Height := BtnSize;
    Width := BtnSize;
  end;
end;

destructor TEditCellBtns.Destroy;
begin
  FreeAndNil(FInsertBtn);
  FreeAndNil(FEditBtn);
  FreeAndNil(FDeleteBtn);
end;

{$R *.lfm}

{ TScheduleForm }

procedure TScheduleForm.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  Table := ListOfTables.GetTableByName('Schedule_items');
  Query := TSQLQueryCreator.Create(Table);
  SetLength(VisibleColumns, Table.ColCount - 1);

  Grid := TScheduleGrid.Create(Self);
  with Grid do begin
    Parent := Self;
    Options := [goRowSizing, goHorzLine, goVertLine];
    Top := 10;
    Align := alClient;
    AnchorToNeighbour(akTop, 0, MenuPanel);
    DefaultColWidth := 300;
    DefaultRowHeight := ElementHeight;
    OnDrawCell := @GridDrawCell;
    OnDblClick := @GridDblClick;
    OnSelectCell := @GridSelectCell;
    OnClick := @GridClick;
    OnMouseDown := @GridMouseDown;
    OnMouseMove := @GridMouseMove;
  end;

  FilterPanel := TExpandPanel.Create(Self);
  with FilterPanel do begin
    Parent := Self;
    AnimationSpeed := 5;
    MaxWidth := 400;
    MinWidth := 0;
    Left := Self.Width;
    Height := 500;
    Anchors := [akRight];
    AnchorToNeighbour(akTop, 0, MenuPanel);
    OpeningSide := osLeft;
  end;

  VisibleColsPanel := TExpandPanel.Create(Self);
  with VisibleColsPanel do begin
    Parent := Self;
    AnimationSpeed := 5;
    MaxWidth := 200;
    MinWidth := 0;
    Left := Self.Width;
    Height := 250;
    Anchors := [akRight];
    AnchorToNeighbour(akTop, 0, MenuPanel);
    OpeningSide := osLeft;
  end;

  VisibleClmnsChkBox := TCheckGroup.Create(VisibleColsPanel);
  with VisibleClmnsChkBox do begin
    Parent := VisibleColsPanel;
    Left := 3;
    AutoSize := true;
    Align := alTop;
    Items.AddStrings(GetColCaptions(Table.GetCols(cstAll, [coVisible])));
    for i := 0 to Items.Count - 1 do begin
      Checked[i] := true;
      VisibleColumns[i] := true;
    end;
    OnItemClick := @CheckGroupClick;
  end;

  FilterList := TFilterList.Create(FilterPanel, Table);
  with FilterList do begin
    Parent := FilterPanel;
    Top := 5;
    Align := alTop;
    OnFilterAdd := @Self.OnFilterAdd;
    OnFilterDel := @Self.OnFilterDel;
    OnHeightChange := @OnFilterHeightChange;
  end;

  with Query do begin
    Table := Self.Table;
    FilterList := Self.FIlterList;
  end;

  EditCellBtns := TEditCellBtns.Create(Grid);
  with EditCellBtns do begin
    OnInsertClick := @OnInsertBtnClick;
    OnEditClick := @OnEditBtnClick;
    OnDeleteClick := @OnDeleteBtnClick;
  end;

  FColumns := Table.GetCols(cstAll, [coVisible]);

  XColumnBox.Items.AddStrings(GetColCaptions(FColumns));
  YColumnBox.Items.AddStrings(GetColCaptions(FColumns));
  XColumnBox.ItemIndex := COL_GROUP_ID;
  YColumnBox.ItemIndex := COL_DAY_ID;
  FillLookupResults();
  SetCaptions();
  FillSQLResult();
end;

procedure TScheduleForm.RefreshButtonClick(Sender: TObject);
begin
  if not FilterList.CheckFields() then begin
    ShowMessage('Проверьте заполненность полей фильтра');
    FilterPanel.Open();
    Exit;
  end;
  FillSQLResult();
  Grid.Invalidate();
  FilterPanel.Close();
  SetDataIsActual();
end;

procedure TScheduleForm.AddFilterButtonClick(Sender: TObject);
begin
  FilterPanel.Open();
  VisibleColsPanel.Close();
  FilterList.Add();
end;

procedure TScheduleForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin

end;

procedure TScheduleForm.GridDblClick(Sender: TObject);
var
  TargetHeight: Integer;
  ListHeight: Integer;
begin
  with LastSelectedCell do begin
    ListHeight := GetListHeight(Row, Column);
    if Grid.RowHeights[Row] >= ListHeight then
      TargetHeight := ElementHeight
    else
      TargetHeight := ListHeight;
    Grid.SetRowHeight(Row, TargetHeight);
  end;
  LastOpenedCell := LastSelectedCell;
end;

procedure TScheduleForm.GridClick(Sender: TObject);
begin

end;

procedure TScheduleForm.GridDrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
const
  WarningImgSize = 16;
var
  ScheduleItem: TScheduleItem;
  RowBottom: Integer;
  i: Integer;
begin
  if (aRow > Length(YTitles)) or (aCol > Length(XTitles)) then Exit;
  //if aRow = 0 then
    //Canvas.TextRect(aRect, aRect.Left, aRect.Top, XTitles[aCol].Value);
  if (aCol = 0) and (aRow > 0) then begin
    Grid.Canvas.TextRect(aRect, aRect.Left, aRect.Top + (aRect.Bottom - aRect.Top) div 2 - 8, YTitles[aRow-1].Value);
  end;

  if (aCol > 0) and (aRow > 0) then begin
    i := 0;
    RowBottom := aRect.Bottom;
    while (i <= High(SQLResult[aRow-1][aCol-1])) and (aRect.Top < RowBottom) do begin
      with ScheduleItem do begin
        Canvas := Grid.Canvas;
        Fields := SQLResult[aRow-1][aCol-1][i];
        Height := ElementHeight;
        BorderRect := aRect;
        IsVisible := VisibleColumns;
        aRect.Top += ElementHeight;
        Draw();
      end;
      inc(i);
    end;
    if Grid.RowHeights[aRow] < GetListHeight(aRow, aCol) then
      ImageList.Draw(Grid.Canvas, aRect.Right - WarningImgSize, aRect.Bottom - WarningImgSize, 0, true);
  end;

  //ItemList.Draw(Self);
end;

procedure TScheduleForm.GridMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  col, row: Integer;
begin
  Grid.MouseToCell(X, Y, col, row);
  if (LastOpenedCell.Row = 0) or (LastOpenedCell.Column = 0) or
     (LastOpenedCell.Row = row) and (LastOpenedCell.Column = col)
  then Exit;
    Grid.CloseRow(LastOpenedCell.Row);
end;

procedure TScheduleForm.GridMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
  col, row: Integer;
  CellRect: TRect;
begin
  {Grid.MouseToCell(X, Y, col, row);
  CellRect := Grid.CellRect(col, row);
  LastSelItemID := (Y - CellRect.Top) div ElementHeight;
  with CellRect do
    EditCellBtns.Rect := Rect(Left, Top + ElementHeight * LastSelItemID, Right - 70, Bottom + ElementHeight * LastSelItemID);}
end;

procedure TScheduleForm.GridSelectCell(Sender: TObject; aCol, aRow: Integer;
  var CanSelect: Boolean);
begin
  //(SQLResult = nil) or (aRow-1 > High(YTitles)) or (aCol > High(XTitles))
  if (SQLResult = nil) or (aRow < 0) or (aCol < 0) or
     (aRow-1 > High(SQLResult)) or (aCol-1 > High(SQLResult[aRow-1])) then
    Exit;

  {if (LastSelectedCell.Row <> aRow) and (LastSelectedCell.Row > 0) and (LastSelectedCell.Column > 0) then
    Grid.CloseRow(LastSelectedCell.Row); }

  with LastSelectedCell do begin
    Column := aCol;
    Row := aRow;
  end;
  //Memo1.Text := SQLResult[aRow-1][aCol-1];
end;

procedure TScheduleForm.CheckGroupClick(Sender: TObject; Index: Integer);
begin
  VisibleColumns[Index] := TCheckGroup(Sender).Checked[Index];
  Grid.Invalidate();
end;

procedure TScheduleForm.OpenFilterPanelButtonClick(Sender: TObject);
begin
  //VisibleColsPanel.Open();
  if FilterList.Count = 0 then Exit;
  VisibleColsPanel.Close();
  if FilterPanel.Width > 0 then
    FilterPanel.Close()
  else
    FilterPanel.Open();
end;

procedure TScheduleForm.OnInsertBtnClick(Sender: TObject);
begin
  with LastSelectedCell do
    EditForms.ShowEditForm(Self, Table, 0, @RefreshButtonClick);
end;

procedure TScheduleForm.OnEditBtnClick(Sender: TObject);
begin
  with LastSelectedCell do
    //EditForms.ShowEditForm(Self, Table, StrToInt(SQLResult[Row-1][Column-1][LastSelItemID][COL_ID]), @RefreshButtonClick);
end;

procedure TScheduleForm.OnDeleteBtnClick(Sender: TObject);
begin
  with LastSelectedCell do
    //QueryCreator.DeleteRecordByID(StrToInt(SQLResult[Row-1][Column-1][LastSelItemID][COL_ID]), SQLQuery);
  RefreshButtonClick(Self);
end;

procedure TScheduleForm.OnFilterAdd(Sender: TObject);
begin
  OpenFilterPanelButton.Caption := Format('Фильтры(%d)', [FilterList.Count]);
  SetDataIsNotActual();
end;

procedure TScheduleForm.OnFilterDel(Sender: TObject);
begin
  If FilterList.Count = 0 then FilterPanel.Close();
  OpenFilterPanelButton.Caption := Format('Фильтры(%d)', [FilterList.Count]);
  SetDataIsNotActual();
end;

procedure TScheduleForm.OnFilterHeightChange(Sender: TObject);
begin
  FilterPanel.Height := FilterList.Height;
end;

procedure TScheduleForm.OpenHideColumnsPanelClick(Sender: TObject);
begin
  FilterPanel.Close();
  if VisibleColsPanel.Width > 0 then
    VisibleColsPanel.Close()
  else
    VisibleColsPanel.Open();
end;

procedure TScheduleForm.XColumnBoxChange(Sender: TObject);
begin
  FillXTitles();
  SetColumnCaptions();
  FillSQLResult();
  Grid.Refresh();
end;

procedure TScheduleForm.YColumnBoxChange(Sender: TObject);
begin
  FillYTitles();
  SetRowCaptions();
  FillSQLResult();
  Grid.Refresh();
end;

procedure TScheduleForm.SetDataIsActual;
begin
  FSomethingChanged := false;
  RefreshButton.Enabled := false;
end;

procedure TScheduleForm.SetDataIsNotActual;
begin
  FSomethingChanged := true;
  RefreshButton.Enabled := true;
end;

procedure TScheduleForm.SetCaptions();
begin
  SetColumnCaptions();
  SetRowCaptions();
end;

function TScheduleForm.CreateLookupQuery(ColumnIndex: Integer): TSQLQueryCreator;
begin
  Result := TSQLQueryCreator.Create(TTableInfo(Table.Columns[ColumnIndex].RefTable));
  Result.SelectCols(cstOwn);
  Result.SetOrderBy([COL_ID]);
  Result.SendQuery();
end;

procedure TScheduleForm.SendQuery();
begin;
  Query.SelectCols(cstOwn);
  Query.SendQuery();
end;

procedure TScheduleForm.SetColumnCaptions();
var
  i: Integer;
begin
  Grid.Columns.Clear();
  for i := 0 to High(XTitles) do
    Grid.Columns.Add.Title.Caption := XTitles[i].Value;
  Grid.ColWidths[0] := 96;
end;

procedure TScheduleForm.SetRowCaptions();
begin
  Grid.RowCount := Length(YTitles) + 1;
  Grid.RowHeights[0] := 22;
  {for i := 0 to High(YTitles) do
    Grid.Rows[i+1].Text := YTitles[i].Value;}
end;

function TScheduleForm.GetListHeight(aRow, aCol: Integer): Integer;
begin
  Result := Max(Length(SQLResult[aRow-1][aCol-1])*ElementHeight, ElementHeight);
end;

function TScheduleForm.GetLookupResult(aColIndex: Integer): TLookupResult;
var
  LookupQuery: TSQLQueryCreator;
  i: Integer;
begin
  LookupQuery := CreateLookupQuery(aColIndex);
  SetLength(Result, LookupQuery.SQLQuery.RecordCount);
  i := 0;
  with LookupQuery.SQLQuery do
    while not LookupQuery.SQLQuery.EOF do begin
      if Length(Result) < RecordCount then
        SetLength(Result, RecordCount);
      Result[i].ID := Fields[0].Value;
      Result[i].Value := Fields[1].Value;
      Next();
      inc(i);
    end;
  FreeAndNil(LookupQuery);
end;

procedure TScheduleForm.FillXTitles();
begin
  XTitles := GetLookupResult(XColumnBox.ItemIndex);
end;

procedure TScheduleForm.FillYTitles();
begin
  YTitles := GetLookupResult(YColumnBox.ItemIndex);
end;

procedure TScheduleForm.FillLookupResults();
begin
  FillXTitles();
  FillYTitles();
end;

procedure TScheduleForm.FillSQLResult();
var
  i, j, k: Integer;
  YFieldID, XFieldID, ColumnLen: Integer;
  XIDCol, YIDCol: TColumnInfo;
  XLen, YLen: Integer;
begin
  XLen := Length(XTitles);
  YLen := Length(YTitles);
  ColumnLen := Length(FColumns);
  XIDCol := Table.GetOwnColByRef(FColumns[XColumnBox.ItemIndex]);
  YIDCol := Table.GetOwnColByRef(FColumns[YColumnBox.ItemIndex]);
  Query.SelectCols(cstAll);
  Query.SetOrderBy([YIDCol, XIDCol, Table.GetColByName('time_id')]);
  Query.SendQuery();
  XFieldID := Query.SQLQuery.FieldByName(XIDCol.AliasName()).Index;
  YFieldID := Query.SQLQuery.FieldByName(YIDCol.AliasName()).Index;

  SQLResult := nil;
  SetLength(SQLResult, YLen);
  for i := 0 to YLen - 1 do
    SetLength(SQLResult[i], XLen);
  i := 0;
  j := 0;
  with Query.SQLQuery do
    while not EOF do begin
      while Fields[YFieldID].AsInteger > YTitles[i].ID do begin inc(i); j := 0; end;
      while Fields[XFieldID].AsInteger > XTitles[j].ID do inc(j);
      SetLength(SQLResult[i][j], Length(SQLResult[i][j]) + 1);
      SetLength(SQLResult[i][j][High(SQLResult[i][j])], ColumnLen);
      for k := 0 to ColumnLen - 1 do begin
        SQLResult[i][j][High(SQLResult[i][j])][k] := FieldByName(FColumns[k].AliasName).AsString;
        //ShowMessage(FieldByName(FColumns[k].AliasName).AsString);
      end;
      Next();
    end;
end;

procedure TScheduleItem.Draw();
begin
  Draw(0);
end;

procedure TScheduleItem.Draw(aOffset: Integer);
const
  Space = 5;
  RoomNameWidth = 50;
  DayNameHeight = 20;
  SubjNameHeight = 30;
  SubjTypeWidth = 50;
  MinFontSize = 8;
  MaxFontSize = 14;
var
  //SubjTypeWidth: Integer;
  ElementRect: TRect;
  SubjTypeRect: TRect;
  SubjNameRect: TRect;
  ProfessorNameRect: TRect;
  DayRect: TRect;
  BeginTimeRect: TRect;
  RoomRect: TRect;
  TextStyle: TTextStyle;
begin
  if Height = 0 then
    Height := BorderRect.Bottom - BorderRect.Top;

  ElementRect := Rect(BorderRect.Left, BorderRect.Top + aOffset, BorderRect.Right, BorderRect.Top + aOffset + Height);
  DayRect := Rect(ElementRect.Left, ElementRect.Top, ElementRect.Right- RoomNameWidth, ElementRect.Top + DayNameHeight);
  BeginTimeRect := Rect(DayRect.Right, DayRect.Top, ElementRect.Right, DayRect.Bottom);
  SubjNameRect := Rect(ElementRect.Left, DayRect.Bottom, ElementRect.Right - SubjTypeWidth, DayRect.Bottom + SubjNameHeight);
  SubjTypeRect := Rect(SubjNameRect.Right, SubjNameRect.Top, ElementRect.Right, SubjNameRect.Bottom);
  ProfessorNameRect := Rect(ElementRect.Left, SubjNameRect.Bottom, ElementRect.Right - RoomNameWidth, ElementRect.Bottom);
  RoomRect := Rect(ProfessorNameRect.Right, ProfessorNameRect.Top, ElementRect.Right, ProfessorNameRect.Bottom);
  with TextStyle do begin
    Wordbreak := false;
    Layout := tlCenter;
    Clipping := false;
    SingleLine := false;
    ExpandTabs := false;
    ShowPrefix := false;
    Opaque := false;
    SystemFont := false;
    RightToLeft := false;
    EndEllipsis := false;
  end;
  with Canvas do begin
    Pen.Width := 1;
    Pen.Color := clGray;
    {Brush.Color := RGBToColor(230, 230, 230);
    Brush.Style := bsSolid;
    if Fill then
      Rectangle(ElementRect);}
    Line(ElementRect.Left, ElementRect.Bottom, ElementRect.Right, ElementRect.Bottom);
    Pen.Color := clBlack;
    {Rectangle(DayRect);
    Rectangle(BeginTimeRect);
    Rectangle(SubjNameRect);
    Rectangle(SubjTypeRect);
    Rectangle(ProfessorNameRect);
    Rectangle(RoomRect);}
    //SubjTypeWidth := TextWidth(FFields[COL_SUBJECT_TYPE_ID]);
    Font.Size := 8;
    if IsVisible[COL_DAY_ID] then
      TextRect(DayRect, DayRect.Left + Space, DayRect.Top, Fields[COL_DAY_ID]);
    if IsVisible[COL_TIME_BEGIN_ID] then
      TextRect(BeginTimeRect, BeginTimeRect.Left + Space, BeginTimeRect.Top, Fields[COL_TIME_BEGIN_ID]);
    Font.Size := 14;
    if IsVisible[COL_SUBJECT_TYPE_ID] then
      TextRect(SubjTypeRect, SubjTypeRect.Left + Space, SubjTypeRect.Top, Fields[COL_SUBJECT_TYPE_ID]);
    Font.Size := Max(Min(Round((SubjNameRect.Right - SubjNameRect.Left) / TextWidth(Fields[COL_SUBJECT_ID]) * Font.Size), MaxFontSize), MinFontSize);
    if IsVisible[COL_SUBJECT_ID] then
      TextRect(SubjNameRect, SubjNameRect.Left + Space, SubjNameRect.Top, Fields[COL_SUBJECT_ID], TextStyle);
    Font.Size := 8;
    if IsVisible[COL_PROFESSOR_ID] then
      TextRect(ProfessorNameRect, ProfessorNameRect.Left + Space, ProfessorNameRect.Top, Fields[COL_PROFESSOR_ID]);
    if IsVisible[COL_ROOM_ID] then
      TextRect(RoomRect, RoomRect.Left + Space, RoomRect.Top, Fields[COL_ROOM_ID]);
  end;
end;

constructor TScheduleItemList.Create(aOwner: TWinControl);
begin
  FScrollBar := TScrollBar.Create(aOwner);
  with FScrollBar do begin
    Parent := aOwner;
    Visible := false;
  end;
end;

destructor TScheduleItemList.Destroy();
begin
  FreeAndNil(FScrollBar);
  inherited;
end;

procedure TScheduleItemList.InitItems();
var
  i: Integer;
begin
  SetLength(FItems, Length(FStringsArr));
  for i := 0 to High(FItems) do
    with FItems[i] do begin
      Canvas := FCanvas;
      Height := ElemHeight;
      Fields := FStringsArr[i];
      Fill := true;
    end;
end;

procedure TScheduleItemList.ShowItems();
begin
  InitItems();
  if Length(FItems) * ElemHeight > FHeight then
    with FScrollBar do begin
      Height := FHeight;
      Visible := true;
    end;
end;

procedure TScheduleItemList.Draw(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to High(FItems) do
    with FItems[i] do begin
      BorderRect := Rect(FRect.Left, FRect.Top + i * ElemHeight, FRect.Right, FRect.Bottom + i * ElemHeight);
      Draw();
    end;
end;

function TScheduleItemList.GetElemHeight(): Integer;
begin
  Result := FRect.Bottom - FRect.Top;
end;

procedure TScheduleItemList.SetElemHeight(aHeight: Integer);
begin
  FRect.Bottom := Frect.Top + aHeight;
  InitItems();
end;

function TScheduleItemList.GetElemWidth(): Integer;
begin
  Result := FRect.Right - FRect.Left;
end;

procedure TScheduleItemList.SetElemWidth(aWidth: Integer);
begin
  FRect.Right := Frect.Left + aWidth;
end;

procedure TScheduleItemList.SetStringsArr(aStringsArr: TStringsArr);
begin
  FStringsArr := aStringsArr;
  InitItems();
end;

end.

