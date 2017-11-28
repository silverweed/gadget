module gadget.rendering.material;

import gl3n.linalg;

template GenMaterial() {
	enum GenMaterial = q{
		struct Material {
			vec3 diffuse;
			vec3 specular;
			float shininess;
		};
	};
}

template GenPointLight() {
	enum GenPointLight = q{
		struct PointLight {
			vec3 position;
			vec3 diffuse;
			float attenuation;
		};
	};
}

template GenDirLight() {
	enum GenDirLight = q{
		struct DirLight {
			vec3 direction;
			vec3 diffuse;
		};
	};
}

template GenAmbientLight() {
	enum GenAmbientLight = q{
		struct AmbientLight {
			vec3 color;
			float strength;
		};
	};
}

mixin(GenMaterial!());
mixin(GenPointLight!());
mixin(GenDirLight!());
mixin(GenAmbientLight!());
