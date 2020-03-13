
{$ifdef INTERFACE}

type
	TTextAlignment = (kAlignmentLeft, 
										kAlignmentCenter
										);

type
	TFontRenderFrame = record
		textureFrame: TRect;
		faceSize: TVec2;
		bearing: TVec2;
		advance: integer;
	end;

type
	IFont = interface (ITexture)
		function CharacterRenderFrame(c: char): TFontRenderFrame;
		function LineHeight: integer;
		function SpaceWidth: integer;
		function TabWidth: integer;
		function HasGlyph(c: char): boolean;
		function PreferredTextColor: TVec4;
	end;

function MeasureText (font: IFont; text: ansistring; maximumWidth: integer = MaxInt): TVec2;
function WrapText (font: IFont; text: ansistring; maximumWidth: integer): TStringList;

function DrawText (text: ansistring; textAlignment: TTextAlignment; bounds: TRect; color: TColor): TVec2; overload; inline;
function DrawText (text: ansistring; textAlignment: TTextAlignment; bounds: TRect): TVec2; overload; inline;
procedure DrawText (text: ansistring; where: TVec2; color: TColor; scale: single = 1.0); overload; inline;
procedure DrawText (text: ansistring; where: TVec2; scale: single = 1.0); overload; inline;

function DrawText (font: IFont; text: ansistring; textAlignment: TTextAlignment; bounds: TRect; color: TColor): TVec2; overload;
function DrawText (font: IFont; text: ansistring; textAlignment: TTextAlignment; bounds: TRect): TVec2; overload;
procedure DrawText (font: IFont; text: ansistring; where: TVec2; color: TColor; scale: single = 1.0); overload;
procedure DrawText (font: IFont; text: ansistring; where: TVec2; scale: single = 1.0); overload;

{$endif}

{$ifdef IMPLEMENTATION}

function SplitString (text: ansistring; chars: integer; var count: integer): TStringList;
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
	count := ExtractStrings([LineEnding], [], p, result);
	
	StrDispose(p);
end;

function RestoreText (text: ansistring): ansistring;
begin
	text := StringReplace(text, '#39', #39, [rfReplaceAll]);
	text := StringReplace(text, '#34', #34, [rfReplaceAll]);
	//text := StringReplace(text, '#13', #13, [rfReplaceAll]);
	result := text;
end;

function CalculateTextWidth (font: IFont; text: ansistring): integer;
var
	c: char;
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

function WrapTextInternal (font: IFont; text: ansistring; max: single; var actualSize: TVec2): TStringList;
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

function WrapText (font: IFont; text: ansistring; maximumWidth: integer): TStringList;
var
	actualSize: TVec2;
begin
	result := WrapTextInternal(font, text, maximumWidth, actualSize);
end;

function MeasureText (font: IFont; text: ansistring; maximumWidth: integer = MaxInt): TVec2;
begin		
	WrapTextInternal(font, text, maximumWidth, result);
end;

function DrawText (text: ansistring; textAlignment: TTextAlignment; bounds: TRect; color: TColor): TVec2;
begin
	DrawText(GLCanvasState.activeFont, text, textAlignment, bounds, color);
end;

function DrawText (text: ansistring; textAlignment: TTextAlignment; bounds: TRect): TVec2;
begin
	DrawText(GLCanvasState.activeFont, text, textAlignment, bounds, 1);	
end;

procedure DrawText (text: ansistring; where: TVec2; color: TColor; scale: single = 1.0);
begin
	DrawText(GLCanvasState.activeFont, text, where, color, scale);
end;

procedure DrawText (text: ansistring; where: TVec2; scale: single = 1.0);
begin
	DrawText(GLCanvasState.activeFont, text, where, 1, scale);
end;

function DrawText (font: IFont; text: ansistring; textAlignment: TTextAlignment; bounds: TRect; color: TColor): TVec2;
var
	line: ansistring;
	lines: TStringList;
	where: TVec2;
begin
	Assert(font <> nil, 'font must not be nil');

	if text = '' then
		exit(V2(0, 0));
		
	where := bounds.origin;
	lines := WrapTextInternal(font, text, Trunc(bounds.width), result);
	for line in lines do
		begin
			case textAlignment of
				kAlignmentCenter:				
					where.x := bounds.MidX - (MeasureText(font, line, maxInt).width / 2);
				otherwise
					;
			end;
			DrawText(font, line, where, color);
			where.y += font.LineHeight;
		end;
end;

function DrawText (font: IFont; text: ansistring; textAlignment: TTextAlignment; bounds: TRect): TVec2;
begin
	result := DrawText(font, text, textAlignment, bounds, 1);
end;

procedure DrawText (font: IFont; text: ansistring; where: TVec2; color: TColor; scale: single = 1.0);
var
	c: char;
	renderFrame: TFontRenderFrame;
	newOrigin: TVec2;
	origin: TVec2;
begin
	Assert(font <> nil, 'font must not be nil');

	if text = '' then
		exit;
		
	origin := where;

	for c in text do
		begin
			if not font.HasGlyph(c) then
				begin
					if c = #32 then
						origin.x += font.SpaceWidth
					else if c = #9 then
						origin.x += font.SpaceWidth * font.TabWidth
					else
						origin.x += font.SpaceWidth;

					continue;
				end;

			renderFrame := font.CharacterRenderFrame(c);

			newOrigin.x := origin.x + renderFrame.bearing.x;
			newOrigin.y := origin.y + renderFrame.bearing.y;
			DrawTexture(font, RectMake(newOrigin, renderFrame.faceSize) * scale, renderFrame.textureFrame, color);
			//FillRect(RectMake(newOrigin, renderFrame.faceSize) * scale, RGBA(1, 0, 0, 0.2));

			origin.x += {renderFrame.faceSize.width +} renderFrame.advance;
		end;
end;

procedure DrawText (font: IFont; text: ansistring; where: TVec2; scale: single = 1.0);
begin
	DrawText(font, text, where, 1, scale);
end;

{$endif}
