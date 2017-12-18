module gadget.rendering.shader;

import std.file : readText;
import std.stdio;
import std.algorithm;
import std.string;
import std.traits;
import std.variant;
import std.format : format;
import std.string : toStringz;
import derelict.opengl;
import gl3n.linalg;
import gadget.rendering.utils : NULL;
import gadget.rendering.material;

alias Uniform = Algebraic!(bool, GLint, GLuint, GLfloat, GLdouble, vec2, vec3, vec4, mat2, mat3, mat4, string,
		const(bool), const(GLint), const(GLuint), const(GLfloat), const(GLdouble), const(vec2),
		const(vec3), const(vec4), const(mat2), const(mat3), const(mat4));

class Shader {
	const string name;

	Uniform[string] uniforms;

	@property auto id() const { return _id; }

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

		fillDeclaredUniforms(vsCode);
		fillDeclaredUniforms(fsCode);
		if (gsCode !is null) fillDeclaredUniforms(gsCode);
	}

	void applyUniforms() {
		foreach (k, v; uniforms) {
			setUni(this, k, v);
		}
	}

	debug void assertAllUniformsDefined() {
		bool ok = true;
		foreach (k, decl; declaredUniforms) {
			writeln("declared: ", declaredUniforms[k].type, " ", k, ", real: ", uniforms[k].type);
			if (!(k in uniforms)) {
				writeln("[ ERROR ] Uniform '", k, "' was not defined for shader '", name, "'");
				ok = false;
			} else {
				if (uniforms[k].type != decl.type) {
					writeln("[ ERROR ] Uniform '", k, "' has type incompatible with declared in shader '",
							name, "' (declared: ", decl.type, ", real: ", uniforms[k].type, ")");
					ok = false;
				}
			}
		}
		if (!ok)
			assert(0);
	}

private:
	int _id;
	debug {
		Uniform[string] declaredUniforms;
		void fillDeclaredUniforms(string code) {
			import std.regex : ctRegex, matchFirst;
			enum basicTypes = ["vec2", "vec3", "vec4", "mat2", "mat3", "mat4", "float",
					"int", "uint", "bool", "double", "sampler2D"];
			auto rgx = ctRegex!(`^uniform (\S+) ([a-zA-Z0-9_]+);`); // don't capture array uniforms
			foreach (line; code.split("\n")) {
				line = line.strip();

				const m = matchFirst(line, rgx);
				if (m.empty) continue;
				const type = m[1];
				const ident = m[2];
				if (basicTypes.canFind(type)) {
					declaredUniforms[ident] = defaultForType(type);
				} else {
					template AddUsedDefinedUni(T) {
						enum AddUsedDefinedUni = `
						{
							` ~ T.stringof ~ ` t;
							const values = t.tupleof;
							const fields = __traits(allMembers, ` ~ T.stringof ~ `);
							enum qualifRgx = ctRegex!(r"(?:.*\()?([a-zA-Z0-9]+)(?:.*\))?");
							foreach (idx, val; values) {
								writeln("val is ", typeof(val).stringof);
								// Kick away type qualifiers
								const mm = matchFirst(typeof(val).stringof, qualifRgx);
								if (m.empty)
									declaredUniforms[fields[idx]] = defaultForType(typeof(val).stringof);
								else {
									writeln("matched ", mm[1]);
									declaredUniforms[fields[idx]] = defaultForType(mm[1]);
								}
							}
						}
						`;
					}
					switch (type) {
					case "DirLight": mixin(AddUsedDefinedUni!(DirLight)); break;
					case "AmbientLight": mixin(AddUsedDefinedUni!(AmbientLight)); break;
					case "PointLight": mixin(AddUsedDefinedUni!(DirLight)); break;
					case "Material": mixin(AddUsedDefinedUni!(Material)); break;
					default: assert(0, "unknown uniform type " ~ type);
					}
				}
			}
			writeln("Shader ", name, " defined the following uniforms: ", declaredUniforms);
		}

		Uniform defaultForType(string name) {
			writeln("defaultForType(", name, ")");
			switch (name) {
			case "int": return Uniform(0);
			case "uint": return Uniform(0u);
			case "float": return Uniform(0f);
			case "bool": return Uniform(false);
			case "double": return Uniform(0.0);
			case "vec2": return Uniform(vec2());
			case "vec3": return Uniform(vec3());
			case "vec4": return Uniform(vec4());
			case "mat2": return Uniform(mat2());
			case "mat3": return Uniform(mat3());
			case "mat4": return Uniform(mat4());
			case "sampler2D": return Uniform("sampler2D"); // HACK: use string to symbolize sampler2D type
			default: assert(0, "unknown uniform type " ~ name);
			}
		}
	}
}

/// Sets `shader` as current.
void use(in Shader shader) {
	glUseProgram(shader.id);
}

/// Sets a uniform to `val`.
void setInt(in Shader shader, in string name, inout GLint val) {
	glUniform1i(glGetUniformLocation(shader.id, cast(const(char*))name), val);
}

void setUint(in Shader shader, in string name, inout GLuint val) {
	glUniform1ui(glGetUniformLocation(shader.id, cast(const(char*))name), val);
}

void setFloat(in Shader shader, in string name, inout GLfloat val) {
	glUniform1f(glGetUniformLocation(shader.id, cast(const(char*))name), val);
}

void setVec2(in Shader shader, in string name, inout vec2 val) {
	glUniform2fv(glGetUniformLocation(shader.id, cast(const(char*))name), 1, val.value_ptr);
}

void setVec2(in Shader shader, in string name, inout GLfloat val1, inout GLfloat val2) {
	glUniform2f(glGetUniformLocation(shader.id, cast(const(char*))name), val1, val2);
}

void setVec3(in Shader shader, in string name, inout vec3 val) {
	glUniform3fv(glGetUniformLocation(shader.id, cast(const(char*))name), 1, val.value_ptr);
}

void setVec3(in Shader shader, in string name, inout GLfloat val1, inout GLfloat val2, inout GLfloat val3) {
	glUniform3f(glGetUniformLocation(shader.id, cast(const(char*))name), val1, val2, val3);
}

void setVec4(in Shader shader, in string name, inout vec4 val) {
	glUniform4fv(glGetUniformLocation(shader.id, cast(const(char*))name), 1, val.value_ptr);
}

void setVec3(in Shader shader, in string name, inout GLfloat val1,
		inout GLfloat val2, inout GLfloat val3, inout GLfloat val4)
{
	glUniform4f(glGetUniformLocation(shader.id, cast(const(char*))name), val1, val2, val3, val4);
}

void setMat2(in Shader shader, in string name, inout mat2 val) {
	glUniformMatrix2fv(glGetUniformLocation(shader.id, cast(const(char*))name), 1, GL_TRUE, val.value_ptr);
}

void setMat3(in Shader shader, in string name, inout mat3 val) {
	glUniformMatrix3fv(glGetUniformLocation(shader.id, cast(const(char*))name), 1, GL_TRUE, val.value_ptr);
}

void setMat4(in Shader shader, in string name, inout mat4 val) {
	glUniformMatrix4fv(glGetUniformLocation(shader.id, cast(const(char*))name), 1, GL_TRUE, val.value_ptr);
}

void setUni(in Shader shader, in string name, inout Uniform val) {
	if (val.convertsTo!(GLint) || val.convertsTo!(const GLint))
		setInt(shader, name, val.get!(const GLint));
	else if (val.convertsTo!(GLfloat) || val.convertsTo!(const GLfloat))
		setFloat(shader, name, val.get!(const GLfloat));
	else if (val.convertsTo!(GLdouble) || val.convertsTo!(const GLdouble))
		setFloat(shader, name, val.get!(const GLdouble));
	else if (val.convertsTo!(vec2) || val.convertsTo!(const vec2))
		setVec2(shader, name, val.get!(const vec2));
	else if (val.convertsTo!(vec3) || val.convertsTo!(const vec3))
		setVec3(shader, name, val.get!(const vec3));
	else if (val.convertsTo!(vec4) || val.convertsTo!(const vec4))
		setVec4(shader, name, val.get!(const vec4));
	else if (val.convertsTo!(mat2) || val.convertsTo!(const mat2))
		setMat2(shader, name, val.get!(const mat2));
	else if (val.convertsTo!(mat3) || val.convertsTo!(const mat3))
		setMat3(shader, name, val.get!(const mat3));
	else if (val.convertsTo!(mat4) || val.convertsTo!(const mat4))
		setMat4(shader, name, val.get!(const mat4));
	else assert(0, "Invalid type for uniform " ~ name ~ " of type " ~ val.type.toString() ~ "!");
}

void setMaterialUniforms(in Shader shader, in Material material) {
	shader.setVec3("material.diffuse", material.diffuse);
	shader.setVec3("material.specular", material.specular);
	shader.setFloat("material.shininess", material.shininess);
}

private void checkErr(string type, A...)(uint _id, A codes) {
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
