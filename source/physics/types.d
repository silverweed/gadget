module gadget.types;

import std.variant;

alias real_t = float;

struct vec2 {
	real_t x;
	real_t y;

	vec2 opBinary(string op)(vec2 other) {
		static if (op == "+") {
			return vec2(x + other.x, y + other.y);
		} else static if (op == "-") {
			return vec2(x - other.x, y - other.y);
		} else static assert(false, "vec2::" ~ op ~ " not supported.");
	}

	vec2 opBinary(string op)(real_t a) {
		static if (op == "*") {
			return vec2(x * a, y * a);
		} else static if (op == "/") {
			return vec2(x / a, y / a);
		} else static assert(false, "vec2::" ~ op ~ " not supported.");
	}

	vec2 opOpAssign(string op)(vec2 other) {
		immutable a = opBinary!op(other);
		x = a.x;
		y = a.y;
		return this;
	}
}

struct AABB {
	vec2 min;
	vec2 max;
}

struct Circle {
	vec2 center;
	real_t radius;
}

struct PhysicsObj {
	AABB bounds; // TODO
	vec2 position;
	vec2 velocity;
	real_t restitution;
}
