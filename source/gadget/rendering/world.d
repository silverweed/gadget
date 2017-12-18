module gadget.rendering.world;

import std.stdio : stderr;
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

void drawWorld(World world, in Camera camera, Shader shader = null) {
	foreach (obj; world.objects) {
		if (shader !is null) {
			world.setUniforms(shader);
			obj.draw(camera, shader);
		} else {
			world.setUniforms(obj.shader);
			obj.draw(camera, obj.shader);
		}
	}
}

private void setUniforms(World world, Shader shader) {
	shader.uniforms["ambientLight.color"] = world.ambientLight.color;
	shader.uniforms["ambientLight.strength"] = world.ambientLight.strength;
	shader.uniforms["dirLight.direction"] = world.dirLight.direction;
	shader.uniforms["dirLight.diffuse"] = world.dirLight.diffuse;
	shader.uniforms["nPointLights"] = cast(GLint)world.pointLights.length;
	foreach (i, pl; world.pointLights) {
		shader.uniforms["pointLight[%d].position".format(i)] = pl.position;
		shader.uniforms["pointLight[%d].diffuse".format(i)] = pl.diffuse;
		shader.uniforms["pointLight[%d].attenuation".format(i)] = pl.attenuation;
	}
	// Shadows (TODO)
	const lightPos = world.pointLights[0].position;
	//const lightPos = vec3(-4, 4, -1);
	const lightProj = mat4.orthographic(-10f, 10f, -10f, 10f, 1, 17.5);
	const lightView = mat4.look_at(lightPos, vec3(0, 0, 0), vec3(0, 1, 0));
	shader.uniforms["lightVP"] = lightProj * lightView;
}
