module gadget.world;

import gadget.types;

class PhysicsWorld {

	enum WORLD_SIZE = 1000;

	PhysicsObj[WORLD_SIZE] objects;
	int i = 0;

	public void add(PhysicsObj o) {
		if (i == WORLD_SIZE)
			throw new Exception("Too many objects in world!");
		objects[i++] = o;
	}

	public void step(real_t dt) {
		foreach (o; objects) {
			o.position += o.velocity * dt;
		}
	}
}
