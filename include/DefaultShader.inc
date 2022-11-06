
{$ifdef INTERFACE}

{ Types }

type
  TDefaultVertex = record
    pos: TVec2;
    texCoord: TVec2;
    color: TVec4;
    uv: byte;
    constructor Create(inPos: TVec2; inTexCoord: TVec2; inColor: TVec4; inUV: byte);
    class operator = (constref a, b: TDefaultVertex): boolean;
    function Compare(constref right: TDefaultVertex): integer;
  end;

type
  generic TTexturedQuad<T> = record
    v: array[0..5] of T;
    procedure SetPosition(minX, minY, maxX, maxY: single); inline;
    procedure SetPosition(constref rect: TRect); inline;
    procedure SetSize(constref size: TVec2); inline;
    procedure SetOrigin(constref origin: TVec2); inline;
    procedure SetColor(r, g, b, a: single); inline;
    procedure SetColor(color: TColor); inline;
    procedure SetTexture(rect: TRect); inline;
    procedure SetUV(id: byte); inline;
    procedure Transform(constref mat: TMat4); inline;
  end;

type
  TDefaultVertexQuad = specialize TTexturedQuad<TDefaultVertex>;
  TDefaultVertexList = specialize TFPGList<TDefaultVertex>;
  TDefaultVertexBuffer = specialize TVertexBuffer<TDefaultVertex>;
  TDefaultVertexBufferList = specialize TFPGList<TDefaultVertexBuffer>;
  
{$endif}

{$ifdef IMPLEMENTATION}

constructor TDefaultVertex.Create(inPos: TVec2; inTexCoord: TVec2; inColor: TVec4; inUV: byte);
begin
  pos := inPos;
  texCoord := inTexCoord;
  color := inColor;
  uv := inUV;
end;

function TDefaultVertex.Compare(constref right: TDefaultVertex): integer;
begin
  result := 0;
end;

class operator TDefaultVertex.= (constref a, b: TDefaultVertex): boolean;
begin
  result := true;
end;

{ Quads }

procedure TTexturedQuad.Transform(constref mat: TMat4); 
begin
  v[0].pos := mat * v[0].pos;
  v[1].pos := mat * v[1].pos;
  v[2].pos := mat * v[2].pos;
  v[3].pos := mat * v[3].pos;
  v[4].pos := mat * v[4].pos;
  v[5].pos := mat * v[5].pos;
end;

procedure TTexturedQuad.SetSize(constref size: TVec2);
begin
  v[1].pos.x := v[0].pos.x + size.width;
  v[2].pos.y := v[0].pos.y + size.height;
  v[3].pos.y := v[0].pos.y + size.height;
  v[4].pos.x := v[0].pos.x + size.width;
  v[4].pos.y := v[0].pos.y + size.height;
  v[5].pos.x := v[0].pos.x + size.width;
end;

procedure TTexturedQuad.SetOrigin(constref origin: TVec2);
begin
  v[0].pos.x := origin.x;
  v[0].pos.y := origin.y;
  v[1].pos.y := origin.y; 
  v[2].pos.x := origin.x;
  v[3].pos.x := origin.x;
  v[5].pos.y := origin.y; 
end;

procedure TTexturedQuad.SetPosition(constref rect: TRect);
begin
  v[0].pos.x := rect.MinX;
  v[0].pos.y := rect.MinY;
  v[1].pos.x := rect.MaxX;
  v[1].pos.y := rect.MinY; 
  v[2].pos.x := rect.MinX;
  v[2].pos.y := rect.MaxY; 
  v[3].pos.x := rect.MinX;
  v[3].pos.y := rect.MaxY; 
  v[4].pos.x := rect.MaxX;
  v[4].pos.y := rect.MaxY; 
  v[5].pos.x := rect.MaxX;
  v[5].pos.y := rect.MinY; 
end;

procedure TTexturedQuad.SetPosition(minX, minY, maxX, maxY: single);
begin
  v[0].pos.x := minX;
  v[0].pos.y := minY;
  v[1].pos.x := maxX;
  v[1].pos.y := minY;
  v[2].pos.x := minX;
  v[2].pos.y := maxY;
  v[3].pos.x := minX;
  v[3].pos.y := maxY;
  v[4].pos.x := maxX;
  v[4].pos.y := maxY;
  v[5].pos.x := maxX;
  v[5].pos.y := minY;
end;

procedure TTexturedQuad.SetColor(color: TColor);
begin
  v[0].color := color;
  v[1].color := color;
  v[2].color := color;
  v[3].color := color;
  v[4].color := color;
  v[5].color := color;
end;

procedure TTexturedQuad.SetColor(r, g, b, a: single);
var
  color: TColor;
begin
  color := RGBA(r, g, b, a);
  v[0].color := color;
  v[1].color := color;
  v[2].color := color;
  v[3].color := color;
  v[4].color := color;
  v[5].color := color;
end;

procedure TTexturedQuad.SetTexture(rect: TRect);
begin
  v[0].texCoord.x := rect.MinX;
  v[0].texCoord.y := rect.MinY;
  v[1].texCoord.x := rect.MaxX;
  v[1].texCoord.y := rect.MinY; 
  v[2].texCoord.x := rect.MinX;
  v[2].texCoord.y := rect.MaxY; 
  v[3].texCoord.x := rect.MinX;
  v[3].texCoord.y := rect.MaxY; 
  v[4].texCoord.x := rect.MaxX;
  v[4].texCoord.y := rect.MaxY; 
  v[5].texCoord.x := rect.MaxX;
  v[5].texCoord.y := rect.MinY; 
end;

procedure TTexturedQuad.SetUV(id: byte);
begin
  v[0].uv := id;
  v[1].uv := id;
  v[2].uv := id;
  v[3].uv := id;
  v[4].uv := id;
  v[5].uv := id;
end;

var
    DefaultVertexShader: pchar = 
                                {$ifdef API_OPENGL}
                                '#version 330 core'#10+
                                {$endif}
                                {$ifdef API_OPENGLES}
                                '#version 300 es'#10+
                                {$endif}
                                'layout (location=0) in vec2 position;'+
                                'layout (location=1) in vec2 inTexCoord;'+
                                'layout (location=2) in vec4 inColor;'+
                                'layout (location=3) in float inUV;'+
                                'out vec2 vertexTexCoord;'+
                                'out vec4 vertexColor;'+
                                'out float vertexUV;'+
                                'uniform mat4 projTransform;'+
                                'uniform mat4 viewTransform;'+
                                'void main() {'+
                                '  gl_Position = projTransform * viewTransform * vec4(position, 0.0, 1.0);'+
                                '  vertexTexCoord = inTexCoord;'+
                                '  vertexUV = inUV;'+
                                '  vertexColor = inColor;'+
                                '}'#0;

    DefaultFragmentShader: pchar =
                                {$ifdef API_OPENGL}
                                '#version 330 core'+#10+
                                {$endif}
                                {$ifdef API_OPENGLES}
                                '#version 300 es'+#10+
                                'precision mediump float;'+
                                {$endif}
                                'uniform sampler2D textures[8];'+
                                'out vec4 fragColor;'+
                                'in vec2 vertexTexCoord;'+
                                'in vec4 vertexColor;'+
                                'in float vertexUV;'+
                                'void main() {'+
                                '  int fragUV = int(vertexUV);'+
                                '  if (fragUV < 8) {'+
                                {$ifdef API_OPENGL}
                                '    fragColor = texture(textures[fragUV], vertexTexCoord.st);'+
                                {$endif}
                                {$ifdef API_OPENGLES}
                                '    if (fragUV == 0) { fragColor = texture(textures[0], vertexTexCoord.st); } else'+
                                '    if (fragUV == 1) { fragColor = texture(textures[1], vertexTexCoord.st); } else'+
                                '    if (fragUV == 2) { fragColor = texture(textures[2], vertexTexCoord.st); } else'+
                                '    if (fragUV == 3) { fragColor = texture(textures[3], vertexTexCoord.st); } else'+
                                '    if (fragUV == 4) { fragColor = texture(textures[4], vertexTexCoord.st); } else'+
                                '    if (fragUV == 5) { fragColor = texture(textures[5], vertexTexCoord.st); } else'+
                                '    if (fragUV == 6) { fragColor = texture(textures[6], vertexTexCoord.st); } else'+
                                '                       { fragColor = texture(textures[7], vertexTexCoord.st); }'+
                                {$endif}
                                '    if (vertexColor.a < fragColor.a) {'+
                                '      fragColor.a = vertexColor.a;'+
                                '    }'+
                                '  fragColor.rgb = fragColor.rgb * vertexColor.rgb;'+
                                '  } else {'+
                                '    fragColor = vertexColor;'+
                                '  }'+
                                '}'#0;

{$endif}