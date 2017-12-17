module gadget.rendering.shadows;

import derelict.opengl;
import gl3n.linalg;
import gadget.rendering.world;
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

enum vs_simpleDepth = q{
	#version 330 core

	layout (location = 0) in vec3 aPos;
	layout (location = 1) in mat4 aInstanceModel;
	// (location = 2) aInstanceModel
	// (location = 3) aInstanceModel
	// (location = 4) aInstanceModel

	uniform mat4 lightVP;

	void main() {
		gl_Position = lightVP * aInstanceModel * vec4(aPos, 1.0);
	}
};

enum fs_simpleDepth = q{
	#version 330 core

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
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

	// Attach the FB to the texture
	glBindFramebuffer(GL_FRAMEBUFFER, depthMapFbo);
	scope (exit) glBindFramebuffer(GL_FRAMEBUFFER, 0);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, depthMapTex, 0);
	glDrawBuffer(GL_NONE);
	glReadBuffer(GL_NONE);
	// Check complete status
	assert(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE);
		
	return DepthMap(depthMapFbo, width, height, depthMapTex);
}

void renderToDepthMap(World world, Camera camera, DepthMap depthMap) {
	glViewport(0, 0, depthMap.width, depthMap.height);
	glBindFramebuffer(GL_FRAMEBUFFER, depthMap.fbo);
	glClear(GL_DEPTH_BUFFER_BIT);
	
	auto lightPos = world.pointLights[0].position;
	//auto lightProj = mat4.orthographic(-10f, 10f, -10f, 10f, 0.01, 5000);
	auto lightProj = mat4.perspective(-10f, 10f, -10f, 10f, camera.near, camera.far);
	auto lightView = mat4.look_at(lightPos, vec3(0, 0, 0), vec3(0, 1, 0));
	const depthShader = presetShaders["simpleDepth"];
	depthShader.use();
	depthShader.setMat4("lightVP", lightProj * lightView);

	// Render scene
	world.draw(camera, depthShader);

	glBindFramebuffer(GL_FRAMEBUFFER, 0);
}
