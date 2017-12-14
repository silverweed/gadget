module gadget.rendering.world;

import std.stdio : stderr;
import std.string;
import std.algorithm;
import derelict.sfml2.window;
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
			setUniforms(obj.shader);
			obj.draw(window, camera);
		}
	}

private:
	void setUniforms(Shader shader) const {
		foreach (i, val; ambientLight.tupleof)
			shader.setUni("ambientLight.%s".format(__traits(identifier, ambientLight.tupleof[i])), val);
		foreach (i, val; dirLight.tupleof)
			shader.setUni("dirLight.%s".format(__traits(identifier, dirLight.tupleof[i])), val);
		shader.setUni("nPointLights", pointLights.length);
		foreach (i, pl; pointLights)
			foreach (j, val; pl.tupleof)
				shader.setUni("pointLights[%d].%s".format(i, __traits(identifier, pl.tupleof[j])), val);
	}

	Mesh[] objects;
	PointLight[] pointLights;
}
