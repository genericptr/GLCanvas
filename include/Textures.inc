
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
	TColor = TVec4;
	// TODO: what are we doing for image data now? we have png and tga loaders
	TImage = pointer;

type
	ITexture = interface
		function GetTexture: TGLTextureID;
		function GetTextureUnit: TGLTextureUnit;
	end;	

type
	TTextureSource = class
		public
			function TextureFrameForTextureSpace (textureSpace: TRect): TRect; virtual;
			procedure SetTextureUnit (newValue: TGLTextureUnit);
			function GetTextureUnit: TGLTextureUnit;

			procedure Load; virtual;
			procedure Unload; virtual;
			function IsLoaded: boolean; virtual;
			function GetName: string; virtual;
		private
			textureUnit: TGLTextureUnit;
	end;
	
type
	TTexture = class (ITexture)
		public
			
			{ Constructors }
			constructor Create (path: ansistring); overload;
			constructor Create (texture: TGLTextureID); overload;
			
			{ Accessors }
			procedure SetTint (newValue: TColor);
			procedure SetTextureFrame (newValue: TRect);
			procedure SetCropping (newValue: TRect);
			procedure SetTextureSpace (newValue: TRect);

			function GetSize: TVec2; inline;
			function GetBounds: TRect; inline;
			function GetHeight: integer; inline;
			function GetWidth: integer; inline;
			function GetTint: TColor; inline;
			function GetCropping: TRect; inline;
			function GetTexture: TGLTextureID; inline;
			function GetTextureFrame: TRect; inline;
			function GetPivot: TVec2; inline;
			function GetTextureSpace: TRect; inline;
			function GetOwner: TTextureSource; inline;
			function GetTextureUnit: TGLTextureUnit; inline;
			
			{ Methods } 
			procedure Load;

		private
			faceSize: TVec2;
			sourceImage: TImage;
			tint: TColor;
			cropping: TRect; 
			textureFrame: TRect;
			textureSpace: TRect;
			textureID: TGLTextureID;
			textureUnit: TGLTextureUnit;
			pivot: TVec2;
			owner: TTextureSource;
			faceName: string;
			originalSize: TVec2;
			generatedTexture: boolean;
			texParams: TTextureParameters;

			destructor Destroy; override;
			procedure Initialize;
			procedure SetOwner (newValue: TTextureSource);
			procedure SetSize (newValue: TVec2);
			procedure LoadImage (image: TImage);
	end;
	TTextureList = specialize TFPGObjectList<TTexture>;
	TTextureMap = specialize TFPGMap<string, TTexture>;

type
	TTextureSheet = class (TTextureSource, ITexture)
		public
			cellSize: TVec2;
			tableSize: TVec2;
		public
					
			{ Constructors }
			constructor Create (path: ansistring; _cellSize: TVec2); overload;
			constructor Create (path: ansistring; _cellSize: TVec2; _tableSize: TVec2); overload;
			
			{ Accessors }
			function GetCount: integer;
			function GetTextures: TTextureList;
			function GetTexture: TGLTextureID;

			function TextureFrameForTextureSpace (textureSpace: TRect): TRect; override;

			{ Faces }
			function GetTexture (index: integer): TTexture; overload;
			function GetTexture (cell: TVec2): TTexture; overload;
			function GetTexture (x, y: integer): TTexture; overload;
			property Indexer[x, y: integer]: TTexture read GetTexture; default;

			procedure Load; override;
			procedure Unload; override;
			function IsLoaded: boolean; override;
			function GetName: string; override;		
		private
			textures: TTextureList;
			textureID: TGLTextureID;
			textureSize: TVec2;
			texParams: TTextureParameters;
			sourceImage: TImage;
			imageWidth, imageHeight: integer;

			destructor Destroy; override;
			procedure LoadImage (image: TImage);
			procedure LoadFromTexture (size: TVec2);
			function GetIndex (x, y: integer): integer;
	end;

type
	TTexturePack = class (TTextureSource, ITexture)
		public
			
			{ Constructors }
			constructor Create; overload;
			constructor Create (_path: ansistring); overload;
			
			{ Accessors }
			function GetTexture (name: string): TTexture;
			function GetCount: integer;
			procedure SetTextureParameters (newValue: TTextureParameters); 
			function GetTexture: TGLTextureID;

			function TextureFrameForTextureSpace (textureSpace: TRect): TRect; override;

			property Indexer[name: string]: TTexture read GetTexture; default;

			procedure Load; override;
			procedure Unload; override;
			function IsLoaded: boolean; override;
			function GetName: string; override;

		private
			textureID: TGLTextureID;
			textures: TTextureMap;
			textureSize: TVec2;
			path: string;
			faceName: string;
			texParams: TTextureParameters;
			scale: TScalar;

			procedure LoadImage (imagePath: ansistring);
			procedure AddTexture (name: string; constref spriteSize, originalSize: TVec2; constref offset, position, pivot: TVec2); 

			destructor Destroy; override;
	end;

function RGBA(r, g, b, a: TScalar): TColor; inline;

{$endif}

{$ifdef IMPLEMENTATION}

var
	DefaultTextureParameters: TTextureParameters = [kTextureNearestFilter, kTextureClampToEdge];
	textureSlots: array[0..64-1] of TGLTextureID;
	nextAvailableTextureUnit: TGLTextureUnit;

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


//$bookmark -
//$bookmark OPENGL UTILITIES
//$bookmark -

var
	RealMaximumTextureUnits: integer = 0;
	RealMaximumVerticies: integer = 0;
	RealMaximumTexureSize: integer = 0;

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
	result := RealMaximumTextureUnits;
end;

function GetMaximumVerticies: integer; 
begin
	if RealMaximumVerticies = 0 then
		glGetIntegerv(GL_MAX_ELEMENTS_VERTICES, @RealMaximumVerticies);
	result := RealMaximumVerticies;
end;

function GetNextAvailableTextureUnit: TGLTextureUnit;
begin
	Assert(nextAvailableTextureUnit < GetMaximumTextureUnits, 'not enough free texture units');
	result := nextAvailableTextureUnit;
	nextAvailableTextureUnit += 1;
end;

procedure GenerateTexture (var texID: TGLTextureID);
begin
	glGenTextures(1, @texID);
end;	

procedure DeleteTexture (texID: TGLTextureID);
begin
	glDeleteTextures(1, @texID);
end;

function BindTexture2D (texID: TGLTextureID; texUnit: TGLTextureUnit = 0): boolean;
begin
	Assert((texUnit < GetMaximumTextureUnits) and (texUnit >= 0), 'texture unit '+IntToStr(texUnit)+' is out of bounds (0-'+IntToStr(GetMaximumTextureUnits-1)+')');
	glActiveTexture(GL_TEXTURE0 + texUnit);
	glBindTexture(GL_TEXTURE_2D, texID);
	Assert(glGetError() = 0, 'glBindTexture error '+IntToStr(glGetError()));
	textureSlots[texUnit] := texID;
	writeln('bind texture id: ', texID, ' to unit #', texUnit);
end;
	
procedure LoadTexture2D (width, height: GLsizei; data: pointer; params: TTextureParameters = []);
begin
	if kTextureRGB in params then
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, data)
	else
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);

	Assert(glGetError() = 0, 'glTexImage2D error '+IntToStr(glGetError()));

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

//$bookmark -
//$bookmark IMAGES
//$bookmark -
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

function LoadImageFromFile (path: ansistring; out width, height: integer): pointer;
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

//$bookmark -
//$bookmark TYPE HELPERS
//$bookmark -

function RGBA(r, g, b, a: TScalar): TColor;
begin
	result := V4(r, g, b, a);
end;

//$bookmark -
//$bookmark TEXTURE SOURCE
//$bookmark -

function TTextureSource.TextureFrameForTextureSpace (textureSpace: TRect): TRect;
begin
	result := RectMake(0, 0, 0, 0);
end;

procedure TTextureSource.SetTextureUnit (newValue: TGLTextureUnit);
begin
	textureUnit := newValue;
end;

function TTextureSource.GetTextureUnit: TGLTextureUnit;
begin
	if not IsLoaded then
		Load;
	result := textureUnit;
end;

procedure TTextureSource.Load;
begin
end;

procedure TTextureSource.Unload;
begin
end;

function TTextureSource.IsLoaded: boolean;
begin
	result := false;
end;

function TTextureSource.GetName: string;
begin
	result := '';
end;

//$bookmark -
//$bookmark TEXTURE PACK
//$bookmark -

type
	TFPGObjectMap =  specialize TFPGMap<string, TObject>;

procedure FreeMapAndObjects (var inMap); 
var
	i: integer;
	map: TFPGObjectMap absolute inMap;
begin
	for i := 0 to map.Count - 1 do
		if assigned(map.data[i]) then
			map.data[i].Free;
	map.Free;
end;

constructor TTexturePack.Create;
begin
	scale := 1.0;
	texParams := DefaultTextureParameters;
end;

constructor TTexturePack.Create (_path: ansistring);
begin
	path := _path;
	scale := 1.0;
	texParams := DefaultTextureParameters;
end;

destructor TTexturePack.Destroy;
begin
	FreeMapAndObjects(textures);
	if textureID <> 0 then
		glDeleteTextures(1, @textureID);
end;

function TTexturePack.TextureFrameForTextureSpace (textureSpace: TRect): TRect;
begin
	result := RectMake(textureSpace.MinX / textureSize.width, textureSpace.MinY / textureSize.height, textureSpace.width / textureSize.width, textureSpace.height / textureSize.height);
end;

procedure TTexturePack.SetTextureParameters (newValue: TTextureParameters); 
begin
	Assert(not IsLoaded, 'texture parameters must be set before loading.');
	texParams := newValue;
end;

function TTexturePack.GetTexture: TGLTextureID;
begin
	result := textureID;
end;

function TTexturePack.GetCount: integer;
begin
	result := textures.Count;
end;

function TTexturePack.GetTexture (name: string): TTexture;
begin
	if not IsLoaded then
		Load;
	Assert(textures <> nil, 'Pack textures haven''t been allocated.');
	result := textures[name] as TTexture;
	Assert(result <> nil, 'Pack face "'+name+'" is nil.');
end;

procedure TTexturePack.Unload;
begin
	Assert(false, 'face pack can''t unload');
end;

function TTexturePack.IsLoaded: boolean;
begin
	result := textures <> nil;
end;

function TTexturePack.GetName: string;
begin
	result := faceName;
end;

procedure TTexturePack.LoadImage (imagePath: ansistring);
var
	parts: TFileParts;
	image: TImage;
	width, height: integer;
begin
	Assert(FileExists(imagePath), imagePath+' for sprite pack doesn'' exist.');
	textureID := 0;
	parts := ExtractFileParts(imagePath);
	image := LoadImageFromFile(imagePath, width, height);
	if assigned(image) then
		begin
			textureUnit := GetNextAvailableTextureUnit;
			GenerateTexture(textureID);
			BindTexture2D(textureID, textureUnit);
			LoadTexture2D(width, height, image, texParams);
			// assume texture size is the same as image size
			textureSize := V2(width, height);
			FreeMem(image);
		end;
	Assert(textureID >= 0, 'No texture loaded for sprite sheet');
end;

procedure TTexturePack.AddTexture (name: string; 	constref spriteSize, originalSize: TVec2; constref offset, position, pivot: TVec2); 
var
	texture: TTexture; 
begin
	Assert(textureID > 0, 'must load image before adding textures');
	texture := TTexture.Create(textureID);
	texture.SetTextureFrame(TextureFrameForTextureSpace(RectMake(position, spriteSize)));
	texture.SetSize(spriteSize*scale);
	texture.SetCropping(RectMake(offset, originalSize));
	texture.SetTextureSpace(RectMake(position, spriteSize));
	texture.SetOwner(self);
	texture.pivot := pivot;
	texture.originalSize := originalSize;
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
	memoryPool := TObjectList.Create(true);
	textures := TTextureMap.Create;
	ReadXMLFile(xml, path);
	
	node := xml.DocumentElement;
	if node.NodeName = 'TextureAtlas' then
		begin
			attributes := NodeAttributes(node);			

			imagePath := ExtractFileDir(path);
			imagePath := imagePath+'/'+attributes['imagePath'];
			LoadImage(imagePath);

			textureSize := V2(attributes['width'], attributes['height']);

			// loop through all <sprite> tags
			node := node.FirstChild;	
			while node <> nil do
				begin
					attributes := NodeAttributes(node);
					
					spriteSize := V2(attributes['w'], attributes['h']);
					originalSize := V2(attributes['oW'], attributes['oH']);
					offset := V2(attributes['oX'], attributes['oY']);
					position := V2(attributes['x'], attributes['y']);
					pivot := V2(attributes['pX'], attributes['pY']);
										
					AddTexture(ExtractFileParts(attributes['n']).name, spriteSize, originalSize, offset, position, pivot);

					node := node.NextSibling;
				end;
		end;
	
	xml.Free;
	memoryPool.Free;
end;

//$bookmark -
//$bookmark TEXTURE SHEET
//$bookmark -

function TTextureSheet.GetTexture (index: integer): TTexture;
begin
	if not IsLoaded then
		Load;
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
	if not IsLoaded then
		Load;
	result := TTexture(textures[GetIndex(trunc(cell.x), trunc(cell.y))]);
end;


function TTextureSheet.GetCount: integer;
begin
	result := textures.Count;
end;

function TTextureSheet.GetTextures: TTextureList;
begin
	result := textures;
end;

function TTextureSheet.GetTexture: TGLTextureID;
begin
	if not IsLoaded then
		Load;
	result := textureID;
end;

function TTextureSheet.TextureFrameForTextureSpace (textureSpace: TRect): TRect;
begin
	result := RectMake(textureSpace.minX / textureSize.width, textureSpace.minY / textureSize.height, textureSpace.width / textureSize.width, textureSpace.height / textureSize.height);
end;

destructor TTextureSheet.Destroy;
begin
	textures.Free;
	FreeMem(sourceImage);
end;

procedure TTextureSheet.LoadImage (image: TImage);
var
	x, y: integer;
begin
	//tableSize.width := image.GetWidth / cellSize.width;
	//tableSize.height := image.GetHeight / cellSize.height;
	//writeln('table size: ', tstr(tableSize));
	
	// generate texture
	texParams := DefaultTextureParameters;
	textureUnit := GetNextAvailableTextureUnit;
	GenerateTexture(textureID);
	BindTexture2D(textureID, textureUnit);
	LoadTexture2D(imageWidth, imageHeight, image, texParams);
	Assert(textureID > 0, 'No texture loaded for sprite sheet');
end;

procedure TTextureSheet.LoadFromTexture (size: TVec2);
var
	x, y: integer;
	cellFrame: TRect;
	scale: TVec2;
	texture: TTexture;
begin
	Assert(textures = nil, 'Already loaded textures.');
	textures := TTextureList.Create(true);
	textureSize := size;
	for y := Round(tableSize.height) downto 1 do
		for x := 1 to Round(tableSize.width) do
			begin
				scale := V2((tableSize.width * cellSize.width) / size.width, (tableSize.height * cellSize.height) / size.height);
				cellFrame := RectMake(((x - 1) * (1 / tableSize.width)) * scale.width, ((1 - ((1 / tableSize.height) * y))) * scale.height, (1 / tableSize.width) * scale.width, (1 / tableSize.height) * scale.height);
				
				texture := TTexture.Create(GetTexture);
				texture.SetTextureFrame(cellFrame);
				texture.SetTextureSpace(RectMake(V2((x-1) * cellSize.width, (tableSize.height-y) * cellSize.height), cellSize));
				texture.SetSize(cellSize);
				texture.SetOwner(self);
				textures.Add(texture);
			end;
end;

procedure TTextureSheet.Unload;
begin
	Assert(false, 'face sheet can''t unload');
end;

function TTextureSheet.IsLoaded: boolean;
begin
	result := textures <> nil;
end;

function TTextureSheet.GetName: string;
begin
	result := 'TTextureSheet';
end;

procedure TTextureSheet.Load;
begin
	LoadImage(sourceImage);
	LoadFromTexture(V2(imageWidth, imageHeight));
	FreeMem(sourceImage);
end;

constructor TTextureSheet.Create (path: ansistring; _cellSize: TVec2; _tableSize: TVec2);
begin
	textureID := 0;
	sourceImage := LoadImageFromFile(path, imageWidth, imageHeight);
	cellSize := _cellSize;


	if _tableSize.Max = 0 then
		begin
			tableSize.width := trunc(imageWidth / cellSize.width);
			tableSize.height := trunc(imageHeight / cellSize.height);
		end
	else
		tableSize := _tableSize;
	
	writeln('imageSize:',V2(imageWidth, imageHeight).Tostr);
	writeln('tableSize:',tableSize.tostr);
	writeln('cellSize:',cellSize.tostr);
end;

constructor TTextureSheet.Create (path: ansistring; _cellSize: TVec2);
begin
	Create(path, _cellSize, V2(0, 0));
end;

//$bookmark -
//$bookmark TEXTURE
//$bookmark -

procedure TTexture.SetTint (newValue: TColor);
begin
	tint := newValue;
end;

procedure TTexture.SetTextureFrame (newValue: TRect);
begin
	textureFrame := newValue;
end;

procedure TTexture.SetTextureSpace (newValue: TRect);
begin
	textureSpace := newValue;
end;

procedure TTexture.SetCropping (newValue: TRect);
begin
	cropping := newValue;
end;

procedure TTexture.SetOwner (newValue: TTextureSource);
begin
	owner := newValue;
end;

procedure TTexture.LoadImage (image: TImage);
begin
	GenerateTexture(textureID);
	generatedTexture := true;
	textureUnit := GetNextAvailableTextureUnit;	
	textureFrame := RectMake(0, 0, faceSize.width, faceSize.height);

	BindTexture2D(textureID, textureUnit);
	LoadTexture2D(trunc(faceSize.width), trunc(faceSize.height), image, texParams);

	FreeMem(sourceImage);
	sourceImage := nil;
end;

procedure TTexture.Load;
begin
	if (textureID = 0) and assigned(sourceImage) then
		LoadImage(sourceImage);
end;

procedure TTexture.SetSize (newValue: TVec2);
begin
	faceSize := newValue;
	if faceSize.Max > GetMaximumTextureSize then
		raise Exception.Create('Sprite face texture exceeds maximum texture size ('+IntToStr(GetMaximumTextureSize)+')');
end;

function TTexture.GetSize: TVec2;
begin
	result := faceSize;
end;

function TTexture.GetBounds: TRect;
begin
	result := RectMake(0, 0, faceSize.width, faceSize.height);
end;

function TTexture.GetWidth: integer;
begin
	result := trunc(GetSize.width);
end;

function TTexture.GetHeight: integer;
begin
	result := trunc(GetSize.height);
end;

function TTexture.GetTexture: TGLTextureID;
begin
	result := textureID;
end;

function TTexture.GetTextureFrame: TRect;
begin
	result := textureFrame;
end;

function TTexture.GetPivot: TVec2;
begin
	result := pivot;
end;

function TTexture.GetTextureSpace: TRect;
begin
	result := textureSpace;
end;

function TTexture.GetOwner: TTextureSource;
begin
	result := owner;
end;

function TTexture.GetTextureUnit: TGLTextureUnit;
begin
	if assigned(owner) then
		result := owner.GetTextureUnit
	else
		result := textureUnit;
end;

function TTexture.GetTint: TColor;
begin
	result := tint;
end;

function TTexture.GetCropping: TRect;
begin
	result := cropping;
end;

procedure TTexture.Initialize;
begin
	tint := V4(1, 1, 1, 0);
	SetTextureFrame(RectMake(0, 0, 1, 1));
	texParams := DefaultTextureParameters;
end;

destructor TTexture.Destroy;
begin	
	// delete the texture if we own it
	if generatedTexture and (textureID <> 0) then
		DeleteTexture(textureID);					
	
	if assigned(sourceImage) then
		FreeMem(sourceImage);
end;

constructor TTexture.Create (texture: TGLTextureID);
begin
	textureID := texture;
	Initialize;
end;

constructor TTexture.Create (path: ansistring);
var
	width, height: integer;
begin
	sourceImage := LoadImageFromFile(path, width, height);
	SetSize(V2(width, height));
	Initialize;
end;

{$endif}
