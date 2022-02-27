
{define DEBUG_FONTS}

{$ifdef INTERFACE}

type
	TTextAlignment = (Left, 
										Center
										);

type
	TFontChar = UnicodeChar;
	TFontString = UnicodeString;

type
	TFontRenderFrame = record
		textureFrame: TRect;
		faceSize: TVec2;
		bearing: TVec2;
		advance: integer;
	end;

type
	IFont = interface (ITexture)
		function CharacterRenderFrame(c: TFontChar): TFontRenderFrame;
		function LineHeight: integer;
		function SpaceWidth: integer;
		function TabWidth: integer;
		function HasGlyph(c: TFontChar): boolean;
		function PreferredTextColor: TVec4;
	end;

type
	TTextWrapping = (
		None,
		Word,
		Chararacter
	);

type
	TTextOffset = LongInt;

	TTextRange = record
	  location: TTextOffset;
	  length: TTextOffset;
	  insertion: TTextOffset;
	  constructor Create(_location, _length: TTextOffset);
	end;

type
	TTextLayoutOptions = record
		font: IFont;
		// TODO: this needs to be a pointer with a range
		text: TFontString;
		range: TTextRange;
		where: TVec2;
		color: TColor;
		scale: float;
		textAlignment: TTextAlignment;
		wrap: TTextWrapping;

		// TODO: make this another record for an overload
		testPoint: TVec2;
		testOffset: TTextOffset;
		hitPoint: TVec2;
		hitOffset: TTextOffset;

		textSize: TVec2;

		draw: boolean;
		cursor: TTextRange;
		class function DefaulOptions: TTextLayoutOptions; static; inline;
	end;

{$endif}

{$ifdef IMPLEMENTATION}

class function TTextLayoutOptions.DefaulOptions: TTextLayoutOptions;
begin
	result.color := TColor.White;
	result.wrap := TTextWrapping.None;
	result.hitPoint := 0;
	result.cursor := TTextRange.Create(-1, 0);
end;

constructor TTextRange.Create(_location, _length: TTextOffset);
begin
	insertion := _location;
	location := _location;
	length := _length;
end;

function SplitString(text: TFontString; chars: integer; var count: integer): TStringList;
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
	// TODO: this fails in Windows because LineEnding is 2 chars wide
	// try
	count := ExtractStrings([LineEnding], [], p, result);
	
	StrDispose(p);
end;

function RestoreText(text: TFontString): TFontString;
begin
	text := StringReplace(text, '#39', #39, [rfReplaceAll]);
	text := StringReplace(text, '#34', #34, [rfReplaceAll]);
	//text := StringReplace(text, '#13', #13, [rfReplaceAll]);
	result := text;
end;

function CalculateTextWidth(font: IFont; text: TFontString): integer;
var
	c: TFontChar;
	renderFrame: TFontRenderFrame;
begin
	result := 0;
	for c in text do
		begin
			if not font.HasGlyph(c) then
				begin
					if c = #32 then
						result += font.SpaceWidth
					else if c = #9 then
						result += font.SpaceWidth * font.TabWidth;
				end
			else
				begin
					renderFrame := font.CharacterRenderFrame(c);
					result += trunc(renderFrame.textureFrame.Width + renderFrame.advance);
				end;
		end;
end;

function WrapTextInternal(font: IFont; text: TFontString; max: single; var actualSize: TVec2): TStringList;
var
	i, s: integer;
	part: string;
	parts: TStringList;
	width: integer;
	count: integer;
	start: integer;
	done: boolean = false;
	longestLine: integer = 0;
	previousLongestLine: integer = 0;
begin
	result := nil;
	
	if text = '' then
		begin
			actualSize := V2(0, 0);
			exit;
		end;
						
  try
		result := TStringList.Create; 
		if max > 0 then
			begin
				start := 1;
				if start < length(text) then
					for i := start to length(text) - 1 do
						begin
							parts := SplitString(text, i, count);
							for s := 0 to count - 1 do
								begin
									part := parts.strings[s];
									width := CalculateTextWidth(font, part);
									
									if (width > longestLine) and (width <= max) then
										longestLine := width;
									
									if (part = text) and (width <= max) then
										begin
											longestLine := width;
											done := true;
											result.Add(RestoreText(text));
											break;
										end;
										
									if width >= max then
										begin
											done := true;
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
				actualSize.height := font.LineHeight * result.count;
			end
		else // use the entire strings width
			begin
				result.Add(text);
				actualSize.width := CalculateTextWidth(font, text);
				actualSize.height := font.LineHeight;
			end;
  finally
  end;
end;

function WrapText(font: IFont; text: TFontString; maximumWidth: integer): TStringList;
var
	actualSize: TVec2;
begin
	result := WrapTextInternal(font, text, maximumWidth, actualSize);
end;

function MeasureText(font: IFont; text: TFontString; maximumWidth: integer = MaxInt): TVec2;
var
	lines: TStringList;
begin
	lines := WrapTextInternal(font, text, maximumWidth, result);
	if lines <> nil then
		lines.Free;
end;

function DrawText(text: TFontString; textAlignment: TTextAlignment; bounds: TRect; color: TColor): TVec2;
begin
	DrawText(CanvasState.activeFont, text, textAlignment, bounds, color);
end;

function DrawText(text: TFontString; textAlignment: TTextAlignment; bounds: TRect): TVec2;
begin
	DrawText(CanvasState.activeFont, text, textAlignment, bounds, 1);	
end;

procedure DrawText(text: TFontString; where: TVec2; color: TColor; scale: single = 1.0);
begin
	DrawText(CanvasState.activeFont, text, where, color, scale);
end;

procedure DrawText(text: TFontString; where: TVec2; scale: single = 1.0);
begin
	DrawText(CanvasState.activeFont, text, where, CanvasState.activeFont.PreferredTextColor, scale);
end;

function DrawText(font: IFont; text: TFontString; textAlignment: TTextAlignment; bounds: TRect; color: TColor): TVec2;
var
	line: TFontString;
	lines: TStringList;
	where: TVec2;
begin
	Assert(font <> nil, 'font must not be nil');

	if text = '' then
		exit(V2(0, 0));
		
	lines := WrapTextInternal(font, text, Trunc(bounds.width), result);
	if lines <> nil then
		begin
			where := bounds.origin;
			for line in lines do
				begin
					case textAlignment of
						TTextAlignment.Center:
							where.x := bounds.MidX - (MeasureText(font, line, maxInt).width / 2);
						otherwise
							;
					end;
					DrawText(font, line, where, color);
					where.y += font.LineHeight;
				end;
			lines.Free;
		end;
end;

function DrawText(font: IFont; text: TFontString; textAlignment: TTextAlignment; bounds: TRect): TVec2;
begin
	result := DrawText(font, text, textAlignment, bounds, 1);
end;

procedure LayoutText(var options: TTextLayoutOptions);

	procedure DrawCursor(origin: TVec2); inline;
	var
		cursorFrame: TRect;
		yMargin: integer;
	begin
		yMargin := 1;
		cursorFrame.width := 1;
		cursorFrame.x := (origin.x - trunc(cursorFrame.width / 2)) - 1 { always draw on left side };
		cursorFrame.y := origin.y - yMargin;
		cursorFrame.height := options.font.LineHeight + (yMargin * 2);
		FillRect(cursorFrame, RGBA(1, 0, 0, 0.9));
	end;

	procedure TestPoints(offset: LongInt; rect: TRect);
	begin
		// test hit offset
		if offset = options.testOffset then
			options.hitPoint := rect.origin;

		// test the hit point
		if options.testPoint.y >= rect.minY then
			begin
				if options.testPoint.x >= rect.midX then
					options.hitOffset := offset + 1
				else if options.testPoint.x >= rect.minX then
					options.hitOffset := offset;
			end;
	end;

var
	offset: TTextOffset;
	c: TFontChar;
	renderFrame: TFontRenderFrame;
	newOrigin,
	prevOrigin,
	origin,
	size: TVec2;
	charFrame: TRect;
	selFrame: TRect;
	newLine: boolean;
begin
	Assert(options.font <> nil, 'DrawText font must not be nil');

	case options.textAlignment of
		TTextAlignment.Left:
			origin := options.where / options.scale;
		TTextAlignment.Center:
			begin
				origin := options.where / options.scale;
				size := MeasureText(options.font, options.text);
				origin.x -= size.width / 2; 
			end;
	end;

	options.hitOffset := -1;
	selFrame.height := 0;
	options.textSize := V2(0, 0);

	for offset := options.range.location to options.range.length - 1 do
		begin
			c := options.text[offset + 1];

			// draw cursor
			if options.draw and (options.cursor.location > -1) then
				begin

					if offset = options.cursor.insertion then
						DrawCursor(origin);

					if (offset = options.cursor.location) and (options.cursor.length > 0) then
						begin
							// start selection frame
							selFrame := RectMake(origin.x, origin.y , 0, options.font.LineHeight);
						end
					else if (offset = options.cursor.location + options.cursor.length) and (selFrame.height > 0) then
						begin
							// end selection frame
							selFrame.size.x := origin.x - selFrame.origin.x;
							FillRect(selFrame, RGBA(1, 0, 0, 0.25));
							selFrame.height := 0;
						end;
				end;

			if not options.font.HasGlyph(c) then
				begin
					newLine := false;
					prevOrigin := origin;

					case c of
						#32: origin.x += options.font.SpaceWidth; 												// space
						#9: origin.x += options.font.SpaceWidth * options.font.TabWidth;  // tab
						#10, #12, #13:																										// EOL
							begin
								newLine := true;

								// test for points outside the line range and
								// and place the hit offset at the end of the line
								// but not after the line break characters
								if (options.testPoint.y >= origin.y) and (options.testPoint.x >= origin.x) then
									options.hitOffset := offset;

								if offset = options.testOffset then
									options.hitPoint := origin;

								// before advacing to the next line draw the selection
								// for the current line
								if options.draw and (selFrame.height > 0) then
									begin
										selFrame.size.x := origin.x - selFrame.origin.x;
										// add an extra amount of space to indicate the line break is selected
										selFrame.size.x += Max(2, options.font.SpaceWidth / 2);
										FillRect(selFrame, RGBA(1, 0, 0, 0.25));
									end;

								origin.y += options.font.LineHeight;
								origin.x := options.where.x / options.scale;

								selFrame.origin := origin;
							end
						otherwise
							origin.x += options.font.SpaceWidth;														// other characters
					end;

					// test points
					if not newLine then
						TestPoints(offset, RectMake(origin.x, origin.y, origin.y - prevOrigin.y, options.font.LineHeight));

					// adjust text size
					if origin.x > options.textSize.width then
						options.textSize.width := origin.x;
					if origin.y > options.textSize.height then
						options.textSize.height := origin.y;	

					continue;
				end;

			renderFrame := options.font.CharacterRenderFrame(c);

			newOrigin.x := origin.x + renderFrame.bearing.x;
			newOrigin.y := origin.y + renderFrame.bearing.y;

			{
				H: 4.0/8.0
				e: 6.0/6.0
				l: 4.0/8.0
				o: 6.0/6.0
				j: 4.0/10.0
				g: 6.0/8.0
			}
			// "originY": (options.font.LineHeight - (renderFrame.bearing.y + renderFrame.faceSize.y)):1:1
			//writeln(char(c),':',renderFrame.bearing.y:1:1,'/',renderFrame.faceSize.y:1:1);

			charFrame := RectMake(newOrigin, renderFrame.faceSize) * options.scale;

			// test points
			TestPoints(offset, charFrame);

			// draw character
			if options.draw then
				begin
					{ TODO: move to direct quad drawing
						charQuad.SetOrigin(origin);
						charQuad.SetSize(face.size);
						charQuad.SetTexture(face.textureFrame);
						DrawQuad(charQuad);
					}
					DrawTexture(options.font, charFrame, renderFrame.textureFrame, options.color);
					{$ifdef DEBUG_FONTS}
					FillRect(charFrame, RGBA(1, 0, 0, 0.2));
					{$endif}
				end;

			origin.x += renderFrame.advance;

			// adjust text size
			if origin.x > options.textSize.width then
				options.textSize.width := origin.x;
			if origin.y > options.textSize.height then
				options.textSize.height := origin.y;
		end;

	options.textSize.y += options.font.LineHeight;

	if (options.testPoint.y >= origin.y) and (options.testPoint.x >= origin.x - renderFrame.advance) then
		options.hitOffset := offset;

	// draw cursor at the final offset
	if options.draw and 
		(options.cursor.location > -1) and (
			(options.cursor.location = options.range.location + options.range.length) or 
			(options.range.length = 0)) then
		DrawCursor(origin);
end;

procedure DrawText(font: IFont; text: TFontString; where: TVec2; color: TColor; scale: single; textAlignment: TTextAlignment);
var
	options: TTextLayoutOptions;
begin
	options.font := font;
	options.text := text;
	options.range := TTextRange.Create(0, length(text));
	options.where := where;
	options.color := color;
	options.scale := scale;
	options.textAlignment := textAlignment;
	options.wrap := TTextWrapping.None;
	options.testPoint := 0;
	options.testOffset := 0;
	options.hitPoint := 0;
	options.hitOffset := 0;
	options.draw := true;
	options.cursor := TTextRange.Create(-1, -1);
	LayoutText(options);
end;

procedure DrawText(font: IFont; text: TFontString; where: TVec2; scale: single);
begin
	DrawText(font, text, where, 1, scale);
end;

procedure DrawText(font: IFont; lines: array of TFontString; bounds: TRect; color: TColor; textAlignment: TTextAlignment);
var
	origin: TVec2;
	line: TFontString;
begin
	Assert(font <> nil, 'font must not be nil');
	
	origin := bounds.origin;

	for line in lines do
		begin
			case textAlignment of
				TTextAlignment.Center:
					origin.x := bounds.MidX - (MeasureText(font, line, maxInt).width / 2);
				otherwise
					;
			end;
			DrawText(font, line, origin, color);
			origin.y += font.LineHeight;
		end;
end;

function CreateFont(name: ansistring; pixelSize: integer): TGLFreeTypeFont;
begin
  result := TGLFreeTypeFont.Create(name);
  result.Render(pixelSize);
end;

{$endif}
