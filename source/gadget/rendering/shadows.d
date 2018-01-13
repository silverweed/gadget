module gadget.rendering.shadows;

import std.string;
import derelict.opengl;
import gl3n.linalg;
import gl3n.math;
import gadget.rendering.world;
import gadget.rendering.gl;
import gadget.rendering.utils;
import gadget.rendering.camera;
import gadget.rendering.shader;
import gadget.rendering.presets;
import gadget.rendering.material;
import gadget.rendering.mesh;

struct DepthMap {
	uint fbo;
	uint width;
	uint height;
	uint texture;
}

// Transform the vertex into light's view space
enum vs_simpleDepthInstanced = MATERIAL_HEADER ~ q{

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
enum fs_simpleDepth = MATERIAL_HEADER ~ q{

	void main() { /* gl_FragDepth = gl_FragCoord.z; */ }
};

enum vs_cubemapDepthInstanced = MATERIAL_HEADER ~ q{

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

enum gs_cubemapDepth = MATERIAL_HEADER ~ q{

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

enum fs_cubemapDepth = MATERIAL_HEADER ~ q{

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

auto genDepthMap(uint width, uint height) {
	// Create 2D texture to store depth information
	uint depthMapTex;
	glGenTextures(1, &depthMapTex);
	glBindTexture(GL_TEXTURE_2D, depthMapTex);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT, width, height, 0,
			GL_DEPTH_COMPONENT, GL_FLOAT, NULL);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
	immutable borderColor = [ 1.0f, 1.0f, 1.0f, 1.0f ];
	glTexParameterfv(GL_TEXTURE_2D, GL_TEXTURE_BORDER_COLOR, borderColor.ptr);

	// Create the framebuffer
	uint depthMapFbo;
	glGenFramebuffers(1, &depthMapFbo);

	// Attach the FB to the texture
	mixin(DEFER_REBIND_CUR_FBO);
	glBindFramebuffer(GL_FRAMEBUFFER, depthMapFbo);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, depthMapTex, 0);
	glDrawBuffer(GL_NONE);
	glReadBuffer(GL_NONE);
	checkFramebuffer();

	return DepthMap(depthMapFbo, width, height, depthMapTex);
}

/// WARNING: if width and height values are too big, an 'unsupported' framebuffer may result!
auto genDepthCubeMap(uint width, uint height) {
	// Create framebuffer object
	uint depthMapFbo;
	glGenFramebuffers(1, &depthMapFbo);

	// Create cubemap
	uint depthMapTex;
	glGenTextures(1, &depthMapTex);

	glBindTexture(GL_TEXTURE_CUBE_MAP, depthMapTex);
	for (uint i = 0; i < 6; ++i)
		glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, GL_DEPTH_COMPONENT,
				width, height, 0, GL_DEPTH_COMPONENT, GL_FLOAT, NULL);

	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);

	mixin(DEFER_REBIND_CUR_FBO);
	glBindFramebuffer(GL_FRAMEBUFFER, depthMapFbo);
	glFramebufferTexture(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, depthMapTex, 0);
	debug checkGLError();
	glDrawBuffer(GL_NONE);
	glReadBuffer(GL_NONE);
	checkFramebuffer(); // XXX

	return DepthMap(depthMapFbo, width, height, depthMapTex);
}

void renderLightDepthMap(World world, DepthMap[] depthMaps) {
	mixin(DEFER_REBIND_CUR_FBO);

	auto depthMap = depthMaps[0];

	glViewport(0, 0, depthMap.width, depthMap.height);
	glBindFramebuffer(GL_FRAMEBUFFER, depthMap.fbo);
	glClear(GL_DEPTH_BUFFER_BIT);

	auto depthShader = presetShaders["simpleDepth"];
	//auto depthShader = presetShaders["cubemapDepth"];

	world.setUniforms(depthShader);
	depthShader.setLightUniforms(world.dirLight);
	//depthShader.setLightUniforms(world.pointLights[0], depthMap);

	// Render scene
	foreach (obj; world.objects) {
		obj.draw(depthShader);
	}
}

void setLightUniforms(Shader shader, DirLight light) {
	// XXX: These values are blindly guessed
	enum near = 1.0;
	enum far = 30.0;
	enum w = 50;
	enum h = 50;

	const lightProj = mat4.orthographic(-w, w, -h, h, near, far);
	//const lightProj = mat4.perspective(-w, w, -h, h, near, far);
	const lightView = mat4.look_at(-14 * light.direction, vec3(0, 0, 0), vec3(0, 1, 0));

	shader.uniforms["lightVP"] = lightProj * lightView;
}

void setLightUniforms(Shader shader, PointLight light, DepthMap depthMap) {
	enum near = 0.5;
	enum far = 25.0;
	enum w = 50;
	enum h = 50;

	const lightProj = mat4.perspective(w, h, radians(90), near, far);
	const shadowTransforms = [
		lightProj * mat4.look_at(light.position, light.position + vec3(1, 0, 0), vec3(0, -1, 0)),
		lightProj * mat4.look_at(light.position, light.position + vec3(-1, 0, 0), vec3(0, -1, 0)),
		lightProj * mat4.look_at(light.position, light.position + vec3(0, 1, 0), vec3(0, 0, 1)),
		lightProj * mat4.look_at(light.position, light.position + vec3(0, -1, 0), vec3(0, 0, -1)),
		lightProj * mat4.look_at(light.position, light.position + vec3(0, 0, 1), vec3(0, -1, 0)),
		lightProj * mat4.look_at(light.position, light.position + vec3(0, 0, -1), vec3(0, -1, 0)),
	];

	for (int i = 0; i < 6; ++i)
		shader.uniforms["shadowTransforms[%d]".format(i)] = shadowTransforms[i];
	shader.uniforms["lightPos"] = light.position;
	shader.uniforms["far"] = far;
}
