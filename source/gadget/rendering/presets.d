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
			vec3 reflectDir = reflect(-lightDir, norm);
			float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32);
			vec3 specular = specularStrength * spec * lightColor;

			vec3 result = (ambient + diffuse + specular) * color;
			fragColor = vec4(result, 1.0);
		}
	});
}

alias Uniform = Algebraic!(bool, GLint, GLfloat, vec2, vec3, vec4, mat2, mat3, mat4);

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

	this(GLuint vao, GLuint count, const Shader shader = defaultShader, const RenderState state = RenderState.global) {
		this.vao = vao;
		this.shader = shader;
		vertexCount = count;
		this.state = state;
	}

	void draw(sfWindow *window, Camera camera) const {
		glBindVertexArray(vao);
		shader.use();
		// Set default uniforms
		shader.setUni("color", color.r, color.g, color.b);
		debug writeln("rotation: ", rotation, " axis: ", rotation.axis, ", alpha: ", rotation.alpha);
		const model = mat4.translation(coords)
				.rotate(rotation.alpha, rotation.axis)
				.scale(scale.x, scale.y, scale.z);
		shader.setUni("model", model);
		shader.setUni("viewPos", camera.position);
		shader.setUni("mvp", state.projection * camera.viewMatrix * model);
		// Set custom uniforms (may overwrite default ones)
		foreach (k, v; uniforms) {
			shader.setUni(k, v);
		}
		glDrawArrays(GL_TRIANGLES, 0, vertexCount);
		glBindVertexArray(0);
	}

	Shape setPos(float x, float y, float z) {
		coords = vec3(x, y, z);
		return this;
	}

	Shape setRot(float yaw, float pitch, float roll) {
		rotation = quat.euler_rotation(yaw, pitch, roll);
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

private:
	const Shader shader;
	GLuint vao;
	GLuint vertexCount;
	const RenderState state;

	invariant {
		assert(rotation.magnitude_squared() == 1);
	}
}

auto makePresetCube() {
	auto cube = new Shape(genCube(), cubeVertices.length);
	cube.setColor(uniform01(), uniform01(), uniform01());
	return cube;
}
