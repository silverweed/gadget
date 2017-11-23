module gadget.fpscounter;

import std.stdio : stderr, writeln, File;
import std.format : format;

class FPSCounter {
	this(float updateRate = 1f, File stream = stderr) {
		this.updateRate = updateRate;
		this.stream = stream;
	}

	void update(float dt) {
		++frames;
		t += dt;
		
		if (t >= updateRate) {
			stream.writeln("FPS: %.1f".format(frames / t));
			t = 0;
			frames = 0;
		}
	}

private:
	double t = 0;
	float updateRate;
	int frames = 0;
	File stream;
}
