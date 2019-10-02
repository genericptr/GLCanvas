#version 150

uniform sampler2D textures[8];

in vec2 vertexTexCoord;
in vec4 vertexColor;
in float vertexUVMap;
out vec4 fragColor;

void main()
{
	if (vertexUVMap == 255) {
		fragColor = vertexColor;
	} else {
		fragColor = texture(textures[int(vertexUVMap)], vertexTexCoord.st);
		if (vertexColor.a < fragColor.a) {
			fragColor.a = vertexColor.a;
		}
	}
}