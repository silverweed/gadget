module gadget.rendering.shapes;

import derelict.opengl3.gl3;
debug import std.stdio;

struct Vertex {
	GLfloat[3] position;
	GLfloat[3] normal;
}

/// Utility module to create basic 2d or 3d shapes

immutable GLfloat[12] quadVertices = [
	0.5f,  0.5f, 0.0f,  // top right
	0.5f, -0.5f, 0.0f,  // bottom right
	-0.5f, -0.5f, 0.0f,  // bottom left
	-0.5f,  0.5f, 0.0f   // top left
];

immutable GLint[6] quadIndices = [
	0, 1, 3,
	1, 2, 3
];

immutable Vertex[36] cubeVertices = [
	{ [-0.5f, -0.5f, -0.5f], [ 0.0f, 0.0f, -1.0f] },
	{ [0.5f, -0.5f, -0.5f], [0.0f, 0.0f, -1.0f] },
	{ [0.5f, 0.5f, -0.5f], [0.0f, 0.0f, -1.0f] },
	{ [0.5f, 0.5f, -0.5f], [0.0f, 0.0f, -1.0f] },
	{ [-0.5f, 0.5f, -0.5f], [ 0.0f, 0.0f, -1.0f] },
	{ [-0.5f, -0.5f, -0.5f], [ 0.0f, 0.0f, -1.0f] },
	
	{ [-0.5f, -0.5f, 0.5f], [ 0.0f, 0.0f, 1.0f] },
	{ [0.5f, -0.5f, 0.5f], [0.0f, 0.0f, 1.0f] },
	{ [0.5f, 0.5f, 0.5f], [0.0f, 0.0f, 1.0f] },
	{ [0.5f, 0.5f, 0.5f], [0.0f, 0.0f, 1.0f] },
	{ [-0.5f, 0.5f, 0.5f], [ 0.0f, 0.0f, 1.0f] },
	{ [-0.5f, -0.5f, 0.5f], [ 0.0f, 0.0f, 1.0f] },
	
	{ [-0.5f, 0.5f, 0.5f], [-1.0f, 0.0f, 0.0f] },
	{ [-0.5f, 0.5f, -0.5f], [-1.0f, 0.0f, 0.0f] },
	{ [-0.5f, -0.5f, -0.5f], [-1.0f, 0.0f, 0.0f] },
	{ [-0.5f, -0.5f, -0.5f], [-1.0f, 0.0f, 0.0f] },
	{ [-0.5f, -0.5f, 0.5f], [-1.0f, 0.0f, 0.0f] },
	{ [-0.5f, 0.5f, 0.5f], [-1.0f, 0.0f, 0.0f] },
	
	{ [0.5f, 0.5f, 0.5f], [1.0f, 0.0f, 0.0f] },
	{ [0.5f, 0.5f, -0.5f], [1.0f, 0.0f, 0.0f] },
	{ [0.5f, -0.5f, -0.5f], [1.0f, 0.0f, 0.0f] },
	{ [0.5f, -0.5f, -0.5f], [1.0f, 0.0f, 0.0f] },
	{ [0.5f, -0.5f, 0.5f], [1.0f, 0.0f, 0.0f] },
	{ [0.5f, 0.5f, 0.5f], [1.0f, 0.0f, 0.0f] },
	
	{ [-0.5f, -0.5f, -0.5f], [ 0.0f, -1.0f, 0.0f] },
	{ [0.5f, -0.5f, -0.5f], [0.0f, -1.0f, 0.0f] },
	{ [0.5f, -0.5f, 0.5f], [0.0f, -1.0f, 0.0f] },
	{ [0.5f, -0.5f, 0.5f], [0.0f, -1.0f, 0.0f] },
	{ [-0.5f, -0.5f, 0.5f], [ 0.0f, -1.0f, 0.0f] },
	{ [-0.5f, -0.5f, -0.5f], [ 0.0f, -1.0f, 0.0f] },
	
	{ [-0.5f, 0.5f, -0.5f], [ 0.0f, 1.0f, 0.0f] },
	{ [0.5f, 0.5f, -0.5f], [0.0f, 1.0f, 0.0f] },
	{ [0.5f, 0.5f, 0.5f], [0.0f, 1.0f, 0.0f] },
	{ [0.5f, 0.5f, 0.5f], [0.0f, 1.0f, 0.0f] },
	{ [-0.5f, 0.5f, 0.5f], [ 0.0f, 1.0f, 0.0f] },
	{ [-0.5f, 0.5f, -0.5f], [ 0.0f, 1.0f, 0.0f] }
];

immutable GLint[36] cubeIndices = [
	// front
	0, 1, 2,
	2, 3, 0,
	// top
	1, 5, 6,
	6, 2, 1,
	// back
	7, 6, 5,
	5, 4, 7,
	// bottom
	4, 0, 3,
	3, 7, 4,
	// left
	4, 5, 1,
	1, 0, 4,
	// right
	3, 2, 6,
	6, 7, 3,
];

// Configures a vertex array object to contain a shape. Returns the vao index.
// This shape is meant to be used with glDrawElements.
auto genShapeElem(alias vertices, alias indices)() {
	uint vbo, vao, ebo;

	glGenVertexArrays(1, &vao);
	glGenBuffers(1, &vbo);
	glGenBuffers(1, &ebo);

	glBindVertexArray(vao);

	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	debug writeln("vertices: ", vertices.sizeof);
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

	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glBufferData(GL_ARRAY_BUFFER, vertices.sizeof, &vertices, GL_STATIC_DRAW);

	glBindVertexArray(vao);

	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, Vertex.sizeof, cast(void*)Vertex.position.offsetof);
	glEnableVertexAttribArray(0);
	glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, Vertex.sizeof, cast(void*)Vertex.normal.offsetof);
	glEnableVertexAttribArray(1);

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
	return genShapeElem!(quadVertices, quadIndices)();
}
