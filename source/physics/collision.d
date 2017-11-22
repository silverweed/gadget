module gadget.collision;

import gadget.types;

bool AABBOverlapsAABB(in AABB a, in AABB b) pure @nogc {
	 return !(a.max.x < b.min.x || a.min.x > b.max.x ||
		a.max.y < b.min.y || a.min.y > b.max.y);
}

bool circleOverlapsCircle(in Circle a, in Circle b) pure @nogc {
	import std.math : pow;
	immutable r = a.radius + b.radius;
	return r * r < (a.center.x + b.center.x) ^^ 2 + (a.center.y + b.center.y) ^^ 2;
}
