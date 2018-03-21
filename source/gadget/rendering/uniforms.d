module gadget.rendering.uniforms;

import std.string;
import derelict.opengl;
import gl3n.linalg;
import gl3n.math;
import gadget.rendering.world;
import gadget.rendering.utils;
import gadget.rendering.camera;
import gadget.rendering.mesh;
import gadget.rendering.material;
import gadget.rendering.shadows;
import gadget.rendering.shader;

// Functions that set uniforms.

/// Sets the camera-related uniforms to all objects' and skybox's shaders.
void setCamera(World world, in Camera camera) {
	foreach (obj; world.objects) {
		obj.setCameraUniforms(obj.shader, camera);
	}

	if (world.skybox.shader !is null) {
		auto sh = world.skybox.shader;
		sh.uniforms["vp"] = camera.projMatrix * mat4(mat3(camera.viewMatrix));
	}
}

/// Sets the "base" uniforms
void setBaseUniforms(World world, Shader shader) {
	shader.uniforms["ambientLight.color"] = world.ambientLight.color;
	shader.uniforms["ambientLight.strength"] = world.ambientLight.strength;
	shader.uniforms["dirLight.direction"] = world.dirLight.direction;
	shader.uniforms["dirLight.diffuse"] = world.dirLight.diffuse;
	shader.uniforms["nPointLights"] = cast(GLuint)world.pointLights.length;
	foreach (i, pl; world.pointLights) {
		shader.uniforms["pointLight[%d].position".format(i)] = pl.position;
		shader.uniforms["pointLight[%d].diffuse".format(i)] = pl.diffuse;
		shader.uniforms["pointLight[%d].attenuation".format(i)] = pl.attenuation;
	}
}

void setLightVPUniform(Shader shader, DirLight light) {
	// XXX: These values are blindly guessed
	enum near = 1.0;
	enum far = 50.0;
	enum w = 20;
	enum h = 20;

	const lightProj = mat4.orthographic(-w, w, -h, h, near, far);
	//const lightProj = mat4.perspective(-w, w, -h, h, near, far);
	const lightView = mat4.look_at(-10 * light.direction, vec3(0, 0, 0), vec3(0, 1, 0));

	shader.uniforms["lightVP"] = lightProj * lightView;
	shader.uniforms["lightPos"] = -10*light.direction;
}

void setPointLightShadowUniforms(Shader shader, PointLight light, DepthMap depthMap) {
	enum near = 0.5;
	enum far = 25.0;
	enum w = 50;
	enum h = 50;

	const lightProj = mat4.perspective(w, h, radians(90), near, far);
	const shadowTransforms = [
		lightProj * mat4.look_at(light.position, light.position + vec3(1, 0, 0), vec3(0, -1, 0)),
		lightProj * mat4.look_at(light.position, light.position + vec3(-1, 0, 0), vec3(0, -1, 0)),
		lightProj * mat4.look_at(light.position, light.position + vec3(0, 1, 0), vec3(0, 0, 1)),
		lightProj * mat4.look_at(light.position, light.position + vec3(0, -1, 0), vec3(0, 0, -1)),
		lightProj * mat4.look_at(light.position, light.position + vec3(0, 0, 1), vec3(0, -1, 0)),
		lightProj * mat4.look_at(light.position, light.position + vec3(0, 0, -1), vec3(0, -1, 0)),
	];

	for (int i = 0; i < 6; ++i)
		shader.uniforms["shadowTransforms[%d]".format(i)] = shadowTransforms[i];
	shader.uniforms["lightPos"] = light.position;
	shader.uniforms["far"] = far;
}

void setCameraUniforms(Mesh mesh, Shader shader, in Camera camera) {
	const t = mesh.transform;
	const model = mat4.identity
			.scale(t.scale.x, t.scale.y, t.scale.z)
			.rotate(t.rotation.alpha, t.rotation.axis)
			.translate(t.position);
	shader.uniforms["viewPos"] = camera.position;
	const vp = camera.projMatrix * camera.viewMatrix;
	shader.uniforms["vp"] = vp;
	shader.uniforms["mvp"] = vp * model;
	shader.uniforms["far"] = camera.far;
}

