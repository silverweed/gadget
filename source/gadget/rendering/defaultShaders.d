module gadget.rendering.defaultShaders;

import gadget.rendering.material;

enum MATERIAL_HEADER = `
	#version 330 core

` ~ GenMaterial ~ `
` ~ GenPointLight ~ `
` ~ GenDirLight ~ `
` ~ GenAmbientLight;

enum f_addAmbientLight = q{
	vec3 addAmbientLight(in AmbientLight light) {
		return light.strength * light.color * material.diffuse;
	}
};

enum f_addPointLight = q{
	vec3 addPointLight(in PointLight light) {
		// diffuse
		vec3 norm = normalize(fs_in.normal);
		vec3 fragToLight = light.position - fs_in.fragPos;
		vec3 lightDir = normalize(fragToLight);
		float diff = max(dot(norm, lightDir), 0.0);
		vec3 diffuse = diff * light.diffuse;

		// specular
		vec3 viewDir = normalize(viewPos - fs_in.fragPos);
		vec3 halfDir = normalize(lightDir + viewDir);
		float spec = pow(max(dot(halfDir, norm), 0.0), 16);
		vec3 specular = material.shininess * spec * light.diffuse;

		vec3 result = diffuse * material.diffuse + specular * material.specular;
		
		// attenuation
		float dist = length(fragToLight);
		float atten = 1.0 / (1.0 + light.attenuation * dist * dist);

		return result * atten;
	}
};

enum f_addDirLight = q{
	vec3 addDirLight(in DirLight light) {
		// diffuse
		vec3 norm = normalize(fs_in.normal);
		vec3 lightDir = normalize(-light.direction);
		float diff = max(dot(norm, lightDir), 0.0);
		vec3 diffuse = diff * light.diffuse;

		// specular
		vec3 viewDir = normalize(viewPos - fs_in.fragPos);
		vec3 halfDir = normalize(lightDir + viewDir);
		float spec = pow(max(dot(halfDir, norm), 0.0), 16);
		vec3 specular = material.shininess * spec * light.diffuse;

		vec3 result = diffuse * material.diffuse + specular * material.specular;
		
		return result;
	}
};

/// Instanced version
enum fi_addAmbientLight = q{
	vec3 addAmbientLight(in AmbientLight light) {
		return light.strength * light.color * fs_in.color;
	}
};

enum fi_addPointLight = q{
	vec3 addPointLight(in PointLight light) {
		// diffuse
		vec3 norm = normalize(fs_in.normal);
		vec3 fragToLight = light.position - fs_in.fragPos;
		vec3 lightDir = normalize(fragToLight);
		float diff = max(dot(norm, lightDir), 0.0);
		vec3 diffuse = diff * light.diffuse;

		// specular
		vec3 viewDir = normalize(viewPos - fs_in.fragPos);
		vec3 halfDir = normalize(lightDir + viewDir);
		float spec = pow(max(dot(halfDir, norm), 0.0), 16);
		vec3 specular = specularStrength * spec * light.diffuse;

		vec3 result = (diffuse + specular) * fs_in.color;
		
		// attenuation
		float dist = length(fragToLight);
		float atten = 1.0 / (1.0 + light.attenuation * dist * dist);

		return result * atten;
	}
};

enum fi_addDirLight = q{
	vec3 addDirLight(in DirLight light) {
		// diffuse
		vec3 norm = normalize(fs_in.normal);
		vec3 lightDir = normalize(-light.direction);
		float diff = max(dot(norm, lightDir), 0.0);
		vec3 diffuse = diff * light.diffuse;

		// specular
		vec3 viewDir = normalize(viewPos - fs_in.fragPos);
		vec3 halfDir = normalize(lightDir + viewDir);
		float spec = pow(max(dot(halfDir, norm), 0.0), 16);
		vec3 specular = specularStrength * spec * light.diffuse;

		vec3 result = (diffuse + specular) * fs_in.color;
		
		return result;
	}
};

//////////////////////////////////////////////

enum vs_posNormTex = MATERIAL_HEADER ~ q{

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

enum vs_posNormTexInstanced = MATERIAL_HEADER ~ q{

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

enum fs_blinnPhong = MATERIAL_HEADER ~ q{

	out vec4 fragColor;

	in VS_OUT {
		vec3 fragPos;
		vec3 normal;
		vec2 texCoord;
	} fs_in;

	uniform vec3 viewPos;
	uniform PointLight pointLight;
	uniform DirLight dirLight;
	uniform AmbientLight ambientLight;
	uniform Material material;

} ~ f_addAmbientLight ~ f_addPointLight ~ f_addDirLight ~ q{

	void main() {
		vec3 result = addAmbientLight(ambientLight);
		result += addPointLight(pointLight);
		result += addDirLight(dirLight);

		fragColor = vec4(result, 1.0);
	}
};

enum fs_blinnPhongInstanced = MATERIAL_HEADER ~ q{

	out vec4 fragColor;

	in VS_OUT {
		vec3 fragPos;
		vec3 normal;
		vec2 texCoord;
		vec3 color;
	} fs_in;

	uniform vec3 viewPos;
	uniform float specularStrength;
	uniform PointLight pointLight;
	uniform DirLight dirLight;
	uniform AmbientLight ambientLight;

} ~ fi_addAmbientLight ~ fi_addPointLight ~ fi_addDirLight ~ q{

	void main() {
		vec3 result = addAmbientLight(ambientLight);
		result += addPointLight(pointLight);
		result += addDirLight(dirLight);

		fragColor = vec4(result, 1.0);
	}
};

enum vs_billboardQuad = MATERIAL_HEADER ~ q{

	layout (location = 0) in vec3 aPos;

	uniform mat4 mvp;

	out vec4 center;

	void main() {
		gl_Position = mvp * vec4(aPos, 1.0);
		center = gl_Position;
	}
};

enum gs_billboardQuad = MATERIAL_HEADER ~ q{

	layout (points) in;
	layout (triangle_strip, max_vertices = 4) out;

	uniform float radius;

	void main() {
		vec4 center = gl_in[0].gl_Position;
		gl_Position = center + vec4(radius, -radius, 0.0, 0.0);
		EmitVertex();
		gl_Position = center + vec4(-radius, -radius, 0.0, 0.0);
		EmitVertex();
		gl_Position = center + vec4(radius, radius, 0.0, 0.0);
		EmitVertex();
		gl_Position = center + vec4(-radius, radius, 0.0, 0.0);
		EmitVertex();
		EndPrimitive();
	}
};

enum fs_billboardQuad = MATERIAL_HEADER ~ q{

	in vec4 center;

	out vec4 fragColor;

	uniform float radius;
	uniform float scrWidth;
	uniform float scrHeight;
	uniform Material material;

	void main() {
		fragColor = vec4(material.diffuse, 1.0);
	}
};
