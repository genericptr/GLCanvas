
{$ifdef INTERFACE}

const
	kTextAlignmentLeft = 0;
	kTextAlignmentCenter = 1;	

// .fnt format
// http://kvazars.com/littera/
// http://www.angelcode.com/products/bmfont/doc/file_format.html

type
	TBitmapFont = class (TTextureSource)
		private
			const
				kFontChars = 256;
			type
				TStringInternal = ansistring;
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

			function GetCharacterSpacing (c: char): integer;
			function GetYOffset (c: char): integer;			
			function GetTextWidth (text: string): integer;
			function GetTexture (index: integer): TTexture; overload;
			function GetXHeight: integer;
			function GetLineHeight: integer;
		public		

			{ Constructors }
			constructor Create (path: ansistring);
			
			{ Accessors }
			procedure SetCharAdvance (newValue: integer);
			function TextureForCharacter (c: char): TTexture; overload; inline;
			function GetTexture: TGLTextureID;

			property SpaceWidth: integer read m_spaceWidth write m_spaceWidth;
			property TabWidth: integer read m_tabWidth;
			property LineHeight: integer read GetLineHeight;
			property XHeight: integer read GetXHeight;
			property Name: string read m_name;

			{ Methods }
			function MeasureText (_string: TStringInternal; maximumWidth: integer = MaxInt): TVec2;
			function WrapText (_string: TStringInternal; maximumWidth: integer): TStringList;
			
			procedure Lock(inUnit: TGLTextureUnit); override;

		private
			infoPath: ansistring;
			texture: TTexturePack;
			fontInfo: TFontInfo;

			destructor Destroy; override;
			procedure LoadProperties;
			function SplitString (text: TStringInternal; chars: integer; var count: integer): TStringList;
			function RestoreText (text: TStringInternal): TStringInternal;
			function WrapTextInternal (text: TStringInternal; max: single; var actualSize: TVec2): TStringList;
			function CharDescriptor(c: char): TFontCharDescriptor; inline;
	end;

function DrawText (font: TBitmapFont; text: ansistring; textAlignment: integer; bounds: TRect): TVec2; overload;
procedure DrawText (font: TBitmapFont; text: ansistring; where: TVec2; scale: single = 1.0); overload;

{$endif}

{$ifdef IMPLEMENTATION}
	
function TBitmapFont.SplitString (text: TStringInternal; chars: integer; var count: integer): TStringList;
var
	p: pchar;
begin	
	// quotes break WrapText so we need to remove them
	text := StringReplace(text, #39, '#39', [rfReplaceAll]);
	text := StringReplace(text, #34, '#34', [rfReplaceAll]);
	//text := StringReplace(text, #13, '#13', [rfReplaceAll]);
	
	text := SysUtils.WrapText(text, chars);	
	
	p := StrAlloc(length(text) + 1);
	StrPCopy(p, text);

	result := TStringList.Create;
	count := ExtractStrings([chr(10)], [], p, result);
	
	StrDispose(p);
end;

function TBitmapFont.RestoreText (text: TStringInternal): TStringInternal;
begin
	text := StringReplace(text, '#39', #39, [rfReplaceAll]);
	text := StringReplace(text, '#34', #34, [rfReplaceAll]);
	//text := StringReplace(text, '#13', #13, [rfReplaceAll]);
	result := text;
end;

function TBitmapFont.WrapTextInternal (text: TStringInternal; max: single; var actualSize: TVec2): TStringList;
var
	i, s: integer;
	fragment: string = '';
	previousFragment: string;
	part: string;
	c: char;
	parts: TStringList;
	width: integer;
	height: integer;
	totalHeight: integer;
	count: integer;
	start: integer;
	done: boolean = false;
	longestLine: integer = 0;
	previousLongestLine: integer = 0;
	startTime: single;
	debug: boolean = false;
begin
	if text = '' then
		begin
			actualSize := V2(0, 0);
			exit;
		end;
						
  try		
		result := TStringList.Create; 
		if max > 0 then
			begin
				// estimate a starting position based on the width of a test character
				//width := MeasuringCanvas.self.GetTextWidth('A');
				start := 1;
				if debug then writeln('WrapText: start ', start, ', width ', width, ', max ', round(max));
								
				if start < length(text) then
					for i := start to length(text) - 1 do
						begin
							//writeln('index: ', i);
							//longestLine := 0;	
							totalHeight := 0;					
							parts := SplitString(text, i, count);
							for s := 0 to count - 1 do
								begin
									part := parts.strings[s];
									width := self.GetTextWidth(part);
									totalHeight += height;
									if debug then writeln('  ', part, ' = ', width, ' (', i, ')');
									
									if (width > longestLine) and (width <= max) then
										longestLine := width;
									
									if (part = text) and (width <= max) then
										begin
											longestLine := width;
											done := true;
											if debug then writeln('done: part is same as text');
											result.Add(RestoreText(text));
											break;
										end;
										
									if width >= max then
										begin
											done := true;
											if debug then writeln('done: width is >= than max (', max:1:1, ')');
											break;
										end
								end;
							
							previousLongestLine := longestLine;
							
							parts.Free;

							if done then
								begin
									if result.Count = 0 then
										begin
											parts := SplitString(text, i - 1, count);
											for s := 0 to count - 1 do
												result.Add(RestoreText(parts.strings[s]));
											parts.Free;
										end;
									break;
								end;
						end;
				
				// clip the longest line to the max
				if longestLine > max then
					longestLine := trunc(max);
				
				// no parts were added so assume the whole string fits
				if result.count = 0 then	
					result.Add(RestoreText(text));
				
				actualSize.width := previousLongestLine;
				actualSize.height := lineHeight * result.count;
			end
		else // use the entire strings width
			begin				
				result.Add(text);
				actualSize.width := self.GetTextWidth(text);
				actualSize.height := lineHeight;
			end;
  finally
  end;
end;

function TBitmapFont.GetTexture: TGLTextureID;
begin
	result := texture.GetTexture;
end;

procedure TBitmapFont.SetCharAdvance (newValue: integer);
begin
	m_charAdvance := newValue;
end;

function TBitmapFont.GetTextWidth (text: string): integer;
var
	c: char;
	tex: TTexture;
	spacing: integer;
begin
	result := 0;
	for c in text do
		begin
			tex := TextureForCharacter(c);
			if tex <> nil then
				begin
					spacing := GetCharacterSpacing(c);
					result += tex.GetWidth + spacing;
				end
			else if c = #32 then
				begin
					spacing := spaceWidth;
					result += spacing;
				end
			else if c = #9 then
				begin
					spacing := spaceWidth * tabWidth;
					result += spacing;
				end;
		end;
	
	if result > 0 then	
		result -= spacing;
end;

function TBitmapFont.GetTexture (index: integer): TTexture;
begin
	result := fontInfo.chars[index].texture;
end;

function TBitmapFont.GetCharacterSpacing (c: char): integer;
begin
	result := m_charAdvance;//fontInfo.chars[ord(c)].xadvance + charAdvance;
end;

function TBitmapFont.GetYOffset (c: char): integer;
begin
	result := fontInfo.chars[ord(c)].yoffset;
end;

function TBitmapFont.GetLineHeight: integer;
begin
	result := fontInfo.lineHeight;
end;

function TBitmapFont.GetXHeight: integer;
begin
	result := fontInfo.base;
end;

function TBitmapFont.CharDescriptor(c: char): TFontCharDescriptor;
begin
	result := fontInfo.chars[ord(c)];
end;

function TBitmapFont.TextureForCharacter (c: char): TTexture;
begin
	if (c = ' ') or (c = '	') then
		exit(nil);
	result := GetTexture(Ord(c));//fontInfo.chars[Ord(c)].texture
end;

procedure TBitmapFont.LoadProperties;
type
	TStringMap = specialize TFPGMap<string, string>;
var
	memoryPool: TObjectList;

	function NodeAttributes (node: TDOMNode): TStringMap;
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
	node, child: TDOMNode;
	attributes: TStringMap;
	font: TFontInfo;
	charDesc: TFontCharDescriptor;
	frame: TRect;
	charTexture: TTexture;
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
			
			// NOTE: why did this happen?
			if charDesc.id < kFontChars then
				begin
					charDesc.x := StrToInt(attributes['x']);
					charDesc.y := StrToInt(attributes['y']);
					charDesc.width := StrToInt(attributes['width']);
					charDesc.height := StrToInt(attributes['height']);
					charDesc.xoffset := StrToInt(attributes['xoffset']);
					charDesc.yoffset := StrToInt(attributes['yoffset']);
					charDesc.xadvance := StrToInt(attributes['xadvance']);
					charDesc.page := StrToInt(attributes['page']);
					charDesc.chnl := StrToInt(attributes['chnl']);

					//frame := RectMake(charDesc.x / font.scaleW, charDesc.y / font.scaleH, charDesc.width / font.scaleW, charDesc.height / font.scaleH);
					////frame := RectMake(0,0,1,1);
					//charTexture := TTexture.Create(texture.textureID);
					//charTexture.SetTextureFrame(frame);
					//charTexture.SetSize(SizeMake(charDesc.width, charDesc.height));
					//charTexture.SetCropping(RectMake(PointMake(charDesc.xoffset, charDesc.yoffset), charTexture.GetSize));
					//charDesc.texture := charTexture;

					texture.AddTexture(chr(charDesc.id), 
							V2(charDesc.width, charDesc.height), 
							V2(charDesc.width, charDesc.height),
							V2(charDesc.xoffset, charDesc.yoffset),
							V2(charDesc.x, charDesc.y),
							V2(0, 0)
						);
					charDesc.texture := texture[chr(charDesc.id)];

					//writeln('id ', charDesc.id, ' = ', chr(charDesc.id));
					font.chars[charDesc.id] := charDesc;
				end
			else
				;//Fatal('invalid char id '+attributes.GetValue('id'));
				
			node := node.NextSibling;
		end;

	memoryPool.Free;
	xml.Free;
	fontInfo := font;
end;

procedure TBitmapFont.Lock(inUnit: TGLTextureUnit);
begin
	texture.Lock(inUnit);
end;

destructor TBitmapFont.Destroy;
begin
	texture.Free;
end;

function TBitmapFont.WrapText (_string: TStringInternal; maximumWidth: integer): TStringList;
var
	actualSize: TVec2;
begin
	result := WrapTextInternal(_string, maximumWidth, actualSize);
end;

function TBitmapFont.MeasureText (_string: TStringInternal; maximumWidth: integer = MaxInt): TVec2;
begin		
	WrapTextInternal(_string, maximumWidth, result);
end;

constructor TBitmapFont.Create (path: ansistring);
begin
	texture := TTexturePack.Create;
	texture.SetTextureParameters([kTextureNearestFilter, kTextureClampToEdge]);
	texture.LoadImage(path+'/font.png');

	textureID := texture.textureID;

	infoPath := path+'/font.fnt';
	Assert(FileExists(infoPath), 'font.fnt file doesn''t exist.');
	m_name := ExtractFileName(path);
	m_spaceWidth := 3;
	m_tabWidth := 4;
	LoadProperties;
end;

function DrawText (font: TBitmapFont; text: ansistring; textAlignment: integer; bounds: TRect): TVec2;
var
	line: ansistring;
	lines: TStringList;
	where: TVec2;
begin
	Assert(font <> nil, 'font must not be nil');

	if text = '' then
		exit(V2(0, 0));
		
	where := bounds.origin;
	lines := font.WrapTextInternal(text, Trunc(bounds.width), result);
	for line in lines do
		begin
			case textAlignment of
				kTextAlignmentLeft:
					;
				kTextAlignmentCenter:				
					where.x := bounds.MidX - (font.MeasureText(line, maxInt).width / 2);
			end;
			DrawText(font, line, where);
			where.y += font.GetLineHeight;
		end;
end;

procedure DrawText (font: TBitmapFont; text: ansistring; where: TVec2; scale: single = 1.0);
var
	i: integer;
	c: char;
	texture: TTexture;
	newOrigin: TVec2;
	origin: TVec2;
begin
	Assert(font <> nil, 'font must not be nil');

	if text = '' then
		exit;
		
	origin := where;

	for c in text do
		begin
			texture := font.TextureForCharacter(c);
			
			if texture = nil then
				if c = #32 then
					begin
						origin.x += font.SpaceWidth;
						continue;
					end
				else if c = #9 then
					begin
						origin.x += font.SpaceWidth * font.TabWidth;
						continue;
					end
				else
					begin
						origin.x += font.SpaceWidth;
						continue;
					end;
				
			newOrigin.x := origin.x;
			newOrigin.y := origin.y + font.CharDescriptor(c).yoffset;
			DrawTexture(texture, RectMake(newOrigin, texture.GetSize) * scale);

			origin.x += texture.GetWidth + font.GetCharacterSpacing(c);
		end;
end;

{$endif}
