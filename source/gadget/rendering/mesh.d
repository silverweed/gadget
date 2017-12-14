module gadget.rendering.mesh;

debug import std.stdio;
import std.math;
import gl3n.linalg;
import derelict.opengl;
import derelict.sfml2.window;
import gadget.rendering.shader;
import gadget.rendering.gl;
import gadget.rendering.renderstate;
import gadget.rendering.interfaces;
import gadget.rendering.utils;
import gadget.rendering.camera;
import gadget.rendering.material;

struct Transform {
	vec3 position = vec3(0, 0, 0);
	quat rotation = quat.identity;
	vec3 scale    = vec3(1, 1, 1);
}

class Mesh : ShaderDrawable {
	Transform transform;
	Material material;
	Uniform[string] uniforms;
	GLenum primitive = GL_TRIANGLES;
	Shader shader;
	GLuint vao;
	/// This is the indices count if the mesh is indexed
	GLuint vertexCount;
	bool cullFace = false;

	this(GLuint vao, GLuint count, Shader shader, bool isIndexed = false) {
		this.vao = vao;
		this.shader = shader;
		vertexCount = count;
		material.diffuse = vec3(0, 0, 0);
		material.specular = vec3(1, 1, 1);
		material.shininess = 0.5;
		if (isIndexed)
			drawFunc = (const(Mesh) shape) {
				glDrawElements(shape.primitive, shape.vertexCount, GL_UNSIGNED_INT, cast(void*)0);
			};
		else
			drawFunc = (const(Mesh) shape) {
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

		auto wasCullEnabled = glIsEnabled(GL_CULL_FACE);
		cull(cullFace);

		drawFunc(this);

		cull(wasCullEnabled);

		glBindVertexArray(0);
	}

	Mesh setPos(float x, float y, float z) {
		transform.position = vec3(x, y, z);
		return this;
	}

	Mesh setPos(in vec3 pos) {
		transform.position = pos;
		return this;
	}

	Mesh setRot(float yaw, float pitch, float roll) {
		transform.rotation = quat.euler_rotation(yaw, pitch, roll).normalized();
		return this;
	}
	
	Mesh setScale(float sx, float sy, float sz) {
		transform.scale = vec3(sx, sy, sz);
		return this;
	}

	Mesh setColor(float r, float g, float b) {
		material.diffuse = vec3(r, g, b);
		return this;
	}

	Mesh setPrimitive(GLenum primitive) {
		this.primitive = primitive;
		return this;
	}

	override Shader getShader() { return shader; }

protected:
	void setDefaultUniforms(Camera camera) const {
		shader.setUni("material.diffuse", material.diffuse);
		shader.setUni("material.shininess", material.shininess);
		const model = mat4.identity
				.scale(transform.scale.x, transform.scale.y, transform.scale.z)
				.rotate(transform.rotation.alpha, transform.rotation.axis)
				.translate(transform.position);
		shader.setUni("model", model);
		shader.setUni("viewPos", camera.position);
		shader.setUni("mvp", camera.projMatrix * camera.viewMatrix * model);
	}
	void function(const(Mesh) shape) drawFunc;

	invariant {
		import std.algorithm;
		assert(transform.rotation.magnitude_squared().approxEqual(1, float.epsilon));
		assert(material.diffuse.isFinite);
		assert(material.specular.isFinite);
		assert(!material.shininess.isNaN);
	}
}

