module gadget.rendering.material;

import std.conv: to;
import gl3n.linalg;

enum GenMaterial = q{
	struct Material {
		vec3 diffuse;
		vec3 specular;
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

enum MATERIAL_HEADER = `
#version 330 core

#define MAX_POINT_LIGHTS ` ~to!string(MAX_POINT_LIGHTS) ~ `

` ~ GenMaterial ~ `
` ~ GenPointLight ~ `
` ~ GenDirLight ~ `
` ~ GenAmbientLight;
