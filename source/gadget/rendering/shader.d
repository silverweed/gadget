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

alias Uniform = Algebraic!(bool, GLint, GLuint, GLfloat, GLdouble, vec2, vec3, vec4, mat2, mat3, mat4,
		const(bool), const(GLint), const(GLuint), const(GLfloat), const(GLdouble), const(vec2),
		const(vec3), const(vec4), const(mat2), const(mat3), const(mat4));

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
	void setInt(in string name, inout GLint val) const {
		glUniform1i(glGetUniformLocation(_id, cast(const(char*))name), val);
	}
	void setUint(in string name, inout GLuint val) const {
		glUniform1ui(glGetUniformLocation(_id, cast(const(char*))name), val);
	}
	void setFloat(in string name, inout GLfloat val) const {
		glUniform1f(glGetUniformLocation(_id, cast(const(char*))name), val);
	}
	void setVec2(in string name, inout vec2 val) const {
		glUniform2fv(glGetUniformLocation(_id, cast(const(char*))name), 1, val.value_ptr);
	}
	void setVec2(in string name, inout GLfloat val1, inout GLfloat val2) const {
		glUniform2f(glGetUniformLocation(_id, cast(const(char*))name), val1, val2);
	}
	void setVec3(in string name, inout vec3 val) const {
		glUniform3fv(glGetUniformLocation(_id, cast(const(char*))name), 1, val.value_ptr);
	}
	void setVec3(in string name, inout GLfloat val1, inout GLfloat val2, inout GLfloat val3) const {
		glUniform3f(glGetUniformLocation(_id, cast(const(char*))name), val1, val2, val3);
	}
	void setVec4(in string name, inout vec4 val) const {
		glUniform4fv(glGetUniformLocation(_id, cast(const(char*))name), 1, val.value_ptr);
	}
	void setVec3(in string name, inout GLfloat val1, inout GLfloat val2, inout GLfloat val3, inout GLfloat val4) const {
		glUniform4f(glGetUniformLocation(_id, cast(const(char*))name), val1, val2, val3, val4);
	}
	void setMat2(in string name, inout mat2 val) const {
		glUniformMatrix2fv(glGetUniformLocation(_id, cast(const(char*))name), 1, GL_TRUE, val.value_ptr);
	}
	void setMat3(in string name, inout mat3 val) const {
		glUniformMatrix3fv(glGetUniformLocation(_id, cast(const(char*))name), 1, GL_TRUE, val.value_ptr);
	}
	void setMat4(in string name, inout mat4 val) const {
		glUniformMatrix4fv(glGetUniformLocation(_id, cast(const(char*))name), 1, GL_TRUE, val.value_ptr);
	}
	void setUni(in string name, inout Uniform val) const {
		if (val.convertsTo!(GLint) || val.convertsTo!(const GLint)) setInt(name, val.get!(const GLint));
		else if (val.convertsTo!(GLfloat) || val.convertsTo!(const GLfloat)) setFloat(name, val.get!(const GLfloat));
		else if (val.convertsTo!(GLdouble) || val.convertsTo!(const GLdouble)) setFloat(name, val.get!(const GLdouble));
		else if (val.convertsTo!(vec2) || val.convertsTo!(const vec2)) setVec2(name, val.get!(const vec2));
		else if (val.convertsTo!(vec3) || val.convertsTo!(const vec3)) setVec3(name, val.get!(const vec3));
		else if (val.convertsTo!(vec4) || val.convertsTo!(const vec4)) setVec4(name, val.get!(const vec4));
		else if (val.convertsTo!(mat2) || val.convertsTo!(const mat2)) setMat2(name, val.get!(const mat2));
		else if (val.convertsTo!(mat3) || val.convertsTo!(const mat3)) setMat3(name, val.get!(const mat3));
		else if (val.convertsTo!(mat4) || val.convertsTo!(const mat4)) setMat4(name, val.get!(const mat4));
		else assert(0, "Invalid type for uniform " ~ name ~ " of type " ~ val.type.toString() ~ "!");
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
