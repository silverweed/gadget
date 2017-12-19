module gadget.rendering.world;

import std.stdio;
import std.string;
import std.algorithm;
import derelict.sfml2.window;
import derelict.opengl;
import gl3n.linalg;
import gadget.rendering.gl;
import gadget.rendering.material;
import gadget.rendering.camera;
import gadget.rendering.shader;
import gadget.rendering.renderstate;
import gadget.rendering.mesh;
import gadget.rendering.shadows;

class World {
	/// Objects
	Mesh[] objects;

	/// Lights
	DirLight dirLight;
	AmbientLight ambientLight;
	PointLight[] pointLights;

	DepthMap[] depthMaps;
}

void drawWorld(World world, Shader shader = null) {
	bool[Shader] processedShaders;

	foreach (obj; world.objects) {
		Shader sh = (shader is null) ? obj.shader : shader;
	
		// Set uniforms
		if (sh !in processedShaders) {
			world.setUniforms(sh);
			world.setLightUniforms(sh, world.dirLight);
			processedShaders[sh] = true;
		}

		obj.draw(sh);
	}
}

void setCamera(World world, in Camera camera, Shader shader = null) {
	foreach (obj; world.objects) {
		obj.setCameraUniforms((shader is null) ? obj.shader : shader, camera);
	}
}

void setLightUniforms(World world, Shader shader, DirLight light) {
	// XXX: These values are blindly guessed
	enum near = 3;
	enum far = 30;
	enum w = 50;
	enum h = 50;

	const lightProj = mat4.orthographic(-w, w, -h, h, near, far);
	//const lightProj = mat4.perspective(-w, w, -h, h, near, far);
	const lightView = mat4.look_at(-light.direction, vec3(0, 0, 0), vec3(0, 1, 0));

	shader.uniforms["lightVP"] = lightProj * lightView;
}

private void setUniforms(World world, Shader shader) {
	shader.uniforms["ambientLight.color"] = world.ambientLight.color;
	shader.uniforms["ambientLight.strength"] = world.ambientLight.strength;
	shader.uniforms["dirLight.direction"] = world.dirLight.direction;
	shader.uniforms["dirLight.diffuse"] = world.dirLight.diffuse;
	shader.uniforms["nPointLights"] = cast(GLuint)world.pointLights.length;
	foreach (i, pl; world.pointLights) {
		shader.uniforms["pointLight[%d].position".format(i)] = pl.position;
		shader.uniforms["pointLight[%d].diffuse".format(i)] = pl.diffuse;
		shader.uniforms["pointLight[%d].attenuation".format(i)] = pl.attenuation;
	}
}

void enableShadows(World world, uint width, uint height) {
	assert(world.depthMaps.length == 0, "Enabled shadows on world but world already had depth maps!");

	// For now we only do shadows for the dir light
	auto depthMap = genDepthMap(width, height);
	world.depthMaps ~= depthMap;
}

void renderDepthMaps(World world) {
	assert(world.depthMaps.length > 0, "Tried to render depth maps on world without shadows enabled!");
	
	world.renderLightDepthMap(world.dirLight, world.depthMaps[0]);
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
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, world.depthMaps[0].texture);

	world.setCamera(camera);
	world.drawWorld();
}
