module gadget.rendering.utils;

import std.math;
import gl3n.linalg : quat, vec3;

enum NULL = cast(int*)0;

auto alpha(in quat q) pure {
	return 2 * acos(q.w);
}

auto axis(in quat q) pure {
	if (q.w == 1)
		return vec3(1, 0, 0); // axis not important when rotation is 0
	const d = sqrt(1 - q.w * q.w);
	return vec3(q.x / d, q.y / d, q.z / d);
}

quat to_quat(float yaw, float pitch, float roll) pure {
	return quat.euler_rotation(yaw, pitch, roll).normalized();
}
