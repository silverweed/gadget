module gadget.rendering.presets;

/// This module contains utility functions to deal with shapes at high level

debug import std.stdio;
import std.variant;
import std.random;
import std.math;
import gadget.rendering.shapes;
import gadget.rendering.shader;
import gadget.rendering.renderstate;
import gadget.rendering.camera;
import derelict.sfml2;
import derelict.opengl;
import gl3n.linalg;

private Shader defaultShader;

void initPresets() {
	defaultShader = new Shader(q{
		#version 330 core

		layout (location = 0) in vec3 aPos;
		layout (location = 1) in vec3 aNormal;
		layout (location = 2) in vec2 aTexCoord;

		uniform mat4 model;
		uniform mat4 mvp;

		out VS_OUT {
			vec3 fragPos;
			vec3 normal;
			vec2 texCoord;
		} vs_out;

		void main() {
			vs_out.normal = mat3(transpose(inverse(model))) * aNormal;
			vs_out.texCoord = aTexCoord;
			vs_out.fragPos = vec3(model * vec4(aPos, 1.0));
			gl_Position = mvp * vec4(aPos, 1.0);
		}
	}, q{
		#version 330 core

		out vec4 fragColor;

		in VS_OUT {
			vec3 fragPos;
			vec3 normal;
			vec2 texCoord;
		} fs_in;

		uniform vec3 color;
		uniform vec3 viewPos;
		uniform vec3 lightPos;
		uniform vec3 lightColor;

		void main() {
			// ambient
			float ambientStrength = 0.1;
			vec3 ambient = ambientStrength * lightColor;

			// diffuse
			vec3 norm = normalize(fs_in.normal);
			vec3 lightDir = normalize(lightPos - fs_in.fragPos);
			float diff = max(dot(norm, lightDir), 0.0);
			vec3 diffuse = diff * lightColor;

			// specular
			float specularStrength = 0.9;
			vec3 viewDir = normalize(viewPos - fs_in.fragPos);
			vec3 halfDir = normalize(lightDir + viewDir);
			float spec = pow(max(dot(halfDir, norm), 0.0), 32);
			vec3 specular = specularStrength * spec * lightColor;

			vec3 result = (ambient + diffuse + specular) * color;
			fragColor = vec4(result, 1.0);
		}
	});
}

auto alpha(in quat q) {
	return 2 * acos(q.w);
}

auto axis(in quat q) {
	const d = sqrt(1 - q.w * q.w);
	if (d == 0)
		return vec3(1, 0, 0); // axis not important when rotation is 0
	return vec3(q.x / d, q.y / d, q.z / d);
}

class Shape {
	vec3 coords; /// world coordinates
	quat rotation = quat.identity;
	vec3 scale = vec3(1, 1, 1);
	vec4 color = vec4(1, 1, 1, 1);
	Uniform[string] uniforms;
	GLenum primitive = GL_TRIANGLES;

	this(GLuint vao, GLuint count, const Shader shader = defaultShader, bool isIndexed = false,
			const RenderState state = RenderState.global)
	{
		this.vao = vao;
		this.shader = shader;
		vertexCount = count;
		this.state = state;
		if (isIndexed)
			drawFunc = (GLenum primitive, GLuint count) {
				glDrawElements(primitive, count, GL_UNSIGNED_INT, cast(void*)0);
			};
		else
			drawFunc = (GLenum primitive, GLuint count) {
				glDrawArrays(primitive, 0, count);
			};
	}

	void draw(sfWindow *window, Camera camera) const {
		glBindVertexArray(vao);
		shader.use();
		// Set default uniforms
		shader.setUni("color", color.r, color.g, color.b);
		const model = mat4.identity
				.scale(scale.x, scale.y, scale.z)
				.rotate(rotation.alpha, rotation.axis)
				.translate(coords);
		shader.setUni("model", model);
		shader.setUni("viewPos", camera.position);
		shader.setUni("mvp", state.projection * camera.viewMatrix * model);
		// Set custom uniforms (may overwrite default ones)
		foreach (k, v; uniforms) {
			shader.setUni(k, v);
		}
		drawFunc(primitive, vertexCount);
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

private:
	const Shader shader;
	GLuint vao;
	/// This is actually the indices count if the shape is indexed
	GLuint vertexCount;
	const RenderState state;
	void function(GLenum primitive, GLuint count) drawFunc;

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
