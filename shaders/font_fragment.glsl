#version 150

uniform sampler2D textures[8];
in vec2 vertexTexCoord;
in float vertexUVMap;
out vec4 fragColor;

void main()
{
	fragColor = texture(textures[int(vertexUVMap)], vertexTexCoord.st);
}