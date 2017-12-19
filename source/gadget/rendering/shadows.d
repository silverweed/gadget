module gadget.rendering.shadows;

import derelict.opengl;
import gl3n.linalg;
import gadget.rendering.world;
import gadget.rendering.gl;
import gadget.rendering.utils;
import gadget.rendering.camera;
import gadget.rendering.shader;
import gadget.rendering.presets;
import gadget.rendering.material;

struct DepthMap {
	uint fbo;
	uint width;
	uint height;
	uint texture;
}

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

enum fs_simpleDepth = MATERIAL_HEADER ~ q{

	void main() {}
};

auto genDepthMap(uint width, uint height) {
	// Create the framebuffer
	uint depthMapFbo;
	glGenFramebuffers(1, &depthMapFbo);

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

	// Attach the FB to the texture
	mixin(DEFER_REBIND_CUR_FBO);
	glBindFramebuffer(GL_FRAMEBUFFER, depthMapFbo);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, depthMapTex, 0);
	glDrawBuffer(GL_NONE);
	glReadBuffer(GL_NONE);
	// Check complete status
	assert(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE);
		
	return DepthMap(depthMapFbo, width, height, depthMapTex);
}

void renderLightDepthMap(World world, DirLight light, DepthMap depthMap) {
	mixin(DEFER_REBIND_CUR_FBO);

	glViewport(0, 0, depthMap.width, depthMap.height);
	glBindFramebuffer(GL_FRAMEBUFFER, depthMap.fbo);
	glClear(GL_DEPTH_BUFFER_BIT);

	auto depthShader = presetShaders["simpleDepth"];

	// Render scene
	world.drawWorld(depthShader);
}
