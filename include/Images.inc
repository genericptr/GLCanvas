
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
      function GetSize: TVec2i;
      function GetCount: integer;
      function GetBytes: integer;
      function GetPixel(x, y: integer): TPixel; inline; overload;
      function GetPixel(point: TVec2i): TPixel; inline; overload;
      procedure SetPixel(x, y: integer; constref newValue: TPixel); inline; overload;
      procedure LoadFromFile(path: AnsiString); virtual; abstract;
    public
      { Constructors }
      constructor Create(_path: AnsiString);
      constructor Create(_width, _height: integer; _data: pointer = nil);
      { Methods }
      function Copy: TBitmap;
      procedure Blit(source: TBitmap;  mode: TBlendMode; offsetX, offsetY: integer);
      destructor Destroy; override;
      { Properties }
      property Data: PPixel read m_data;
      property Width: integer read m_width;
      property Height: integer read m_height;
      property Size: TVec2i read GetSize;
      property Count: integer read GetCount;
      property Pixels[x, y: integer]: TPixel read GetPixel write SetPixel; default;
  end;

type
  TImage4b = class abstract(specialize TBitmap<4, byte>);
  TImage3b = class abstract(specialize TBitmap<3, byte>);
  //TImage4f = class abstract(specialize TBitmap<4, float>);

type
  TPNGImage = class(TImage4b)
    private
      procedure LoadFromFile(path: AnsiString); override;
  end;

{$endif}

{$ifdef IMPLEMENTATION}

{ TPNGImage }

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

procedure TPNGImage.LoadFromFile(path: AnsiString);
var
  fileRef: file;
  bytes: pointer = nil;
  extension: string;
begin
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


// TODO: TGA
(*
 function ReadFile(path: string): pointer;
 var
  f: file;
  bytes: pointer;
  i: integer;
 begin
  try
    AssignFile(f, path);
    FileMode := fmOpenRead;
    Reset(f, 1);
    bytes := GetMem(FileSize(f));
    BlockRead(f, bytes^, FileSize(f));
    CloseFile(f);
    result := bytes;
   except
    Assert(false, 'can''t load file '+path);
   end;
 end;

 procedure BlockMove(dest, src: pointer; size: SizeInt); 
 begin 
   Move(src^, dest^, size);
 end; 

 function CopyMem(src: pointer; offset: integer; count: integer): pointer;
 begin
  result := GetMem(count);
  BlockMove(result, src + offset, count);
 end;

 type
  TGAImage = record
    bytes: pointer;
    width, height: integer;
    bytesPerRow: integer;
  end;

 function LoadTGAFile (path: string): TGAImage;
 {$packrecords c}
 type
  uint8_t = cuint8;
  int16_t = cint16;
  uint16_t = cuint16;
  TGAHeader = packed record
    private
      IDSize: uint8_t;         // Size of ID info following header
      colorMapType: uint8_t;   // Whether this is a paletted image
      imageType: uint8_t;      // type of image 0=none, 1=indexed, 2=rgb, 3=grey, +8=rle packed

      colorMapStart: int16_t;  // Offset to color map in palette
      colorMapLength: int16_t; // Number of colors in palette
      colorMapBpp: uint8_t;    // number of bits per palette entry

      xOffset: uint16_t;        // Number of pixels to the right to start of image
      yOffset: uint16_t;        // Number of pixels down to start of image
      width: uint16_t;          // Width in pixels
      height: uint16_t;         // Height in pixels
      bitsPerPixel: uint8_t;    // Bits per pixel 8,16,24,32
      descriptor: uint8_t;      // Descriptor bits (flipping, etc)
  end;
  TGAHeaderPtr = ^TGAHeader;
  BytePtr = ^byte;
 var
  header: TGAHeaderPtr;
  fileBytes: pointer;
  width, height, dataSize: integer;
  srcImageData: BytePtr;
  destImageData: BytePtr;
  x, y: integer;
  srcPixelIndex, dstPixelIndex: integer;
 begin
  fileBytes := ReadFile(path);
  header := TGAHeaderPtr(fileBytes);

  width := header^.width;
  height := header^.height;
  dataSize := width * height * 4;

  //writeln('LoadTGAFile: width: ', result.width, ' height: ', result.height);

  Fatal(header^.imageType <> 2, 'This image loader only supports non-compressed BGR(A) TGA files');
  Fatal(header^.colorMapType <> 0, 'This image loader doesn''t support TGA files with a colormap');
  Fatal((header^.xOffset <> 0) or (header^.yOffset <> 0), 'This image loader doesn''t support TGA files with offsets');
  Fatal((header^.bitsPerPixel <> 32) and (header^.bitsPerPixel <> 24), 'This image loader only supports 24-bit and 32-bit TGA files');
  Fatal((header^.bitsPerPixel = 32) and ((header^.descriptor and $f) <> 8), 'Image loader only supports 32-bit TGA files with 8 bits of alpha');
  Fatal(header^.descriptor <> 0, 'Image loader only supports 24-bit TGA files with the default descriptor');

  // copy image data after header
  srcImageData := CopyMem(fileBytes, sizeof(TGAHeader) + header^.IDSize, dataSize);
  
  FreeMem(fileBytes);

  if header^.bitsPerPixel = 24 then
    begin
      // Metal will not understand an image with 24-bpp format so we must convert our
      //   TGA data from the 24-bit BGR format to a 32-bit BGRA format that Metal does
      //   understand (as MTLPixelFormatBGRA8Unorm)
      destImageData := BytePtr(GetMem(dataSize));
      //BlockMove(destImageData, srcImageData, dataSize);

      for y := 0 to height - 1 do
      for x := 0 to width - 1 do
        begin
          // Calculate the index for the first byte of the pixel you're
          // converting in both the source and destination images
          srcPixelIndex := 3 * (y * width + x);
          dstPixelIndex := 4 * (y * width + x);

          // Copy BGR channels from the source to the destination
          // Set the alpha channel of the destination pixel to 255
          destImageData[dstPixelIndex + 0] := srcImageData[srcPixelIndex + 0];
          destImageData[dstPixelIndex + 1] := srcImageData[srcPixelIndex + 1];
          destImageData[dstPixelIndex + 2] := srcImageData[srcPixelIndex + 2];
          destImageData[dstPixelIndex + 3] := 255;
        end;

      FreeMem(srcImageData);
      result.bytes := destImageData;
    end
  else
    begin
      // Metal will understand an image with 32-bpp format
      result.bytes := srcImageData;
    end;

  result.width := width;
  result.height := height;
  result.bytesPerRow := 4 * width;
 end;
 *)

{ TBitmap }

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

procedure TBitmap.Blit(source: TBitmap;  mode: TBlendMode; offsetX, offsetY: integer);

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

{$endif}

{$ifdef INITIALIZATION}
{$endif}
