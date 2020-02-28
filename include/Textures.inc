
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
		function GetTextureFrame: TTextureFrame;
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

			function TextureToPixel (textureRect: TRect): TRect;
			function PixelToTexture (pixelRect: TRect): TRect;
			function GetTextureFrame: TTextureFrame;

			function PixelAt(x, y: integer): TImagePixel;

			procedure Lock(inUnit: TGLTextureUnit);
			procedure Unlock;
			procedure Load;
			procedure Unload;
			function IsLoaded: boolean;
			function IsLocked: boolean;
		private
			textureID: TGLTextureID;
			textureUnit: TGLTextureUnit;
			textureFrame: TTextureFrame;
			m_locked: boolean;
		public
			property TextureSize: TVec2 read textureFrame.pixel.size;
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

			function GetTextureFrame: TTextureFrame;
			function GetSize: TVec2; inline;
			function GetBounds: TRect; inline;
			function GetHeight: integer; inline;
			function GetWidth: integer; inline;
			function GetTexture: TGLTextureID; inline;
			
			{ Methods } 
			procedure Load; virtual;
			function IsLoaded: boolean;
			destructor Destroy; override;
			function PixelAt(x, y: integer): TImagePixel;
			
			function Subdivide (cellSize: TVec2): TTextureSheet;
			function Splice(rect: TRect): TTexture;

		private
			sourceImage: TImage;
			generatedTexture: boolean;
			textureParams: TTextureParameters;
			slices: TTextureList;

			procedure SetSize (newValue: TVec2);
			procedure LoadImage (image: TImage);
			constructor Create (texture: TGLTextureID; inPixelFrame, inTextureFrame: TRect);
	end;
	TTextureMap = specialize TFPGMapObject<String, TTexture>;
	TTextureArray = array of TTexture;

	TTextureSheet = class (TTexture)
		public
			cellSize: TVec2i;
			tableSize: TVec2i;
		public
					
			{ Constructors }
			constructor Create (path: ansistring; _cellSize: TVec2); overload;
			constructor Create (path: ansistring; _cellSize: TVec2; _tableSize: TVec2); overload;

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

			procedure Load; override;
			destructor Destroy; override;
		private
			textures: TTextureList;
			procedure Subdivide;
			function GetIndex (x, y: integer): integer; inline;
			constructor Create (_textureID: TGLTextureID; _textureFrame: TTextureFrame; _cellSize, _tableSize: TVec2); overload;
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

			property Indexer[name: string]: TTexture read GetTexture; default;

			procedure Load;
			function IsLoaded: boolean;

			destructor Destroy; override;

		private
			textures: TTextureMap;
			path: string;
			textureParams: TTextureParameters;
			scale: TScalar;

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
			function GetTexture (name: string): TTexture;
			function GetCount: integer;
			procedure SetTextureParameters (newValue: TTextureParameters); 
			function GetTexture: TGLTextureID;

			property Indexer[name: string]: TTexture read GetTexture; default;

			{ Loading }
			procedure Load;
			function IsLoaded: boolean;

			function Subdivide (cellSize: TVec2): TTextureSheet;
			destructor Destroy; override;

		private
			textures: TTextureMap;
			textureParams: TTextureParameters;
			imagePaths: TImagePathArray;
	end;

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
	GLAssert('glBindTexture');	
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
	Assert(texture.GetTexture > 0, 'Texture is not loaded');
	Assert(texture.GetTexture < GetMaximumTextureUnits, 'Invalid texture unit');
	if TextureSlots[textureUnit] <> nil then
	  Assert(false, 'Another texture ('+IntToStr(TextureSlots[textureUnit].id)+') is loaded in unit '+IntToStr(textureUnit));
	TextureSlots[textureUnit].SetTexture(texture);
	BindTexture2D(texture.GetTexture, textureUnit);
end;

function PushTexture (texture: ITexture): TGLTextureUnit;
var
	i: integer;
	textureUnit,
	lastLocked: integer;
begin
	if not texture.IsLoaded then
		texture.Load;

	Assert(texture.GetTexture > 0, 'Texture is not loaded');

	// locked texture can guarantee their texture unit
	if texture.IsLocked then
		exit(texture.GetTextureUnit);

	// find the next available unit
	textureUnit := -1;
	lastLocked := 0;
	for i := 0 to GetMaximumTextureUnits - 1 do
		if TextureSlots[i].IsUsed and TextureSlots[i].IsLocked then
		  begin
		  	lastLocked := i;
		  	continue;
		  end
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
			textureUnit := lastLocked + 1;
			for i := lastLocked + 1 to GetMaximumTextureUnits - 1 do
				TextureSlots[i].SetTexture(nil);
		end;

	Assert((textureUnit >= 0) and (textureUnit < GetMaximumTextureUnits), 'No texture units available for '+IntToStr(texture.GetTexture));

	TextureSlots[textureUnit].SetTexture(texture);
	BindTexture2D(texture.GetTexture, textureUnit);
	writeln('bind texture ', texture.GetTexture, ' ', HexStr(texture), ' to unit ', textureUnit);
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

function TTextureSource.GetTextureFrame: TTextureFrame;
begin
	result := textureFrame{Default(TTextureFrame)};
end;

function TTextureSource.PixelAt(x, y: integer): TImagePixel;
begin
	result := Default(TImagePixel);
end;

procedure TTextureSource.Lock(inUnit: TGLTextureUnit);
begin
	Assert(not IsLocked, 'Texture is already locked');
	if not IsLoaded then
	  Load;
	ChangeTextureUnit(self, inUnit);
	textureUnit := inUnit;
	m_locked := true;
	writeln('bound and locked texture ', textureID, ' to unit ', textureUnit);
end;

procedure TTextureSource.Unlock;
begin
	Assert(IsLocked, 'Texture is already unlocked');
	m_locked := false;
	TextureSlots[textureUnit].SetTexture(nil);
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

function TTextureSource.IsLocked: boolean;
begin
	result := m_locked;
end;

function TTextureSource.GetTexture: TGLTextureID;
begin
	result := textureID;
end;

function TTextureSource.GetTextureUnit: TGLTextureUnit;
begin
	result := textureUnit;
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
	if textureID <> 0 then
		glDeleteTextures(1, @textureID);
end;

procedure TTexturePack.SetTextureParameters (newValue: TTextureParameters); 
begin
	Assert(not IsLoaded, 'texture parameters must be set before loading.');
	textureParams := newValue;
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

function TTexturePack.IsLoaded: boolean;
begin
	result := textureID > 0;
end;

procedure TTexturePack.LoadImage (imagePath: ansistring);
var
	image: TImage;
	width, height: integer;
begin
	Assert(FileExists(imagePath), imagePath+' for sprite pack doesn'' exist.');
	image := LoadImageFromFile(imagePath, width, height);
	if assigned(image) then
		begin
			GenerateTexture(textureID);
			BindTexture2D(textureID);
			LoadTexture2D(width, height, image, textureParams);
			RestoreTextureUnit(0, textureID);

			textureFrame.texture := RectMake(0, 0, 1, 1);
			textureFrame.pixel := RectMake(0, 0, width, height);

			//FreeMem(image);
		end;
end;

procedure TTexturePack.AddTexture (name: string; constref spriteSize: TVec2; constref offset, position, pivot: TVec2); 
var
	texture: TTexture; 
begin
	Assert(textureID > 0, 'must load image before adding textures');
	texture := TTexture.Create(textureID);
	texture.SetTextureFrame(PixelToTexture(RectMake(position, spriteSize)));
	texture.SetSize(spriteSize*scale);
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

			imagePath := ExtractFileDir(path);
			imagePath := imagePath+'/'+attributes['imagePath'];
			LoadImage(imagePath);

			//textureSize := V2(attributes['width'], attributes['height']);
			textureFrame.texture := RectMake(0, 0, 1, 1);
			textureFrame.pixel := RectMake(0, 0, attributes['width'], attributes['height']);

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
	textureFrame.texture := RectMake(0, 0, 1, 1);
	textureFrame.pixel := RectMake(0, 0, canvasSize);
	imagePaths := images;
end;

function TTextureComposite.GetTexture (name: string): TTexture;
begin
	if not IsLoaded then
		Load;
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

function TTextureComposite.GetTexture: TGLTextureID;
begin
	result := textureID;
end;

procedure TTextureComposite.Load;
var
	width, height: integer;
	image: TImage;
	offset: TVec2i;
	imagePath: string;
	pixelFrame: TRect;
	texture: TTexture;
begin
	Assert(not IsLoaded, 'Texture is already loaded.');

	GenerateTexture(textureID);
	BindTexture2D(textureID);
	LoadTexture2D(trunc(textureSize.width), trunc(textureSize.height), nil, textureParams);

	offset := 0;

	for imagePath in imagePaths do
		begin
			image := LoadImageFromFile(imagePath, width, height);
			// TODO: respect texture params for target type
			glTexSubImage2D(GL_TEXTURE_2D, 0, offset.x, offset.y, width, height, GL_RGBA, GL_UNSIGNED_BYTE, image);
			GLAssert('glTexSubImage2D');	

			pixelFrame := RectMake(offset, width, height);

			texture := TTexture.Create(textureID);
			texture.SetTextureFrame(PixelToTexture(pixelFrame));
			texture.SetSize(V2(width, height));
			texture.SetPixelFrame(pixelFrame);
			textures.Add(ExtractFileParts(imagePath).name, texture);

			// TODO: replace with bin packer, UPacker works?
			offset.x += width;
			FreeMem(image);
		end;

	RestoreTextureUnit(0, textureID);
end;

function TTextureComposite.IsLoaded: boolean;
begin
	result := textureID > 0;
end;

function TTextureComposite.Subdivide (cellSize: TVec2): TTextureSheet;
var
	tableSize: TVec2;
begin
	if not IsLoaded then
		Load;

	tableSize.width := trunc(textureSize.width / cellSize.width);
	tableSize.height := trunc(textureSize.height / cellSize.height);

	result := TTextureSheet.Create(GetTexture, GetTextureFrame, cellSize, tableSize);
end;

destructor TTextureComposite.Destroy;
begin
	FreeAndNil(textures);
	if textureID <> 0 then
		glDeleteTextures(1, @textureID);
end;


//#########################################################
// TEXTURE SHEET
//#########################################################

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

function TTextureSheet.Columns: integer;
begin
	result := tableSize.width;
end;

function TTextureSheet.Rows: integer;
begin
	result := tableSize.height;
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

	if not IsLoaded then
		Load;

	textures := TTextureList.Create(true);

	if (tableSize.width = 0) or (tableSize.height = 0) then
		begin
			tableSize.width := trunc(textureSize.width / cellSize.width);
			tableSize.height := trunc(textureSize.height / cellSize.height);
		end;

	for y := Round(tableSize.height) downto 1 do
		for x := 1 to Round(tableSize.width) do
			begin
				scale := V2((tableSize.width * cellSize.width) / textureSize.width, 
										(tableSize.height * cellSize.height) / textureSize.height);
				
				spanX := textureFrame.texture.size.x;
				spanY := textureFrame.texture.size.y;

				cellFrame.origin.x := textureFrame.texture.origin.x + (((x - 1) * (spanX / tableSize.width)) * scale.width);
				cellFrame.origin.y := textureFrame.texture.origin.y + (((spanY - ((spanY / tableSize.height) * y))) * scale.height);
				cellFrame.size.x := (spanX / tableSize.width) * scale.width;
				cellFrame.size.y := (spanX / tableSize.height) * scale.height;

				texture := TTexture.Create(GetTexture);
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

constructor TTextureSheet.Create (path: ansistring; _cellSize: TVec2; _tableSize: TVec2);
begin
	inherited Create(path);
	cellSize := _cellSize;
	tableSize := _tableSize;
	//writeln('imageSize: ',V2(imageWidth, imageHeight).Tostr);
	//writeln('tableSize: ',tableSize.tostr);
	//writeln('cellSize: ',cellSize.tostr);
end;

constructor TTextureSheet.Create (path: ansistring; _cellSize: TVec2);
begin
	Create(path, _cellSize, 0);
end;

constructor TTextureSheet.Create (_textureID: TGLTextureID; _textureFrame: TTextureFrame; _cellSize, _tableSize: TVec2);
begin
	inherited Create(_textureID, trunc(_textureFrame.pixel.width), trunc(_textureFrame.pixel.height));
	cellSize := _cellSize;
	tableSize := _tableSize;
	textureFrame := _textureFrame;
	Subdivide;
end;

//#########################################################
// TEXTURE
//#########################################################

procedure TTexture.SetTextureFrame (newValue: TRect);
begin
	textureFrame.texture := newValue;
end;

procedure TTexture.SetPixelFrame (newValue: TRect);
begin
	textureFrame.pixel := newValue;
end;

function TTexture.Splice(rect: TRect): TTexture;
begin
	if not IsLoaded then
		Load;
	result := TTexture.Create(GetTexture, rect, PixelToTexture(rect));
	if slices = nil then
		slices := TTextureList.Create;
	slices.Add(result);
end;

function TTexture.Subdivide (cellSize: TVec2): TTextureSheet;
var
	tableSize: TVec2;
begin
	if not IsLoaded then
		Load;

	tableSize.width := trunc(textureSize.width / cellSize.width);
	tableSize.height := trunc(textureSize.height / cellSize.height);

	result := TTextureSheet.Create(GetTexture, GetTextureFrame, cellSize, tableSize);
end;

procedure TTexture.LoadImage (image: TImage);
begin
	generatedTexture := true;
	GenerateTexture(textureID);
	
	BindTexture2D(textureID);
	LoadTexture2D(GetWidth, GetHeight, image, textureParams);
	RestoreTextureUnit(0, textureID);

	//FreeMem(sourceImage);
	sourceImage := nil;
end;

function TTexture.PixelAt(x, y: integer): TImagePixel;
begin
	Assert(IsLoaded, 'Texture must be loaded before inspecting pixels.');
	result := sourceImage[x + y * trunc(textureSize.width)];
end;

procedure TTexture.Load;
begin
	Assert(not IsLoaded, 'Texture is already loaded.');
	LoadImage(sourceImage);
end;

function TTexture.IsLoaded: boolean;
begin
	result := textureID > 0;
end;

procedure TTexture.SetSize (newValue: TVec2);
begin
	Assert(newValue.Max < GetMaximumTextureSize, 'Sprite face texture exceeds maximum texture size ('+IntToStr(GetMaximumTextureSize)+')');
	textureFrame.pixel.size := newValue;
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

function TTexture.GetTexture: TGLTextureID;
begin
	result := textureID;
end;

function TTexture.GetTextureFrame: TTextureFrame;
begin
	result := textureFrame;
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

constructor TTexture.Create (texture: TGLTextureID; inPixelFrame, inTextureFrame: TRect);
begin
	Assert(texture > 0, 'Must use a valid texture ID.');
	textureID := texture;
	textureFrame.pixel := inPixelFrame;
	textureFrame.texture := inTextureFrame;
	// TODO: we need to call this from the parent!
	//writeln(texturesize.tostr, ' ', textureFrame.pixel.tostr, ' ', textureFrame.texture.tostr);
	//SetSize(V2(width, height));
	//SetTextureFrame(RectMake(0, 0, 1, 1));
	textureParams := DefaultTextureParameters;
end;

constructor TTexture.Create (texture: TGLTextureID; width: integer = 0; height: integer = 0);
begin
	Assert(texture > 0, 'Must use a valid texture ID.');
	textureID := texture;
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
