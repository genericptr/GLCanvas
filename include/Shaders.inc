
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