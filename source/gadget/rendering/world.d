module gadget.rendering.world;

import std.stdio : stderr;
import std.string;
import std.algorithm;
import derelict.sfml2.window;
import derelict.opengl;
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

void drawWorld(World world, in Camera camera, in Shader shader = null) {
	foreach (obj; world.objects) {
		world.setUniforms(obj);
		if (shader !is null)
			obj.draw(camera, shader);
		else
			obj.draw(camera, obj.shader);
	}
}

private void setUniforms(World world, Mesh obj) {
	obj.uniforms["ambientLight.color"] = world.ambientLight.color;
	obj.uniforms["ambientLight.strength"] = world.ambientLight.strength;
	obj.uniforms["dirLight.direction"] = world.dirLight.direction;
	obj.uniforms["dirLight.diffuse"] = world.dirLight.diffuse;
	obj.uniforms["nPointLights"] = cast(GLuint)world.pointLights.length;
	foreach (i, pl; world.pointLights) {
		obj.uniforms["pointLight[%d].position".format(i)] = pl.position;
		obj.uniforms["pointLight[%d].diffuse".format(i)] = pl.diffuse;
		obj.uniforms["pointLight[%d].attenuation".format(i)] = pl.attenuation;
	}
}
