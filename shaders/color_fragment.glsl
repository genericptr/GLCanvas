#version 330 core
out vec4 final_color;

in vec3 vertex_color;

void main()
{
		final_color = vec4(vertex_color, 1.0);
}
