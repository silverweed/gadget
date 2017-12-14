module gadget.rendering.world;

import std.stdio : stderr;
import std.string;
import std.algorithm;
import derelict.sfml2.window;
import derelict.opengl;
import gadget.rendering.interfaces;
import gadget.rendering.material;
import gadget.rendering.camera;
import gadget.rendering.shader;
import gadget.rendering.renderstate;
import gadget.rendering.mesh;

class World : Drawable {

	DirLight dirLight;
	AmbientLight ambientLight;

	this() {}

	void addObject(Mesh object) {
		objects ~= object;
	}

	void removeObject(Mesh object) {
		auto idx = objects.countUntil(object);
		if (idx >= 0)
			objects = objects.remove(idx);
	}

	void addPointLight(in PointLight light) {
		if (pointLights.length > MAX_POINT_LIGHTS) {
			stderr.writefln("Warning: tried to add more lights than the maximum allowed (%d)", MAX_POINT_LIGHTS);
			return;
		}
		pointLights ~= light;
	}
	
	ref PointLight getPointLight(uint i)
	in {
		assert(i < pointLights.length);
	} do {
		return pointLights[i];
	}

	void draw(sfWindow* window, Camera camera) {
		foreach (obj; objects) {
			setUniforms(obj);
			obj.draw(window, camera);
		}
	}

private:
	void setUniforms(Mesh obj) const {
		obj.uniforms["ambientLight.color"] = ambientLight.color;
		obj.uniforms["ambientLight.strength"] = cast(GLfloat)ambientLight.strength;
		obj.uniforms["dirLight.direction"] = dirLight.direction;
		obj.uniforms["dirLight.diffuse"] = dirLight.diffuse;
		obj.uniforms["nPointLights"] = cast(GLuint)pointLights.length;
		obj.uniforms["pointLight.position"] = pointLights[0].position;
		obj.uniforms["pointLight.diffuse"] = pointLights[0].diffuse;
		obj.uniforms["pointLight.attenuation"] = cast(GLfloat)pointLights[0].attenuation;
		//foreach (i, pl; pointLights) {
			//shader.setUni("pointLight[%d].position".format(i), pl.position);
			//shader.setUni("pointLight[%d].diffuse".format(i), pl.diffuse);
			//shader.setUni("pointLight[%d].attenuation".format(i), pl.attenuation);
		//}
	}

	Mesh[] objects;
	PointLight[] pointLights;
}
