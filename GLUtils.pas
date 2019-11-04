{$mode objfpc}

unit GLUtils;
interface
uses
  GL, SysUtils;

procedure GLAssert (messageString: string = 'OpenGL error');

implementation

procedure GLAssert (messageString: string = 'OpenGL error'); inline; 
var
  error: GLenum;
begin
  error := glGetError();
  if error <> GL_NO_ERROR then
    begin
      case error of
        GL_INVALID_VALUE:
          Assert(false, messageString+' GL_INVALID_VALUE');
        GL_INVALID_OPERATION:
          Assert(false, messageString+' GL_INVALID_OPERATION');
        GL_INVALID_ENUM:
          Assert(false, messageString+' GL_INVALID_ENUM');
        otherwise
          Assert(false, messageString+' '+HexStr(error, 4));
      end;
    end;
end;

end.