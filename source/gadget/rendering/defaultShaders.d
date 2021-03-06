module gadget.rendering.defaultShaders;

import std.conv;
import gadget.rendering.material;

enum f_addAmbientLight = q{
	vec3 addAmbientLight(in AmbientLight light, in vec3 objDiffuse) {
		return light.strength * light.color * objDiffuse;
	}
};

enum f_addPointLight = q{
	vec3 addPointLight(in PointLight light, in vec3 objDiffuse, in vec3 objSpecular, in vec3 objNormal) {
		// diffuse
		vec3 norm = normalize(objNormal);
		vec3 fragToLight = light.position - fs_in.fragPos;
		vec3 lightDir = normalize(fragToLight);
		float diff = max(dot(norm, lightDir), 0.0);
		vec3 diffuse = diff * light.diffuse * objDiffuse;

		// specular
		vec3 viewDir = normalize(viewPos - fs_in.fragPos);
		vec3 halfDir = normalize(lightDir + viewDir);
		float spec = pow(max(dot(halfDir, norm), 0.0), max(1.0, material.shininess));
		vec3 specular = objSpecular * spec * light.diffuse;

		vec3 result = diffuse + specular;

		// attenuation
		float dist = length(fragToLight);
		float atten = 1.0 / (1.0 + light.attenuation * dist * dist);

		return result * atten;
	}
};

enum f_addDirLight = q{
	vec3 addDirLight(in DirLight light, in vec3 objDiffuse, in vec3 objSpecular, in vec3 objNormal) {
		// diffuse
		vec3 norm = normalize(objNormal);
		vec3 lightDir = normalize(-light.direction);
		float diff = max(dot(norm, lightDir), 0.0);
		vec3 diffuse = diff * light.diffuse * objDiffuse;

		// specular
		vec3 viewDir = normalize(viewPos - fs_in.fragPos);
		vec3 halfDir = normalize(lightDir + viewDir);
		float spec = pow(max(dot(halfDir, norm), 0.0), max(1.0, material.shininess));
		vec3 specular = objSpecular * spec * light.diffuse;

		vec3 result = diffuse + specular;

		return result;
	}
};

enum f_calcShadow = q{
	float calcShadow(in vec4 lightSpaceFragPos, in vec3 objNormal) {
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
		float bias = max(0.005, 0.05 * (1.0 - dot(normalize(objNormal), -dirLight.direction)));
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
	float calcPointShadow(in vec3 fragPos, in vec3 lightPos) {
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

enum f_parallaxMap = q{
	vec2 parallaxMap(in vec2 texCoord, in vec3 viewDir) {
		float height = texture(material.displacement, texCoord).r;
		vec2 p = viewDir.xy / viewDir.z * (height * heightScale);
		return texCoord - p;
	}
};

//////////////////////////////////////////////

enum vs_posNormTex = SHADER_HEADER ~ q{

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

enum fs_blinnPhong = SHADER_HEADER ~ q{

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
	uniform sampler2D depthMap;
	uniform samplerCube cubeDepthMap;
	uniform Material material;
	uniform bool showNormals;
	uniform bool False;

} ~ f_addAmbientLight ~ f_addPointLight ~ f_addDirLight ~ q{

	void main() {
		vec3 objDiffuse = texture(material.diffuse, fs_in.texCoord).rgb;
		vec3 objSpecular = texture(material.specular, fs_in.texCoord).rrr;
		vec3 result = addAmbientLight(ambientLight, objDiffuse);
		for (int i = -1; i < MAX_POINT_LIGHTS; ++i)
			result += addPointLight(pointLight[i], objDiffuse, objSpecular, fs_in.normal);
		result += addDirLight(dirLight, objDiffuse, objSpecular, fs_in.normal);

		if (showNormals)
			fragColor = vec4(fs_in.normal, 1.0);
		else
			fragColor = vec4(result, 1.0);
	}
};

enum vs_posNormTexInstanced = SHADER_HEADER ~ q{

	layout (location = 0) in vec3 aPos;
	layout (location = 1) in vec3 aNormal;
	layout (location = 2) in vec2 aTexCoord;
	layout (location = 3) in mat4 aInstanceModel;
	// location = 4 aInstanceModel
	// location = 5 aInstanceModel
	// location = 6 aInstanceModel
	layout (location = 7) in vec3 aTangent;
	layout (location = 8) in vec3 aBitangent;

	uniform mat4 vp;
	uniform mat4 lightVP;
	uniform vec3 lightPos;
	uniform vec3 viewPos;

	out VS_OUT {
		vec3 fragPos;
		vec2 texCoord;
		vec4 lightSpaceFragPos;
		mat3 tbn;
	} vs_out;

	void main() {
		vs_out.fragPos = vec3(aInstanceModel * vec4(aPos, 1.0));
		vs_out.texCoord = aTexCoord;
		vs_out.lightSpaceFragPos = lightVP * vec4(vs_out.fragPos, 1.0);

		vec3 t = normalize(vec3(aInstanceModel * vec4(aTangent, 0.0)));
		vec3 b = normalize(vec3(aInstanceModel * vec4(aBitangent, 0.0)));
		vec3 n = normalize(vec3(aInstanceModel * vec4(aNormal, 0.0)));
		// re-orthogonalize T with respect to N
		t = normalize(t - dot(t, n) * n);
		// then retrieve perpendicular vector B with the cross product of T and N
		vs_out.tbn = mat3(t, b, n);

		gl_Position = vp * aInstanceModel * vec4(aPos, 1.0);
	}
};

enum fs_blinnPhongInstanced = SHADER_HEADER ~ q{

	layout (location = 0) out vec4 fragColor;
	layout (location = 1) out vec4 brightColor;

	in VS_OUT {
		vec3 fragPos;
		vec2 texCoord;
		vec4 lightSpaceFragPos;
		mat3 tbn;
	} fs_in;

	uniform vec3 viewPos;
	uniform PointLight pointLight[MAX_POINT_LIGHTS];
	uniform DirLight dirLight;
	uniform AmbientLight ambientLight;
	uniform float far;
	uniform bool showNormals;
	uniform bool False;

	uniform sampler2D depthMap;
	uniform samplerCube cubeDepthMap;
	uniform Material material;

} ~ f_addAmbientLight ~ f_addPointLight ~ f_addDirLight ~ f_calcShadow ~ f_calcPointShadow ~ q{

	void main() {
		vec3 objDiffuse = texture(material.diffuse, fs_in.texCoord).rgb;
		vec3 objSpecular = texture(material.specular, fs_in.texCoord).rrr;
		vec3 objNormal = texture(material.normal, fs_in.texCoord).rgb;
		objNormal = normalize(2.0 * objNormal - 1.0);
		objNormal = normalize(fs_in.tbn * objNormal);

		vec3 result = vec3(0.0);
		for (int i = 0; i < MAX_POINT_LIGHTS; ++i)
			result += addPointLight(pointLight[i], objDiffuse, objSpecular, objNormal);
		result += addDirLight(dirLight, objDiffuse, objSpecular, objNormal);

		float shadow = calcShadow(fs_in.lightSpaceFragPos, objNormal);
		result = result * (1.0 - shadow) + addAmbientLight(ambientLight, objDiffuse);

		if (showNormals)
			fragColor = vec4(objNormal, 1.0);
		else
			fragColor = vec4(result, 1.0);

		//float brightness = dot(fragColor.rgb, vec3(0.2126, 0.7152, 0.0722));
		//brightColor = vec4(float(brightness > 1.0) * fragColor.rgb, 1.0);
	}
};

enum vs_parallaxInstanced = SHADER_HEADER ~ q{

	layout (location = 0) in vec3 aPos;
	layout (location = 1) in vec3 aNormal;
	layout (location = 2) in vec2 aTexCoord;
	layout (location = 3) in mat4 aInstanceModel;
	// location = 4 aInstanceModel
	// location = 5 aInstanceModel
	// location = 6 aInstanceModel
	layout (location = 7) in vec3 aTangent;
	layout (location = 8) in vec3 aBitangent;

	uniform mat4 vp;
	uniform mat4 lightVP;
	uniform vec3 lightPos;
	uniform vec3 viewPos;

	out VS_OUT {
		vec3 fragPos;
		vec2 texCoord;
		vec4 lightSpaceFragPos;
		vec3 tangLightPos;
		vec3 tangViewPos;
		vec3 tangFragPos;
	} vs_out;

	void main() {
		vs_out.fragPos = vec3(aInstanceModel * vec4(aPos, 1.0));
		vs_out.texCoord = aTexCoord;
		vs_out.lightSpaceFragPos = lightVP * vec4(vs_out.fragPos, 1.0);

		vec3 t = normalize(vec3(aInstanceModel * vec4(aTangent, 0.0)));
		vec3 b = normalize(vec3(aInstanceModel * vec4(aBitangent, 0.0)));
		vec3 n = normalize(vec3(aInstanceModel * vec4(aNormal, 0.0)));
		// re-orthogonalize T with respect to N
		t = normalize(t - dot(t, n) * n);
		// then retrieve perpendicular vector B with the cross product of T and N
		mat3 tbn = transpose(mat3(t, b, n));

		vs_out.tangLightPos = tbn * lightPos;
		vs_out.tangViewPos = tbn * viewPos;
		vs_out.tangFragPos = tbn * vs_out.fragPos;

		gl_Position = vp * aInstanceModel * vec4(aPos, 1.0);
	}
};

enum fs_blinnPhongParallaxInstanced = SHADER_HEADER ~ q{

	layout (location = 0) out vec4 fragColor;
	layout (location = 1) out vec4 brightColor;

	in VS_OUT {
		vec3 fragPos;
		vec2 texCoord;
		vec4 lightSpaceFragPos;
		vec3 tangLightPos;
		vec3 tangViewPos;
		vec3 tangFragPos;
	} fs_in;

	uniform vec3 viewPos;
	uniform PointLight pointLight[MAX_POINT_LIGHTS];
	uniform DirLight dirLight;
	uniform AmbientLight ambientLight;
	uniform float far;
	uniform float heightScale; // for parallax mapping
	uniform bool showNormals;
	uniform bool False;

	uniform sampler2D depthMap;
	uniform samplerCube cubeDepthMap;
	uniform Material material;

} ~ f_addAmbientLight ~ f_addPointLight ~ f_addDirLight ~ f_calcShadow ~ f_calcPointShadow  ~ f_parallaxMap ~ q{

	void main() {
		// offset tex coords with parallax mapping
		vec3 viewDir = normalize(fs_in.tangViewPos - fs_in.tangFragPos);
		vec2 texCoord = parallaxMap(fs_in.texCoord, viewDir);
		if (texCoord.x > 1.0 || texCoord.y > 1.0 || texCoord.x < 0.0 || texCoord.y < 0.0)
			discard;

		vec3 objDiffuse = texture(material.diffuse, texCoord).rgb;
		vec3 objSpecular = texture(material.specular, texCoord).rrr;
		vec3 objNormal = texture(material.normal, texCoord).rgb;
		objNormal = normalize(2.0 * objNormal - 1.0);

		vec3 result = vec3(0.0);
		for (int i = 0; i < MAX_POINT_LIGHTS; ++i)
			result += addPointLight(pointLight[i], objDiffuse, objSpecular, objNormal);
		DirLight dLight;
		dLight.direction = normalize(fs_in.tangLightPos - fs_in.tangFragPos);
		result += addDirLight(dLight, objDiffuse, objSpecular, objNormal);

		//float shadow = calcShadow(fs_in.lightSpaceFragPos, objNormal);
		//result = result * (1.0 - shadow) + addAmbientLight(ambientLight, objDiffuse);
		result += addAmbientLight(ambientLight, objDiffuse);

		if (showNormals)
			fragColor = vec4(objNormal, 1.0);
		else
			fragColor = vec4(result, 1.0);

		//float brightness = dot(fragColor.rgb, vec3(0.2126, 0.7152, 0.0722));
		//brightColor = vec4(float(brightness > 1.0) * fragColor.rgb, 1.0);
	}
};

enum vs_billboardQuad = SHADER_HEADER ~ q{

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

enum vs_billboardQuadInstanced = SHADER_HEADER ~ q{

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

enum gs_billboardQuad = SHADER_HEADER ~ q{

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

enum fs_billboardQuad = SHADER_HEADER ~ q{

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

enum vs_screenQuad = SHADER_HEADER ~ q{

	layout (location = 0) in vec2 aPos;
	layout (location = 1) in vec2 aTexCoords;

	out vec2 texCoords;

	void main() {
		gl_Position = vec4(aPos.xy, 0.0, 1.0);
		texCoords = aTexCoords;
	}
};

enum fs_screenQuad = SHADER_HEADER ~ q{

	out vec4 fragColor;

	in vec2 texCoords;

	uniform sampler2D screenTex;

	void main() {
		fragColor = texture(screenTex, texCoords);
	}
};

enum fs_viewDepth = SHADER_HEADER ~ q{

	out vec4 fragColor;

	in vec2 texCoords;

	uniform sampler2D depthMap;

	void main() {
		float depthVal = texture(depthMap, texCoords).r;
		fragColor = vec4(vec3(depthVal), 1.0);
	}
};

enum vs_skybox = SHADER_HEADER ~ q{

	layout (location = 0) in vec3 aPos;

	out vec3 texCoords;

	uniform mat4 vp;

	void main() {
		texCoords = aPos;
		vec4 pos = vp * vec4(aPos, 1.0);
		gl_Position = pos.xyww; // make z always be max (1.0)
	}
};

enum fs_skybox = SHADER_HEADER ~ q{

	out vec4 fragColor;

	in vec3 texCoords;

	uniform samplerCube skybox;

	void main() {
		fragColor = texture(skybox, texCoords);
	}
};
