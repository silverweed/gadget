module gadget.rendering.shapes;

import derelict.opengl;
debug import std.stdio;

struct Vertex {
	GLfloat[3] position;
	GLfloat[3] normal;
	GLfloat[2] texCoords;
}

enum ShapeType {
	CUBE,
	QUAD,
	POINT
}

/// Utility module to create basic 2d or 3d shapes
immutable Vertex[1] pointVertices = [
	{ [0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0] }
];

immutable Vertex[12] quadVertices = [
	{ [ 0.5f,  0.5f, 0f], [0f, 0f, 1f], [1f, 1f] },
	{ [-0.5f,  0.5f, 0f], [0f, 0f, 1f], [0f, 1f] },
	{ [-0.5f, -0.5f, 0f], [0f, 0f, 1f], [0f, 0f] },
	{ [ 0.5f,  0.5f, 0f], [0f, 0f, 1f], [1f, 1f] },
	{ [-0.5f, -0.5f, 0f], [0f, 0f, 1f], [0f, 0f] },
	{ [ 0.5f, -0.5f, 0f], [0f, 0f, 1f], [1f, 0f] },
];

immutable Vertex[36] cubeVertices = [
	// positions              // normals             // texture coords
	{ [-0.5f, -0.5f, -0.5f],  [0.0f,  0.0f, -1.0f],  [0.0f, 0.0f] },
	{ [ 0.5f,  0.5f, -0.5f],  [0.0f,  0.0f, -1.0f],  [1.0f, 1.0f] },
	{ [ 0.5f, -0.5f, -0.5f],  [0.0f,  0.0f, -1.0f],  [1.0f, 0.0f] },
	{ [ 0.5f,  0.5f, -0.5f],  [0.0f,  0.0f, -1.0f],  [1.0f, 1.0f] },
	{ [-0.5f, -0.5f, -0.5f],  [0.0f,  0.0f, -1.0f],  [0.0f, 0.0f] },
	{ [-0.5f,  0.5f, -0.5f],  [0.0f,  0.0f, -1.0f],  [0.0f, 1.0f] },

	{ [-0.5f, -0.5f,  0.5f],  [0.0f,  0.0f, 1.0f],   [0.0f, 0.0f] },
	{ [ 0.5f, -0.5f,  0.5f],  [0.0f,  0.0f, 1.0f],   [1.0f, 0.0f] },
	{ [ 0.5f,  0.5f,  0.5f],  [0.0f,  0.0f, 1.0f],   [1.0f, 1.0f] },
	{ [ 0.5f,  0.5f,  0.5f],  [0.0f,  0.0f, 1.0f],   [1.0f, 1.0f] },
	{ [-0.5f,  0.5f,  0.5f],  [0.0f,  0.0f, 1.0f],   [0.0f, 1.0f] },
	{ [-0.5f, -0.5f,  0.5f],  [0.0f,  0.0f, 1.0f],   [0.0f, 0.0f] },

	{ [-0.5f,  0.5f,  0.5f],  [-1.0f,  0.0f, 0.0f],  [1.0f, 0.0f] },
	{ [-0.5f,  0.5f, -0.5f],  [-1.0f,  0.0f, 0.0f],  [1.0f, 1.0f] },
	{ [-0.5f, -0.5f, -0.5f],  [-1.0f,  0.0f, 0.0f],  [0.0f, 1.0f] },
	{ [-0.5f, -0.5f, -0.5f],  [-1.0f,  0.0f, 0.0f],  [0.0f, 1.0f] },
	{ [-0.5f, -0.5f,  0.5f],  [-1.0f,  0.0f, 0.0f],  [0.0f, 0.0f] },
	{ [-0.5f,  0.5f,  0.5f],  [-1.0f,  0.0f, 0.0f],  [1.0f, 0.0f] },

	{ [ 0.5f,  0.5f,  0.5f],  [1.0f,  0.0f,  0.0f],  [1.0f, 0.0f] },
	{ [ 0.5f, -0.5f, -0.5f],  [1.0f,  0.0f,  0.0f],  [0.0f, 1.0f] },
	{ [ 0.5f,  0.5f, -0.5f],  [1.0f,  0.0f,  0.0f],  [1.0f, 1.0f] },
	{ [ 0.5f, -0.5f, -0.5f],  [1.0f,  0.0f,  0.0f],  [0.0f, 1.0f] },
	{ [ 0.5f,  0.5f,  0.5f],  [1.0f,  0.0f,  0.0f],  [1.0f, 0.0f] },
	{ [ 0.5f, -0.5f,  0.5f],  [1.0f,  0.0f,  0.0f],  [0.0f, 0.0f] },

	{ [-0.5f, -0.5f, -0.5f],  [0.0f, -1.0f,  0.0f],  [0.0f, 1.0f] },
	{ [ 0.5f, -0.5f, -0.5f],  [0.0f, -1.0f,  0.0f],  [1.0f, 1.0f] },
	{ [ 0.5f, -0.5f,  0.5f],  [0.0f, -1.0f,  0.0f],  [1.0f, 0.0f] },
	{ [ 0.5f, -0.5f,  0.5f],  [0.0f, -1.0f,  0.0f],  [1.0f, 0.0f] },
	{ [-0.5f, -0.5f,  0.5f],  [0.0f, -1.0f,  0.0f],  [0.0f, 0.0f] },
	{ [-0.5f, -0.5f, -0.5f],  [0.0f, -1.0f,  0.0f],  [0.0f, 1.0f] },

	{ [ 0.5f,  0.5f, -0.5f],  [0.0f,  1.0f,  0.0f],  [1.0f, 1.0f] },
	{ [-0.5f,  0.5f, -0.5f],  [0.0f,  1.0f,  0.0f],  [0.0f, 1.0f] },
	{ [ 0.5f,  0.5f,  0.5f],  [0.0f,  1.0f,  0.0f],  [1.0f, 0.0f] },
	{ [-0.5f,  0.5f,  0.5f],  [0.0f,  1.0f,  0.0f],  [0.0f, 0.0f] },
	{ [ 0.5f,  0.5f,  0.5f],  [0.0f,  1.0f,  0.0f],  [1.0f, 0.0f] },
	{ [-0.5f,  0.5f, -0.5f],  [0.0f,  1.0f,  0.0f],  [0.0f, 1.0f] }
];

// Configures a vertex array object to contain a shape. Returns the vao index.
// This shape is meant to be used with glDrawElements.
@disable // since we don't use indexed drawing yet
auto genShapeElem(alias vertices, alias indices)() {
	uint vbo, vao, ebo;

	glGenVertexArrays(1, &vao);
	glGenBuffers(1, &vbo);
	glGenBuffers(1, &ebo);

	glBindVertexArray(vao);

	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	debug writeln("vertices: ", vertices.length / 3);
	glBufferData(GL_ARRAY_BUFFER, vertices.sizeof, &vertices, GL_STATIC_DRAW);

	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.sizeof, &indices, GL_STATIC_DRAW);

	// Bind vertex attributes
	/// Position
	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * float.sizeof, cast(void*)0);
	glEnableVertexAttribArray(0);

	// Unbind the buffer
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindVertexArray(0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0); // must do this AFTER unbinding the vao

	return vao;
}

// Like genShapeElem but used with glDrawArrays
auto genShape(alias vertices)() {
	uint vao, vbo;

	glGenVertexArrays(1, &vao);
	glGenBuffers(1, &vbo);

	debug writeln("vertices: ", vertices.length);
	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glBufferData(GL_ARRAY_BUFFER, vertices.sizeof, &vertices, GL_STATIC_DRAW);

	glBindVertexArray(vao);

	// Position
	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, Vertex.sizeof, cast(void*)Vertex.position.offsetof);
	glEnableVertexAttribArray(0);
	// Normals
	glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, Vertex.sizeof, cast(void*)Vertex.normal.offsetof);
	glEnableVertexAttribArray(1);
	// Texture coords
	glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, Vertex.sizeof, cast(void*)Vertex.texCoords.offsetof);
	glEnableVertexAttribArray(2);

	// Unbind the buffer
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindVertexArray(0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0); // must do this AFTER unbinding the vao

	return vao;
}

auto genCube() {
	return genShape!(cubeVertices)();
}

auto genQuad() {
	return genShape!(quadVertices)();
}

auto genPoint() {
	return genShape!(pointVertices)();
}
