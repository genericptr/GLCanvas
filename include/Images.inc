
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
  TFileFormat = (
    PNG,
    JPEG,
    TIFF,
    BMP
  );

type
  TRotationFilter = (
    Nearest,
    Bilinear
  );

type
  generic TBitmap<const U: integer; T> = class 
    public const
      TComponents = U;
    private type
      TClass = class of TBitmap;
    public type
      TComponent = T;
      TFormat = specialize TBitmap<TComponents, TComponent>;
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
        class operator := (right: array of TComponent): TPixel;
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
      function RotateBilinear(angle: single): TBitmap;
      function RotateNearest(angle: single): TBitmap;
      { File Handling }
      procedure LoadFromFile(path: AnsiString); virtual; abstract;
      function SaveToFile(path: AnsiString; format: TFileFormat; components: integer; hasAlpha: boolean): Boolean; overload;
      function GetFileName: String;
      function GetFilePath: String;
    public
      { Constructors }
      constructor Create(_path: AnsiString); overload;
      constructor Create(_width, _height: integer; _data: pointer = nil); overload;
      destructor Destroy; override;
      { Methods }
      function Copy: TBitmap; overload;
      function Copy(offsetX, offsetY, width, height: integer): TBitmap; overload;
      function Rotate(angle: single; filter: TRotationFilter = TRotationFilter.Bilinear): TBitmap;
      procedure Blit(source: TBitmap; offsetX, offsetY: integer; mode: TBlendMode = TBlendMode.Copy);
      procedure Fill(newValue: TPixel);
      { Properties }
      property Data: PPixel read m_data;
      property Width: integer read m_width;
      property Height: integer read m_height;
      property Size: TVec2i read GetSize;
      property Count: integer read GetCount;
      property Bytes: integer read GetBytes;
      property FileName: String read GetFileName;
      property FilePath: String read GetFilePath;
      property Pixels[x, y: integer]: TPixel read GetPixel write SetPixel; default;
  end;

type
  TImage4b = class (specialize TBitmap<4, byte>)
    function SaveToFile(path: AnsiString; format: TFileFormat): Boolean; overload;
  end;
  TImage3b = class (specialize TBitmap<3, byte>)
    function SaveToFile(path: AnsiString; format: TFileFormat): Boolean; overload;
  end;

type
  TImage4bArray = array of TImage4b;
  TImage3bArray = array of TImage3b;

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

class operator TBitmap.TPixel.:= (right: array of TComponent): TPixel;
var
  i: integer;
begin
  for i := 0 to Length(right) - 1 do
    result.components[i] := right[i];
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
  if TComponents = 4 then
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
  result := TClass(ClassType).Create(Width, Height, Data);
end;

function TBitmap.Copy(offsetX, offsetY, width, height: integer): TBitmap;
var
  x, y: integer;
begin
  result := TClass(ClassType).Create(Width, Height);

  for y := 0 to height - 1 do
  for x := 0 to width - 1 do
    // TODO: copy by row
    result.Pixels[x, y] := self.Pixels[offsetX + x, offsetY + y];
end;

procedure TBitmap.Fill(newValue: TPixel);
var
  i: integer;
begin
  for i := 0 to Count - 1 do
    data[i] := newValue.components;
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

// TODO: rotate left/right flip vertical/horizontal
{
  procedure RotateCounterClockwise90(var image: TImage);
  var
    i, j: integer;
    newImage: TImage;
  begin
    SetLength(newImage, Length(image[0]), Length(image));
    for i := 0 to High(image) do
      for j := 0 to High(image[i]) do
        newImage[High(newImage) - j][i] := image[i][j];
    image := newImage;
  end;

  procedure FlipBitmapHorizontally(var bitmap: TBitmap);
  var
    x, y: Integer;
    temp: TColor;
  begin
    for y := 0 to bitmap.Height - 1 do
      for x := 0 to (bitmap.Width div 2) - 1 do
      begin
        temp := bitmap.Canvas.Pixels[x, y];
        bitmap.Canvas.Pixels[x, y] := bitmap.Canvas.Pixels[bitmap.Width - x - 1, y];
        bitmap.Canvas.Pixels[bitmap.Width - x - 1, y] := temp;
      end;
  end;

  procedure FlipBitmapVertically(var bitmap: TBitmap);
  var
    x, y: Integer;
    temp: TColor;
  begin
    for x := 0 to bitmap.Width - 1 do
      for y := 0 to (bitmap.Height div 2) - 1 do
      begin
        temp := bitmap.Canvas.Pixels[x, y];
        bitmap.Canvas.Pixels[x, y] := bitmap.Canvas.Pixels[x, bitmap.Height - y - 1];
        bitmap.Canvas.Pixels[x, bitmap.Height - y - 1] := temp;
      end;
  end;

  function TBitmap.Rotate90Clockwise: TBitmap;
  var
    x, y: integer;
    newBmp: TBitmap;
  begin
    newBmp := Copy;
    for y := 0 to Height - 1 do
      for x := 0 to Width - 1 do
        newBmp.Pixels[x, Height - 1 - y] := self.Pixels[y, x];
    result := newBmp;
  end;
}

function TBitmap.Rotate(angle: single; filter: TRotationFilter): TBitmap;
begin
  // TODO: if the angle is multiple of 90 then use other rotate functions
  case filter of
    TRotationFilter.Bilinear:
      result := RotateBilinear(angle);
    TRotationFilter.Nearest:
      result := RotateNearest(angle);
  end;
end;

function TBitmap.RotateNearest(angle: single): TBitmap;
var
  radians: double;
  sinTheta, cosTheta: double;
  cx, cy: double;
  x, y: integer;
  sx, sy: double;
  w, h: integer;
  newBmp: TBitmap;
begin
  radians := DegToRad(angle);
  sinTheta := sin(radians);
  cosTheta := cos(radians);

  w := self.Width;
  h := self.Height;
  cx := w / 2;
  cy := h / 2;

  newBmp := Copy;
  // TODO: how many components?
  newBmp.Fill(TPixel.Create(255, 255, 255, 0));

  for x := 0 to w - 1 do
    for y := 0 to h - 1 do
      begin
        sx := (x - cx) * cosTheta - (y - cy) * sinTheta + cx;
        sy := (x - cx) * sinTheta + (y - cy) * cosTheta + cy;
        if (sx >= 0) and (sx < w) and (sy >= 0) and (sy < h) then
          newBmp.Pixels[x, y] := self.Pixels[Trunc(sx), Trunc(sy)];
      end;

  result := newBmp;
end;


function TBitmap.RotateBilinear(angle: single): TBitmap;

  { The Blend function can be used to perform linear interpolation between two colors. 
    For example, if w2 is 0, the resulting color will be equal to c1, and if w2 is 255, 
    the resulting color will be equal to c2. If w2 is 128, the resulting color will be halfway between c1 and c2. }

  // TODO: nested functions with result in generics are broken on windows
  // https://gitlab.com/freepascal.org/fpc/source/-/issues/40104
  {$ifdef DARWIN}
  function Blend(c1, c2: TColor; w2: byte): TColor; inline;
  var
    w1: byte;
  begin
    w1 := 255 - w2;
    Result := RGBA(c1.r * w1 / 255 + c2.r * w2 / 255,
                   c1.g * w1 / 255 + c2.g * w2 / 255,
                   c1.b * w1 / 255 + c2.b * w2 / 255,
                   1);
  end;
  {$endif}

var
  radians: single;
  sinTheta, cosTheta: single;
  cx, cy: single;
  x, y: integer;
  sx, sy: single;
  w, h: integer;
  newBmp: TBitmap;
  x1, x2, y1, y2: integer;
  fx, fy: single;
  c1, c2, c3, c4: TColor;
begin
  radians := DegToRad(angle);
  sinTheta := sin(radians);
  cosTheta := cos(radians);

  w := self.Width;
  h := self.Height;
  cx := w / 2;
  cy := h / 2;

  newBmp := Copy;
  // TODO: how many components?
  newBmp.Fill(TPixel.Create(255, 255, 255, 0));

  for x := 0 to w - 1 do
    for y := 0 to h - 1 do
      begin
        sx := (x - cx) * cosTheta - (y - cy) * sinTheta + cx;
        sy := (x - cx) * sinTheta + (y - cy) * cosTheta + cy;
        if (sx >= 0) and (sx < w - 1) and (sy >= 0) and (sy < h - 1) then
          begin
            x1 := Trunc(sx);
            y1 := Trunc(sy);
            x2 := x1 + 1;
            y2 := y1 + 1;
            fx := sx - x1;
            fy := sy - y1;

            c1 := self.Pixels[x1, y1];
            c2 := self.Pixels[x2, y1];
            c3 := self.Pixels[x1, y2];
            c4 := self.Pixels[x2, y2];

            {$ifdef DARWIN}
            newBmp.Pixels[x, y] :=
              Blend(Blend(c1, c2, Round(fx * 255)),
                    Blend(c3, c4, Round(fx * 255)),
                    Round(fy * 255));
            {$else}
            Assert(false, 'Blend is broken on this platform');
            {$endif}
          end;
      end;

  result := newBmp;
end;

function TBitmap.GetFileName: String;
begin
  result := ExtractFileName(FilePath);
end;

function TBitmap.GetFilePath: String;
begin
  result := m_filePath;
end;

function TBitmap.SaveToFile(path: AnsiString; format: TFileFormat; components: integer; hasAlpha: boolean): Boolean;
{$ifdef TARGET_OS_MAC}
var
  bitmap: NSBitmapImageRep;
  output: NSData;
  fileType: NSBitmapImageFileType;
begin
  bitmap := NSBitmapImageRep.alloc.initWithBitmapDataPlanes_pixelsWide_pixelsHigh_bitsPerSample_samplesPerPixel_hasAlpha_isPlanar_colorSpaceName_bitmapFormat_bytesPerRow_bitsPerPixel(
      @Data,
      Width,
      Height,
      8, {bitsPerSample}
      components, {samplesPerPixel}
      hasAlpha,
      false, {isPlanar}
      NSDeviceRGBColorSpace,
      NSAlphaNonpremultipliedBitmapFormat,
      Width * 4, {bytesPerRow}
      32 {bitsPerPixel}
    );

  case format of
    TFileFormat.PNG:
      fileType := NSPNGFileType;
    TFileFormat.JPEG:
      fileType := NSJPEGFileType;
    TFileFormat.TIFF:
      fileType := NSTIFFFileType;
    TFileFormat.BMP:
      fileType := NSBMPFileType;
  end;

  output := bitmap.representationUsingType_properties(fileType, nil);
  if output <> nil then
    begin
      result := output.writeToFile_atomically(NSSTR(path), true);
      output.release;
    end
  else
    result := false;

  bitmap.release;
end;
{$else}
begin
  Assert(false, 'TPNGImage.SaveToFile not implemented for platform');
end;
{$endif}

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
  rawBytes: pointer = nil;
  extension: string;
begin
  m_filePath := path;
  extension := ExtractFileExt(path);
  Assert(extension = '.png', 'only png images are implemented');
  try
    AssignFile(fileRef, path);
    FileMode := fmOpenRead;
    Reset(fileRef, 1);
    rawBytes := GetMem(FileSize(fileRef));
    BlockRead(fileRef, rawBytes^, FileSize(fileRef));
    CloseFile(fileRef);
    if not LoadPNG(rawBytes, MemSize(rawBytes), m_data, m_width, m_height, false) then
      raise Exception.Create('Failed to load PNG image '+path);
  except
    if rawBytes <> nil then
      FreeMem(rawBytes);
    raise Exception.Create('Failed to load file '+path);
  end;
end;

{*****************************************************************************
 *                                 TImage4b
 *****************************************************************************}

function TImage4b.SaveToFile(path: AnsiString; format: TFileFormat): Boolean;
begin
  result := SaveToFile(path, format, 4, true);
end;

{*****************************************************************************
 *                                 TImage3b
 *****************************************************************************}

function TImage3b.SaveToFile(path: AnsiString; format: TFileFormat): Boolean;
begin
  result := SaveToFile(path, format, 3, false);
end;

{$endif}

{$ifdef INITIALIZATION}
{$endif}
