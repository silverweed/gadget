module gadget.rendering.batch;

debug import std.stdio;
import std.string;
import gadget.rendering.shader;
import gadget.rendering.camera;
import gadget.rendering.mesh;
import gadget.rendering.renderstate;
import derelict.opengl;
import derelict.sfml2;
import gl3n.math : min;
import gl3n.linalg;

/// A Batch draws n instances of the same shape
class Batch : Mesh {
	GLuint nInstances = 1;

	this(GLuint vao, GLuint count, Shader shader, bool isIndexed = false) {
		super(vao, count, shader, isIndexed);
		if (!isIndexed)
			drawFunc = (const(Mesh) shape) {
				glDrawArraysInstanced(shape.primitive, 0, shape.vertexCount,
						(cast(Batch)shape).nInstances);
			};
	}

protected:
	override void setDefaultUniforms(Camera camera) const {
		super.setDefaultUniforms(camera);
		shader.setMat4("vp", camera.projMatrix * camera.viewMatrix);
	}
}

void setData(T)(Batch batch, string name, T[] data) {
	GLuint iVbo;
	glGenBuffers(1, &iVbo);
	glBindBuffer(GL_ARRAY_BUFFER, iVbo);
	glBufferData(GL_ARRAY_BUFFER, T.sizeof * data.length, data.ptr, GL_STATIC_DRAW);

	const loc = glGetAttribLocation(batch.shader.id, name.toStringz());
	assert(loc >= 0, "Found no attribute " ~ name ~ " for shader " ~ batch.shader.name);
	const sz = min(4, T.sizeof);

	glBindVertexArray(batch.vao);
	glEnableVertexAttribArray(loc);
	glVertexAttribPointer(loc, sz, GL_FLOAT, GL_FALSE, T.sizeof, cast(void*)0);
	glVertexAttribDivisor(loc, 1);
	// TODO replace with static foreach when possible
	static if (T.sizeof > vec4.sizeof) {
		glEnableVertexAttribArray(loc + 1);
		glVertexAttribPointer(loc + 1, sz, GL_FLOAT, GL_FALSE, T.sizeof, cast(void*)(1 * vec4.sizeof));
		glVertexAttribDivisor(loc + 1, 1);
		static if (T.sizeof > 2 * vec4.sizeof) {
			glEnableVertexAttribArray(loc + 2);
			glVertexAttribPointer(loc + 2, sz, GL_FLOAT, GL_FALSE, T.sizeof, cast(void*)(2 * vec4.sizeof));
			glVertexAttribDivisor(loc + 2, 1);
			static if (T.sizeof > 3 * vec4.sizeof) {
				glEnableVertexAttribArray(loc + 3);
				glVertexAttribPointer(loc + 3, sz, GL_FLOAT, GL_FALSE, T.sizeof, cast(void*)(3 * vec4.sizeof));
				glVertexAttribDivisor(loc + 3, 1);
			}
		}
	}
	glBindVertexArray(0);
	glBindBuffer(GL_ARRAY_BUFFER, 0);
}
