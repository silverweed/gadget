module gadget.rendering.presets;

/// This module contains utility functions to deal with shapes at high level

debug import std.stdio;
import std.variant;
import std.random;
import std.math;
import gadget.rendering.shapes;
import gadget.rendering.utils;
import gadget.rendering.interfaces;
import gadget.rendering.shader;
import gadget.rendering.renderstate;
import gadget.rendering.camera;
import gadget.rendering.defaultShaders;
import derelict.sfml2;
import derelict.opengl;
import gl3n.linalg;

Shader defaultShader,
       defaultShaderInstanced;

void initPresets() {
	defaultShader = new Shader(vs_posNormTex, fs_blinnPhong);
	defaultShaderInstanced = new Shader(vs_posNormTexInstanced, fs_blinnPhongInstanced);
}

class Shape : Drawable {
	vec3 coords = vec3(0, 0, 0); /// world coordinates
	quat rotation = quat.identity;
	vec3 scale = vec3(1, 1, 1);
	vec4 color = vec4(1, 1, 1, 1);
	Uniform[string] uniforms;
	GLenum primitive = GL_TRIANGLES;
	const Shader shader;
	GLuint vao;
	/// This is actually the indices count if the shape is indexed
	GLuint vertexCount;
	const RenderState state;

	this(GLuint vao, GLuint count, const Shader shader = defaultShader, bool isIndexed = false,
			const RenderState state = RenderState.global)
	{
		this.vao = vao;
		this.shader = shader;
		vertexCount = count;
		this.state = state;
		if (isIndexed)
			drawFunc = (const(Shape) shape) {
				glDrawElements(shape.primitive, shape.vertexCount, GL_UNSIGNED_INT, cast(void*)0);
			};
		else
			drawFunc = (const(Shape) shape) {
				glDrawArraysInstanced(shape.primitive, 0, shape.vertexCount, 300);
			};
	}

	override void draw(sfWindow *window, Camera camera) const {
		glBindVertexArray(vao);
		shader.use();
		setDefaultUniforms(camera);
		// Set custom uniforms (may overwrite default ones)
		foreach (k, v; uniforms) {
			shader.setUni(k, v);
		}
		drawFunc(this);
		glBindVertexArray(0);
	}

	Shape setPos(float x, float y, float z) {
		coords = vec3(x, y, z);
		return this;
	}

	Shape setPos(in vec3 pos) {
		coords = pos;
		return this;
	}

	Shape setRot(float yaw, float pitch, float roll) {
		rotation = quat.euler_rotation(yaw, pitch, roll).normalized();
		return this;
	}
	
	Shape setScale(float sx, float sy, float sz) {
		scale = vec3(sx, sy, sz);
		return this;
	}

	Shape setColor(float r, float g, float b, float a = 1) {
		color = vec4(r, g, b, a);
		return this;
	}

	Shape setPrimitive(GLenum primitive) {
		this.primitive = primitive;
		return this;
	}

protected:
	void setDefaultUniforms(Camera camera) const {
		shader.setUni("color", color.r, color.g, color.b);
		shader.setUni("specularStrength", 0.9);
		const model = mat4.identity
				.scale(scale.x, scale.y, scale.z)
				.rotate(rotation.alpha, rotation.axis)
				.translate(coords);
		shader.setUni("model", model);
		shader.setUni("viewPos", camera.position);
		shader.setUni("mvp", state.projection * camera.viewMatrix * model);
	}
	void function(const(Shape) shape) drawFunc;

	invariant {
		assert(rotation.magnitude_squared().approxEqual(1, float.epsilon));
	}
}

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

	auto shape = new Shape(genFunc(), count);
	shape.primitive = prim;
	shape.setColor(color.r, color.g, color.b);
	return shape;
}
