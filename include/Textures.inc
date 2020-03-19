
{$ifdef INTERFACE}

type
	TGLTextureID = GLuint;
	TGLTextureUnit = GLuint;
	TTextureParameters = set of (	kTextureLinearFilter, 
																kTextureNearestFilter,
																kTextureClampToEdge,
																kTextureRGB
																);

type
	// TODO: what are we doing for image data now? we have png and tga loaders
	TImagePixel = TPNGPixel;
	TImagePixelArray = array[0..0] of TImagePixel;
	TImage = ^TImagePixelArray;

type
	TTextureFrame = record
		texture: TRect;
		pixel: TRect;
	end;

type
	ITexture = interface
		function GetTexture: TGLTextureID;
		function GetTextureUnit: TGLTextureUnit;
		function GetFrame: TTextureFrame;

		procedure Lock(inUnit: TGLTextureUnit);
		procedure Unlock;
		procedure Load;
		procedure Unload;
		function IsLoaded: boolean;
		function IsLocked: boolean;
	end;	

type
	TTextureSource = class(ITexture)
		public	
			function GetTexture: TGLTextureID;
			function GetTextureUnit: TGLTextureUnit;
			function GetFrame: TTextureFrame;

			function TextureToPixel (textureRect: TRect): TRect;
			function PixelToTexture (pixelRect: TRect): TRect;
			function SubTextureFrame (x, y, w, h: float): TRect; overload;
			function SubTextureFrame (pixelFrame: TRect): TRect; overload;
			function PixelAt(x, y: integer): TImagePixel; virtual; overload;
			function PixelAt(point: TVec2i): TImagePixel; virtual; overload;

			procedure Lock(inUnit: TGLTextureUnit); virtual;
			procedure Unlock; virtual;
			procedure Load; virtual;
			procedure Unload; virtual;
			function IsLoaded: boolean; virtual;
			function IsLocked: boolean; virtual;

			procedure LoadIfNeeded; inline;
		private
			m_textureID: TGLTextureID;
			m_textureUnit: TGLTextureUnit;
			m_textureFrame: TTextureFrame;
			m_owner: TTextureSource;
		public
			property TextureSize: TVec2 read m_textureFrame.pixel.size;
			property TextureFrame: TRect read m_textureFrame.texture;
			property PixelFrame: TRect read m_textureFrame.pixel;
			property TextureID: TGLTextureID read m_textureID;
			property Owner: TTextureSource read m_owner;
	end;
	
type
	TTexture = class;
	TTextureSheet = class;
	TTextureList = specialize TFPGObjectList<TTexture>;

	TTexture = class (TTextureSource, ITexture)
		public
			
			{ Constructors }
			constructor Create (path: ansistring); overload;
			constructor Create (texture: TGLTextureID; width: integer = 0; height: integer = 0); overload;
			
			{ Accessors }
			procedure SetTextureFrame (newValue: TRect);
			procedure SetPixelFrame (newValue: TRect);

			function GetSize: TVec2; inline;
			function GetBounds: TRect; inline;
			function GetHeight: integer; inline;
			function GetWidth: integer; inline;
			
			{ Methods } 
			procedure Load; override;
			procedure Lock(inUnit: TGLTextureUnit); override;
			function IsLocked: boolean; override;
			destructor Destroy; override;
			function PixelAt(x, y: integer): TImagePixel; override;
			
			function Subdivide (cellSize: TVec2): TTextureSheet;
			function Splice(rect: TRect): TTexture;

		private
			sourceImage: TImage;
			generatedTexture: boolean;
			textureParams: TTextureParameters;
			slices: TTextureList;

			procedure SetSize (newValue: TVec2);
			procedure LoadImage (image: TImage);

			{ Constructors for sub-textures }
			constructor Create (source: TTextureSource); overload;
			constructor Create (source: TTextureSource; inPixelFrame, inTextureFrame: TRect); overload;
	end;
	TTextureMap = specialize TFPGMapObject<String, TTexture>;
	TTextureArray = array of TTexture;

	TTextureSheet = class (TTexture)
		private
			m_cellSize: TVec2i;
			m_tableSize: TVec2i;
			function GetCellSize: TVec2i; inline;
			function GetTableSize: TVec2i; inline;
		public
					
			{ Constructors }
			constructor Create (path: ansistring; inCellSize: TVec2i); overload;
			constructor Create (path: ansistring; inCellSize, inTableSize: TVec2i); overload;

			{ Accessors }
			function Columns: integer; inline;
			function Rows: integer; inline;

			function GetCount: integer;
			function GetTextures: TTextureList;

			{ Cells }
			function GetTexture (index: integer): TTexture; overload;
			function GetTexture (cell: TVec2): TTexture; overload;
			function GetTexture (x, y: integer): TTexture; overload;
			property Cells[x, y: integer]: TTexture read GetTexture; default;

			property TableSize: TVec2i read GetTableSize;
			property CellSize: TVec2i read GetCellSize;

			procedure Load; override;
			destructor Destroy; override;
		private
			textures: TTextureList;
			procedure Subdivide;
			function GetIndex (x, y: integer): integer; inline;
			constructor Create (inTextureID: TGLTextureID; inTextureFrame: TTextureFrame; inCellSize, inTableSize: TVec2i); overload;
	end;

type
	TTexturePack = class (TTextureSource, ITexture)
		public
			
			{ Constructors }
			constructor Create; overload;
			constructor Create (_path: ansistring); overload;
			
			{ Accessors }
			function GetTexture (name: string): TTexture; overload;
			function GetCount: integer;
			procedure SetTextureParameters (newValue: TTextureParameters); 

			property Indexer[name: string]: TTexture read GetTexture; default;

			function PixelAt(x, y: integer): TImagePixel; override;
			procedure Load; override;
			destructor Destroy; override;
		private
			textures: TTextureMap;
			path: string;
			textureParams: TTextureParameters;
			scale: TScalar;
			sourceImage: TImage;

			procedure LoadImage (imagePath: ansistring);
			procedure AddTexture (name: string; constref spriteSize: TVec2; constref offset, position, pivot: TVec2); 
	end;

type
	TTextureComposite = class (TTextureSource, ITexture)
		private type
			TImagePathArray = array of string;
		public
			
			{ Constructors }
			constructor Create(canvasSize: TVec2i; images: TImagePathArray);
			
			{ Accessors }
			function GetTexture (name: string): TTexture; overload;
			function GetCount: integer;
			procedure SetTextureParameters (newValue: TTextureParameters); 

			property Indexer[name: string]: TTexture read GetTexture; default;

			{ Loading }
			procedure Load; override;

			function Subdivide (cellSize: TVec2): TTextureSheet;
			destructor Destroy; override;
		private
			textures: TTextureMap;
			textureParams: TTextureParameters;
			imagePaths: TImagePathArray;
	end;

operator := (right: TImagePixel): TVec4;

procedure SetMaximumTextureUnits(newValue: integer); 
function PushTexture (texture: ITexture): TGLTextureUnit;
procedure ChangeTextureUnit(texture: ITexture; textureUnit: integer); 
procedure ClearTextureUnit(textureUnit: integer); 

{$endif}

{$ifdef IMPLEMENTATION}

type
	TTextureSlot = record
		id: integer;
		obj: ITexture;
		class operator = (left: TTextureSlot; right: ITexture): boolean;
		procedure SetTexture(newValue: ITexture);
		function IsLocked: boolean; inline;
		function IsUsed: boolean; inline;
	end;

class operator TTextureSlot.= (left: TTextureSlot; right: ITexture): boolean;
begin
	if right = nil then
		result := (left.obj = right)
	else
		result := left.id = right.GetTexture;
end;

procedure TTextureSlot.SetTexture(newValue: ITexture);
begin
	if newValue = nil then
		begin
			id := -1;
			obj := nil;
		end
	else
		begin
			id := newValue.GetTexture;
			obj := newValue;
		end;
end;

function TTextureSlot.IsLocked: boolean;
begin
	result := obj.IsLocked;
end;

function TTextureSlot.IsUsed: boolean;
begin
	result := assigned(obj);
end;

var
	DefaultTextureParameters: TTextureParameters = [kTextureNearestFilter, kTextureClampToEdge];
	TextureSlots: array[0..127] of TTextureSlot;

type
	TFileParts = record
		name: string;
		dir: ansistring;
		ext: string;
	end;

function ExtractFileParts (path: ansistring): TFileParts;
begin
	result.ext := ExtractFileExt(path);
	result.name := ExtractFileName(path);
	result.name := StringReplace(result.name, result.ext, '', []);
	result.dir := ExtractFileDir(path);
end;

operator := (right: TImagePixel): TVec4;
begin
	result.r := right.r/255;
	result.g := right.g/255;
	result.b := right.b/255;
	result.a := right.a/255;
end;

//#########################################################
// OPENGL UTILITIES
//#########################################################

var
	RealMaximumTextureUnits: integer = 0;
	RealMaximumVerticies: integer = 0;
	RealMaximumTexureSize: integer = 0;
	UserMaximumTextureUnits: integer = 0;

function GetMaximumTextureSize: integer;
begin
	if RealMaximumTexureSize = 0 then
		glGetIntegerv(GL_MAX_TEXTURE_SIZE, @RealMaximumTexureSize);
	result := RealMaximumTexureSize;
end;

function GetMaximumTextureUnits: integer; 
begin
	if RealMaximumTextureUnits = 0 then
		glGetIntegerv(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS, @RealMaximumTextureUnits);
	if UserMaximumTextureUnits = 0 then
		result := RealMaximumTextureUnits
	else
		result := UserMaximumTextureUnits;
end;

function GetMaximumVerticies: integer; 
begin
	if RealMaximumVerticies = 0 then
		glGetIntegerv(GL_MAX_ELEMENTS_VERTICES, @RealMaximumVerticies);
	result := RealMaximumVerticies;
end;

procedure SetMaximumTextureUnits(newValue: integer); 
begin
	GetMaximumTextureUnits;
	Assert(newValue <= RealMaximumTextureUnits, 'Must not exceed real maximum texture units ('+IntToStr(RealMaximumTextureUnits)+').');
	UserMaximumTextureUnits := newValue;
end;

procedure GenerateTexture (var texID: TGLTextureID);
begin
	glGenTextures(1, @texID);
	GLAssert('glGenTextures');	
end;	

procedure DeleteTexture (texID: TGLTextureID);
begin
	glDeleteTextures(1, @texID);
	GLAssert('glDeleteTextures');
end;

var
	PreviousTextureID: GLint = -1;
	PreviousTextureUnit: GLint = -1;

function BindTexture2D (texID: TGLTextureID; texUnit: TGLTextureUnit = 0): boolean;
var
	saved: GLint;
begin
	Assert((texUnit < GetMaximumTextureUnits) and (texUnit >= 0), 'texture unit '+IntToStr(texUnit)+' is out of bounds (0-'+IntToStr(GetMaximumTextureUnits-1)+')');
	glActiveTexture(GL_TEXTURE0 + texUnit);
	glBindTexture(GL_TEXTURE_2D, texID);
	GLAssert('glBindTexture');	
	GlCanvasState.bindTextureCount += 1;

	PreviousTextureID := texID;
	PreviousTextureUnit := texUnit;
end;
	
function RestorePreviousTexture: boolean;
begin
	Assert((PreviousTextureID > -1) and (PreviousTextureUnit > -1), 'No previous texture was set.');
	glActiveTexture(GL_TEXTURE0 + PreviousTextureUnit);
	glBindTexture(GL_TEXTURE_2D, PreviousTextureID);
	PreviousTextureID := -1;
	PreviousTextureUnit := -1;
	result := true;
end;

procedure LoadTexture2D (width, height: GLsizei; data: pointer; params: TTextureParameters = []);
begin
	if kTextureRGB in params then
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, data)
	else
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);

	GLAssert('glTexImage2D');	

	if kTextureLinearFilter in params then
		begin
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		end
	else if kTextureNearestFilter in params then
		begin
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		end
	else
		begin
			// default
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		end;

	if kTextureClampToEdge in params then
		begin
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		end
	else
		begin
			// default
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		end;
end;

procedure ClearTextureUnit(textureUnit: integer); 
begin
	TextureSlots[textureUnit].SetTexture(nil);
end;

procedure ChangeTextureUnit(texture: ITexture; textureUnit: integer); 
begin
	Assert(texture.GetTexture > 0, 'Texture is not loaded (invalid texture ID)');
	Assert(textureUnit < GetMaximumTextureUnits, 'Texture unit '+IntToStr(textureUnit)+' exceeds maximum ('+IntToStr(GetMaximumTextureUnits)+')');
	Assert(TextureSlots[textureUnit] = nil, 'Another texture ('+IntToStr(TextureSlots[textureUnit].id)+') is loaded in unit '+IntToStr(textureUnit));
	TextureSlots[textureUnit].SetTexture(texture);
	BindTexture2D(texture.GetTexture, textureUnit);
end;

function PushTexture (texture: ITexture): TGLTextureUnit;
var
	i: integer;
	textureUnit: integer;
begin
	if not texture.IsLoaded then
		texture.Load;

	Assert(texture.GetTexture > 0, 'Texture is not loaded (invalid texture ID)');

	//writeln('push texture id ', texture.GetTexture, ' locked=', texture.IsLocked, ' unit=', texture.GetTextureUnit);

	// locked texture can guarantee their texture unit
	if texture.IsLocked then
		exit(texture.GetTextureUnit);

	// find the next available unit
	textureUnit := -1;
	for i := 0 to GetMaximumTextureUnits - 1 do
		if TextureSlots[i].IsUsed and TextureSlots[i].IsLocked then
		  continue
		else if TextureSlots[i] = texture then
			exit(i)
		else if not TextureSlots[i].IsUsed then
			begin
				textureUnit := i;
				break;
			end;

	// not available units were found so we need to 
	// flush drawing and clear unlocked slots
	if textureUnit < 0 then
		begin
			FlushDrawing;
			for i := 0 to GetMaximumTextureUnits - 1 do
				if not TextureSlots[i].IsLocked then
					begin
						if textureUnit = -1 then
							textureUnit := i;
						TextureSlots[i].SetTexture(nil);
					end;
		end;

	Assert((textureUnit >= 0) and (textureUnit < GetMaximumTextureUnits), 'No texture units available for textureID '+IntToStr(texture.GetTexture));

	TextureSlots[textureUnit].SetTexture(texture);
	BindTexture2D(texture.GetTexture, textureUnit);
	//writeln('bind texture ', texture.GetTexture, ' ', HexStr(texture), ' to unit ', textureUnit);
	result := textureUnit;
end;

procedure RestoreTextureUnit (textureUnit: TGLTextureUnit; textureID: TGLTextureID);
begin
	if TextureSlots[textureUnit].IsUsed and (TextureSlots[textureUnit].id <> textureID) then
		glBindTexture(GL_TEXTURE_2D, TextureSlots[textureUnit].id);
end;

//#########################################################
// IMAGES
//#########################################################

procedure BlockMove(dest, src: pointer; size: SizeInt); 
begin 
  Move(src^, dest^, size);
end; 

function CopyMem (src: pointer; offset: integer; count: integer): pointer;
begin
	result := GetMem(count);
	BlockMove(result, src + offset, count);
end;

function LoadTGA (fileBytes: pointer; var width, height: integer): pointer;
{$packrecords c}
type
	uint8_t = cuint8;
	int16_t = cint16;
	uint16_t = cuint16;
	TGAHeader = packed record
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
	dataSize: integer;
	srcImageData: BytePtr;
	destImageData: BytePtr;
	x, y: integer;
	srcPixelIndex, dstPixelIndex: integer;
begin
	header := TGAHeaderPtr(fileBytes);
	width := header^.width;
	height := header^.height;
	dataSize := width * height * 4;

	//writeln('LoadTGAFile: width: ', result.width, ' height: ', result.height);

	Assert(not (header^.imageType <> 2), 'This image loader only supports non-compressed BGR(A) TGA files');
	Assert(not (header^.colorMapType <> 0), 'This image loader doesn''t support TGA files with a colormap');
	Assert(not ((header^.xOffset <> 0) or (header^.yOffset <> 0)), 'This image loader doesn''t support TGA files with offsets');
	Assert(not ((header^.bitsPerPixel <> 32) and (header^.bitsPerPixel <> 24)), 'This image loader only supports 24-bit and 32-bit TGA files');
	Assert(not ((header^.bitsPerPixel = 32) and ((header^.descriptor and $f) <> 8)), 'Image loader only supports 32-bit TGA files with 8 bits of alpha');
	Assert(not (header^.descriptor <> 0), 'Image loader only supports 24-bit TGA files with the default descriptor');

	// copy image data after header
	srcImageData := CopyMem(fileBytes, sizeof(TGAHeader) + header^.IDSize, dataSize);

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
			result := destImageData;
		end
	else
		begin
			// Metal will understand an image with 32-bpp format
			result := srcImageData;
		end;
end;

function Pow2Size (from: single): integer;
var
	i: integer;
	pow2: integer;
begin
	result := 0;
	pow2 := 2;
	for i := 1 to maxInt do
		begin
			if pow2 >= from then
				begin
					result := pow2;
					break;
				end;
			pow2 := pow2 * 2;
		end;
end;

function LoadImageFromFile (path: ansistring; out width, height: integer): TImage;
type
	TPNGDataArray = array[0..0] of TPNGPixel;
	PPNGDataArray = ^TPNGDataArray;
var
	f: file;
	bytes: pointer;
	i: integer;
	extension: string;
begin
	try
		AssignFile(f, path);
		FileMode := fmOpenRead;
	  Reset(f, 1);
	  bytes := GetMem(FileSize(f));
	  BlockRead(f, bytes^, FileSize(f));
	  CloseFile(f);

	  extension := ExtractFileExt(path);

	  Assert(extension = '.png', 'only png images are implemented');
	  if not LoadPNG(bytes, MemSize(bytes), result, width, height, false) then
	    result := nil;		

	  //Assert((width = Pow2Size(width)) and (height = Pow2Size(height)), 'image must be power of 2');
	  //writeln('loaded:', ExtractFileName(path), ' ', width, 'x', height);
		FreeMem(bytes);
  except
    on E:Exception do
      begin
      	writeln('LoadImageFromFile: ', E.Message, ' ', path);
      	halt(-1);
      end;
  end;
end;

//#########################################################
// TEXTURE SOURCE
//#########################################################

function TTextureSource.TextureToPixel (textureRect: TRect): TRect;
begin
	result := RectMake(textureRect.MinX * textureSize.width, 
										 textureRect.MinY * textureSize.height, 
										 textureRect.width * textureSize.width, 
										 textureRect.height * textureSize.height);
end;

function TTextureSource.PixelToTexture (pixelRect: TRect): TRect;
begin
	result := RectMake(pixelRect.MinX / textureSize.width, 
										 pixelRect.MinY / textureSize.height, 
										 pixelRect.width / textureSize.width, 
										 pixelRect.height / textureSize.height);
end;

{ Returns a sub-frame of the texture frame using AABB
  	0,0,1,1 = entire frame
		0,0.5,1,1 = 50% split at minY }
function TTextureSource.SubTextureFrame (x, y, w, h: float): TRect;
begin
	result := AABB(TextureFrame.MinX + (TextureFrame.size.Width * x),
								 TextureFrame.MinY + (TextureFrame.size.Height * y),
								 TextureFrame.MinX + (TextureFrame.size.Width * w), 
								 TextureFrame.MinY + (TextureFrame.size.Height * h)
								 );
end;

{ Returns a sub-frame of the texture frame using pixel coordinates 
		with a texture frame of [100,100,32,32] a  pixel frame of [0,16,32,16]
		will return a sub texture frame that is [100,116,32,16] (in pixel coordinates) }
function TTextureSource.SubTextureFrame (pixelFrame: TRect): TRect;
var
	relSize, 
	relPos: TVec2;
begin
	relSize := pixelFrame.size / TextureSize;
	relPos := pixelFrame.origin / TextureSize;
	result := TextureFrame;
	result.origin += (result.size * relPos);
	result.size := result.size * relSize;
end;

function TTextureSource.GetFrame: TTextureFrame;
begin
	result := m_textureFrame;
end;

function TTextureSource.PixelAt(x, y: integer): TImagePixel;
begin
	Assert(false, 'PixelAt must be implemented by texture.');
	result := Default(TImagePixel);
end;

function TTextureSource.PixelAt(point: TVec2i): TImagePixel;
begin
	result := PixelAt(point.x, point.y);
end;

procedure TTextureSource.Lock(inUnit: TGLTextureUnit);
begin
	Assert(not IsLocked, 'Texture is already locked');
	LoadIfNeeded;
	ChangeTextureUnit(self, inUnit);
	m_textureUnit := inUnit;
	writeln('bound and locked texture ', textureID, ' to unit ', GetTextureUnit);
end;

procedure TTextureSource.Unlock;
begin
	Assert(IsLocked, 'Texture is already unlocked');
	TextureSlots[GetTextureUnit].SetTexture(nil);
end;

procedure TTextureSource.LoadIfNeeded;
begin
	if not IsLoaded then
		Load;
end;

procedure TTextureSource.Load;
begin
end;

procedure TTextureSource.Unload;
begin
end;

function TTextureSource.IsLoaded: boolean;
begin
	result := textureID > 0;
end;

function TTextureSource.IsLocked: boolean;
begin
	result := TextureSlots[GetTextureUnit].obj = ITexture(self);
end;

function TTextureSource.GetTexture: TGLTextureID;
begin
	result := textureID;
end;

function TTextureSource.GetTextureUnit: TGLTextureUnit;
begin
	if owner <> nil then
		result := owner.GetTextureUnit
	else
	result := m_textureUnit;
end;

//#########################################################
// TEXTURE PACK
//#########################################################

constructor TTexturePack.Create;
begin
	scale := 1.0;
	textureParams := DefaultTextureParameters;
	textures := TTextureMap.Create;
end;

constructor TTexturePack.Create (_path: ansistring);
begin
	path := _path;
	scale := 1.0;
	textureParams := DefaultTextureParameters;
	textures := TTextureMap.Create;
end;

destructor TTexturePack.Destroy;
begin
	FreeAndNil(textures);
	if IsLoaded then
		DeleteTexture(textureID);
	if assigned(sourceImage) then
		FreeMem(sourceImage);
	inherited;
end;

procedure TTexturePack.SetTextureParameters (newValue: TTextureParameters); 
begin
	Assert(not IsLoaded, 'texture parameters must be set before loading.');
	textureParams := newValue;
end;

function TTexturePack.GetCount: integer;
begin
	result := textures.Count;
end;

function TTexturePack.GetTexture (name: string): TTexture;
begin
	LoadIfNeeded;
	Assert(textures <> nil, 'Pack textures haven''t been allocated.');
	result := textures[name] as TTexture;
	Assert(result <> nil, 'Pack face "'+name+'" is nil.');
end;

function TTexturePack.PixelAt(x, y: integer): TImagePixel;
begin
	Assert(IsLoaded, 'Texture must be loaded before inspecting pixels.');
	Assert(sourceImage <> nil, 'Texture image data was freed before inspecting pixels.');
	result := sourceImage[x + y * trunc(textureSize.width)];
end;

procedure TTexturePack.LoadImage (imagePath: ansistring);
var
	width, height: integer;
begin
	sourceImage := LoadImageFromFile(imagePath, width, height);
	if assigned(sourceImage) then
		begin
			GenerateTexture(m_textureID);

			BindTexture2D(textureID);
			LoadTexture2D(width, height, sourceImage, textureParams);
			RestoreTextureUnit(0, textureID);

			m_textureFrame.texture := RectMake(0, 0, 1, 1);
			m_textureFrame.pixel := RectMake(0, 0, width, height);
		end;
end;

procedure TTexturePack.AddTexture (name: string; constref spriteSize: TVec2; constref offset, position, pivot: TVec2); 
var
	texture: TTexture; 
begin
	Assert(textureID > 0, 'must load image before adding textures');
	texture := TTexture.Create(self);
	texture.SetTextureFrame(PixelToTexture(RectMake(position, spriteSize)));
	texture.SetSize(spriteSize * scale);
	texture.SetPixelFrame(RectMake(position, spriteSize));
	textures.Add(name, texture);
end;

procedure TTexturePack.Load;
type
	TVariantMap = specialize TFPGMap<string, Variant>;
var
	memoryPool: TObjectList;

	function NodeAttributes (node: TDOMNode): TVariantMap;
	var
		i: integer;
	begin
		result := TVariantMap.Create;
		for i := 0 to node.Attributes.Length - 1 do
			result.Add(node.Attributes.Item[i].NodeName, node.Attributes.Item[i].NodeValue);
		memoryPool.Add(result);
	end;

var
	xml: TXMLDocument;
	node, child: TDOMNode;
	attributes: TVariantMap;
	imagePath: ansistring;
	spriteSize, originalSize: TVec2;
	offset, position, pivot: TVec2;
begin	
	Assert(not IsLoaded, 'Texture is already loaded.');

	memoryPool := TObjectList.Create(true);
	ReadXMLFile(xml, path);
	
	node := xml.DocumentElement;
	if node.NodeName = 'TextureAtlas' then
		begin
			attributes := NodeAttributes(node);			

			// use absolute or relative paths
			imagePath := ExtractFileDir(path);
			if imagePath <> '' then
				imagePath := imagePath+'/'+attributes['imagePath']
			else
				imagePath := attributes['imagePath'];
			LoadImage(imagePath);

			//textureSize := V2(attributes['width'], attributes['height']);
			m_textureFrame.texture := RectMake(0, 0, 1, 1);
			m_textureFrame.pixel := RectMake(0, 0, attributes['width'], attributes['height']);

			// loop through all <sprite> tags
			node := node.FirstChild;	
			while node <> nil do
				begin
					attributes := NodeAttributes(node);
					
					spriteSize := V2(attributes['w'], attributes['h']);
					
					// TODO: what is originalSize used for?
					//if attributes.Indexof('oW') <> -1 then
					//	originalSize := V2(attributes['oW'], attributes['oH'])
					//else
					//	originalSize := spriteSize;
					
					if attributes.Indexof('oX') <> -1 then
						offset := V2(attributes['oX'], attributes['oY'])
					else
						offset := V2(0, 0);

					position := V2(attributes['x'], attributes['y']);
					pivot := V2(attributes['pX'], attributes['pY']);
										
					AddTexture(ExtractFileParts(attributes['n']).name, spriteSize, offset, position, pivot);

					node := node.NextSibling;
				end;
		end;
	
	xml.Free;
	memoryPool.Free;
end;

//#########################################################
// TEXTURE COMPOSITE
//#########################################################
		
constructor TTextureComposite.Create(canvasSize: TVec2i; images: TImagePathArray);
begin
	textureParams := DefaultTextureParameters;
	textures := TTextureMap.Create;
	m_textureFrame.texture := RectMake(0, 0, 1, 1);
	m_textureFrame.pixel := RectMake(0, 0, canvasSize);
	imagePaths := images;
end;

function TTextureComposite.GetTexture (name: string): TTexture;
begin
	LoadIfNeeded;
	Assert(textures <> nil, 'Pack textures haven''t been allocated.');
	result := textures[name] as TTexture;
	Assert(result <> nil, 'Pack face "'+name+'" is nil.');
end;

function TTextureComposite.GetCount: integer;
begin
	result := textures.Count;
end;

procedure TTextureComposite.SetTextureParameters (newValue: TTextureParameters); 
begin
	Assert(not IsLoaded, 'texture parameters must be set before loading.');
	textureParams := newValue;
end;

procedure TTextureComposite.Load;
var
	width, height: integer;
	image: TImage;
	offset: TVec2i;
	imagePath: string;
	rect: TRect;
	texture: TTexture;
begin
	Assert(not IsLoaded, 'Texture is already loaded.');

	GenerateTexture(m_textureID);
	BindTexture2D(textureID);
	LoadTexture2D(trunc(textureSize.width), trunc(textureSize.height), nil, textureParams);

	offset := 0;

	for imagePath in imagePaths do
		begin
			image := LoadImageFromFile(imagePath, width, height);
			// TODO: respect texture params for target type
			glTexSubImage2D(GL_TEXTURE_2D, 0, offset.x, offset.y, width, height, GL_RGBA, GL_UNSIGNED_BYTE, image);
			GLAssert('glTexSubImage2D');	

			rect := RectMake(offset, width, height);

			texture := TTexture.Create(self);
			texture.SetTextureFrame(PixelToTexture(rect));
			texture.SetSize(V2(width, height));
			texture.SetPixelFrame(rect);
			textures.Add(ExtractFileParts(imagePath).name, texture);

			// TODO: replace with bin packer, UPacker works?
			offset.x += width;
			FreeMem(image);
		end;

	RestoreTextureUnit(0, textureID);
end;

function TTextureComposite.Subdivide (cellSize: TVec2): TTextureSheet;
var
	tableSize: TVec2;
begin
	LoadIfNeeded;

	tableSize.width := trunc(textureSize.width / cellSize.width);
	tableSize.height := trunc(textureSize.height / cellSize.height);

	result := TTextureSheet.Create(GetTexture, GetFrame, cellSize, tableSize);
end;

destructor TTextureComposite.Destroy;
begin
	FreeAndNil(textures);
	if IsLoaded then
		DeleteTexture(textureID);
end;


//#########################################################
// TEXTURE SHEET
//#########################################################

function TTextureSheet.GetTexture (index: integer): TTexture;
begin
	LoadIfNeeded;
	result := TTexture(textures[index]);
end;

function TTextureSheet.GetTexture (x, y: integer): TTexture;
begin
	result := GetTexture(V2(x, y));
end;

function TTextureSheet.GetIndex (x, y: integer): integer;
begin
	result := Trunc((tableSize.width * y) + x);
end;

function TTextureSheet.GetTexture (cell: TVec2): TTexture;
begin
	LoadIfNeeded;
	result := TTexture(textures[GetIndex(trunc(cell.x), trunc(cell.y))]);
end;

function TTextureSheet.Columns: integer;
begin
	result := TableSize.width;
end;

function TTextureSheet.Rows: integer;
begin
	result := TableSize.height;
end;

function TTextureSheet.GetCellSize: TVec2i;
begin
	LoadIfNeeded;
	result := m_cellSize;
end;

function TTextureSheet.GetTableSize: TVec2i;
begin
	LoadIfNeeded;
	result := m_tableSize;
end;

function TTextureSheet.GetCount: integer;
begin
	result := textures.Count;
end;

function TTextureSheet.GetTextures: TTextureList;
begin
	result := textures;
end;

destructor TTextureSheet.Destroy;
begin
	textures.Free;
	inherited;
end;

procedure TTextureSheet.Subdivide;
var
	x, y: integer;
	cellFrame: TRect;
	scale: TVec2;
	texture: TTexture;
	spanX, spanY: float;
begin
	Assert(textures = nil, 'Texture sheet is already subdivided.');
	Assert(textureSize.x + textureSize.y > 0, 'Texture sheet must be larger than 0 in order to subdivide.');

	LoadIfNeeded;

	textures := TTextureList.Create(true);

	if (tableSize.width = 0) or (tableSize.height = 0) then
		begin
			// TODO: bug in helpers so we need to access directly
			// https://bugs.freepascal.org/view.php?id=36768
			m_tableSize.width := trunc(textureSize.width / cellSize.width);
			m_tableSize.height := trunc(textureSize.height / cellSize.height);
		end;

	//writeln('textureSize: ',textureSize.Tostr);
	//writeln('tableSize: ',tableSize.tostr);
	//writeln('cellSize: ',cellSize.tostr);

	for y := tableSize.height downto 1 do
		for x := 1 to tableSize.width do
			begin
				scale := V2((tableSize.width * cellSize.width) / textureSize.width, 
										(tableSize.height * cellSize.height) / textureSize.height);
				
				spanX := TextureFrame.Width;
				spanY := TextureFrame.Height;

				cellFrame.origin.x := TextureFrame.MinX + (((x - 1) * (spanX / tableSize.width)) * scale.width);
				cellFrame.origin.y := TextureFrame.MinY + (((spanY - ((spanY / tableSize.height) * y))) * scale.height);
				cellFrame.size.x := (spanX / tableSize.width) * scale.width;
				cellFrame.size.y := (spanX / tableSize.height) * scale.height;

				texture := TTexture.Create(self);
				texture.SetTextureFrame(cellFrame);
				texture.SetPixelFrame(RectMake(V2((x - 1) * cellSize.width, (tableSize.height - y) * cellSize.height), cellSize));
				texture.SetSize(cellSize);
				textures.Add(texture);
			end;
end;

procedure TTextureSheet.Load;
begin
	inherited;
	Subdivide;
end;

constructor TTextureSheet.Create (path: ansistring; inCellSize, inTableSize: TVec2i);
begin
	inherited Create(path);
	m_cellSize := inCellSize;
	m_tableSize := inTableSize;
end;

constructor TTextureSheet.Create (path: ansistring; inCellSize: TVec2i);
begin
	Create(path, inCellSize, 0);
end;

constructor TTextureSheet.Create (inTextureID: TGLTextureID; inTextureFrame: TTextureFrame; inCellSize, inTableSize: TVec2i);
begin
	inherited Create(inTextureID, trunc(inTextureFrame.pixel.width), trunc(inTextureFrame.pixel.height));
	m_cellSize := inCellSize;
	m_tableSize := inTableSize;
	m_textureFrame := inTextureFrame;
	Subdivide;
end;

//#########################################################
// TEXTURE
//#########################################################

procedure TTexture.SetTextureFrame (newValue: TRect);
begin
	m_textureFrame.texture := newValue;
end;

procedure TTexture.SetPixelFrame (newValue: TRect);
begin
	m_textureFrame.pixel := newValue;
end;

function TTexture.Splice(rect: TRect): TTexture;
begin
	LoadIfNeeded;
	result := TTexture.Create(self, rect, PixelToTexture(rect));
	if slices = nil then
		slices := TTextureList.Create;
	slices.Add(result);
end;

function TTexture.Subdivide (cellSize: TVec2): TTextureSheet;
var
	tableSize: TVec2;
begin
	LoadIfNeeded;
	tableSize.width := trunc(textureSize.width / cellSize.width);
	tableSize.height := trunc(textureSize.height / cellSize.height);
	result := TTextureSheet.Create(GetTexture, GetFrame, cellSize, tableSize);
end;

procedure TTexture.LoadImage (image: TImage);
begin
	generatedTexture := true;
	GenerateTexture(m_textureID);
	
	BindTexture2D(textureID);
	LoadTexture2D(GetWidth, GetHeight, image, textureParams);
	RestoreTextureUnit(0, textureID);

	// TOOD: make this an option? we need to keep it around for PixelAt but this can be an option
	//FreeMem(sourceImage);
	//sourceImage := nil;
end;

function TTexture.PixelAt(x, y: integer): TImagePixel;
begin
	// if the texture has an owner then offset to the owners
	// cooridinate space and sample from the owner
	if owner <> nil then
		result := owner.PixelAt(PixelFrame.origin + V2(x, y))
	else
		begin
			Assert(IsLoaded, 'Texture must be loaded before inspecting pixels.');
			Assert(sourceImage <> nil, 'Texture image data was freed before inspecting pixels.');
			result := sourceImage[x + y * trunc(textureSize.width)];
		end;
end;

procedure TTexture.Load;
begin
	Assert(not IsLoaded, 'Texture is already loaded.');
	LoadImage(sourceImage);
end;

procedure TTexture.Lock(inUnit: TGLTextureUnit);
begin
	if owner <> nil then
		owner.Lock(inUnit)
	else
		inherited Lock(inUnit);
end;

function TTexture.IsLocked: boolean;
begin
	if owner <> nil then
		result := owner.IsLocked
	else
		result := inherited;
end;

procedure TTexture.SetSize (newValue: TVec2);
begin
	Assert(newValue.Max < GetMaximumTextureSize, 'Sprite face texture exceeds maximum texture size ('+IntToStr(GetMaximumTextureSize)+')');
	m_textureFrame.pixel.size := newValue;
end;

function TTexture.GetSize: TVec2;
begin
	result := TextureSize;
end;

function TTexture.GetBounds: TRect;
begin
	result := RectMake(0, 0, TextureSize.width, TextureSize.height);
end;

function TTexture.GetWidth: integer;
begin
	result := trunc(GetSize.width);
end;

function TTexture.GetHeight: integer;
begin
	result := trunc(GetSize.height);
end;

destructor TTexture.Destroy;
begin	
	// delete the texture if we own it
	if generatedTexture and (textureID <> 0) then
		DeleteTexture(textureID);					
	
	if assigned(sourceImage) then
		FreeMem(sourceImage);

	if assigned(slices) then
		slices.Free;

	inherited;
end;

constructor TTexture.Create (source: TTextureSource; inPixelFrame, inTextureFrame: TRect);
begin
	Create(source);
	m_textureFrame.pixel := inPixelFrame;
	m_textureFrame.texture := inTextureFrame;
	textureParams := DefaultTextureParameters;
end;

constructor TTexture.Create (source: TTextureSource);
begin
	m_owner := source;
	m_textureID := source.GetTexture;
	Create(textureID);
end;

constructor TTexture.Create (texture: TGLTextureID; width: integer = 0; height: integer = 0);
begin
	Assert(texture > 0, 'Must use a valid texture ID.');
	m_textureID := texture;
	SetSize(V2(width, height));
	SetTextureFrame(RectMake(0, 0, 1, 1));
	textureParams := DefaultTextureParameters;
end;

constructor TTexture.Create (path: ansistring);
var
	width, height: integer;
begin
	sourceImage := LoadImageFromFile(path, width, height);
	SetSize(V2(width, height));
	SetTextureFrame(RectMake(0, 0, 1, 1));
	textureParams := DefaultTextureParameters;
end;

{$endif}
