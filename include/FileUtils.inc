
{$ifdef INTERFACE}

function ReadFile(path: ansistring): ansistring;
function Explode(delimiter: char; s: ansistring): TStringList;

{$endif}

{$ifdef IMPLEMENTATION}

function ReadFile(path: ansistring): ansistring;
var
  f: File;
  list: TStringList;
begin
  try
    list := TStringList.Create;
    list.LoadFromFile(path);
    result := list.Text;
  except
    on E:Exception do
      writeln(path+': ', E.Message);
  end;
  list.Free;
  //try
  //  AssignFile(f, path);
  //  FileMode := fmOpenRead;
  //  Reset(f, 1);
  //  SetLength(result, FileSize(f));
  //  BlockRead(f, pointer(result)^, FileSize(f));
  //  CloseFile(f);
  //except
  //  on E:Exception do
  //    writeln(path+': ', E.Message);
  //end;
end;

function Explode(delimiter: char; s: ansistring): TStringList;
begin
  result := TStringList.Create;
  result.Delimiter := delimiter;
  result.StrictDelimiter := true;
  result.DelimitedText := s;
end;

{$endif}
