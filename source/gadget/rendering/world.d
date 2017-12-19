module gadget.rendering.world;

import std.stdio;
import std.string;
import std.algorithm;
import derelict.sfml2.window;
import derelict.opengl;
import gl3n.linalg;
import gadget.rendering.material;
import gadget.rendering.camera;
import gadget.rendering.shader;
import gadget.rendering.renderstate;
import gadget.rendering.mesh;

class World {
	/// Objects
	Mesh[] objects;

	/// Lights
	DirLight dirLight;
	AmbientLight ambientLight;
	PointLight[] pointLights;
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
	// XXX: Near and far values are blindly guessed
	enum near = 1;
	enum far = 20;

	const lightProj = mat4.orthographic(-10f, 10f, -10f, 10f, near, far);
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
