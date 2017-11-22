module gadget.rendering.shader;

import std.typecons : Nullable;
import std.file : readText;
import std.stdio;
import std.format;
import derelict.opengl3.gl3;
import gadget.rendering.c_utils : NULL;
import gl3n.linalg;

class Shader {
	this(string vsPath, string fsPath, Nullable!string gsPath = null) {
		char* vsCode, fsCode, gsCode;
		try {
			// Read the code from shader files
			vsCode = readText(vsPath).dup.ptr;
			fsCode = readText(fsPath).dup.ptr;
			if (!gsPath.isNull)
				gsCode = readText(gsPath).dup.ptr;
		} catch (Exception e) {
			stderr.writefln("Shader %s + %s %s failed to load: %s".format(
				vsPath, fsPath, gsPath.isNull ? "" : "+ " ~ gsPath,
				e.toString()));
		}
		// Compile the shaders
		const vsId = glCreateShader(GL_VERTEX_SHADER);
		glShaderSource(vsId, 1, &vsCode, null);
		glCompileShader(vsId);
		checkErr!"Vertex"(vsId);

		const fsId = glCreateShader(GL_FRAGMENT_SHADER);
		glShaderSource(fsId, 1, &fsCode, null);
		glCompileShader(fsId);
		checkErr!"Fragment"(fsId);

		int gsId = -1;
		if (!gsPath.isNull) {
			gsId = glCreateShader(GL_GEOMETRY_SHADER);
			glShaderSource(gsId, 1, &gsCode, null);
			glCompileShader(gsId);
			checkErr!"Geometry"(gsId);
		}
		id = glCreateProgram();
		glAttachShader(id, vsId);
		glAttachShader(id, fsId);
		if (gsId >= 0)
			glAttachShader(id, gsId);
		glLinkProgram(id);
		checkErr!"Program"(id);
		// Cleanup
		glDeleteShader(vsId);
		glDeleteShader(fsId);
		if (gsId)
			glDeleteShader(gsId);
	}

	void use() immutable {
		glUseProgram(id);
	}

	void setVal(T)(in string name, T val) immutable {
		static if (is(T == bool) || T.isImplicitlyConvertible!int) {
			glUniform1i(glGetUniformLocation(id, cast(const(char*))name), cast(int)val);
		} else static if (T.isImplicitlyConvertible!float) {
			glUniform1f(glGetUniformLocation(id, cast(const(char*))name), cast(float)val);
		} else static if (is(T == vec2)) {
			glUniform2fv(glGetUniformLocation(id, cast(const(char*))name), 1, val);
		} else static if (is(T == vec3)) {
			glUniform3fv(glGetUniformLocation(id, cast(const(char*))name), 1, val);
		} else static if (is(T == vec4)) {
			glUniform4fv(glGetUniformLocation(id, cast(const(char*))name), 1, val);
		} else static if (is(T == mat2)) {
			glUniformMatrix2fv(glGetUniformLocation(id, cast(const(char*))name), 1, val);
		} else static if (is(T == mat3)) {
			glUniformMatrix3fv(glGetUniformLocation(id, cast(const(char*))name), 1, val);
		} else static if (is(T == mat4)) {
			glUniformMatrix4fv(glGetUniformLocation(id, cast(const(char*))name), 1, val);
		} else {
			static assert(0);
		}
	}

	void setVal(T...)(in string name, T vals) immutable {
		static if(T.isImplicitlyConvertible!float) {
			static if (vals.length == 2) {
				glUniform2f(glGetUniformLocation(id, cast(const(char*))name), vals[0], vals[1]);
			} else static if (vals.length == 3) {
				glUniform3f(glGetUniformLocation(id, cast(const(char*))name),
						vals[0], vals[1], vals[2]);
			} else static if (vals.length == 4) {
				glUniform4f(glGetUniformLocation(id, cast(const(char*))name),
						vals[0], vals[1], vals[2], vals[3]);
			} else {
				static assert(0);
			}
		} else {
			static assert(0);
		}
	}

private:
	void checkErr(string type)(uint id) {
		int success = 0;
		char[1024] infoLog;
		static if (type == "Program") {
			glGetShaderiv(id, GL_COMPILE_STATUS, &success);
			if (!success) {
				glGetShaderInfoLog(id, infoLog.length, NULL, infoLog.ptr);
				stderr.writeln("[ ERR ] ", type, " Shader failed to compile: ", infoLog);
			}
		} else {
			glGetShaderiv(id, GL_LINK_STATUS, &success);
			if (!success) {
				glGetShaderInfoLog(id, infoLog.length, NULL, infoLog.ptr);
				stderr.writeln("[ ERR ] Shader failed to link: ", infoLog);
			}
		}
	}

	int id;
}
