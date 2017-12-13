module gadget.rendering.material;

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
