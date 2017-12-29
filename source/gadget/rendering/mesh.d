module gadget.rendering.mesh;

debug import std.stdio;
import std.math;
import gl3n.linalg;
import derelict.opengl;
import derelict.sfml2.window;
import gadget.rendering.shader;
import gadget.rendering.gl;
import gadget.rendering.renderstate;
import gadget.rendering.utils;
import gadget.rendering.camera;
import gadget.rendering.material;

struct Transform {
	vec3 position = vec3(0, 0, 0);
	quat rotation = quat.identity;
	vec3 scale    = vec3(1, 1, 1);
}

class Mesh {
	Transform transform;
	Material material;
	Shader shader;
	GLenum primitive = GL_TRIANGLES;
	GLuint vao;
	GLuint vertexCount;
	GLuint indexCount;
	bool cullFace;

	this(GLuint vao, GLuint count, Shader shader, bool isIndexed = false) {
		this.vao = vao;
		this.shader = shader;
		material.shininess = 0;
		if (isIndexed) {
			indexCount = count;
			drawFunc = (in Mesh shape) {
				glDrawElements(shape.primitive, shape.indexCount, GL_UNSIGNED_INT, NULL);
			};
		} else {
			vertexCount = count;
			drawFunc = (in Mesh shape) {
				glDrawArrays(shape.primitive, 0, shape.vertexCount);
			};
		}
	}

protected:
	void function(const(Mesh) shape) drawFunc;

	invariant {
		import std.algorithm;
		assert(transform.rotation.magnitude_squared().approxEqual(1, float.epsilon), "rotation magnitude is not 1!");
		assert(!material.shininess.isNaN, "material shininess is NaN!");
	}
}

void draw(in Mesh mesh, Shader shader) {
	glBindVertexArray(mesh.vao);

	shader.use();
	mesh.setDefaultUniforms(shader);
	shader.applyUniforms();
	debug shader.assertAllUniformsDefined();

	mesh.setTextures();

	auto wasCullEnabled = glIsEnabled(GL_CULL_FACE);
	cull(mesh.cullFace);

	mesh.drawFunc(mesh);

	cull(wasCullEnabled);

	glBindVertexArray(0);
}

void setCameraUniforms(Mesh mesh, Shader shader, in Camera camera) {
	const t = mesh.transform;
	const model = mat4.identity
			.scale(t.scale.x, t.scale.y, t.scale.z)
			.rotate(t.rotation.alpha, t.rotation.axis)
			.translate(t.position);
	shader.uniforms["viewPos"] = camera.position;
	const vp = camera.projMatrix * camera.viewMatrix;
	shader.uniforms["vp"] = vp;
	shader.uniforms["mvp"] = vp * model;
}

private:

void setTextures(in Mesh mesh) {
	glActiveTexture(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_2D, mesh.material.diffuse);
	glActiveTexture(GL_TEXTURE2);
	glBindTexture(GL_TEXTURE_2D, mesh.material.specular);
}

void setDefaultUniforms(in Mesh mesh, Shader shader) {
	const t = mesh.transform;
	const model = mat4.identity
			.scale(t.scale.x, t.scale.y, t.scale.z)
			.rotate(t.rotation.alpha, t.rotation.axis)
			.translate(t.position);
	shader.setMaterialUniforms(mesh.material);
	shader.uniforms["model"] = model;
	shader.uniforms["depthMap"] = 0;
	shader.uniforms["material.diffuse"] = 1;
	shader.uniforms["material.specular"] = 2;
}
