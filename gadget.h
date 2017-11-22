#pragma once

using real_t = float;

struct vec2 {
	real_t x;
	real_t y;
};

extern vec2 makeVec2(real_t x, real_t y);

struct AABB {
	vec2 min;
	vec2 max;
};

struct Circle {
	vec2 center;
	real_t radius;
};

extern bool AABBOverlapsAABB(AABB a, AABB b);
extern bool circleOverlapsCircle(Circle a, Circle b);

struct PhysicsObj {
	AABB bounds; // TODO
	vec2 position;
	vec2 velocity;
	real_t restitution;
};

class PhysicsWorld {
	static constexpr auto WORLD_SIZE = 1000;
	PhysicsObj objects[WORLD_SIZE];
	int i = 0;
public:
	void add(PhysicsObj o);
	void step(real_t dt);
};
