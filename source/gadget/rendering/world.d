module gadget.rendering.world;

import std.stdio;
import std.string;
import std.algorithm;
import derelict.sfml2.window;
import derelict.opengl;
import gl3n.linalg;
import gadget.rendering.gl;
import gadget.rendering.material;
import gadget.rendering.texture;
import gadget.rendering.rendertexture;
import gadget.rendering.presets;
import gadget.rendering.shapes;
import gadget.rendering.camera;
import gadget.rendering.shader;
import gadget.rendering.renderstate;
import gadget.rendering.mesh;
import gadget.rendering.shadows;
import gadget.rendering.uniforms;

class World {
	Skybox skybox;

	/// Objects
	Mesh[] objects;

	/// Lights
	DirLight dirLight;
	AmbientLight ambientLight;
	PointLight[] pointLights;

	DepthMap[] depthMaps;

	RenderTexture renderTex;
	bool ppEnabled = false;
}

void drawWorld(World world) {
	bool[Shader] processedShaders;

	// Draw the objects
	foreach (obj; world.objects) {
		Shader sh = obj.shader;

		// Set uniforms
		if (sh !in processedShaders) {
			world.setUniforms(sh);
			setLightVPUniform(sh, world.dirLight);
			processedShaders[sh] = true;
		}

		obj.draw(sh);
	}

	// Draw the skybox
	if (world.skybox.shader !is null) {
		world.skybox.drawSkybox();
	}
}

void enableShadows(World world, uint width, uint height) {
	assert(world.depthMaps.length == 0, "Enabled shadows on world but world already had depth maps!");

	// Dirlight depth map
	auto depthMap = genDepthMap(width, height);
	world.depthMaps ~= depthMap;
	// Pointlight
	auto cubeDepthMap = genDepthCubeMap(4096, 4096);
	world.depthMaps ~= cubeDepthMap;
}

void renderDepthMaps(World world) {
	assert(world.depthMaps.length > 0, "Tried to render depth maps on world without shadows enabled!");

	world.renderLightDepthMap(world.depthMaps);
}

void enablePostProcessing(World world) {
	assert(!world.ppEnabled, "Enabled PP on world but world already has render texture!");

	world.renderTex = genRenderTexture(RenderState.global.screenSize.x, RenderState.global.screenSize.y, 2);
	world.ppEnabled = true;

	auto screenQuadShader = presetShaders["screenQuad"];
	screenQuadShader.use();
	screenQuadShader.uniforms["screenTex"] = 0;
}

// Renders the world from `camera`'s point of view to the internal render texture.
void renderToInternalTex(World world, in Camera camera) {
	assert(world.ppEnabled, "Rendering to internal on world but world already has no render texture!");
	world.render(camera, world.renderTex.fbo);
}

// Draws the internal render texture quad to the screen
void renderQuad(World world, uint target = 0) {
	mixin(DEFER_REBIND_CUR_FBO);

	glViewport(0, 0, RenderState.global.screenSize.x, RenderState.global.screenSize.y);
	glBindFramebuffer(GL_FRAMEBUFFER, target);

	glClearColor(1, 1, 1, 1);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	auto screenQuadShader = presetShaders["screenQuad"];
	screenQuadShader.use();
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, world.renderTex.colorBufs[0]);
	debug screenQuadShader.assertAllUniformsDefined();
	screenQuadShader.applyUniforms();
	drawElements(world.renderTex.quadVao, screenQuadIndices.length);
}

void render(World world, in Camera camera, uint target = 0) {
	mixin(DEFER_REBIND_CUR_FBO);

	glViewport(0, 0, RenderState.global.screenSize.x, RenderState.global.screenSize.y);
	glBindFramebuffer(GL_FRAMEBUFFER, target);

	const clCol = RenderState.global.clearColor;
	glClearColor(clCol.r, clCol.g, clCol.b, clCol.a);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	glEnable(GL_DEPTH_TEST);

	// Bind all textures
	if (world.depthMaps.length > 0) {
		// Depth map for directional light
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, world.depthMaps[0].texture);
		glActiveTexture(GL_TEXTURE1);
		glBindTexture(GL_TEXTURE_CUBE_MAP, world.depthMaps[1].texture);
	}

	world.setCamera(camera);
	world.drawWorld();
}

struct Skybox {
	Shader shader;
	uint cubeVao;
	uint cubemapVao;
}

void loadSkybox(World world, string[] textures) {
	// TODO unload current skybox
	assert(world.skybox.shader is null, "Skybox already loaded!");

	world.skybox = Skybox(
		presetShaders["skybox"],
		genCube(),
		genCubemap(textures)
	);
	world.skybox.shader.uniforms["skybox"] = 0;
}

void drawSkybox(in Skybox skybox) {
	int depthMode;
	glGetIntegerv(GL_DEPTH_FUNC, &depthMode);
	glDepthFunc(GL_LEQUAL);
	auto sh = skybox.shader;
	sh.use();
	sh.applyUniforms();
	glBindVertexArray(skybox.cubeVao);
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_CUBE_MAP, skybox.cubemapVao);
	drawElements(skybox.cubeVao, cubeIndices.length);
	glDepthFunc(depthMode);
}
