module gadget.rendering.defaultShaders;

enum vs_posNormTex = q{
	#version 330 core

	layout (location = 0) in vec3 aPos;
	layout (location = 1) in vec3 aNormal;
	layout (location = 2) in vec2 aTexCoord;

	uniform mat4 model;
	uniform mat4 mvp;

	out VS_OUT {
		vec3 fragPos;
		vec3 normal;
		vec2 texCoord;
	} vs_out;

	void main() {
		vs_out.normal = mat3(transpose(inverse(model))) * aNormal;
		vs_out.texCoord = aTexCoord;
		vs_out.fragPos = vec3(model * vec4(aPos, 1.0));
		gl_Position = mvp * vec4(aPos, 1.0);
	}
};

enum vs_posNormTexInstanced = q{
	#version 330 core

	layout (location = 0) in vec3 aPos;
	layout (location = 1) in vec3 aNormal;
	layout (location = 2) in vec2 aTexCoord;
	layout (location = 3) in mat4 aInstanceModel;
	// location = 4 instanceModel
	// location = 5 instanceModel
	// location = 6 instanceModel
	layout (location = 7) in vec3 aColor;

	uniform mat4 vp;

	out VS_OUT {
		vec3 fragPos;
		vec3 normal;
		vec2 texCoord;
		vec3 color;
	} vs_out;

	void main() {
		vs_out.normal = mat3(transpose(inverse(aInstanceModel))) * aNormal;
		vs_out.texCoord = aTexCoord;
		vs_out.fragPos = vec3(aInstanceModel * vec4(aPos, 1.0));
		vs_out.color = aColor;
		gl_Position = vp * aInstanceModel * vec4(aPos, 1.0);
	}
};

enum fs_blinnPhong = q{
	#version 330 core

	out vec4 fragColor;

	in VS_OUT {
		vec3 fragPos;
		vec3 normal;
		vec2 texCoord;
	} fs_in;

	uniform vec3 color;
	uniform vec3 viewPos;
	uniform vec3 lightPos;
	uniform vec3 lightColor;
	uniform float specularStrength;

	void main() {
		// ambient
		float ambientStrength = 0.2;
		vec3 ambient = ambientStrength * lightColor;

		// diffuse
		vec3 norm = normalize(fs_in.normal);
		vec3 lightDir = normalize(lightPos - fs_in.fragPos);
		float diff = max(dot(norm, lightDir), 0.0);
		vec3 diffuse = diff * lightColor;

		// specular
		vec3 viewDir = normalize(viewPos - fs_in.fragPos);
		vec3 halfDir = normalize(lightDir + viewDir);
		float spec = pow(max(dot(halfDir, norm), 0.0), 16);
		vec3 specular = specularStrength * spec * lightColor;

		vec3 result = (ambient + diffuse + specular) * color;
		fragColor = vec4(result, 1.0);
	}
};

enum fs_blinnPhongInstanced = q{
	#version 330 core

	out vec4 fragColor;

	in VS_OUT {
		vec3 fragPos;
		vec3 normal;
		vec2 texCoord;
		vec3 color;
	} fs_in;

	uniform vec3 viewPos;
	uniform vec3 lightPos;
	uniform vec3 lightColor;
	uniform float specularStrength;

	void main() {
		// ambient
		float ambientStrength = 0.2;
		vec3 ambient = ambientStrength * lightColor;

		// diffuse
		vec3 norm = normalize(fs_in.normal);
		vec3 lightDir = normalize(lightPos - fs_in.fragPos);
		float diff = max(dot(norm, lightDir), 0.0);
		vec3 diffuse = diff * lightColor;

		// specular
		vec3 viewDir = normalize(viewPos - fs_in.fragPos);
		vec3 halfDir = normalize(lightDir + viewDir);
		float spec = pow(max(dot(halfDir, norm), 0.0), 16);
		vec3 specular = specularStrength * spec * lightColor;

		vec3 result = (ambient + diffuse + specular) * fs_in.color;
		fragColor = vec4(result, 1.0);
	}
};
