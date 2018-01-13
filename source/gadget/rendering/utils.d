module gadget.rendering.utils;

import std.math;
import gl3n.linalg;

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

auto add(T, int N)(in Vector!(T, N) a, in Vector!(T, N) b) pure if (N >= 2 && N <= 4) {
	Vector!(T, N) r;
	r.x = a.x + b.x;
	r.y = a.y + b.y;
	static if (N > 2) {
		r.z = a.z + b.z;
		static if (N > 3) {
			r.w = a.w + b.w;
		}
	}
	return r;
}

auto neg(T, int N)(in Vector!(T, N) a) pure if (N >= 2 && N <= 4) {
	Vector!(T, N) r;
	r.x = -a.x;
	r.y = -a.y;
	static if (N > 2) {
		r.z = -a.z;
		static if (N > 3) {
			r.w = -a.w;
		}
	}
	return r;
}
