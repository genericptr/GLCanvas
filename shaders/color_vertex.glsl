#version 330 core
layout (location=0) in vec2 position;
layout (location=1) in vec3 in_color;

out vec3 vertex_color;
uniform mat4 projTransform;
uniform mat4 modelTransform;

void main()
{
	gl_Position = projTransform * modelTransform * vec4(position, 0.0, 1.0);
	vertex_color = in_color;
}
