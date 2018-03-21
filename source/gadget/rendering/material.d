module gadget.rendering.material;

import std.conv: to;
import gl3n.linalg;

alias sampler2D = int;

enum GenMaterial = q{
	struct Material {
		sampler2D diffuse;
		sampler2D specular;
		sampler2D normal;
		sampler2D displacement;
		float shininess;
	};
};

enum GenPointLight = q{
	struct PointLight {
		vec3 position;
		vec3 diffuse;
		float attenuation;
	};
};

enum GenDirLight = q{
	struct DirLight {
		vec3 direction;
		vec3 diffuse;
	};
};

enum GenAmbientLight = q{
	struct AmbientLight {
		vec3 color;
		float strength;
	};
};

mixin(GenMaterial);
mixin(GenPointLight);
mixin(GenDirLight);
mixin(GenAmbientLight);

/// Maximum number of point lights supported in default shaders
enum MAX_POINT_LIGHTS = 10;

enum SHADER_HEADER = `
#version 330 core

#define MAX_POINT_LIGHTS ` ~to!string(MAX_POINT_LIGHTS) ~ `

` ~ GenMaterial ~ `
` ~ GenPointLight ~ `
` ~ GenDirLight ~ `
` ~ GenAmbientLight;
