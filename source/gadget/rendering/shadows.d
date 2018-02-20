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
import gadget.rendering.uniforms;
import gadget.rendering.mesh;

struct DepthMap {
	uint fbo;
	uint width;
	uint height;
	uint texture;
}

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

	world.setBaseUniforms(depthShader);
	depthShader.setLightVPUniform(world.dirLight);
	//depthShader.setPointLightShadowUniforms(world.pointLights[0], depthMap);

	// Render scene
	foreach (obj; world.objects) {
		obj.draw(depthShader);
	}
}

