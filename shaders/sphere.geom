#version 330 core

layout (points) in;
layout (triangle_strip, max_vertices = 4) out;

in VS_OUT {
	vec4 worldCoords;
} vs_out[];

uniform float radius;
uniform mat4 view;
uniform mat4 projection;

void main() {
	vec4 center = gl_in[0].gl_Position;
	gl_Position = center + vec4(-radius, -radius, 0.0, 0.0);
	EmitVertex();
	gl_Position = center + vec4(-radius, radius, 0.0, 0.0);
	EmitVertex();
	gl_Position = center + vec4(radius, -radius, 0.0, 0.0);
	EmitVertex();
	gl_Position = center + vec4(radius, radius, 0.0, 0.0);
	EmitVertex();
	EndPrimitive();
}
