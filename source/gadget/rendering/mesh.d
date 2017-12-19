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
	bool cullFace = false;

	this(GLuint vao, GLuint count, Shader shader) {
		this.vao = vao;
		this.shader = shader;
		vertexCount = count;
		material.diffuse = vec3(0, 0, 0);
		material.specular = vec3(1, 1, 1);
		material.shininess = 0.5;
		drawFunc = (in Mesh shape) {
			glDrawArrays(shape.primitive, 0, shape.vertexCount);
		};
	}

protected:
	void function(const(Mesh) shape) drawFunc;

	invariant {
		import std.algorithm;
		assert(transform.rotation.magnitude_squared().approxEqual(1, float.epsilon));
		assert(material.diffuse.isFinite);
		assert(material.specular.isFinite);
		assert(!material.shininess.isNaN);
	}
}

void draw(in Mesh mesh, Shader shader) {
	glBindVertexArray(mesh.vao);

	shader.use();
	mesh.setDefaultUniforms(shader);
	shader.applyUniforms();
	debug shader.assertAllUniformsDefined();

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

package void setDefaultUniforms(in Mesh mesh, Shader shader) {
	const t = mesh.transform;
	const model = mat4.identity
			.scale(t.scale.x, t.scale.y, t.scale.z)
			.rotate(t.rotation.alpha, t.rotation.axis)
			.translate(t.position);
	shader.setMaterialUniforms(mesh.material);
	shader.uniforms["model"] = model;
	shader.uniforms["depthMap"] = 0;
}
