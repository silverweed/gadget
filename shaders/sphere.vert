#version 330 core

layout (location = 0) in vec3 aPos;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform float radius;

out VS_OUT {
	vec4 worldCoords;
} vs_out;

void main() {
	vec4 wc = model * vec4(aPos, 1.0);
	vs_out.worldCoords = wc;
	gl_Position = projection * view * wc;
}
