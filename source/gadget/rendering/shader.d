module gadget.rendering.shader;

import std.file : readText;
import std.stdio;
import std.traits;
import std.variant;
import std.format : format;
import std.string : toStringz;
import derelict.opengl;
import gadget.rendering.c_utils : NULL;
import gl3n.linalg;

class Shader {
	static Shader fromFiles(string vsPath, string fsPath, string gsPath = null) {
		string vsCode, fsCode, gsCode;
		try {
			// Read the code from shader files
			vsCode = readText(vsPath);
			fsCode = readText(fsPath);
			if (gsPath != null)
				gsCode = readText(gsPath);
		} catch (Exception e) {
			stderr.writefln("Shader %s + %s %s failed to load: %s".format(
				vsPath, fsPath, gsPath == null ? "" : "+ " ~ gsPath,
				e.toString()));
		}
		return new Shader(vsCode, fsCode, gsPath == null ? null : gsCode);
	}

	this(string vsCode, string fsCode, string gsCode = null) {
		// Compile the shaders
		debug writeln("compiling vertex shader");
		const vsId = glCreateShader(GL_VERTEX_SHADER);
		const char* vsCodePtr = vsCode.toStringz();
		glShaderSource(vsId, 1, &vsCodePtr, null);
		glCompileShader(vsId);
		checkErr!"Vertex"(vsId);

		debug writeln("compiling fragment shader");
		const fsId = glCreateShader(GL_FRAGMENT_SHADER);
		const char* fsCodePtr = fsCode.toStringz();
		glShaderSource(fsId, 1, &fsCodePtr, null);
		glCompileShader(fsId);
		checkErr!"Fragment"(fsId);

		GLint gsId = -1;
		if (gsCode != null) {
			debug writeln("compiling geometry shader");
			gsId = glCreateShader(GL_GEOMETRY_SHADER);
			const char* gsCodePtr = gsCode.toStringz();
			glShaderSource(gsId, 1, &gsCodePtr, null);
			glCompileShader(gsId);
			checkErr!"Geometry"(gsId);
		}
		_id = glCreateProgram();
		glAttachShader(_id, vsId);
		glAttachShader(_id, fsId);
		if (gsId >= 0)
			glAttachShader(_id, gsId);
		debug writeln("linking shader");
		glLinkProgram(_id);
		checkErr!"Program"(_id);
		// Cleanup
		glDeleteShader(vsId);
		glDeleteShader(fsId);
		if (gsId)
			glDeleteShader(gsId);
	}

	int id() const { return _id; }

	/// Sets this shader as current.
	void use() const {
		glUseProgram(_id);
	}

	/// Sets a uniform to `val`.
	void setUni(T)(in string name, inout T val) const {
		static if (is(T == bool) || isImplicitlyConvertible!(T, GLint)) {
			glUniform1i(glGetUniformLocation(_id, cast(const(char*))name), cast(GLint)val);
		} else static if (isImplicitlyConvertible!(T, GLfloat)) {
			glUniform1f(glGetUniformLocation(_id, cast(const(char*))name), val);
		} else static if (is(T == vec2)) {
			glUniform2fv(glGetUniformLocation(_id, cast(const(char*))name), 1, val.value_ptr);
		} else static if (is(T == vec3)) {
			glUniform3fv(glGetUniformLocation(_id, cast(const(char*))name), 1, val.value_ptr);
		} else static if (is(T == vec4)) {
			glUniform4fv(glGetUniformLocation(_id, cast(const(char*))name), 1, val.value_ptr);
		} else static if (is(T == mat2)) {
			glUniformMatrix2fv(glGetUniformLocation(_id, cast(const(char*))name),
					1, GL_TRUE, val.value_ptr);
		} else static if (is(T == mat3)) {
			glUniformMatrix3fv(glGetUniformLocation(_id, cast(const(char*))name),
					1, GL_TRUE, val.value_ptr);
		} else static if (is(T == mat4)) {
			glUniformMatrix4fv(glGetUniformLocation(_id, cast(const(char*))name),
					1, GL_TRUE, val.value_ptr);
		} else static if (is(T == Variant)) {
			// Runtime dispatch
			if (val.convertsTo!(const GLint)) setUni(name, val.get!(const GLint));
			else if (val.convertsTo!(const GLfloat)) setUni(name, val.get!(const GLfloat));
			else if (val.convertsTo!(const vec2)) setUni(name, val.get!(const vec2));
			else if (val.convertsTo!(const vec3)) setUni(name, val.get!(const vec3));
			else if (val.convertsTo!(const vec4)) setUni(name, val.get!(const vec4));
			else if (val.convertsTo!(const mat2)) setUni(name, val.get!(const mat2));
			else if (val.convertsTo!(const mat3)) setUni(name, val.get!(const mat3));
			else if (val.convertsTo!(const mat4)) setUni(name, val.get!(const mat4));
			else assert(0, "Invalid type for uniform " ~ name ~ " of type " ~ val.type.toString() ~ "!");
		}
	}

	/// Sets a uniform array to `vals`
	void setUni(T...)(in string name, inout T vals) const {
		static if(isImplicitlyConvertible!(T[0], GLfloat)) {
			static if (vals.length == 2) {
				glUniform2f(glGetUniformLocation(_id, cast(const(char*))name), vals[0], vals[1]);
			} else static if (vals.length == 3) {
				glUniform3f(glGetUniformLocation(_id, cast(const(char*))name),
						vals[0], vals[1], vals[2]);
			} else static if (vals.length == 4) {
				glUniform4f(glGetUniformLocation(_id, cast(const(char*))name),
						vals[0], vals[1], vals[2], vals[3]);
			} else {
				static assert(0);
			}
		} else {
			static assert(0);
		}
	}

private:
	void checkErr(string type)(uint _id) {
		int success = 0;
		char[1024] infoLog;
		static if (type != "Program") {
			glGetShaderiv(_id, GL_COMPILE_STATUS, &success);
			if (!success) {
				glGetShaderInfoLog(_id, infoLog.length, NULL, infoLog.ptr);
				stderr.writeln("[ ERR ] ", type, " Shader failed to compile: ", infoLog);
			}
		} else {
			glGetProgramiv(_id, GL_LINK_STATUS, &success);
			if (!success) {
				glGetShaderInfoLog(_id, infoLog.length, NULL, infoLog.ptr);
				stderr.writeln("[ ERR ] Shader failed to link: ", infoLog);
			}
		}
	}

	int _id;
}
