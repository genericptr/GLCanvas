{$mode objfpc}
{$assertions on}

program Test7;
uses
  // rtl
  CThreads, VectorMath,
  GLCanvas, GLShader, GLPT;

{$define API_OPENGL}

var
  VertexShader: pchar =       '#version 330 core'#10+
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

  FragmentShader: pchar =     '#version 330 core'+#10+
                              'uniform sampler2D textures[8];'+
                              'out vec4 fragColor;'+
                              'in vec2 vertexTexCoord;'+
                              'in vec4 vertexColor;'+
                              'in float vertexUV;'+
                              'void main() {'+
                              '  int fragUV = int(vertexUV);'+
                              '  if (fragUV < 8) {'+
                              '    fragColor = texture(textures[fragUV], vertexTexCoord.st);'+
                              '    if (vertexColor.a < fragColor.a) {'+
                              '      fragColor.a = vertexColor.a;'+
                              '    }'+
                              '  fragColor.rgb = fragColor.rgb * vertexColor.rgb;'+
                              // make it all red!
                              '  fragColor.r = 1;'+
                              '  } else {'+
                              '    fragColor = vertexColor;'+
                              '  }'+
                              '}'#0;

const
  window_size_width = 512;
  window_size_height = 512;

var
  texture: TTexture;
  shader: TShader;
begin
  SetupCanvas(window_size_width, window_size_height);

  Chdir(GLPT_GetBasePath+'/tests');

  texture := CreateTexture('deer.png');

  shader := CreateShader(VertexShader, FragmentShader);
  shader.Push;

  while IsRunning do
    begin
      ClearBackground;
      DrawTexture(texture, 100, 100);
      SwapBuffers;
    end;

  QuitApp;
end.