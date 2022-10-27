{
    Copyright (c) 2022 by Ryan Joseph

    GLCanvas Test #21
    
    Test 3D shaders
}
{$mode objfpc}
{$modeswitch advancedrecords}
{$modeswitch arrayoperators}

program Test21;
uses
  SysUtils, FGL, Math,
  GeometryTypes, VectorMath,
  GLVertexBuffer, GLShader, GLCanvas;

const
  kGridSize = 20;
  kTileSize = 64 / 2;
  kGridDepth = kTileSize * 5; // used for aligning the top
  kWindowSize = 600;
  kSqrt2 = 1.4142135624;

var
  VertexShader: pchar = 
                      '#version 330 core'#10+
                      'layout (location=0) in vec3 position;'+
                      'layout (location=1) in vec2 inTexCoord;'+
                      'layout (location=2) in float inUV;'+
                      'out vec2 vertexTexCoord;'+
                      'out vec4 vertexColor;'+
                      'out float vertexUV;'+
                      'uniform mat4 projTransform;'+
                      'uniform mat4 viewTransform;'+
                      'void main() {'+
                      '  gl_Position = projTransform * viewTransform * vec4(position, 1.0);'+
                      '  vertexTexCoord = inTexCoord;'+
                      '  vertexUV = inUV;'+
                      '}'#0;

  FragmentShader: pchar =
                      '#version 330 core'+#10+
                      'uniform sampler2D textures[8];'+
                      'out vec4 fragColor;'+
                      'in vec2 vertexTexCoord;'+
                      'in float vertexUV;'+
                      'void main() {'+
                      '  int fragUV = int(vertexUV);'+
                      '  if (fragUV > 0) {'+
                      '    fragColor = texture(textures[fragUV], vertexTexCoord.st);'+
                      '  } else {'+
                      '    fragColor = vec4(0,0,0,1);'+
                      '  }'+
                      '}'#0;

var
  IsometricViewTransform: TMat4;

type
  TVertex = record
    pos: TVec3;
    texCoord: TVec2;
    uv: byte;
    constructor Create(inPos: TVec3);
    class operator = (left: TVertex; right: TVertex): boolean;
  end;
  TVertexArray = array of TVertex;

constructor TVertex.Create(inPos: TVec3);
begin
  pos := inPos;
  texCoord := 0;
  uv := 0;
end;

class operator TVertex.= (left: TVertex; right: TVertex): boolean;
begin
  result := CompareByte(left, right, sizeof(TVertex)) = 0;
end;

function MakeIsometricTransform(origin: TVec2; scale: Float = 1): TMat4;
begin
  // https://www.gamedev.net/forums/topic/711336-create-an-isometric-view-with-opengl-and-c/
  result := TMat4.Identity;
  result *= TMat4.Translate(origin.x, origin.y, 0);
  result *= TMat4.RotateX(DegToRad(60));
  result *= TMat4.RotateZ(DegToRad(45));
  // 64/1.17=54.7??
  result *= TMat4.Scale(kSqrt2, kSqrt2, kSqrt2 / 1.17);
  if scale <> 1 then
    result *= TMat4.Scale(scale);
end;

function CreateCube(worldPos: TVec3; dim, depth: single): TVertexArray;
var
  i: integer;
begin
  result := [
    // top
    TVertex.Create(V3(0, 0, depth)),
    TVertex.Create(V3(dim, 0, depth)),
    TVertex.Create(V3(0, dim, depth)),
    TVertex.Create(V3(0, dim, depth)),
    TVertex.Create(V3(dim, dim, depth)),
    TVertex.Create(V3(dim, 0, depth)),

    // front-right
    TVertex.Create(V3(dim, 0, 0)),
    TVertex.Create(V3(dim, 0, depth)),
    TVertex.Create(V3(dim, dim, 0)),
    TVertex.Create(V3(dim, dim, 0)),
    TVertex.Create(V3(dim, dim, depth)),
    TVertex.Create(V3(dim, 0, depth)),

    // front-left
    TVertex.Create(V3(0, dim, 0)),
    TVertex.Create(V3(dim, dim, 0)),
    TVertex.Create(V3(dim, dim, depth)),
    TVertex.Create(V3(dim, dim, depth)),
    TVertex.Create(V3(0, dim, depth)),
    TVertex.Create(V3(0, dim, 0))
  ];

  for i := 0 to high(result) do
    result[i].pos += worldPos;
end;

type
  TVertexBuffer = specialize TVertexBuffer<TVertex>;

function CreateVertexBuffer: TVertexBuffer;
begin
  result := TVertexBuffer.Create([TVertexAttribute.Create('position',   TVertexAttributeKind.GL_FLOAT, 3),
                                  TVertexAttribute.Create('inTexCoord', TVertexAttributeKind.GL_FLOAT, 2),
                                  TVertexAttribute.Create('inUV',       TVertexAttributeKind.GL_UNSIGNED_BYTE, 1)],
                                  true);
end;

var
  buffer: TVertexBuffer;
  shader: TShader;
  verticies: TVertexArray;
begin
  SetupCanvas(kWindowSize, kWindowSize, nil);

  IsometricViewTransform := MakeIsometricTransform(V2(kWindowSize / 2, kGridDepth));

  glEnable(GL_DEPTH_TEST);

  buffer := CreateVertexBuffer;

  verticies := CreateCube(V3(32*3, 32, 0), kTileSize, kTileSize);
  buffer.Add(verticies);

  shader := CreateShader(VertexShader, FragmentShader);
  shader.Push;
  shader.SetUniformMat4('viewTransform', IsometricViewTransform);
  shader.Pop;

  while IsRunning do
    begin
      glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

      shader.Push;
      buffer.Draw;
      shader.Pop;

      SwapBuffers;
    end;

  QuitApp;
end.