
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
			type
				TStringInternal = ansistring;
			const
				kFontChars = 256;
			type
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
		public		

			{ Constructors }
			constructor Create (path: ansistring);
			
			{ Accessors }
			procedure SetSpaceWidth (newValue: integer);
			procedure SetCharAdvance (newValue: integer);
			
			function GetTexture (c: char): TTexture; overload; inline;
			function GetSpaceWidth: integer;
			function GetTabWidth: integer;
			function GetLineHeight: integer;
			function GetName: string;
			
			{ Methods }
			function MeasureText (_string: TStringInternal; maximumWidth: integer = MaxInt): TSize;
			function WrapText (_string: TStringInternal; maximumWidth: integer): TStringList;

		private
			infoPath: ansistring;
			texture: TTexturePack;
			fontInfo: TFontInfo;
			spaceWidth: integer;
			tabWidth: integer;
			charAdvance: integer;
			name: string;

			destructor Destroy; override;
			procedure LoadProperties;
			procedure Load;
			function SplitString (text: TStringInternal; chars: integer; var count: integer): TStringList;
			function RestoreText (text: TStringInternal): TStringInternal;
			function WrapTextInternal (text: TStringInternal; max: single; var actualSize: TSize): TStringList;

			function GetCharacterSpacing (c: char): integer;
			function GetYOffset (c: char): integer;			
			function GetTextWidth (text: string): integer;
			function GetTexture (index: integer): TTexture; overload;
			function GetXHeight: integer;
			function GetCharDesc(c: char): TFontCharDescriptor;
	end;

function DrawText (font: TBitmapFont; text: ansistring; textAlignment: integer; bounds: TRect): TSize; overload;
procedure DrawText (font: TBitmapFont; text: ansistring; where: TPoint; scale: single = 1.0); overload;

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

function TBitmapFont.WrapTextInternal (text: TStringInternal; max: single; var actualSize: TSize): TStringList;
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
	lineHeight, xHeight: integer;
	debug: boolean = false;
begin
	if text = '' then
		begin
			actualSize := SizeMake(0, 0);
			exit;
		end;
						
  try		
		lineHeight := self.GetLineHeight;
		xHeight := self.GetXHeight;
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

procedure TBitmapFont.SetSpaceWidth (newValue: integer);
begin
	spaceWidth := newValue;
end;

procedure TBitmapFont.SetCharAdvance (newValue: integer);
begin
	charAdvance := newValue;
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
			tex := GetTexture(c);
			if tex <> nil then
				begin
					spacing := GetCharacterSpacing(c);
					result += tex.GetWidth + spacing;
				end
			else if c = #32 then
				begin
					spacing := GetSpaceWidth;
					result += spacing;
				end
			else if c = #9 then
				begin
					spacing := GetSpaceWidth * tabWidth;
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
	result := charAdvance;//fontInfo.chars[ord(c)].xadvance + charAdvance;
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

function TBitmapFont.GetCharDesc(c: char): TFontCharDescriptor;
begin
	result := fontInfo.chars[ord(c)];
end;

function TBitmapFont.GetSpaceWidth: integer;
begin
	result := spaceWidth;
end;

function TBitmapFont.GetTabWidth: integer;
begin
	result := tabWidth;
end;

function TBitmapFont.GetName: string;
begin
	result := name;
end;

function TBitmapFont.GetTexture (c: char): TTexture;
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
	
	// TODO: make a method to preload texture map
	texture.textures := TTextureMap.Create;

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
							SizeMake(charDesc.width, charDesc.height), 
							SizeMake(charDesc.width, charDesc.height),
							PointMake(charDesc.xoffset, charDesc.yoffset),
							PointMake(charDesc.x, charDesc.y),
							PointMake(0, 0)
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

procedure TBitmapFont.Load;
begin	
	LoadProperties;	
	//texture.Load;
end;

destructor TBitmapFont.Destroy;
begin
	texture.Free;
end;

function TBitmapFont.WrapText (_string: TStringInternal; maximumWidth: integer): TStringList;
var
	actualSize: TSize;
begin
	result := WrapTextInternal(_string, maximumWidth, actualSize);
end;

function TBitmapFont.MeasureText (_string: TStringInternal; maximumWidth: integer = MaxInt): TSize;
begin		
	WrapTextInternal(_string, maximumWidth, result);
end;

constructor TBitmapFont.Create (path: ansistring);
begin
	texture := TTexturePack.Create;
	texture.LoadImage(path+'/font.png');
	texture.SetTextureParameters([kTextureNearestFilter, kTextureClampToEdge]);
	infoPath := path+'/font.fnt';
	Assert(FileExists(infoPath), 'font.fnt file doesn''t exist.');
	name := ExtractFileName(path);
	spaceWidth := 3;
	tabWidth := 4;
	Load;
end;

function DrawText (font: TBitmapFont; text: ansistring; textAlignment: integer; bounds: TRect): TSize;
var
	line: ansistring;
	lines: TStringList;
	where: TPoint;
begin
	Assert(font <> nil, 'font must not be nil');

	if text = '' then
		exit(SizeMake(0, 0));
		
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

procedure DrawText (font: TBitmapFont; text: ansistring; where: TPoint; scale: single = 1.0);
var
	i: integer;
	c: char;
	texture: TTexture;
	newOrigin: TPoint;
	origin: TPoint;
begin
	Assert(font <> nil, 'font must not be nil');

	if text = '' then
		exit;
		
	origin := where;

	for c in text do
		begin
			texture := font.GetTexture(c);
			
			if texture = nil then
				if c = #32 then
					begin
						origin.x += font.GetSpaceWidth;
						continue;
					end
				else if c = #9 then
					begin
						origin.x += font.GetSpaceWidth * font.GetTabWidth;
						continue;
					end
				else
					begin
						origin.x += font.GetSpaceWidth;
						continue;
					end;
				
			newOrigin.x := origin.x;
			newOrigin.y := origin.y + font.GetCharDesc(c).yoffset;
			DrawTexture(texture, RectMake(newOrigin, texture.GetSize) * scale);

			origin.x += texture.GetWidth + font.GetCharacterSpacing(c);
		end;
end;

{$endif}
