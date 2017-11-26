#version 330 core

layout (points) in;
layout (triangle_strip, max_vertices = 12) out;

uniform float radius;
uniform vec3 color;

out vec4 vColor;

void main() {
	// 1
	vec4 center = gl_in[0].gl_Position;
	vColor = vec4(color, 1.0);
	gl_Position = center;
	EmitVertex();
	// 2
	vColor = vec4(0.0, 0.0, 0.0, 0.0);
	gl_Position = center + vec4(radius, -radius, 0.0, 0.0);
	EmitVertex();
	// 3
	gl_Position = center + vec4(-radius, -radius, 0.0, 0.0);
	EmitVertex();
	EndPrimitive();

	// 1
	vColor = vec4(color, 1.0);
	gl_Position = center;
	EmitVertex();
	// 2
	vColor = vec4(0.0, 0.0, 0.0, 0.0);
	gl_Position = center + vec4(-radius, -radius, 0.0, 0.0);
	EmitVertex();
	// 3
	gl_Position = center + vec4(-radius, radius, 0.0, 0.0);
	EmitVertex();
	EndPrimitive();

	// 1
	vColor = vec4(color, 1.0);
	gl_Position = center;
	EmitVertex();
	// 2
	vColor = vec4(0.0, 0.0, 0.0, 0.0);
	gl_Position = center + vec4(-radius, radius, 0.0, 0.0);
	EmitVertex();
	// 3
	gl_Position = center + vec4(radius, radius, 0.0, 0.0);
	EmitVertex();
	EndPrimitive();

	// 1
	vColor = vec4(color, 1.0);
	gl_Position = center;
	EmitVertex();
	// 2
	vColor = vec4(0.0, 0.0, 0.0, 0.0);
	gl_Position = center + vec4(radius, radius, 0.0, 0.0);
	EmitVertex();
	// 3
	gl_Position = center + vec4(radius, -radius, 0.0, 0.0);
	EmitVertex();
	EndPrimitive();
}
