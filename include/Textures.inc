
{$ifdef INTERFACE}

type
  TTextureImage = ( { Filters }
                    Linear, 
                    NearestNeighbor,
                    
                    { Wrapping }
                    _Repeat,
                    MirroredRepeat,
                    ClampToEdge,

                    { Color Format }
                    RGB,
                    RGBA,
                    BGRA,

                    { Pixel Type }
                    Float,
                    UnsignedByte
                    ); 
  TTextureImageOptions = set of TTextureImage; 

type
	TTextureImageHelper = type helper for TTextureImageOptions
		function Components: Integer;
		function BytesPerComponent: Integer;
		function Format: GLenum;
	end;

type
	TImage = TImage4b;
	TImageArray = array of TImage;
	TImagePixel = TImage4b.TPixel;
	PImagePixel = ^TImagePixel;

type
	TTextureFrame = record
		texture: TRect;
		pixel: TRect;
		property Size: TVec2 read pixel.size;
		property Width: float read pixel.size.x;
		property Height: float read pixel.size.y;
	end;

type
	ITexture = interface
		function GetTexture: integer;
		function GetTextureUnit: integer;
		function GetFrame: TTextureFrame;

		procedure Lock(inUnit: integer);
		procedure Unlock;
		procedure Load;
		procedure Unload;
		function IsLoaded: boolean;
		function IsLocked: boolean;
	end;

type
	TTextureSource = class abstract(ITexture)
		private
			m_textureID: integer;
			m_textureUnit: integer;
			m_textureFrame: TTextureFrame;
			m_owner: TTextureSource;
		public
			{ Methods }
			function GetTexture: integer;
			function GetTextureUnit: integer;
			function GetFrame: TTextureFrame; inline;
			function HasOwner: boolean; inline;

			function TextureToPixel(textureRect: TRect): TRect; overload;
			function PixelToTexture(pixelRect: TRect): TRect; overload;
			function TextureToPixel(texturePoint: TVec2): TVec2; overload;
			function PixelToTexture(pixelPoint: TVec2): TVec2; overload;
			function SubTextureFrame(x, y, w, h: float): TRect; overload;
			function SubTextureFrame(pixelFrame: TRect): TRect; overload;
			function PixelAt(x, y: integer): TImagePixel; virtual; overload;
			function PixelAt(point: TVec2i): TImagePixel; virtual; overload;

			procedure Lock(inUnit: integer); virtual;
			procedure Unlock; virtual;
			procedure Load; virtual;
			procedure Unload; virtual;
			function IsLoaded: boolean; virtual;
			function IsLocked: boolean; virtual;

			procedure LoadIfNeeded; inline;
			
			{ Properties }
			property TextureSize: TVec2 read m_textureFrame.pixel.size;
			property TextureFrame: TRect read m_textureFrame.texture;
			property PixelFrame: TRect read m_textureFrame.pixel;
			property TextureID: integer read m_textureID;
			property TextureUnit: integer read m_textureUnit;
			property Owner: TTextureSource read m_owner;
	end;

const
	DefaultTextureOptions = [TTextureImage.ClampToEdge,
													 TTextureImage.NearestNeighbor, 
													 TTextureImage.RGBA,
													 TTextureImage.UnsignedByte
													 ];
	
type
	TTexture = class;
	TTextureSheet = class;
	TTextureList = specialize TFPGObjectList<TTexture>;
	TTextureMap = specialize TFPGMapObject<String, TTexture>;
	TTextureArray = array of TTexture;

	TTexture = class(TTextureSource, ITexture)
		private type
			TTextureFlag = (DisposeTexture, 		// we own the textureID
											FreeSourceImage			// we own internal image data
											);
			TTextureFlags = set of TTextureFlag;
		private
			flags: TTextureFlags;
			sourceImage: TImage;
			textureOptions: TTextureImageOptions;
			children: TTextureList;
		private
			procedure AddChild(child: TTexture);
			procedure SetSize(newValue: TVec2);
			procedure LoadImage(image: TImage);
			function GetTextureCoords: TRect; inline;

			{ Constructors for sub-textures }
			constructor Create(source: TTextureSource); overload;
			constructor Create(source: TTextureSource; inPixelFrame, inTextureFrame: TRect; options: TTextureImageOptions = DefaultTextureOptions); overload;
		public
			{ Constructors }
			constructor Create(path: ansistring; options: TTextureImageOptions = DefaultTextureOptions); overload;
			constructor Create(texture: integer; width: integer = 0; height: integer = 0; options: TTextureImageOptions = DefaultTextureOptions); overload;
			constructor Create(width, height: integer; data: pointer; options: TTextureImageOptions = DefaultTextureOptions); overload;
			constructor Create(_size: TVec2i; data: pointer; options: TTextureImageOptions = DefaultTextureOptions); overload;
			constructor Create(image: TImage; copyImage: boolean = true); overload;

			{ Accessors }
			procedure SetTextureFrame(newValue: TRect);
			procedure SetPixelFrame(newValue: TRect);

			function GetSize: TVec2; inline;
			function GetBounds: TRect; inline;
			function GetHeight: integer; inline;
			function GetWidth: integer; inline;
			function GetByteCount: integer; inline;

			{ Properties }
			property Size: TVec2 read GetSize;
			property Bounds: TRect read GetBounds;
			property Width: integer read GetWidth;
			property Height: integer read GetHeight;
			property ByteCount: integer read GetByteCount;
			property Image: TImage read sourceImage;

			{ Methods }
			procedure Load; override;
			procedure Reload; overload;
			procedure Reload(region: TRect; data: pointer); overload;
			procedure Reload(data: pointer); overload;
			procedure Lock(inUnit: integer); override;
			function IsLocked: boolean; override;
			destructor Destroy; override;
			function PixelAt(x, y: integer): TImagePixel; override;
				
			{ Slicing }
			function Subdivide(cellSize: TVec2): TTextureSheet;
			function Slice(rect: TRect): TTexture;
			function Slice(columns: integer; rows: integer = 0): TTextureArray;
	end;

	TTextureCollection = class abstract(TTexture)
		protected
			textures: TTextureList;
			function GetTexture(index: integer): TTexture; overload;
		public
			property Texture[index: integer]: TTexture read GetTexture; default;
	end;

	TTextureSheet = class(TTextureCollection)
		private
			m_cellSize: TVec2i;
			m_tableSize: TVec2i;
			margin: integer;		// margin from top-left origin
			spacing: integer;		// margin between tiles
			function GetCellSize: TVec2i; inline;
			function GetTableSize: TVec2i; inline;
			function GetColumns: integer; inline;
			function GetRows: integer; inline;

			procedure Subdivide;
			constructor Create(inTextureID: integer; inTextureFrame: TTextureFrame; inCellSize, inTableSize: TVec2i); overload;
		public
			{ Constructors }
			constructor Create(inCellSize, inTableSize: TVec2; options: TTextureImageOptions = DefaultTextureOptions); overload;
			constructor Create(path: ansistring; inCellSize: TVec2i; inMargin, inSpacing: integer; options: TTextureImageOptions = DefaultTextureOptions); overload;
			constructor Create(path: ansistring; inCellSize: TVec2i); overload;
			constructor Create(path: ansistring; inCellSize, inTableSize: TVec2i); overload;
			constructor Create(_texture: TTexture; inCellSize, inTableSize: TVec2i); overload;
			constructor Create(_texture: TTexture; inCellSize: TVec2i); overload;

			{ Accessors }
			function GetCount: integer;
			function GetTextures: TTextureList;

			{ Cells }
			function GetIndex(x, y: integer): integer; inline;
			function GetTexture(cell: TVec2): TTexture; overload;
			function GetTexture(x, y: integer): TTexture; overload;
			property Texture[x, y: integer]: TTexture read GetTexture; default;

			{ Methods }
			procedure Load; override;
			destructor Destroy; override;

			function Slice(x, y, spanX, spanY: integer): TTexture; overload;

			{ Properties }
			property Columns: integer read GetColumns;
			property Rows: integer read GetRows;
			property TableSize: TVec2i read GetTableSize;
			property CellSize: TVec2i read GetCellSize;
			property CellWidth: integer read m_cellSize.x;
			property CellHeight: integer read m_cellSize.y;
	end;

type
	TTextureSprite = class(TTexture)
		private
			m_originalSize: TVec2i;
			m_offset: TVec2i;
			m_pivot: TVec2;
		public
			property OriginalSize: TVec2i read m_originalSize;
			property Offset: TVec2i read m_offset;
			property Pivot: TVec2 read m_pivot;
	end;

type
	TTexturePack = class (TTextureCollection)
		private
			map: TTextureMap;
			path: string;
			scale: TScalar;
			useOriginalSize: boolean;

			procedure LoadImage(imagePath: ansistring);
			procedure AddTexture(name: string; spriteSize, position: TVec2); 
			function GetTexture(name: string): TTextureSprite; overload;
			function GetTexture(index: integer): TTextureSprite; overload;
		public
			{ Constructors }
			constructor Create; overload;
			constructor Create(_path: ansistring); overload;
			destructor Destroy; override;

			{ Accessors }
			function GetCount: integer;
			procedure SetTextureOptions(newValue: TTextureImageOptions); 
			function TryGet(name: string; var sprite: TTextureSprite): boolean;
			property Texture[name: string]: TTextureSprite read GetTexture; default;

			{ Methods }
			procedure Load; override;
	end;

type
	TTextureComposite = class(TTextureSource, ITexture)
		private type
			TImagePathArray = array of string;
		private
			textures: TTextureMap;
			textureOptions: TTextureImageOptions;
			bitmaps: TImageArray;
			freeImages: boolean;

			procedure Initialize(canvasSize: TVec2i; options: TTextureImageOptions = DefaultTextureOptions);
		public
			{ Constructors }
			constructor Create(canvasSize: TVec2i; paths: TImagePathArray; options: TTextureImageOptions = DefaultTextureOptions);
			constructor Create(canvasSize: TVec2i; images: TImageArray; options: TTextureImageOptions = DefaultTextureOptions);

			{ Accessors }
			function GetTexture(name: string): TTexture; overload;
			function GetCount: integer;
			procedure SetTextureOptions(newValue: TTextureImageOptions); 

			property Indexer[name: string]: TTexture read GetTexture; default;

			{ Loading }
			procedure Load; override;

			function Subdivide(cellSize: TVec2): TTextureSheet;
			destructor Destroy; override;
	end;

{ Operators }

procedure SetMaximumTextureUnits(newValue: integer); 
procedure ChangeTextureUnit(texture: ITexture; textureUnit: integer); 
function PushTexture(texture: ITexture): integer;
procedure ClearUnlockTextures;

{ OpenGL Primitive Helpers }
const
	DEFAULT_LOADING_UNIT = 0;

function GetMaximumTextureSize: integer;
function GetMaximumTextureUnits: integer;
function GetMaximumVerticies: integer;

procedure GenerateTexture(var texID: integer);
procedure DeleteTexture(var texID: integer);
procedure LoadTexture2D(width, height: GLsizei; data: pointer; options: TTextureImageOptions);
function BindTexture2D(texID: integer; texUnit: integer = DEFAULT_LOADING_UNIT): boolean;
procedure ClearTextureUnit(textureUnit: integer); 
procedure RestoreLastBoundTexture;

{$endif}

{$ifdef IMPLEMENTATION}

{*****************************************************************************
 *                              Texture Slots
 *****************************************************************************}

type
	TTextureSlot = record
		id: integer;
		obj: ITexture;
		class operator = (left: TTextureSlot; right: ITexture): boolean;
		procedure SetTexture(newValue: ITexture);
		function IsLocked: boolean; inline;
		function IsUsed: boolean; inline;
	end;

var
	TextureSlots: array[0..1024-1] of TTextureSlot;
	UsedTextureSlots: integer = 0;

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
			if IsUsed then
				Dec(UsedTextureSlots);
			id := -1;
			obj := nil;
		end
	else
		begin
			id := newValue.GetTexture;
			obj := newValue;
			Inc(UsedTextureSlots);
		end;
	//writeln('slot ', HexStr(obj), ' #', id, ' used ', UsedTextureSlots);
end;

function TTextureSlot.IsLocked: boolean;
begin
	if IsUsed then
		result := obj.IsLocked
	else
		result := false;
end;

function TTextureSlot.IsUsed: boolean;
begin
	result := assigned(obj);
end;

{*****************************************************************************
 *                            OpenGL Utilities
 *****************************************************************************}

var
	RealMaximumTextureUnits: integer = 0;
	RealMaximumVerticies: integer = 0;
	RealMaximumTexureSize: integer = 0;
	UserMaximumTextureUnits: integer = 0;

function GetMaximumTextureSize: integer; inline;
begin
	if RealMaximumTexureSize = 0 then
		glGetIntegerv(GL_MAX_TEXTURE_SIZE, @RealMaximumTexureSize);
	result := RealMaximumTexureSize;
end;

function GetMaximumTextureUnits: integer; inline;
begin
	if RealMaximumTextureUnits = 0 then
		glGetIntegerv(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS, @RealMaximumTextureUnits);
	if UserMaximumTextureUnits = 0 then
		result := RealMaximumTextureUnits
	else
		result := UserMaximumTextureUnits;
end;

function GetMaximumVerticies: integer; inline;
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
	
var
	ActiveTextureUnit: GLInt = -1;
	RestoreTextureID: GLint = -1;
	RestoreTextureUnit: GLint = -1;

procedure GenerateTexture(var texID: integer);
begin
	glGenTextures(1, @texID);
	GLAssert('glGenTextures');
end;

procedure DeleteTexture(var texID: integer);
begin
	glDeleteTextures(1, @texID);
	GLAssert('glDeleteTextures');
	texID := 0;
end;

function BindTexture2D(texID: integer; texUnit: integer = DEFAULT_LOADING_UNIT): boolean;
begin
	Assert((texUnit < GetMaximumTextureUnits) and (texUnit >= 0), 'texture unit '+IntToStr(texUnit)+' is out of bounds (0-'+IntToStr(GetMaximumTextureUnits-1)+')');
	Assert(texUnit < DEFAULT_SHADER_TEXTURE_UNITS, 'default shader only supports a maximum of '+IntToStr(DEFAULT_SHADER_TEXTURE_UNITS));

	glActiveTexture(GL_TEXTURE0 + texUnit);
	glBindTexture(GL_TEXTURE_2D, texID);
	GLAssert('glBindTexture');
	CanvasState.bindTextureCount += 1;

	if TextureSlots[texUnit].IsUsed then
	  begin
	  	RestoreTextureID := TextureSlots[texUnit].id;
	  	RestoreTextureUnit := texUnit;
	  end;

	ActiveTextureUnit := texUnit;
end;

procedure SetTextureParameters(options: TTextureImageOptions); 
begin
	//Assert((TTextureImage.Linear in options) and (TTextureImage.NearestNeighbor in options), 
	//	'Must choose only 1 texture filter mode.');

	// filter
	if TTextureImage.Linear in options then
		begin
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		end
	else if TTextureImage.NearestNeighbor in options then
		begin
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		end
	else
		begin
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		end;

	// wrapping
	if TTextureImage.ClampToEdge in options then
		begin
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		end
	else if TTextureImage.MirroredRepeat in options then
		begin
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_MIRRORED_REPEAT);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_MIRRORED_REPEAT);
		end
	else if TTextureImage._Repeat in options then
		begin
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
		end
	else
		begin
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		end;
end;

procedure GetPixelFormat(const options: TTextureImageOptions; out pixelFormat: GLenum; out internalformat: GLenum; out pixelType: GLenum);
begin
	pixelFormat := 0;
	pixelType := 0;
	internalformat := 0;

	Assert((TTextureImage.RGB in options) or 
				(TTextureImage.RGBA in options) or 
				(TTextureImage.BGRA in options), 'Texture2D requires a pixel format.');

	Assert((TTextureImage.Float in options) or 
				(TTextureImage.UnsignedByte in options), 'Texture2D requires a pixel type.');

	// pixel format
	if TTextureImage.RGB in options then
		begin
			pixelFormat := GL_RGB;
			internalformat := GL_RGB;
		end
	else if TTextureImage.RGBA in options then
		begin
			pixelFormat := GL_RGBA;
			internalformat := GL_RGBA;
		end
	else if TTextureImage.BGRA in options then
		begin
			{$ifdef API_OPENGLES}
			writeln('GL_BGRA is not available in OpenGLES');
			halt;
			{$else}
			pixelFormat := GL_BGRA;
			internalformat := GL_RGBA;
			{$endif}
		end;

	// pixel type
	if TTextureImage.Float in options then
		pixelType := GL_FLOAT
	else if TTextureImage.UnsignedByte in options then
		pixelType := GL_UNSIGNED_BYTE;

	{
	Specifies the data type of the pixel data. The following symbolic values are accepted: 
	GL_UNSIGNED_BYTE, GL_BYTE, GL_UNSIGNED_SHORT, GL_SHORT, GL_UNSIGNED_INT, GL_INT, 
	GL_HALF_FLOAT, GL_FLOAT, GL_UNSIGNED_BYTE_3_3_2, GL_UNSIGNED_BYTE_2_3_3_REV, 
	GL_UNSIGNED_SHORT_5_6_5, GL_UNSIGNED_SHORT_5_6_5_REV, GL_UNSIGNED_SHORT_4_4_4_4, 
	GL_UNSIGNED_SHORT_4_4_4_4_REV, GL_UNSIGNED_SHORT_5_5_5_1, GL_UNSIGNED_SHORT_1_5_5_5_REV, 
	GL_UNSIGNED_INT_8_8_8_8, GL_UNSIGNED_INT_8_8_8_8_REV, GL_UNSIGNED_INT_10_10_10_2, and GL_UNSIGNED_INT_2_10_10_10_REV.
	
	from macgl.pas:
	
	const GL_UNSIGNED_BYTE_3_3_2            = $8032;
	const GL_UNSIGNED_SHORT_4_4_4_4         = $8033;
	const GL_UNSIGNED_SHORT_5_5_5_1         = $8034;
	const GL_UNSIGNED_INT_8_8_8_8           = $8035;
	const GL_UNSIGNED_INT_10_10_10_2        = $8036;
	const GL_UNSIGNED_BYTE_2_3_3_REV        = $8362;
	const GL_UNSIGNED_SHORT_5_6_5           = $8363;
	const GL_UNSIGNED_SHORT_5_6_5_REV       = $8364;
	const GL_UNSIGNED_SHORT_4_4_4_4_REV     = $8365;
	const GL_UNSIGNED_SHORT_1_5_5_5_REV     = $8366;
	const GL_UNSIGNED_INT_8_8_8_8_REV       = $8367;
	const GL_UNSIGNED_INT_2_10_10_10_REV    = $8368;

	}
end;

procedure LoadTexture2D(width, height: GLsizei; data: pointer; options: TTextureImageOptions);
var
	pixelFormat: GLenum;
	pixelType: GLenum;
	internalformat: GLenum;
begin
	GetPixelFormat(options, pixelFormat, internalformat, pixelType);
	SetTextureParameters(options);
	glTexImage2D(GL_TEXTURE_2D, 0, internalformat, width, height, 0, pixelFormat, pixelType, data);

	GLAssert('glTexImage2D');
end;

procedure LoadSubTexture2D(xoffset, yoffset, width, height: GLsizei; data: pointer; options: TTextureImageOptions);
var
	pixelFormat: GLenum;
	pixelType: GLenum;
	internalformat: GLenum;
begin
	GetPixelFormat(options, pixelFormat, internalformat, pixelType);
	glTexSubImage2D(GL_TEXTURE_2D, 0, xoffset, yoffset, width, height, pixelFormat, pixelType, data);

	GLAssert('glTexSubImage2D');
end;

procedure LoadSubTexture2D(rect: TRect; data: pointer; options: TTextureImageOptions); inline;
begin
	LoadSubTexture2D(trunc(rect.x), trunc(rect.y), trunc(rect.width), trunc(rect.height), data, options);
end;

{ Takes `source` as a rect into the frame buffer currently bound to GL_READ_FRAMEBUFFER
	and `dest` as rect into the currently bound texture to GL_TEXTURE_2D. 
  
  No interpolation is done on the destination so `source.size` is the amound of pixels
  read from the frame buffer and copied into the destination texture.  }
procedure CopyTexture2D(source, dest: TRecti);
begin
	// https://registry.khronos.org/OpenGL-Refpages/gl4/html/glCopyTexSubImage2D.xhtml
	// (0, 0) is at lower left-hand corner of frame buffer so we transform to the
	// origin being the top-rigth corner of the destination texture.
	glCopyTexSubImage2D(GL_TEXTURE_2D, 0, 
		dest.MinX, ((dest.Height - source.Height) - dest.MinY), // Destination texture offset
		source.MinX, ((dest.Height - source.Height)  - source.MinY),           // Frame buffer offset (0,0 at lower-left corner)
		source.Width, source.Height         // Size of the texture subimage
	);

	GLAssert('glCopyTexSubImage2D');
end;

procedure RestoreLastBoundTexture;
begin
	if RestoreTextureID = -1 then
		exit;
	glActiveTexture(GL_TEXTURE0 + RestoreTextureUnit);
	glBindTexture(GL_TEXTURE_2D, RestoreTextureID);
	RestoreTextureID := -1;
	RestoreTextureUnit := -1;
end;

function TextureImagePixelFormat(format: GLenum): TTextureImage;
begin
	case format of
		GL_RGB:
			result := TTextureImage.RGB;
		GL_RGBA:
			result := TTextureImage.RGBA;
		otherwise
			Assert(false, 'pixel format not supported');
	end;
end;

function TextureImagePixelType(typ: GLenum): TTextureImage;
begin
	case typ of
		GL_UNSIGNED_BYTE:
			result := TTextureImage.UnsignedByte;
		otherwise
			Assert(false, 'pixel type not supported');
	end;
end;

{*****************************************************************************
 *                              Texture Units
 *****************************************************************************}

procedure ClearUnlockTextures;
var
	i: integer;
begin
	FlushDrawing;
	for i := 0 to GetMaximumTextureUnits - 1 do
		if TextureSlots[i].IsUsed and not TextureSlots[i].IsLocked then
			TextureSlots[i].SetTexture(nil);
end;

procedure ClearTextureUnit(textureUnit: integer); 
begin
	Assert(textureUnit < GetMaximumTextureUnits, 'Texture unit '+IntToStr(textureUnit)+' exceeds maximum ('+IntToStr(GetMaximumTextureUnits)+')');
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

var
	MaximumTextureSlots: integer = MaxInt;

{ Binds the texture to the next available unit and returns the unit number.
  In the case no available units for found all draw calls are flushed. }
function PushTexture(texture: ITexture): integer;
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

	// no available units were found so we need to 
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

	BindTexture2D(texture.GetTexture, textureUnit);
	TextureSlots[textureUnit].SetTexture(texture);

	//writeln('bind texture ', texture.GetTexture, ' ', HexStr(texture), ' to unit ', textureUnit);
	result := textureUnit;
end;

{*****************************************************************************
 *                                TTextureImageHelper
 *****************************************************************************}
function TTextureImageHelper.Components: Integer;
begin
	if TTextureImage.RGB in self then
		result := 3
	else if (TTextureImage.RGBA in self) or (TTextureImage.BGRA in self) then
		result := 4
	else
		result := 0;

	Assert(result > 0, 'Invalid texture color format');
end;

function TTextureImageHelper.BytesPerComponent: Integer;
begin
	if TTextureImage.Float in self then
		result := sizeof(GLfloat)
	else if TTextureImage.UnsignedByte in self then
		result := sizeof(GLubyte)
	else
		result := 0;

	Assert(result > 0, 'Invalid texture pixel type');
end;

function TTextureImageHelper.Format: GLenum;
begin
	if TTextureImage.Float in self then
		result := GL_FLOAT
	else if TTextureImage.UnsignedByte in self then
		result := GL_UNSIGNED_BYTE
	else
		result := -1;

	Assert(result > -1, 'Invalid texture color format');
end;

{*****************************************************************************
 *                                 Images
 *****************************************************************************}

function IsPowerOfTwo(n: float): boolean;
begin
	if n = 0 then
		exit(false);

	while n <> 1 do
		begin
			n := n / 2;
			if (n mod 2 <> 0) and (n <> 1) then
				exit(false);
		end;

	result := true;
end;

function IsPowerOfTwo(size: TVec2): boolean;
begin
	result := IsPowerOfTwo(size.x) and IsPowerOfTwo(size.y);
end;

{ Returns the next power of 2 for a size }
function Pow2Size(from: float): integer;
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

function LoadImageFromFile(path: ansistring; out width, height: integer): TImage;
begin
	result := TPNGImage.Create(path);
	width := result.width;
	height := result.height;
end;

{*****************************************************************************
 *                              Texture Source
 *****************************************************************************}

function TTextureSource.TextureToPixel(textureRect: TRect): TRect;
begin
	if HasOwner then
		result := Owner.TextureToPixel(RectMake(textureFrame.origin + textureRect.origin, textureRect.size))
	else
		result := RectMake(textureRect.MinX * textureSize.width, 
											 textureRect.MinY * textureSize.height, 
											 textureRect.width * textureSize.width, 
											 textureRect.height * textureSize.height);
end;

function TTextureSource.PixelToTexture(pixelRect: TRect): TRect;
begin
	if HasOwner then
		result := Owner.PixelToTexture(RectMake(PixelFrame.origin + pixelRect.origin, pixelRect.size))
	else
		result := RectMake(pixelRect.MinX / textureSize.width, 
											 pixelRect.MinY / textureSize.height, 
											 pixelRect.width / textureSize.width, 
											 pixelRect.height / textureSize.height);
end;

function TTextureSource.TextureToPixel(texturePoint: TVec2): TVec2;
begin
		if HasOwner then
		result := Owner.TextureToPixel(textureFrame.origin + texturePoint)
	else
		result := V2(texturePoint.x * textureSize.width, 
								 texturePoint.y * textureSize.height);
end;

function TTextureSource.PixelToTexture(pixelPoint: TVec2): TVec2;
begin
	if HasOwner then
		result := Owner.PixelToTexture(PixelFrame.origin + pixelPoint)
	else
		result := V2(pixelPoint.x / textureSize.width, 
								 pixelPoint.y / textureSize.height);
end;

{ Returns a sub-frame of the texture frame using AABB
  	0,0,1,1 = entire frame
		0,0.5,1,1 = 50% split at minY }
function TTextureSource.SubTextureFrame(x, y, w, h: float): TRect;
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
function TTextureSource.SubTextureFrame(pixelFrame: TRect): TRect;
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

function TTextureSource.HasOwner: boolean;
begin
	result := owner <> nil;
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

procedure TTextureSource.Lock(inUnit: integer);
begin
	Assert(not IsLocked, 'Texture is already locked');
	LoadIfNeeded;
	ChangeTextureUnit(self, inUnit);
	m_textureUnit := inUnit;
	//writeln('bound and locked texture ', textureID, ' to unit ', GetTextureUnit);
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

{ Unloads texture memory but keeps source intact }
procedure TTextureSource.Unload;
begin
	{$ifdef DEBUG_TEXTURES}
	writeln('delete texture ', hexstr(self), ' id = ', m_textureID);
	{$endif}
	DeleteTexture(m_textureID);
end;

function TTextureSource.IsLoaded: boolean;
begin
	result := textureID > 0;
end;

function TTextureSource.IsLocked: boolean;
begin
	result := TextureSlots[GetTextureUnit].obj = ITexture(self);
end;

function TTextureSource.GetTexture: integer;
begin
	result := textureID;
end;

function TTextureSource.GetTextureUnit: integer;
begin
	if HasOwner then
		result := owner.GetTextureUnit
	else
	result := m_textureUnit;
end;

{*****************************************************************************
 *                            Texture Collection
 *****************************************************************************}

function TTextureCollection.GetTexture(index: integer): TTexture;
begin
	LoadIfNeeded;
	Assert(textures <> nil, 'textures haven''t been allocated.');
	result := textures[index];
	Assert(result <> nil, 'texture '+IntToStr(index)+' is nil.');
end;


{*****************************************************************************
 *                              Texture Pack
 *****************************************************************************}

constructor TTexturePack.Create;
begin
	scale := 1.0;
	textureOptions := DefaultTextureOptions;
	map := TTextureMap.Create;
	textures := TTextureList.Create(false);
end;

constructor TTexturePack.Create(_path: ansistring);
begin
	path := _path;
	scale := 1.0;
	textureOptions := DefaultTextureOptions;
	map := TTextureMap.Create;
	textures := TTextureList.Create(false);
end;

destructor TTexturePack.Destroy;
begin
	FreeAndNil(map);
	inherited;
end;

function TTexturePack.TryGet(name: string; var sprite: TTextureSprite): boolean;
begin
	LoadIfNeeded;
	Assert(map <> nil, 'Pack textures haven''t been allocated.');
	result := map.TryGetData(name, TTexture(sprite));
end;

procedure TTexturePack.SetTextureOptions(newValue: TTextureImageOptions); 
begin
	Assert(not IsLoaded, 'texture parameters must be set before loading.');
	textureOptions := newValue;
end;

function TTexturePack.GetCount: integer;
begin
	result := map.Count;
end;

function TTexturePack.GetTexture(name: string): TTextureSprite;
begin
	LoadIfNeeded;
	Assert(map <> nil, 'Pack textures haven''t been allocated.');
	result := TTextureSprite(map[name]);
	Assert(result <> nil, 'Texture pack face "'+name+'" is nil.');
end;

function TTexturePack.GetTexture(index: integer): TTextureSprite;
begin
	result := TTextureCollection(self).GetTexture(index) as TTextureSprite;
end;

procedure TTexturePack.LoadImage(imagePath: ansistring);
var
	imageWidth, imageHeight: integer;
begin
	sourceImage := LoadImageFromFile(imagePath, imageWidth, imageHeight);
	if assigned(sourceImage) then
		begin
			Include(flags, TTextureFlag.FreeSourceImage);
			GenerateTexture(m_textureID);

			BindTexture2D(textureID);
			LoadTexture2D(imageWidth, imageHeight, sourceImage.Data, textureOptions);
			RestoreLastBoundTexture;

			m_textureFrame.texture := GetTextureCoords;
			m_textureFrame.pixel := RectMake(0, 0, imageWidth, imageHeight);
		end;
end;

procedure TTexturePack.AddTexture(name: string; spriteSize, position: TVec2); 
var
	tex: TTextureSprite; 
begin
	Assert(textureID > 0, 'must load image before adding textures');
	tex := TTextureSprite.Create(self);
	tex.SetTextureFrame(PixelToTexture(RectMake(position, spriteSize)));
	tex.SetSize(spriteSize * scale);
	tex.SetPixelFrame(RectMake(position, spriteSize));
	map.Add(name, tex);

	// add to ordered list
	textures.Add(tex);
end;

procedure TTexturePack.Load;
var
	memoryPool: TObjectList;

	function NodeAttributes(node: TDOMNode): TVariantMap;
	var
		i: integer;
	begin
		result := TVariantMap.Create;
		for i := 0 to node.Attributes.Length - 1 do
			result.Add(node.Attributes.Item[i].NodeName, node.Attributes.Item[i].NodeValue);
		memoryPool.Add(result);
	end;

	procedure AddSprite(attributes: TVariantMap); 
	var
		sprite: TTextureSprite;
		spriteSize, 
		originalSize: TVec2;
		position,
		pivot: TVec2;
	begin
		sprite := TTextureSprite.Create(self);

		spriteSize := V2(attributes['w'], attributes['h']);
		
		if attributes.Indexof('oW') <> -1 then
			begin
				sprite.m_originalSize := V2(attributes['oW'], attributes['oH']);
				if useOriginalSize then
					spriteSize := originalSize;
			end;
		
		if attributes.Indexof('oX') <> -1 then
			sprite.m_offset := V2(attributes['oX'], attributes['oY']);

		sprite.m_pivot := V2(attributes['pX'], attributes['pY']);

		position := V2(attributes['x'], attributes['y']);
		if useOriginalSize then
			position -= sprite.offset;		

		sprite.SetTextureFrame(PixelToTexture(RectMake(position, spriteSize)));
		sprite.SetSize(spriteSize * scale);
		sprite.SetPixelFrame(RectMake(position, spriteSize));

		// add sprite texture
		map.Add(ExtractFileParts(attributes['n']).name, sprite);
		textures.Add(sprite);
	end;


var
	xml: TXMLDocument;
	node: TDOMNode;
	attributes: TVariantMap;
	imagePath: ansistring;
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
			m_textureFrame.texture := GetTextureCoords;
			m_textureFrame.pixel := RectMake(0, 0, attributes['width'], attributes['height']);

			// loop through all <sprite> tags
			node := node.FirstChild;	
			while node <> nil do
				begin
					attributes := NodeAttributes(node);
					AddSprite(attributes);
					node := node.NextSibling;
				end;
		end;
	
	xml.Free;
	memoryPool.Free;
end;

{*****************************************************************************
 *                            Texture Composite
 *****************************************************************************}

procedure TTextureComposite.Initialize(canvasSize: TVec2i; options: TTextureImageOptions);
begin
	textureOptions := options;
	textures := TTextureMap.Create;
	m_textureFrame.texture := RectMake(0, 0, 1, 1);
	m_textureFrame.pixel := RectMake(0, 0, canvasSize);
end;
		
constructor TTextureComposite.Create(canvasSize: TVec2i; paths: TImagePathArray; options: TTextureImageOptions);
var
	path: string;
begin
	Initialize(canvasSize, options);

	freeImages := true;

	for path in paths do
		bitmaps += [TPNGImage.Create(path)];
end;

constructor TTextureComposite.Create(canvasSize: TVec2i; images: TImageArray; options: TTextureImageOptions);
begin
	Assert((TTextureImage.RGBA in options) and (TTextureImage.UnsignedByte in options), 'Texture must be RGBA and UnsignedByte.');
	Initialize(canvasSize, options);
	bitmaps := images;
end;

function TTextureComposite.GetTexture(name: string): TTexture;
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

procedure TTextureComposite.SetTextureOptions(newValue: TTextureImageOptions); 
begin
	Assert(not IsLoaded, 'texture parameters must be set before loading.');
	textureOptions := newValue;
end;

procedure TTextureComposite.Load;
var
	width, height: integer;
	image: TImage;
	rect: TRect;
	texture: TTexture;
	packer: TBinPacker;
begin
	Assert(not IsLoaded, 'Texture is already loaded.');

	GenerateTexture(m_textureID);
	BindTexture2D(textureID);
	LoadTexture2D(trunc(textureSize.width), trunc(textureSize.height), nil, textureOptions);
	
  packer := TBinPacker.Create(trunc(textureSize.width), trunc(textureSize.height), false);

  for image in bitmaps do
  	begin
  		rect := packer.Insert(image.width, image.height);

  		LoadSubTexture2D(rect, image.Data, textureOptions);

  		texture := TTexture.Create(self);
  		texture.SetTextureFrame(PixelToTexture(rect));
  		texture.SetSize(rect.size);
  		texture.SetPixelFrame(rect);

  		if image.FileName <> '' then
				textures.Add(image.FileName, texture);
  	end;

	packer.Free;
	RestoreLastBoundTexture;
end;

function TTextureComposite.Subdivide(cellSize: TVec2): TTextureSheet;
var
	tableSize: TVec2;
begin
	LoadIfNeeded;

	tableSize.width := trunc(textureSize.width / cellSize.width);
	tableSize.height := trunc(textureSize.height / cellSize.height);

	result := TTextureSheet.Create(GetTexture, GetFrame, cellSize, tableSize);
end;

destructor TTextureComposite.Destroy;
var
	image: TImage;
begin
	FreeAndNil(textures);

	if freeImages then
		for image in bitmaps do
			image.Free;

	if IsLoaded then
		Unload;
end;

{*****************************************************************************
 *                              Texture Sheet
 *****************************************************************************}

function TTextureSheet.GetTexture(x, y: integer): TTexture;
begin
	result := GetTexture(V2(x, y));
end;

function TTextureSheet.GetIndex(x, y: integer): integer;
begin
	result := Trunc((tableSize.width * y) + x);
end;

function TTextureSheet.GetTexture(cell: TVec2): TTexture;
begin
	LoadIfNeeded;
	result := TTexture(textures[GetIndex(trunc(cell.x), trunc(cell.y))]);
end;

function TTextureSheet.GetColumns: integer;
begin
	result := TableSize.width;
end;

function TTextureSheet.GetRows: integer;
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
	LoadIfNeeded;
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
  tex: TTexture;
begin
  Assert(textures = nil, 'Texture sheet is already subdivided.');
  Assert(textureSize.x + textureSize.y > 0, 'Texture sheet must be larger than 0 in order to subdivide.');
  //Assert(IsPowerOfTwo(textureSize), 'Texture sheet ('+textureSize.ToStr+') must be power of two');

  LoadIfNeeded;

  textures := TTextureList.Create(true);

  if (tableSize.width = 0) or (tableSize.height = 0) then
    begin
      m_tableSize.width := trunc((textureSize.width - margin)/(cellSize.width + spacing));
      m_tableSize.height := trunc((textureSize.height - margin)/(cellSize.height + spacing));
    end;

  //writeln('textureSize: ', textureSize.ToStr);
  //writeln('tableSize: ', tableSize.ToStr);
  //writeln('cellSize: ', cellSize.ToStr);

  for y := 0 to tableSize.height - 1 do
    for x := 0 to tableSize.width - 1 do
      begin
      	cellFrame := RectMake(V2(x * cellSize.width, y * cellSize.height), cellSize);

      	cellFrame.origin.x += margin + (spacing * x);
      	cellFrame.origin.y += margin + (spacing * y);

        tex := TTexture.Create(self);
        tex.SetTextureFrame(PixelToTexture(cellFrame));
        tex.SetPixelFrame(cellFrame);
        tex.SetSize(cellSize);
        textures.Add(tex);
      end;
end;

{ Slices a texture made of multiple cells }
function TTextureSheet.Slice(x, y, spanX, spanY: integer): TTexture;
begin
	result := Slice(RectMake(
		x * CellSize.x, 
		y * CellSize.y, 
		spanX * CellSize.x, 
		spanY * CellSize.y)
	);
end;

procedure TTextureSheet.Load;
begin
	inherited;
	Subdivide;
end;

constructor TTextureSheet.Create(path: ansistring; inCellSize: TVec2i; inMargin, inSpacing: integer; options: TTextureImageOptions = DefaultTextureOptions); overload;
begin
	margin := inMargin;
	spacing := inSpacing;
	Create(path, inCellSize, 0);
end;

constructor TTextureSheet.Create(_texture: TTexture; inCellSize, inTableSize: TVec2i);
begin
	m_cellSize := inCellSize;
	m_tableSize := inTableSize;
	Create(_texture.TextureID, _texture.GetFrame, inCellSize, inTableSize);
end;

constructor TTextureSheet.Create(_texture: TTexture; inCellSize: TVec2i);
begin
	Create(_texture, inCellSize, 0);
end;

constructor TTextureSheet.Create(path: ansistring; inCellSize, inTableSize: TVec2i);
begin
	inherited Create(path);
	m_cellSize := inCellSize;
	m_tableSize := inTableSize;
end;

constructor TTextureSheet.Create(path: ansistring; inCellSize: TVec2i);
begin
	Create(path, inCellSize, 0);
end;

{ Creates an empty texture sheet }
constructor TTextureSheet.Create(inCellSize, inTableSize: TVec2; options: TTextureImageOptions = DefaultTextureOptions);
var
	componentCount: integer;
	componentSize: integer;
	imageSize: TVec2i;
	data: pointer;
begin
	m_cellSize := inCellSize;
	m_tableSize := inTableSize;

	// get component count
	componentCount := 0;
	if TTextureImage.RGBA in options then
		componentCount := 4
	else 	if TTextureImage.RGB in options then
		componentCount := 3;

	if componentCount = 0 then
		raise Exception.Create('invalid component count');

	// get component size
	componentSize := 0;
	if TTextureImage.UnsignedByte in options then
		componentSize := sizeof(byte)
	else if TTextureImage.Float in options then
		componentSize := sizeof(single);

	if componentSize = 0 then
		raise Exception.Create('invalid component size');

	// allocate pixel memory
	Include(flags, TTextureFlag.FreeSourceImage);
	imageSize := inCellSize * inTableSize;
	data := GetMem(imageSize.width * imageSize.height * componentCount * componentSize);
	if data = nil then
		raise Exception.Create('failed to allocate texture memory');
		
	inherited Create(imageSize.width, imageSize.height, data, options);

	Subdivide;
end;

{ Creates a texture sheet from an existing raw texture }
constructor TTextureSheet.Create(inTextureID: integer; inTextureFrame: TTextureFrame; inCellSize, inTableSize: TVec2i);
begin
	inherited Create(inTextureID, trunc(inTextureFrame.pixel.width), trunc(inTextureFrame.pixel.height));
	m_cellSize := inCellSize;
	m_tableSize := inTableSize;
	m_textureFrame := inTextureFrame;
	Subdivide;
end;

{*****************************************************************************
 *                                Texture
 *****************************************************************************}

procedure TTexture.SetTextureFrame(newValue: TRect);
begin
	m_textureFrame.texture := newValue;
end;

procedure TTexture.SetPixelFrame(newValue: TRect);
begin
	m_textureFrame.pixel := newValue;
end;

{ Slice a uniform array of textures.
  The textures created are owned by the primary texture. }
function TTexture.Slice(columns: integer; rows: integer = 0): TTextureArray;
var
	x, y: integer;
	cellWidth, cellHeight: integer;
begin
	LoadIfNeeded;

	result := [];
	cellWidth := Width div Columns;

	if rows > 0 then
		begin
			cellHeight := Height div rows;
			for y := 0 to rows - 1 do
			for x := 0 to columns - 1 do
				result += [Slice(RectMake(x * cellWidth, y * cellHeight, cellWidth, cellHeight))];
		end
	else
		begin
			y := 0;
			cellHeight := Height;
			for x := 0 to columns - 1 do
				result += [Slice(RectMake(x * cellWidth, y * cellHeight, cellWidth, cellHeight))];
		end;
end;

{ Slice a sub-texture.
  The texture created is owned by the primary texture. }
function TTexture.Slice(rect: TRect): TTexture;
begin
	LoadIfNeeded;
	result := TTexture.Create(self, rect, PixelToTexture(rect));
	AddChild(result);
end;

{ Sub-divide the texture into a sheet.
  The sheet is owned by the primary texture. }
function TTexture.Subdivide(cellSize: TVec2): TTextureSheet;
var
	tableSize: TVec2;
begin
	LoadIfNeeded;
	tableSize.width := trunc(textureSize.width / cellSize.width);
	tableSize.height := trunc(textureSize.height / cellSize.height);
	result := TTextureSheet.Create(GetTexture, GetFrame, cellSize, tableSize);
	AddChild(result);
end;

procedure TTexture.LoadImage(image: TImage);
begin
	if m_textureID = 0 then
		begin
			Include(flags, TTextureFlag.DisposeTexture);
			GenerateTexture(m_textureID);
		end;
	
	BindTexture2D(textureID);
	LoadTexture2D(GetWidth, GetHeight, image.data, textureOptions);
	RestoreLastBoundTexture;
end;

function TTexture.PixelAt(x, y: integer): TImagePixel;
begin
	// if the texture has an owner then offset to the owners
	// cooridinate space and sample from the owner
	if HasOwner then
		result := owner.PixelAt(PixelFrame.origin + V2(x, y))
	else
		begin
			Assert(IsLoaded, 'Texture must be loaded before inspecting pixels.');
			Assert(sourceImage <> nil, 'Texture image data was freed (or never allocated) before inspecting pixels.');
			// TODO: we're keeping the bitmap data the entire life of the texture just for this
			// https://registry.khronos.org/OpenGL-Refpages/gl4/html/glGetTexImage.xhtml
			result := sourceImage.data[x + y * trunc(textureSize.width)];
		end;
end;

procedure TTexture.Load;
begin
	Assert(not IsLoaded, 'Texture is already loaded.');
	LoadImage(sourceImage);
end;

procedure TTexture.Reload;
begin
	LoadImage(sourceImage);
end;

procedure TTexture.Reload(region: TRect; data: pointer);
begin
	Assert(IsLoaded, 'Texture must be loaded before reloading sub-region.');
	BindTexture2D(textureID);
	LoadSubTexture2D(region, data, textureOptions);
	RestoreLastBoundTexture;
end;

procedure TTexture.Reload(data: pointer);
begin
	Reload(PixelFrame, data);
end;

procedure TTexture.Lock(inUnit: integer);
begin
	if HasOwner then
		owner.Lock(inUnit)
	else
		inherited Lock(inUnit);
end;

function TTexture.IsLocked: boolean;
begin
	if HasOwner then
		result := owner.IsLocked
	else
		result := inherited;
end;

{ Store a sub-texture which is owned by the texture }
procedure TTexture.AddChild(child: TTexture);
begin
	if children = nil then
		children := TTextureList.Create;
	children.Add(child);
end;

procedure TTexture.SetSize(newValue: TVec2);
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

function TTexture.GetByteCount: integer;
begin
	result := width * height * textureOptions.Components * textureOptions.BytesPerComponent;
end;

function TTexture.GetHeight: integer;
begin
	result := trunc(GetSize.height);
end;

function TTexture.GetTextureCoords: TRect;
begin
	result := RectMake(0, 0, 1, 1);
end;

destructor TTexture.Destroy;
begin
	{$ifdef DEBUG_TEXTURES}
	writeln('free texture ', hexstr(self));
	{$endif}

	// free child textures
	FreeAndNil(children);

	// delete the texture if we own it
	if (TTextureFlag.DisposeTexture in flags) and (textureID <> 0) then
		Unload;
	
	// free the source image if we own it
	if (TTextureFlag.FreeSourceImage in flags) and assigned(sourceImage) then
		sourceImage.Free;

	inherited;
end;

constructor TTexture.Create(image: TImage; copyImage: boolean = true);
begin
	Assert(image <> nil, 'texture data must not be nil');
	if copyImage then
		begin
			sourceImage := TImage(image.Copy);
			Include(flags, TTextureFlag.FreeSourceImage);
		end
	else
		sourceImage := image;
	SetSize(image.size);
	SetPixelFrame(RectMake(0, 0, width, height));
	SetTextureFrame(GetTextureCoords);
	textureOptions := DefaultTextureOptions;
end;

constructor TTexture.Create(_size: TVec2i; data: pointer; options: TTextureImageOptions);
begin
	Create(_size.width, _size.height, data, options);
end;

constructor TTexture.Create(width, height: integer; data: pointer; options: TTextureImageOptions = DefaultTextureOptions);
begin
	//Assert(data <> nil, 'texture data must not be nil');
	sourceImage := TImage.Create(width, height, data);
	Include(flags, TTextureFlag.FreeSourceImage);
	SetPixelFrame(RectMake(0, 0, width, height));
	SetTextureFrame(GetTextureCoords);
	textureOptions := options;
end;

constructor TTexture.Create(source: TTextureSource; inPixelFrame, inTextureFrame: TRect; options: TTextureImageOptions = DefaultTextureOptions);
begin
	Create(source);
	m_textureFrame.pixel := inPixelFrame;
	m_textureFrame.texture := inTextureFrame;
	textureOptions := options;
end;

constructor TTexture.Create(source: TTextureSource);
begin
	m_owner := source;
	m_textureID := source.GetTexture;
	Create(textureID);
end;

constructor TTexture.Create(texture: integer; width: integer = 0; height: integer = 0; options: TTextureImageOptions = DefaultTextureOptions);
begin
	Assert(texture > 0, 'Must use a valid texture ID.');
	m_textureID := texture;
	SetSize(V2(width, height));
	SetTextureFrame(GetTextureCoords);
	textureOptions := options;
end;

constructor TTexture.Create(path: ansistring; options: TTextureImageOptions = DefaultTextureOptions);
var
	imageWidth, imageHeight: integer;
begin
	sourceImage := LoadImageFromFile(path, imageWidth, imageHeight);
	Include(flags, TTextureFlag.FreeSourceImage);
	SetSize(V2(imageWidth, imageHeight));
	SetTextureFrame(GetTextureCoords);
	textureOptions := options;
end;

{$endif}
