module gadget.rendering.defaultShaders;

import std.conv;
import gadget.rendering.material;

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
	vec3 addAmbientLight(in AmbientLight light, in vec3 objDiffuse) {
		return light.strength * light.color * objDiffuse;
	}
};

enum fi_addPointLight = q{
	vec3 addPointLight(in PointLight light, in vec3 objDiffuse, in vec3 objSpecular) {
		// diffuse
		vec3 norm = normalize(fs_in.normal);
		vec3 fragToLight = light.position - fs_in.fragPos;
		vec3 lightDir = normalize(fragToLight);
		float diff = max(dot(norm, lightDir), 0.0);
		vec3 diffuse = diff * light.diffuse * objDiffuse;

		// specular
		vec3 viewDir = normalize(viewPos - fs_in.fragPos);
		vec3 halfDir = normalize(lightDir + viewDir);
		float spec = pow(max(dot(halfDir, norm), 0.0), material.shininess);
		vec3 specular = objSpecular * spec * light.diffuse;

		vec3 result = diffuse + specular;

		// attenuation
		float dist = length(fragToLight);
		float atten = 1.0 / (1.0 + light.attenuation * dist * dist);

		return result * atten;
	}
};

enum fi_addDirLight = q{
	vec3 addDirLight(in DirLight light, in vec3 objDiffuse, in vec3 objSpecular) {
		// diffuse
		vec3 norm = normalize(fs_in.normal);
		vec3 lightDir = normalize(-light.direction);
		float diff = max(dot(norm, lightDir), 0.0);
		vec3 diffuse = diff * light.diffuse * objDiffuse;

		// specular
		vec3 viewDir = normalize(viewPos - fs_in.fragPos);
		vec3 halfDir = normalize(lightDir + viewDir);
		float spec = pow(max(dot(halfDir, norm), 0.0), material.shininess);
		vec3 specular = objSpecular * spec * light.diffuse;

		vec3 result = diffuse + specular;

		return result;
	}
};

enum f_calcShadow = q{
	float calcShadow(vec4 lightSpaceFragPos) {
		// Perform perspective divide (maps coords to [-1, 1])
		vec3 projCoords = lightSpaceFragPos.xyz / lightSpaceFragPos.w;
		// Transform [-1, 1] -> [0, 1] to sample from the depth map
		projCoords = projCoords * 0.5 + 0.5;
		// Find closest depth by sampling a texel from the depth map
		float closestDepth = texture(depthMap, projCoords.xy).r;
		float curDepth = projCoords.z;

		// Compare depth of this fragment with the one sampled from the shadow map
		// Use PCF to smooth shadows
		const int PCF_OFF = 1;
		float bias = max(0.005, 0.05 * (1.0 - dot(normalize(fs_in.normal), -dirLight.direction)));
		float shadow = 0.0;
		vec2 texelSize = 1.0 / textureSize(depthMap, 0);
		for (int x = -PCF_OFF; x <= PCF_OFF; ++x) {
			for (int y = -PCF_OFF; y <= PCF_OFF; ++y) {
				float pcfDepth = texture(depthMap, projCoords.xy + vec2(x, y) * texelSize).r;
				shadow += float(curDepth - bias > pcfDepth);
			}
		}
		shadow /= pow(2.0 * PCF_OFF + 1.0, 2.0);

		return float(projCoords.z <= 1.0) * shadow;
	}
};

enum f_calcPointShadow = q{
	float calcPointShadow(vec3 fragPos, vec3 lightPos) {
		// get vector between fragment position and light position
		vec3 fragToLight = fragPos - lightPos;
		// use the light to fragment vector to sample from the depth map
		float closestDepth = texture(cubeDepthMap, fragToLight).r;
		// it is currently in linear range between [0,1]. Re-transform back to original value
		closestDepth *= far;
		// now get current linear depth as the length between the fragment and light position
		float currentDepth = length(fragToLight);
		// now test for shadows
		const float bias = 0.05;
		float shadow = currentDepth -  bias > closestDepth ? 1.0 : 0.0;

		return shadow;
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

enum fs_blinnPhong = MATERIAL_HEADER ~ q{

	out vec4 fragColor;

	in VS_OUT {
		vec3 fragPos;
		vec3 normal;
		vec2 texCoord;
	} fs_in;

	uniform vec3 viewPos;
	uniform PointLight pointLight[MAX_POINT_LIGHTS];
	uniform int nPointLights;
	uniform DirLight dirLight;
	uniform AmbientLight ambientLight;
	uniform Material material;

} ~ f_addAmbientLight ~ f_addPointLight ~ f_addDirLight ~ q{

	void main() {
		vec3 result = addAmbientLight(ambientLight);
		for (int i = 0; i < MAX_POINT_LIGHTS; ++i)
			result += addPointLight(pointLight[i]);
		result += addDirLight(dirLight);

		fragColor = vec4(result, 1.0);
	}
};

enum vs_posNormTexInstanced = MATERIAL_HEADER ~ q{

	layout (location = 0) in vec3 aPos;
	layout (location = 1) in vec3 aNormal;
	layout (location = 2) in vec2 aTexCoord;
	layout (location = 3) in mat4 aInstanceModel;
	// location = 4 aInstanceModel
	// location = 5 aInstanceModel
	// location = 6 aInstanceModel
	layout (location = 7) in vec3 aTangent;

	uniform mat4 vp;
	uniform mat4 lightVP;

	out VS_OUT {
		vec3 fragPos;
		vec3 normal;
		vec2 texCoord;
		vec3 tangent;
		vec4 lightSpaceFragPos;
	} vs_out;

	void main() {
		vs_out.fragPos = vec3(aInstanceModel * vec4(aPos, 1.0));
		vs_out.normal = mat3(transpose(inverse(aInstanceModel))) * aNormal;
		vs_out.texCoord = aTexCoord;
		vs_out.tangent = aTangent;
		vs_out.lightSpaceFragPos = lightVP * vec4(vs_out.fragPos, 1.0);
		gl_Position = vp * aInstanceModel * vec4(aPos, 1.0);
	}
};

enum fs_blinnPhongInstanced = MATERIAL_HEADER ~ q{

	layout (location = 0) out vec4 fragColor;
	layout (location = 1) out vec4 brightColor;

	in VS_OUT {
		vec3 fragPos;
		vec3 normal;
		vec2 texCoord;
		vec3 tangent;
		vec4 lightSpaceFragPos;
	} fs_in;

	uniform vec3 viewPos;
	uniform PointLight pointLight[MAX_POINT_LIGHTS];
	uniform DirLight dirLight;
	uniform AmbientLight ambientLight;
	uniform float far;
	uniform bool False;

	uniform sampler2D depthMap;
	uniform samplerCube cubeDepthMap;
	uniform Material material;

} ~ fi_addAmbientLight ~ fi_addPointLight ~ fi_addDirLight ~ f_calcShadow ~ f_calcPointShadow  ~ q{

	void main() {
		vec3 objDiffuse = texture(material.diffuse, fs_in.texCoord).rgb;
		vec3 objSpecular = texture(material.specular, fs_in.texCoord).rrr;

		vec3 result = vec3(0.0);
		for (int i = 0; i < MAX_POINT_LIGHTS; ++i)
			result += addPointLight(pointLight[i], objDiffuse, objSpecular);
		result += addDirLight(dirLight, objDiffuse, objSpecular);

		float shadow = calcShadow(fs_in.lightSpaceFragPos);
		//float shadow = calcPointShadow(fs_in.fragPos, pointLight[0].position);
		result = result * (1.0 - shadow) + addAmbientLight(ambientLight, objDiffuse);

		//vec3 fragToLight = (fs_in.fragPos - pointLight[0].position);
		//float closestDepth = texture(cubeDepthMap, fragToLight).r;
		if (False)
			fragColor = vec4(result, 1.0);
		else
			fragColor = vec4(fs_in.tangent, 1.0);
			//fragColor = vec4(vec3(closestDepth), 1.0);
		//fragColor = vec4(fs_in.texCoord.x, fs_in.texCoord.y, 0, 1.0);

		float brightness = dot(fragColor.rgb, vec3(0.2126, 0.7152, 0.0722));
		brightColor = vec4(float(brightness > 1.0) * fragColor.rgb, 1.0);
	}
};

enum vs_billboardQuad = MATERIAL_HEADER ~ q{

	layout (location = 0) in vec3 aPos;

	uniform mat4 mvp;
	uniform vec3 color;

	out VS_OUT {
		vec4 center;
		vec3 color;
	} vs_out;

	void main() {
		vs_out.color = color;
		vs_out.center = gl_Position;
		gl_Position = mvp * vec4(aPos, 1.0);
	}
};

enum vs_billboardQuadInstanced = MATERIAL_HEADER ~ q{

	layout (location = 0) in vec3 aPos;
	layout (location = 1) in vec3 aColor;
	layout (location = 2) in mat4 aInstanceModel;
	// (location = 3) aInstanceModel
	// (location = 4) aInstanceModel
	// (location = 5) aInstanceModel

	uniform mat4 vp;

	out VS_OUT {
		vec4 center;
		vec3 color;
	} vs_out;

	void main() {
		vs_out.color = aColor;
		vs_out.center = gl_Position;
		gl_Position = vp * aInstanceModel * vec4(aPos, 1.0);
	}
};

enum gs_billboardQuad = MATERIAL_HEADER ~ q{

	layout (points) in;
	layout (triangle_strip, max_vertices = 4) out;

	in VS_OUT {
		vec4 center;
		vec3 color;
	} gs_in[];

	out VS_OUT {
		vec4 center;
		vec3 color;
	} gs_out;

	uniform float radius;

	void main() {
		vec4 center = gl_in[0].gl_Position;
		gl_Position = center + vec4(radius, -radius, 0.0, 0.0);
		gs_out.center = gs_in[0].center;
		gs_out.color = gs_in[0].color;
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

	in VS_OUT {
		vec4 center;
		vec3 color;
	} fs_in;

	out vec4 fragColor;

	uniform float radius;
	uniform float scrWidth;
	uniform float scrHeight;

	void main() {
		fragColor = vec4(fs_in.color, 1.0);
	}
};

enum vs_screenQuad = MATERIAL_HEADER ~ q{

	layout (location = 0) in vec2 aPos;
	layout (location = 1) in vec2 aTexCoords;

	out vec2 texCoords;

	void main() {
		gl_Position = vec4(aPos.xy, 0.0, 1.0);
		texCoords = aTexCoords;
	}
};

enum fs_screenQuad = MATERIAL_HEADER ~ q{

	out vec4 fragColor;

	in vec2 texCoords;

	uniform sampler2D screenTex;

	void main() {
		fragColor = texture(screenTex, texCoords);
	}
};

enum fs_viewDepth = MATERIAL_HEADER ~ q{

	out vec4 fragColor;

	in vec2 texCoords;

	uniform sampler2D depthMap;

	void main() {
		float depthVal = texture(depthMap, texCoords).r;
		fragColor = vec4(vec3(depthVal), 1.0);
	}
};

enum vs_skybox = MATERIAL_HEADER ~ q{

	layout (location = 0) in vec3 aPos;

	out vec3 texCoords;

	uniform mat4 vp;

	void main() {
		texCoords = aPos;
		vec4 pos = vp * vec4(aPos, 1.0);
		gl_Position = pos.xyww; // make z always be max (1.0)
	}
};

enum fs_skybox = MATERIAL_HEADER ~ q{

	out vec4 fragColor;

	in vec3 texCoords;

	uniform samplerCube skybox;

	void main() {
		fragColor = texture(skybox, texCoords);
	}
};
