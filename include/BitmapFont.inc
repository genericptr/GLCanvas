
{$ifdef INTERFACE}

{ .fnt format }
// http://kvazars.com/littera/
// http://www.angelcode.com/products/bmfont/doc/file_format.html

type
	TBitmapFont = class (TTextureSource, IFont, ITexture)
		private const
			kFontChars = 256;
		private type
			TFontCharDescriptor = record
				id: integer;
				x, y: single;
				width, height: single;
				xoffset, yoffset: integer;
				xadvance: integer;
				page: byte;
				chnl: byte;
				texture: TTexture;
			end;
			TFontInfo = record
				// <info>
				face: string;
				size: byte;
				bold: byte;
				italic: byte;
				charset: string;
				stretchH: smallint;
				smooth: byte;
				aa: byte;
				padding: array[0..3] of byte;
				spacing: array[0..1] of byte;
				outline: Byte;
				// <common>
				lineHeight: byte;
				base: byte;
				scaleW, scaleH: integer;
				pages: byte;
				_packed: byte;
				// <chars>
				chars: array[0..kFontChars - 1] of TFontCharDescriptor;
			end;	
		private
			m_spaceWidth: integer;
			m_tabWidth: integer;
			m_charAdvance: integer;
			m_name: string;	

			function GetTexture(index: integer): TTexture; overload;
		public		

			{ Constructors }
			constructor Create(path: ansistring);
			destructor Destroy; override;

			{ Accessors }
			procedure SetCharAdvance(newValue: integer);
			function TextureForCharacter(c: TFontChar): TTexture; inline;
			function GetTexture: integer;
			function GetFrame: TTextureFrame;
			property Name: string read m_name;
			
			procedure Lock(inUnit: integer); override;
			function IsLocked: boolean; override;

			{ IFont }
			function CharacterRenderFrame(c: TFontChar): TFontRenderFrame;
			function LineHeight: integer;
			function SpaceWidth: integer;
			function TabWidth: integer;
			function HasGlyph(c: TFontChar): boolean;
			function PreferredTextColor: TVec4;

		private
			infoPath: ansistring;
			texturePack: TTexturePack;
			fontInfo: TFontInfo;

			procedure LoadProperties;
			function CharDescriptor(c: TFontChar): TFontCharDescriptor; inline;
	end;

{$endif}

{$ifdef IMPLEMENTATION}

function TBitmapFont.CharacterRenderFrame(c: TFontChar): TFontRenderFrame;
begin
	result.bearing.y := fontInfo.chars[ord(c)].yoffset;
	result.bearing.x := 0;
	result.textureFrame := TextureForCharacter(c).TextureFrame;
	result.faceSize := TextureForCharacter(c).GetSize;
	result.advance := trunc(result.faceSize.width) + m_charAdvance;
end;

function TBitmapFont.LineHeight: integer;
begin
	result := fontInfo.lineHeight;
end;

function TBitmapFont.SpaceWidth: integer;
begin
	result := m_spaceWidth;
end;

function TBitmapFont.TabWidth: integer;
begin
	result := m_tabWidth;
end;

function TBitmapFont.HasGlyph(c: TFontChar): boolean;
begin
	result := TextureForCharacter(c) <> nil;
end;

function TBitmapFont.PreferredTextColor: TVec4;
begin
	result := RGBA(1, 1, 1, 1);
end;

function TBitmapFont.GetTexture: integer;
begin
	result := texturePack.GetTexture;
end;

function TBitmapFont.GetFrame: TTextureFrame;
begin
	result := texturePack.GetFrame;
end;

procedure TBitmapFont.SetCharAdvance(newValue: integer);
begin
	m_charAdvance := newValue;
end;

function TBitmapFont.GetTexture(index: integer): TTexture;
begin
	result := fontInfo.chars[index].texture;
end;

function TBitmapFont.CharDescriptor(c: TFontChar): TFontCharDescriptor;
begin
	result := fontInfo.chars[ord(c)];
end;

function TBitmapFont.TextureForCharacter(c: TFontChar): TTexture;
begin
	if (c = ' ') or (c = '	') then
		exit(nil);
	result := GetTexture(Ord(c));
end;

procedure TBitmapFont.LoadProperties;
type
	TStringMap = specialize TFPGMap<string, string>;
var
	memoryPool: TObjectList;

	function NodeAttributes(node: TDOMNode): TStringMap;
	var
		i: integer;
	begin
		result := TStringMap.Create;
		for i := 0 to node.Attributes.Length - 1 do
			result.Add(node.Attributes.Item[i].NodeName, node.Attributes.Item[i].NodeValue);
		memoryPool.Add(result);
	end;
var
	xml: TXMLDocument;
	node: TDOMNode;
	attributes: TStringMap;
	font: TFontInfo;
	charDesc: TFontCharDescriptor;
begin
	memoryPool := TObjectList.Create(true);
	ReadXMLFile(xml, infoPath);
	
	//http://www.angelcode.com/products/bmfont/doc/file_format.html
	//https://www.gamedev.net/topic/330742-quick-tutorial-variable-width-bitmap-fonts/
	
	node := xml.DocumentElement.FindNode('info');
	attributes := NodeAttributes(node);		

	FillChar(font, sizeof(font), 0);
	font.face := attributes['face'];
	font.size := StrToInt(attributes['size']);
	font.bold := StrToInt(attributes['bold']);
	font.italic := StrToInt(attributes['italic']);
	font.charset := attributes['charset'];
	font.stretchH := StrToInt(attributes['stretchH']);
	font.smooth := StrToInt(attributes['smooth']);
	font.aa := StrToInt(attributes['aa']);
	font.outline := StrToInt(attributes['outline']);

	node := xml.DocumentElement.FindNode('common');
	attributes := NodeAttributes(node);	
	font.lineHeight := StrToInt(attributes['lineHeight']);
	font.base := StrToInt(attributes['base']);
	font.scaleW := StrToInt(attributes['scaleW']);
	font.scaleH := StrToInt(attributes['scaleH']);
	font.pages := StrToInt(attributes['pages']);
	font._packed := StrToInt(attributes['packed']);

	node := xml.DocumentElement.FindNode('chars');
	node := node.FirstChild;	
	while node <> nil do
		begin
			attributes := NodeAttributes(node);	
			charDesc.id := StrToInt(attributes['id']);
			Assert(charDesc.id < kFontChars, 'invalid character id '+IntToStr(charDesc.id));

			charDesc.x := StrToInt(attributes['x']);
			charDesc.y := StrToInt(attributes['y']);
			charDesc.width := StrToInt(attributes['width']);
			charDesc.height := StrToInt(attributes['height']);
			charDesc.xoffset := StrToInt(attributes['xoffset']);
			charDesc.yoffset := StrToInt(attributes['yoffset']);
			charDesc.xadvance := StrToInt(attributes['xadvance']);
			charDesc.page := StrToInt(attributes['page']);
			charDesc.chnl := StrToInt(attributes['chnl']);

			texturePack.AddTexture(chr(charDesc.id), 
					V2(charDesc.width, charDesc.height), 
					V2(charDesc.x, charDesc.y));
			
			charDesc.texture := texturePack[chr(charDesc.id)];

			font.chars[charDesc.id] := charDesc;
				
			node := node.NextSibling;
		end;

	memoryPool.Free;
	xml.Free;
	fontInfo := font;
end;

procedure TBitmapFont.Lock(inUnit: integer);
begin
	texturePack.Lock(inUnit);
end;

function TBitmapFont.IsLocked: boolean;
begin
	result := texturePack.IsLocked;
end;

destructor TBitmapFont.Destroy;
begin
	texturePack.Free;
end;

constructor TBitmapFont.Create(path: ansistring);
begin
	// TODO: should implement Loading!
	texturePack := TTexturePack.Create;
	texturePack.SetTextureOptions([TTextureImage.RGBA, 
																 TTextureImage.UnsignedByte, 
																 TTextureImage.NearestNeighbor
																 ]);
	texturePack.LoadImage(path+'/font.png');

	m_textureID := texturePack.textureID;
	m_owner := texturePack;

	infoPath := path+'/font.fnt';
	Assert(FileExists(infoPath), 'font.fnt file doesn''t exist.');

	m_name := ExtractFileName(path);
	m_spaceWidth := 3;
	m_tabWidth := 4;
	LoadProperties;

	//writeln('loaded bitmap font textureID=', textureID, ' textureUnit=',GetTextureUnit);
end;

{$endif}
