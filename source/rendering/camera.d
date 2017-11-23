module gadget.rendering.camera;

debug import std.stdio;
import std.math;
import gl3n.linalg;

enum Direction {
	FWD, BACK, LEFT, RIGHT
}

class Camera {
	this(in vec3 position = vec3(0, 0, 0), in vec3 worldUp = vec3(0, 1, 0)) {
		this.position = position;
		this.worldUp = worldUp;
		updateVecs();
	}

	mat4 viewMatrix() const {
		return mat4.look_at(position, position + front, up);
	}

	void move(Direction dir, float dt) {
		immutable v = moveSpeed * dt;
		final switch (dir) {
		case Direction.FWD:
			position += front * v;
			break;
		case Direction.BACK:
			position -= front * v;
			break;
		case Direction.LEFT:
			position -= right * v;
			break;
		case Direction.RIGHT:
			position += right * v;
			break;
		}
	}

	void turn(int xoff, int yoff, bool constrainPitch = true) {
		yaw += sensitivity * xoff;
		pitch += sensitivity * yoff;
		if (constrainPitch) {
			if (pitch > PI)
				pitch = PI;
			else if (pitch < -PI)
				pitch = -PI;
		}
		updateVecs();
	}

	void zoom(int delta) {
		fov -= delta;
		if (fov < 1)
			fov = 1;
		else if (fov > 45)
			fov = 45;
	}

	private void updateVecs() {
		front = vec3(
			cos(yaw) * cos(pitch),
			sin(pitch),
			sin(yaw) * cos(pitch)
		).normalized;
		right = cross(front, worldUp).normalized;
		up = cross(right, front).normalized;
	}

	vec3 position;
	vec3 up;
	vec3 front;
	vec3 right;
	const vec3 worldUp;
	float yaw = -PI/2;
	float pitch = 0;
	float sensitivity = 0.003;
	float fov = 45;
	float moveSpeed = 4f;
}
