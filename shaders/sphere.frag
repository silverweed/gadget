#version 330 core

in vec4 center;

out vec4 fragColor;

uniform vec3 color;
uniform float radius;
uniform float scrWidth;
uniform float scrHeight;

void main() {
	vec2 ndcPos = vec2(gl_FragCoord.x / scrWidth, gl_FragCoord.y / scrHeight);
	fragColor = vec4(color, length(ndcPos - center.xy) * radius);
}
