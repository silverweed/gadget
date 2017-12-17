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
			drawFunc = (in Mesh shape) {
				glDrawElements(shape.primitive, shape.vertexCount, GL_UNSIGNED_INT, cast(void*)0);
			};
		else
			drawFunc = (in Mesh shape) {
				glDrawArrays(shape.primitive, 0, shape.vertexCount);
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

	override Shader getShader() { return shader; }

protected:
	void setDefaultUniforms(Camera camera) const {
		shader.setVec3("material.diffuse", material.diffuse);
		shader.setFloat("material.shininess", material.shininess);
		const model = mat4.identity
				.scale(transform.scale.x, transform.scale.y, transform.scale.z)
				.rotate(transform.rotation.alpha, transform.rotation.axis)
				.translate(transform.position);
		shader.setMat4("model", model);
		shader.setVec3("viewPos", camera.position);
		shader.setMat4("mvp", camera.projMatrix * camera.viewMatrix * model);
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

