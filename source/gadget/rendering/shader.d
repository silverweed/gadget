module gadget.rendering.shader;

import std.file : readText;
import std.stdio;
import std.string;
import std.traits;
import std.variant;
import std.format : format;
import std.string : toStringz;
import derelict.opengl;
import gadget.rendering.utils : NULL;
import gl3n.linalg;

alias Uniform = Algebraic!(bool, GLint, GLuint, GLfloat, GLdouble, vec2, vec3, vec4, mat2, mat3, mat4);

class Shader {
	const string name;

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
		return new Shader(vsCode, fsCode, gsPath == null ? null : gsCode,
			vsPath ~ " + " ~ fsPath ~ " + " ~ gsPath);

	}

	this(string vsCode, string fsCode, string gsCode = null, string name = "") {
		this.name = name;

		// Compile the shaders
		debug writefln("[%s] compiling vertex shader", name);
		const vsId = glCreateShader(GL_VERTEX_SHADER);
		const char* vsCodePtr = vsCode.toStringz();
		glShaderSource(vsId, 1, &vsCodePtr, null);
		glCompileShader(vsId);
		checkErr!"Vertex"(vsId, vsCode);

		debug writefln("[%s] compiling fragment shader", name);
		const fsId = glCreateShader(GL_FRAGMENT_SHADER);
		const char* fsCodePtr = fsCode.toStringz();
		glShaderSource(fsId, 1, &fsCodePtr, null);
		glCompileShader(fsId);
		checkErr!"Fragment"(fsId, fsCode);

		GLint gsId = -1;
		if (gsCode != null) {
			debug writefln("[%s] compiling geometry shader", name);
			gsId = glCreateShader(GL_GEOMETRY_SHADER);
			const char* gsCodePtr = gsCode.toStringz();
			glShaderSource(gsId, 1, &gsCodePtr, null);
			glCompileShader(gsId);
			checkErr!"Geometry"(gsId, gsCode);
		}
		_id = glCreateProgram();
		glAttachShader(_id, vsId);
		glAttachShader(_id, fsId);
		if (gsId >= 0)
			glAttachShader(_id, gsId);
		debug writefln("[%s] linking shader", name);
		glLinkProgram(_id);
		checkErr!"Program"(_id, vsCode, fsCode, gsCode);
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
		writeln("setting uni ", name, " to ", val);
		static if (is(T == bool) || isImplicitlyConvertible!(T, GLint)) {
			glUniform1i(glGetUniformLocation(_id, cast(const(char*))name), cast(GLint)val);
		} else static if (isImplicitlyConvertible!(T, GLuint)) {
			glUniform1ui(glGetUniformLocation(_id, cast(const(char*))name), cast(GLuint)val);
		} else static if (isImplicitlyConvertible!(T, GLfloat) || isImplicitlyConvertible!(T, GLdouble)) {
			glUniform1f(glGetUniformLocation(_id, cast(const(char*))name), cast(GLfloat)val);
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
		} else static if (is(T == Uniform)) {
			// Runtime dispatch
			if (val.convertsTo!(GLint)) setUni(name, val.get!(GLint));
			else if (val.convertsTo!(GLfloat)) setUni(name, val.get!(GLfloat));
			else if (val.convertsTo!(GLdouble)) setUni(name, val.get!(GLdouble));
			else if (val.convertsTo!(vec2)) setUni(name, val.get!(vec2));
			else if (val.convertsTo!(vec3)) setUni(name, val.get!(vec3));
			else if (val.convertsTo!(vec4)) setUni(name, val.get!(vec4));
			else if (val.convertsTo!(mat2)) setUni(name, val.get!(mat2));
			else if (val.convertsTo!(mat3)) setUni(name, val.get!(mat3));
			else if (val.convertsTo!(mat4)) setUni(name, val.get!(mat4));
			else assert(0, "Invalid type for uniform " ~ name ~ " of type " ~ val.type.toString() ~ "!");
		} else static assert(0);
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
	void checkErr(string type, A...)(uint _id, A codes) {
		int success = 0;
		char[1024] infoLog;
		static if (type != "Program") {
			glGetShaderiv(_id, GL_COMPILE_STATUS, &success);
			if (!success) {
				glGetShaderInfoLog(_id, infoLog.length, NULL, infoLog.ptr);
				stderr.writeln("[ ERR ] ", type, " Shader failed to compile: ", infoLog);
				stderr.writeln("  Shader code looks like this:");
				auto l = 0;
				foreach (c; codes) {
					auto lines = c.split("\n");
					foreach (line; lines)
						stderr.writefln("%d %s", l++, line);
					stderr.writeln("----------------");
				}
			}
		} else {
			glGetProgramiv(_id, GL_LINK_STATUS, &success);
			if (!success) {
				glGetProgramInfoLog(_id, infoLog.length, NULL, infoLog.ptr);
				stderr.writeln("[ ERR ] Shader failed to link: ", infoLog);
				stderr.writeln("  Shader code looks like this:");
				auto l = 0;
				foreach (c; codes) {
					auto lines = c.split("\n");
					foreach (line; lines)
						stderr.writefln("%d %s", l++, line);
					stderr.writeln("----------------");
				}
			}
		}
	}

	int _id;
}
