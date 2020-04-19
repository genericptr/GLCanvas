{$mode objfpc}
{$modeswitch advancedrecords}

unit FastList;
interface
uses
  SysUtils;

type
  generic TFastList<T> = class
    private type
      TValuesArray = array[0..0] of T;
      PValuesArray = ^TValuesArray;
      PValue = ^T;
      TEnumerator = record
        list: TFastList;
        currentValue: PValue;
        index: integer;
        constructor Create(from: TFastList); 
        function MoveNext: Boolean;
        property Current: PValue read currentValue;
      end;
    private
      data: PValuesArray;
      m_count: integer;
      m_capacity: integer;
      function GetFirst: PValue; inline;
      function GetLast: PValue; inline;
      function GetValue(index: integer): PValue; inline;
      procedure PutValue(index: integer; value: PValue); inline;
      procedure SetCapacity(newValue: integer);
    public
      constructor Create;
      destructor Destroy; override;
      procedure Add(constref value: T); overload;
      procedure Add(value: PValue; elements: integer); overload;
      procedure Clear;
      procedure Delete(index: integer);
      procedure Exchange(index1, index2: integer);
      property Count: integer read m_count write m_count;
      property Capacity: integer read m_capacity write SetCapacity;
      property Items[index: integer]: PValue read GetValue; default;
      property First: PValue read GetFirst;
      property Last: PValue read GetLast;
      function GetEnumerator: TEnumerator;
  end;

implementation

procedure TFastList.Exchange(index1, index2: integer);
var
  tmp: T;
begin
  tmp := data^[index2];
  data^[index2] := data^[index1];
  data^[index1] := tmp;
end;

constructor TFastList.TEnumerator.Create(from: TFastList);
begin
  list := from;
  index := 0;
end;
  
function TFastList.TEnumerator.MoveNext: Boolean;
begin
  if index < list.Count then
    currentValue := list[index]
  else
    currentValue := nil;
  Inc(index);
  result := index <= list.Count;
end;

function TFastList.GetEnumerator: TEnumerator;
begin
  result := TEnumerator.Create(self);
end;

procedure TFastList.Clear;
begin
  if Capacity > 0 then
    begin
      FreeMem(data);
      data := nil;
      m_capacity := 0;
      m_count := 0;
    end;
end;

procedure TFastList.Delete(index: integer);
var
  tail: integer;
begin
  if index = Count - 1 then
    begin
      m_count := Count - 1;
      exit;
    end;
  tail := Count - index;
  if tail > 0 then
    begin
      Move(data^[index + 1], data^[index], SizeOf(T) * tail);
      m_count := Count - 1;
    end;
end;

function TFastList.GetFirst: PValue;
begin
  result := @data[0];
end;

function TFastList.GetLast: PValue;
begin
  result := @data[Count - 1];
end;

function TFastList.GetValue(index: integer): PValue;
begin
  result := @data[index];
end;

procedure TFastList.PutValue(index: integer; value: PValue);
begin
  data^[index] := value^;
end;

procedure TFastList.SetCapacity(newValue: integer);
begin
  ReAllocMem(data, newValue * SizeOf(T));
  m_capacity := newValue;
end;

procedure TFastList.Add(constref value: T);
begin
  if Count >= Capacity then
    SetCapacity(Capacity * 2);
  PutValue(Count, @value);
  Inc(m_count);
end;

procedure TFastList.Add(value: PValue; elements: integer);
begin
  if Count >= Capacity then
    SetCapacity(Capacity * 2);
  System.Move(value^, data[Count], elements * sizeof(T));
  Inc(m_count, elements);
end;

constructor TFastList.Create;
begin
  Capacity := 4;
end;

destructor TFastList.Destroy;
begin
  if data <> nil then
    FreeMem(data);
  inherited;
end;

end.