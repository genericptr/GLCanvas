
{$ifdef INTERFACE}
type
  TBlendMode = (
    Copy,
    Multiply,
    Screen,
    Darken,
    Lighten,
    ColorBurn,
    ColorDodge
  );

type
  generic TBitmap<const U: integer; T> = class 
    public const
      TComponents = U;
    public type
      TComponent = T;
      TPixel = packed record
        components: array[0..TComponents-1] of TComponent;
        { Methods }
        constructor Create(_r,_g,_b: TComponent; _a: TComponent = 0);
        { Operators }
        class operator = (left: TPixel; right: TPixel): boolean;
        class operator * (left: TPixel; right: TPixel): TPixel;
        class operator - (left: TPixel; right: TPixel): TPixel;
        class operator + (left: TPixel; right: TPixel): TPixel;
        class operator := (right: TPixel): TVec4;
        class operator := (right: TVec4): TPixel;
        { Properties }
        property R: TComponent read components[0] write components[0];
        property G: TComponent read components[1] write components[1];
        property B: TComponent read components[2] write components[2];
        property A: TComponent read components[3] write components[3];
      end;
      PPixel = ^TPixel;
    private
      m_data: PPixel;
      m_width: integer;
      m_height: integer;
      m_filePath: AnsiString;
      function GetSize: TVec2i;
      function GetCount: integer;
      function GetBytes: integer;
      function GetPixel(x, y: integer): TPixel; inline; overload;
      function GetPixel(point: TVec2i): TPixel; inline; overload;
      procedure SetPixel(x, y: integer; constref newValue: TPixel); inline; overload;
      { File Handling }
      procedure LoadFromFile(path: AnsiString); virtual; abstract;
      function GetFileName: String;
      function GetFilePath: String;
    public
      { Constructors }
      constructor Create(_path: AnsiString); overload;
      constructor Create(_width, _height: integer; _data: pointer = nil); overload;
      { Methods }
      function Copy: TBitmap;
      procedure Blit(source: TBitmap; offsetX, offsetY: integer; mode: TBlendMode = TBlendMode.Copy);
      procedure Fill(newValue: TPixel);
      destructor Destroy; override;
      { Properties }
      property Data: PPixel read m_data;
      property Width: integer read m_width;
      property Height: integer read m_height;
      property Size: TVec2i read GetSize;
      property Count: integer read GetCount;
      property FileName: String read GetFileName;
      property FilePath: String read GetFilePath;
      property Pixels[x, y: integer]: TPixel read GetPixel write SetPixel; default;
  end;

type
  TImage4b = class (specialize TBitmap<4, byte>);
  TImage3b = class (specialize TBitmap<3, byte>);
  //TImage4f = class abstract(specialize TBitmap<4, float>);

type
  TImage4bArray = array of TImage4b;
  TImage3bArray = array of TImage3b;
  //TImage4fArray = array of TImage4f;

type
  TPNGImage = class(TImage4b)
    private
      procedure LoadFromFile(path: AnsiString); override;
  end;

{$endif}

{$ifdef IMPLEMENTATION}

{*****************************************************************************
 *                                 TBitmap
 *****************************************************************************}

class operator TBitmap.TPixel.:= (right: TVec4): TPixel;
var
  i: integer;
begin
  for i := 0 to TComponents - 1 do
    result.components[i] := trunc(right.components[i] * high(TComponent));
end;

class operator TBitmap.TPixel.:= (right: TPixel): TVec4;
var
  i: integer;
begin
  for i := 0 to TComponents - 1 do
    result.components[i] := right.components[i] / high(TComponent);
end;

class operator TBitmap.TPixel.= (left: TPixel; right: TPixel): boolean;
begin
  result := CompareByte(left, right, sizeof(TPixel)) = 0;
end;

class operator TBitmap.TPixel.* (left: TPixel; right: TPixel): TPixel;
var
  i: integer;
begin
  for i := 0 to TComponents - 1 do
    result.components[i] := left.components[i] * right.components[i];
end;

class operator TBitmap.TPixel.- (left: TPixel; right: TPixel): TPixel;
var
  i: integer;
begin
  for i := 0 to TComponents - 1 do
    result.components[i] := left.components[i] - right.components[i];
end;


class operator TBitmap.TPixel.+ (left: TPixel; right: TPixel): TPixel;
var
  i: integer;
begin
  for i := 0 to TComponents - 1 do
    result.components[i] := left.components[i] + right.components[i];
end;

constructor TBitmap.TPixel.Create(_r,_g,_b: TComponent; _a: TComponent = 0);
begin
  r:=_r;
  g:=_g;
  b:=_b;
  a:=_a;
end;

(*
procedure TBitmap.Resize(bm1: TBitmap);
// http://www.davdata.nl/math/bmresize.html
//copy bm1 to bm2
type PDW = ^dword;
var ps0,pd0,psStep,pdStep : dword;       //scanline[0], row steps
    sx1,sy1,sx2,sy2 : single;             //source field positions
    x,y,i,j,destwidth,destheight : word;  //source,dest field pixels
    destR,destG,destB : single;           //destination colors
    sR,sG,sB : byte;                      //source colors
    fx,fy,fix,fiy,dyf : single;           //factors
    fxstep,fystep, dx,dy : single;
    color : dword;
    pdy,pdx,psi,psj : dword;
    AP : single;
    istart,iend,jstart,jend : word;
    devX1,devX2,devY1,devY2 : single;
    bm2: TBitmap;
begin
 bm2 := self;
 ps0 := DWORD(bm1.scanline[0]);
 psstep := ps0 - DWORD(bm1.scanline[1]);
 pd0 := DWORD(bm2.scanline[0]);
 pdstep := pd0 - DWORD(bm2.scanline[1]);
 destwidth := bm2.Width-1;
 destheight := bm2.Height-1;
 fx := bm1.width/bm2.width;
 fy := bm1.height/bm2.height;
 fix := 1/fx;
 fiy := 1/fy;
 fxstep := 0.9999 * fx;
 fystep := 0.9999 * fy;
 pdy := pd0;
 for y := 0 to destheight do         //vertical destination pixels
  begin
   sy1 := fy * y;
   sy2 := sy1 + fystep;
   jstart := trunc(sy1);
   jend := trunc(sy2);
   devY1 := 1-sy1+jstart;
   devY2 := jend+1-sy2;
   pdx := pdy;
   for x := 0 to destwidth do        //horizontal destination pixels
    begin
     sx1 := fx * x;                        //x related values are repeated
     sx2 := sx1 + fxstep;                  //for each y and may be placed in
     istart := trunc(sx1);                 //lookup table
     iend := trunc(sx2);                   //...
     devX1 := 1-sx1+istart;                  //...
     devX2 := iend+1-sx2;                  //...
     destR := 0; destG := 0; destB := 0;   //clear destination colors
     psj := ps0-jstart*psStep;
     dy := devY1;
     for j := jstart to jend do  //vertical source pixels
      begin
       if j = jend then dy := dy - devY2;
       dyf := dy*fiy;
       psi := psj + (istart shl 2);
       dx := devX1;
       for i := istart to iend do //horizontal source pixels
        begin
         if i = iend then dx := dx - devX2;
         AP := dx*dyf*fix;
         color := PDW(psi)^;
         sB := color;
         destB := destB + sB*AP;
         sG := color shr 8;
         destG := destG + sG*AP;
         sR := color shr 16;
         destR := destR + sR*AP;
         inc(psi,4);
         dx := 1;
        end;//for i
       dec(psj,psStep);
       dy := 1;
      end;//for j
      sB := round(destB);
      sG := round(destG);
      sR := round(destR);
      color := sB or (sG shl 8) or (sR shl 16);
     PDW(pdx)^ := color;
     inc(pdx,4);
    end;//for x
   dec(pdy,pdstep);
  end;//for y
end;
*)

procedure TBitmap.SetPixel(x, y: integer; constref newValue: TPixel);
begin
  data[x + y * Width] := newValue;
end;

function TBitmap.GetPixel(x, y: integer): TPixel;
begin
  result := data[x + y * Width];
end;

function TBitmap.GetPixel(point: TVec2i): TPixel;
begin
  result := GetPixel(point.x, point.y)
end;

function TBitmap.GetSize: TVec2i;
begin
  result.width := m_width;
  result.height := m_height
end;

{ Returns number of pixels }
function TBitmap.GetCount: integer;
begin
  result := width * height;
end;

{ Returns number of bytes }
function TBitmap.GetBytes: integer;
begin
  result := sizeof(TPixel) * Count;
end;

function TBitmap.Copy: TBitmap;
begin
  result := specialize TBitmap<TComponents, TComponent>.Create(Width, Height, Data);
end;

procedure TBitmap.Fill(newValue: TPixel);
var
  i: integer;
begin
  for i := 0 to Count - 1 do
    data[i] := newValue;
end;

procedure TBitmap.Blit(source: TBitmap; offsetX, offsetY: integer; mode: TBlendMode = TBlendMode.Copy);

  {
    a = source
    b = dest
  }
  function BlendComponent(mode: TBlendMode; a, b: TComponent): TComponent; inline;
  var
    final,
    target,
    blend: float;
  begin
    // http://www.deepskycolors.com/archive/2010/04/21/formulas-for-Photoshop-blending-modes.html
    // https://en.wikipedia.org/wiki/Blend_modes
    // https://photoshoptrainingchannel.com/blending-modes-explained/
    {
      * Darken          min(Target,Blend)
      * Multiply        Target * Blend
      * Color Burn      1 - (1-Target) / Blend
      * Linear Burn     Target + Blend - 1
      * Lighten         max(Target,Blend)
      * Screen          1 - (1-Target) * (1-Blend)
      * Color Dodge     Target / (1-Blend)
      * Linear Dodge    Target + Blend
      * Overlay         (Target > 0.5) * (1 - (1-2*(Target-0.5)) * (1-Blend)) +
        (Target <= 0.5) * ((2*Target) * Blend)  
      * Soft Light     (Blend > 0.5) * (1 - (1-Target) * (1-(Blend-0.5))) +
        (Blend <= 0.5) * (Target * (Blend+0.5))
      * Hard Light     (Blend > 0.5) * (1 - (1-Target) * (1-2*(Blend-0.5))) +
        (Blend <= 0.5) * (Target * (2*Blend))
      * Vivid Light    (Blend > 0.5) * (Target / (1-2*(Blend-0.5))) +
        (Blend <= 0.5) * (1 - (1-Target) / (2*Blend)) )
      * Linear Light     (Blend > 0.5) * (Target + 2*(Blend-0.5)) +
        (Blend <= 0.5) * (Target + 2*Blend - 1)
      * Pin Light    (Blend > 0.5) * (max(Target,2*(Blend-0.5))) +
        (Blend <= 0.5) * (min(Target,2*Blend)))
      * Difference     | Target - Blend |
      * Exclusion    0.5 - 2*(Target-0.5)*(Blend-0.5)
    }
    case mode of
      TBlendMode.Multiply:
        result := (a * b) div high(TComponent);
      TBlendMode.Screen:
        result := ((a + b) - ((a * b) div high(TComponent)));
      TBlendMode.ColorBurn:
        begin
          target := a / high(TComponent);
          blend := b / high(TComponent);
          final := 1 - (1 - blend) / target;
          result := Trunc(Clamp(final, 0, 1) * high(TComponent));
        end;
      TBlendMode.ColorDodge:
        begin
          target := a / high(TComponent);
          blend := b / high(TComponent);
          final := target / (1 - blend);
          result := Trunc(Clamp(final, 0, 1) * high(TComponent));
        end;
      TBlendMode.Darken:
        begin
          if a < b then
            result := a
          else
            result := b;
        end;
      TBlendMode.Lighten:
        begin
          if a > b then
            result := a
          else
            result := b;
        end;
    end;
  end;

var
  i, j, k, columns: integer;
  a: TPixel;
  b: PPixel;
  f: float;
  target, blend: float;
begin
  // TODO: don't exceed bounds of dest
  //destWidth :=
  //destHeight := source.height
  if mode = TBlendMode.Copy then
    begin
      for i := 0 to source.height - 1 do
        begin
          columns := source.width;
          Move(source.data[i * columns], self.data[(offsetX + offsetY * self.width) + (i * self.width)], sizeof(TPixel) * columns);
        end;
    end
  else
    begin
      for i := 0 to source.height - 1 do
      for j := 0 to source.width - 1 do
        begin
          a := source.data[j + i * source.width];
          b := @data[(offsetX + offsetY * self.width) + (j + i * self.width)];
          for k := 0 to TComponents - 1 do
            a.components[k] := BlendComponent(mode, a.components[k], b^.components[k]);
          Move(a, b^, sizeof(TPixel));
        end;
    end;
end;

function TBitmap.GetFileName: String;
begin
  result := ExtractFileName(FilePath);
end;

function TBitmap.GetFilePath: String;
begin
  result := m_filePath;
end;

destructor TBitmap.Destroy;
begin
  FreeMem(data);
  inherited;
end;

constructor TBitmap.Create(_path: AnsiString);
begin
  LoadFromFile(_path);
end;

constructor TBitmap.Create(_width, _height: integer; _data: pointer);
begin
  m_width := _width;
  m_height := _height;
  m_data := GetMem(GetBytes);
  if _data <> nil then
    Move(_data^, m_data^, GetBytes);
end;

{*****************************************************************************
 *                               TPNGImage
 *****************************************************************************}
procedure TPNGImage.LoadFromFile(path: AnsiString);
var
  fileRef: file;
  bytes: pointer = nil;
  extension: string;
begin
  m_filePath := path;
  extension := ExtractFileExt(path);
  Assert(extension = '.png', 'only png images are implemented');
  try
    AssignFile(fileRef, path);
    FileMode := fmOpenRead;
    Reset(fileRef, 1);
    bytes := GetMem(FileSize(fileRef));
    BlockRead(fileRef, bytes^, FileSize(fileRef));
    CloseFile(fileRef);
    if not LoadPNG(bytes, MemSize(bytes), m_data, m_width, m_height, false) then
      raise Exception.Create('Failed to load PNG image '+path);
  except
    if bytes <> nil then
      FreeMem(bytes);
    raise Exception.Create('Failed to load file '+path);
  end;
end;

{$endif}

{$ifdef INITIALIZATION}
{$endif}
