module gadget.rendering.presets;

/// This module contains utility functions to deal with shapes at high level

debug import std.stdio;
import std.variant;
import std.random;
import std.math;
import gadget.rendering.shapes;
import gadget.rendering.shader;
import gadget.rendering.mesh;
import gadget.rendering.shadows;
import gadget.rendering.defaultShaders;
import derelict.sfml2;
import derelict.opengl;
import gl3n.linalg;

/// A lazy cache that constructs preset shaders on demand
private class PresetShaderCache {
	Shader opIndex(string name) {
		if (name in cache) return cache[name];
		Shader shader;
		switch (name) {
		case "default":
			shader = new Shader(vs_posNormTex, fs_blinnPhong, null, name);
			break;
		case "defaultInstanced":
			shader = new Shader(vs_posNormTexInstanced, fs_blinnPhongInstanced, null, name);
			break;
		case "billboardQuad":
			shader = new Shader(vs_billboardQuad, fs_billboardQuad, gs_billboardQuad, name);
			break;
		case "simpleDepth":
			shader = new Shader(vs_simpleDepthInstanced, fs_simpleDepth, null, name);
			break;
		case "screenQuad":
			shader = new Shader(vs_screenQuad, fs_screenQuad, null, name);
			break;
		default: assert(0, "Invalid preset shader: " ~ name);
		}
		return cache[name] = shader;
	}

	private Shader[string] cache;
};

__gshared auto presetShaders = new PresetShaderCache();

auto makePreset(ShapeType type, vec3 color = vec3(uniform01(), uniform01(), uniform01())) {
	GLuint function() genFunc;
	GLuint count;
	GLenum prim = GL_TRIANGLES;
	final switch (type) with (ShapeType) {
	case CUBE:
		genFunc = &genCube;
		count = cubeVertices.length;
		break;
	case QUAD:
		genFunc = &genQuad;
		count = quadVertices.length;
		break;
	case POINT:
		genFunc = &genPoint;
		count = 1;
		prim = GL_POINTS;
		break;
	}

	auto shape = new Mesh(genFunc(), count, presetShaders["default"]);
	shape.primitive = prim;
	shape.material.diffuse = color;
	return shape;
}
