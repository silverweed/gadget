#version 330 core

in vec4 center;

out vec4 fragColor;

uniform vec3 color;
uniform float radius;

in vec4 vColor;

void main() {
	fragColor = vColor;
}
