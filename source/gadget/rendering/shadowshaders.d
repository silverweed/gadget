module gadget.rendering.shadowshaders;

import gadget.rendering.material;

// Transform the vertex into light's view space
enum vs_simpleDepthInstanced = SHADER_HEADER ~ q{

	layout (location = 0) in vec3 aPos;
	// (location = 1) aNormal;
	// (location = 2) aTexCoords;
	layout (location = 3) in mat4 aInstanceModel;
	// (location = 4) aInstanceModel
	// (location = 5) aInstanceModel
	// (location = 6) aInstanceModel

	uniform mat4 lightVP;

	void main() {
		gl_Position = lightVP * aInstanceModel * vec4(aPos, 1.0);
	}
};

// Just fill the z-buffer with the depth info
enum fs_simpleDepth = SHADER_HEADER ~ q{

	void main() { /* gl_FragDepth = gl_FragCoord.z; */ }
};

enum vs_cubemapDepthInstanced = SHADER_HEADER ~ q{

	layout (location = 0) in vec3 aPos;
	// (location = 1) aNormal;
	// (location = 2) aTexCoords;
	layout (location = 3) in mat4 aInstanceModel;
	// (location = 4) aInstanceModel
	// (location = 5) aInstanceModel
	// (location = 6) aInstanceModel

	void main() {
		// Just transform to world space; geom shader will map them to light view space
		gl_Position = aInstanceModel * vec4(aPos, 1.0);
	}
};

enum gs_cubemapDepth = SHADER_HEADER ~ q{

	layout (triangles) in;
	layout (triangle_strip, max_vertices = 18) out;

	uniform mat4 shadowTransforms[6];

	out vec4 fragPos;

	void main() {
		for (int face = 0; face < 6; ++face) {
			gl_Layer = face; // redirect to proper cubemap face
			for (int i = 0; i < 3; ++i) {
				fragPos = gl_in[i].gl_Position;
				gl_Position = shadowTransforms[face] * fragPos;
				EmitVertex();
			}
			EndPrimitive();
		}
	}
};

enum fs_cubemapDepth = SHADER_HEADER ~ q{

	in vec4 fragPos;

	uniform vec3 lightPos;
	uniform float far;

	void main() {
		float lightDist = length(fragPos.xyz - lightPos);
		// map to [0, 1]
		lightDist = lightDist / far;
		gl_FragDepth = lightDist;
	}
};
