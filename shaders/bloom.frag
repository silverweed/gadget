#version 330 core

out vec4 fragColor;

in vec2 texCoords;

uniform sampler2D scene;
uniform sampler2D bloomBlur;
uniform bool bloom;

void main() {
	const float gamma = 2.2;
	vec3 hdrColor = texture(scene, texCoords).rgb;
	vec3 bloomColor = texture(bloomBlur, texCoords).rgb;

	if (bloom)
		hdrColor += bloomColor; // additive blending

	const float exposure = 0.4;
	vec3 result = vec3(1.0) - exp(-hdrColor * exposure);

	// also gamma correct while we're at it
	result = pow(result, vec3(1.0 / gamma));
	fragColor = vec4(result, 1.0);
}
