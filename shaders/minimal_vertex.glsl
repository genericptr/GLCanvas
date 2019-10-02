#version 150

in vec2 inPosition;   
in vec2 inTexCoord;
// in vec4 inColor;
// in float inUVMap;

out vec2 outTexCoord;
// out vec4 vertexColor;
// out float vertexUVMap;

uniform mat4 fullTransform;

void main()
{
	gl_Position = fullTransform * vec4(inPosition, 0, 1); 
	outTexCoord = inTexCoord;
	// vertexUVMap = inUVMap;
	// vertexColor = inColor;
}