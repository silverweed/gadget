module gadget.rendering.camera;

debug import std.stdio;
import std.math;
import gl3n.linalg;

enum Direction {
	FWD, BACK, LEFT, RIGHT
}

class Camera {
	this(in vec3 position = vec3(0, 0, 0)) {
		this.position = position;
		updateVecs();
	}

	@property vec3 up() pure const { return _up; }
	@property vec3 front() pure const { return _front; }
	@property vec3 right() pure const { return _right; }
	
	vec3 worldUp = vec3(0, 1, 0);
	vec3 position;
	float yaw = -PI/2;
	float pitch = 0;
	float sensitivity = 0.003;
	float fov = 45;
	float moveSpeed = 6f;
	float width = 6f;
	float height = 6f;
	float near = 0.1;
	float far = 5000f;
	private {
		vec3 _up;
		vec3 _front;
		vec3 _right;
	}

	package void updateVecs() {
		_front = vec3(
			cos(yaw) * cos(pitch),
			sin(pitch),
			sin(yaw) * cos(pitch)
		).normalized;
		_right = cross(front, worldUp).normalized;
		_up = cross(right, front).normalized;
	}
}

mat4 viewMatrix(const Camera camera) pure {
	return mat4.look_at(camera.position, camera.position + camera.front, camera.up);
}

mat4 projMatrix(const Camera camera) pure {
	return mat4.perspective(camera.width, camera.height, camera.fov, camera.near, camera.far);
}

void move(Camera camera, Direction dir, float dt = 1/60.0) {
	immutable v = camera.moveSpeed * dt;
	final switch (dir) {
	case Direction.FWD:
		camera.position += camera.front * v;
		break;
	case Direction.BACK:
		camera.position -= camera.front * v;
		break;
	case Direction.LEFT:
		camera.position -= camera.right * v;
		break;
	case Direction.RIGHT:
		camera.position += camera.right * v;
		break;
	}
}

void turn(Camera camera, int xoff, int yoff, bool constrainPitch = true) {
	camera.yaw += camera.sensitivity * xoff;
	camera.pitch += camera.sensitivity * yoff;
	if (constrainPitch) {
		if (camera.pitch > PI)
			camera.pitch = PI;
		else if (camera.pitch < -PI)
			camera.pitch = -PI;
	}
	camera.updateVecs();
}

void zoom(Camera camera, int delta) {
	camera.fov -= delta;
	if (camera.fov < 1)
		camera.fov = 1;
	else if (camera.fov > 45)
		camera.fov = 45;
}

