module gadget.rendering.batch;

debug import std.stdio;
import std.string;
import gadget.rendering.shader;
import gadget.rendering.interfaces;
import gadget.rendering.camera;
import gadget.rendering.presets;
import gadget.rendering.renderstate;
import derelict.opengl;
import derelict.sfml2;
import gl3n.math : min;
import gl3n.linalg;

/// A Batch draws n instances of the same shape
class Batch : Shape {

	GLuint nInstances = 1;

	this(GLuint vao, GLuint count, const Shader shader = defaultShaderInstanced, bool isIndexed = false,
			const RenderState state = RenderState.global)
	{
		super(vao, count, shader, isIndexed, state);
		if (!isIndexed)
			drawFunc = (const(Shape) shape) {
				debug writeln("drawing ", (cast(Batch)shape).nInstances, " instances");
				glDrawArraysInstanced(shape.primitive, 0, shape.vertexCount,
						(cast(Batch)shape).nInstances);
			};
	}

	void setData(T)(string name, T[] data) {
		GLuint iVbo;
		glGenBuffers(1, &iVbo);
		glBindBuffer(GL_ARRAY_BUFFER, iVbo);
		glBufferData(GL_ARRAY_BUFFER, T.sizeof * data.length, data.ptr, GL_STATIC_DRAW);

		const loc = glGetAttribLocation(shader.id, name.toStringz());
		assert(loc >= 0);
		const sz = min(4, T.sizeof);

		glBindVertexArray(vao);
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

protected:
	override void setDefaultUniforms(Camera camera) const {
		super.setDefaultUniforms(camera);
		shader.setUni("vp", state.projection * camera.viewMatrix);
	}
}
