
-------------------------------------------------------- Libraries --------------------------------------------------------

local OCGLTR = require("OpenComputersGLTriangleRenderer")
local matrix = require("matrix")
local buffer = require("doubleBuffering")

-------------------------------------------------------- Constants --------------------------------------------------------

local OCGL = {}
local doubleHeight = buffer.screen.height * 2

OCGL.axis = {
	x = 1,
	y = 2,
	z = 3,
}

OCGL.colors = {
	axis = {
		x = 0xFF0000,
		y = 0x00FF00,
		z = 0x0000FF,
	},
	pivotPoint = 0xFFFFFF,
	wireframe = 0x00FFFF,
}

OCGL.renderModes = {
	material = 1,
	wireframe = 2,
	vertices = 3,
}

OCGL.materialTypes = {
	textured = 1,
	solid = 2,
}

-------------------------------------------------------- Materials --------------------------------------------------------

function OCGL.newSolidMaterial(color)
	return {
		type = OCGL.materialTypes.solid,
		color = color
	}
end

function OCGL.newTexturedMaterial(texture)
	return {
		type = OCGL.materialTypes.textured,
		texture = texture
	}
end

-------------------------------------------------------- Vertices manipulation --------------------------------------------------------

function OCGL.newVector2(x, y)
	checkArg(1, x, "number")
	checkArg(2, y, "number")

	return { x, y }
end

function OCGL.newVector3(x, y, z)
	checkArg(1, x, "number")
	checkArg(2, y, "number")
	checkArg(3, z, "number")
	
	return { x, y, z }
end

function OCGL.newVector4(x, y, z, w)
	checkArg(1, x, "number")
	checkArg(2, y, "number")
	checkArg(3, z, "number")
	checkArg(4, w, "number")
	
	return { x, y, z, w }
end

function OCGL.convertVector3ArrayToVerticesMatrix(vector3Position, vector3Vertices)
	checkArg(1, vector3Vertices, "table")
	
	local verticesMatrix = {}
	for i = 1, #vector3Vertices do
		verticesMatrix[i] = OCGL.newVector3(
			vector3Position[1] + vector3Vertices[i][1],
			vector3Position[2] + vector3Vertices[i][2],
			vector3Position[3] + vector3Vertices[i][3]
		)
	end

	-- Костыль, добавляющий нулевой вектор в матрицу в том случае, если количество вертексов меньше 3, чисто для заполнения массива
	-- if #vector3Vertices < 3 then
	-- 	for i = 1, 3 - #vector3Vertices do
	-- 		table.insert(verticesMatrix, OCGL.newVector3(0, 0, 0))
	-- 	end
	-- end
	
	return verticesMatrix
end

function OCGL.isVertexInScreenRange(vector3Vertex)
	return 
		vector3Vertex[1] >= 1 and
		vector3Vertex[1] <= buffer.screen.width and
		vector3Vertex[2] >= 1 and
		vector3Vertex[2] <= doubleHeight
end


-------------------------------------------------------- Matrix objects --------------------------------------------------------

function OCGL.newRotationMatrix(axis, angle)
	checkArg(1, axis, "number")
	checkArg(1, angle, "number")

	local rotationMatrix, sin, cos = {}, math.sin(angle), math.cos(angle)
	if axis == OCGL.axis.x then
		rotationMatrix = {
			{ 1, 0, 0 },
			{ 0, cos, -sin },
			{ 0, sin, cos }
		}
	elseif axis == OCGL.axis.y then
		rotationMatrix = {
			{ cos, 0, sin },
			{ 0, 1, 0 },
			{ -sin, 0, cos }
		}
	elseif axis == OCGL.axis.z then
		rotationMatrix = {
			{ cos, -sin, 0 },
			{ sin, cos, 0 },
			{ 0, 0, 1 }
		}
	else
		error("Axis enum " .. tostring(axis) .. " doesn't exists")
	end

	return rotationMatrix
end

function OCGL.newPivotPoint(vector3Position)
	return {
		position = vector3Position,
		axis = {
			{ 1, 0, 0 },
			{ 0, 1, 0 },
			{ 0, 0, 1 }
		}
	}
end

function OCGL.newScaleMatrix(vector3Scale)
	return {
		{ vector3Scale[1], 0, 0 },
		{ 0, vector3Scale[2], 0 },
		{ 0, 0, vector3Scale[3] }
	}
end

-------------------------------------------------------- Object translation methods --------------------------------------------------------

local function objectTranslate(object, vector3Translation)
	for vertexIndex = 1, #object.verticesMatrix do
		object.verticesMatrix[vertexIndex][1] = object.verticesMatrix[vertexIndex][1] + vector3Translation[1]
		object.verticesMatrix[vertexIndex][2] = object.verticesMatrix[vertexIndex][2] + vector3Translation[2]
		object.verticesMatrix[vertexIndex][3] = object.verticesMatrix[vertexIndex][3] + vector3Translation[3]
	end
	object.pivotPoint.position[1] = object.pivotPoint.position[1] + vector3Translation[1]
	object.pivotPoint.position[2] = object.pivotPoint.position[2] + vector3Translation[2]
	object.pivotPoint.position[3] = object.pivotPoint.position[3] + vector3Translation[3]

	return object
end

local function objectSetPosition(object, vector3Position)
	object:translate(OCGL.newVector3(	
		vector3Position[1] - object.pivotPoint.position[1],
		vector3Position[2] - object.pivotPoint.position[2],
		vector3Position[3] - object.pivotPoint.position[3]
	))
	return object
end

-------------------------------------------------------- Object rotation methods --------------------------------------------------------

local function objectRotateRelativeToWorldAxisPosition(object, rotationMatrix)
	object.verticesMatrix = matrix.multiply(object.verticesMatrix, rotationMatrix)
	object.pivotPoint.axis = matrix.multiply(object.pivotPoint.axis, rotationMatrix)
	object.pivotPoint.position = matrix.multiply({object.pivotPoint.position}, rotationMatrix)[1]

	return object
end

local function objectRotateRelativeToSpecifiedAxisPosition(object, vector3Position, rotationMatrix)
	local oldPosition = OCGL.newVector3(vector3Position[1], vector3Position[2], vector3Position[3])
	object:translate(OCGL.newVector3(-oldPosition[1], -oldPosition[2], -oldPosition[3]))
	object:rotateRelativeToWorldAxisPosition(rotationMatrix)
	object:translate(oldPosition)

	return object
end

local function objectRotateRelativeToSpecifiedPivotPoint(object, specifiedPivotPoint, rotationMatrix)
	local oldPosition = OCGL.newVector3(specifiedPivotPoint.position[1], specifiedPivotPoint.position[2], specifiedPivotPoint.position[3])
	object:translate(OCGL.newVector3(-oldPosition[1], -oldPosition[2], -oldPosition[3]))

	local transitionMatrix = matrix.transpose(object.pivotPoint.axis)
	local invertedTransitionMatrix = matrix.invert(transitionMatrix)
	object.verticesMatrix = matrix.multiply(object.verticesMatrix, transitionMatrix)
	object.pivotPoint.axis = matrix.multiply(object.pivotPoint.axis, transitionMatrix)

	object:rotateRelativeToWorldAxisPosition(rotationMatrix)

	object.verticesMatrix = matrix.multiply(object.verticesMatrix, invertedTransitionMatrix)
	object.pivotPoint.axis = matrix.multiply(object.pivotPoint.axis, invertedTransitionMatrix)

	object:translate(oldPosition)
end

local function objectRotateRelativeToLocalPivotPoint(object, rotationMatrix)
	object:rotateRelativeToSpecifiedPivotPoint(object.pivotPoint, rotationMatrix)
	return object
end

-------------------------------------------------------- Object Scale methods --------------------------------------------------------

local function objectScaleRelativeToWorldAxisPosition(object, scaleMatrix)
	object.verticesMatrix = matrix.multiply(object.verticesMatrix, scaleMatrix)
	object.pivotPoint.axis = matrix.multiply(object.pivotPoint.axis, scaleMatrix)
	
	return object
end

local function objectScaleRelativeToSpecifiedAxisPosition(object, vector3Position, scaleMatrix)
	local oldPosition = OCGL.newVector3(vector3Position[1], vector3Position[2], vector3Position[3])
	object:translate(OCGL.newVector3(-oldPosition[1], -oldPosition[2], -oldPosition[3]))
	object:scaleRelativeToWorldAxisPosition(scaleMatrix)
	object:translate(oldPosition)

	return object
end

local function objectScaleRelativeToLocalPivotPoint(object, scaleMatrix)
	local oldPosition = OCGL.newVector3(object.pivotPoint.position[1], object.pivotPoint.position[2], object.pivotPoint.position[3])
	object:translate(OCGL.newVector3(-oldPosition[1], -oldPosition[2], -oldPosition[3]))
	object:scaleRelativeToWorldAxisPosition(scaleMatrix)
	object:translate(oldPosition)

	return object
end

-------------------------------------------------------- Object creation --------------------------------------------------------

function OCGL.newObject(vector3Position, vector3Vertices)
	local object = {}

	object.verticesMatrix = OCGL.convertVector3ArrayToVerticesMatrix(vector3Position, vector3Vertices)
	object.pivotPoint = OCGL.newPivotPoint(vector3Position)

	object.translate = objectTranslate
	object.setPosition = objectSetPosition

	object.rotateRelativeToWorldAxisPosition = objectRotateRelativeToWorldAxisPosition
	object.rotateRelativeToSpecifiedAxisPosition = objectRotateRelativeToSpecifiedAxisPosition
	object.rotateRelativeToSpecifiedPivotPoint = objectRotateRelativeToSpecifiedPivotPoint
	object.rotate = objectRotateRelativeToLocalPivotPoint
	
	object.scaleRelativeToWorldAxisPosition = objectScaleRelativeToWorldAxisPosition
	object.scaleRelativeToSpecifiedAxisPosition = objectScaleRelativeToSpecifiedAxisPosition
	object.scale = objectScaleRelativeToLocalPivotPoint

	return object
end

-------------------------------------------------------- Primitive rendering --------------------------------------------------------

function OCGL.renderLine(vector3Vertex1, vector3Vertex2, color)
	buffer.semiPixelLine(
		math.floor(vector3Vertex1[1]),
		math.floor(vector3Vertex1[2]),
		math.floor(vector3Vertex2[1]),
		math.floor(vector3Vertex2[2]),
		color
	)
end

function OCGL.renderDot(vector3Vertex, color)
	buffer.semiPixelSet(math.floor(vector3Vertex[1]), math.floor(vector3Vertex[2]), color)
end

function OCGL.renderTriangle(vector3Vertex1, vector3Vertex2, vector3Vertex3, renderMode, material)
	if renderMode == OCGL.renderModes.material then
		if material.type == OCGL.materialTypes.solid then
			OCGLTR.renderFilledTriangle(
				{
					OCGL.newVector3(vector3Vertex1[1], math.floor(vector3Vertex1[2]), vector3Vertex1[3]),
					OCGL.newVector3(vector3Vertex2[1], math.floor(vector3Vertex2[2]), vector3Vertex2[3]),
					OCGL.newVector3(vector3Vertex3[1], math.floor(vector3Vertex3[2]), vector3Vertex3[3])
				},
				material.color
			)
		else
			error("Material type " .. tostring(material.type) .. " doesn't supported for rendering triangles")
		end
	elseif renderMode == OCGL.renderModes.wireframe then
		OCGL.renderLine(vector3Vertex1, vector3Vertex2, OCGL.colors.wireframe)
		OCGL.renderLine(vector3Vertex2, vector3Vertex3, OCGL.colors.wireframe)
		OCGL.renderLine(vector3Vertex1, vector3Vertex3, OCGL.colors.wireframe)
	elseif renderMode == OCGL.renderModes.vertices then
		OCGL.renderDot(vector3Vertex1, OCGL.colors.wireframe)
		OCGL.renderDot(vector3Vertex2, OCGL.colors.wireframe)
		OCGL.renderDot(vector3Vertex3, OCGL.colors.wireframe)
	else
		error("Rendermode enum " .. tostring(renderMode) .. " doesn't supported for rendering triangles")
	end
end

-------------------------------------------------------- Mesh object --------------------------------------------------------

function OCGL.newIndexedTriangle(indexOfVertex1, indexOfVertex2, indexOfVertex3, material)
	return {
		indexOfVertex1,
		indexOfVertex2,
		indexOfVertex3,
		material
	}
end

local function renderMesh(mesh, renderMode)
	for triangleIndex = 1, #mesh.triangles do
		if
			OCGL.isVertexInScreenRange(mesh.verticesMatrix[mesh.triangles[triangleIndex][1]]) or
			OCGL.isVertexInScreenRange(mesh.verticesMatrix[mesh.triangles[triangleIndex][2]]) or
			OCGL.isVertexInScreenRange(mesh.verticesMatrix[mesh.triangles[triangleIndex][3]])
		then
			OCGL.renderTriangle(
				mesh.verticesMatrix[mesh.triangles[triangleIndex][1]],
				mesh.verticesMatrix[mesh.triangles[triangleIndex][2]],
				mesh.verticesMatrix[mesh.triangles[triangleIndex][3]],
				renderMode,
				mesh.triangles[triangleIndex][4] or mesh.material
			)
		end
	end

	-- Рендерим локальные оси
	if mesh.showPivotPoint then
		local scale = 30
		OCGL.renderLine(
			mesh.pivotPoint.position,
			OCGL.newVector3(mesh.pivotPoint.position[1] + mesh.pivotPoint.axis[1][1] * scale, mesh.pivotPoint.position[2] + mesh.pivotPoint.axis[1][2] * scale, mesh.pivotPoint.position[3] + mesh.pivotPoint.axis[1][3] * scale),
			OCGL.colors.axis.x
		)
		OCGL.renderLine(
			mesh.pivotPoint.position,
			OCGL.newVector3(mesh.pivotPoint.position[1] + mesh.pivotPoint.axis[2][1] * scale, mesh.pivotPoint.position[2] + mesh.pivotPoint.axis[2][2] * scale, mesh.pivotPoint.position[3] + mesh.pivotPoint.axis[2][3] * scale),
			OCGL.colors.axis.y
		)
		OCGL.renderLine(
			mesh.pivotPoint.position,
			OCGL.newVector3(mesh.pivotPoint.position[1] + mesh.pivotPoint.axis[3][1] * scale, mesh.pivotPoint.position[2] + mesh.pivotPoint.axis[3][2] * scale, mesh.pivotPoint.position[3] + mesh.pivotPoint.axis[3][3] * scale),
			OCGL.colors.axis.z
		)
	end

	return mesh
end

function OCGL.newMesh(vector3Position, vector3Vertices, triangles, material)
	local mesh = OCGL.newObject(vector3Position, vector3Vertices)

	mesh.material = material
	mesh.triangles = triangles
	mesh.render = renderMesh

	return mesh
end

-------------------------------------------------------- Line object --------------------------------------------------------

local function lineObjectRender(line, renderMode)
	if renderMode == OCGL.renderModes.vertices then
		OCGL.renderDot(line.verticesMatrix[1], line.color)
		OCGL.renderDot(line.verticesMatrix[2], line.color)
	else
		OCGL.renderLine(
			line.verticesMatrix[1],
			line.verticesMatrix[2],
			line.color
		)
	-- else
	-- 	error("Rendermode enum " .. tostring(renderMode) .. " doesn't supported for rendering lines")
	end
end

function OCGL.newLine(vector3Position, vector3Vertex1, vector3Vertex2, color)
	local line = OCGL.newObject(vector3Position, { vector3Vertex1, vector3Vertex2 })

	line.color = color
	line.render = lineObjectRender

	return line
end

-------------------------------------------------------- Plane object --------------------------------------------------------

function OCGL.newPlane(vector3Position, width, height, material)
	local halfWidth, halfHeight = width / 2, height / 2
	return OCGL.newMesh(
		vector3Position,
		{
			OCGL.newVector3(-halfWidth, 0, -halfHeight),
			OCGL.newVector3(-halfWidth, 0, halfHeight),
			OCGL.newVector3(halfWidth, 0, halfHeight),
			OCGL.newVector3(halfWidth, 0, -halfHeight),
		},
		{
			OCGL.newIndexedTriangle(1, 2, 3),
			OCGL.newIndexedTriangle(1, 4, 3)
		},
		material
	)
end

-------------------------------------------------------- Cyka helper --------------------------------------------------------

--[[
	|    /
	|  /
	y z
	  x -----

	FRONT		LEFT		BACK		RIGHT		TOP 		BOTTOM
	2######3	3######6	6######7	7######2	7######6	8######5
	########	########	########	########	########	########
	1######4	4######5	5######8	8######1	2######3	1######4
]]


-------------------------------------------------------- Cube object --------------------------------------------------------

-- Start point is a bottom left nearest corner of cube
function OCGL.newCube(vector3Position, size, material)
	local halfSize = size / 2
	return OCGL.newMesh(
		vector3Position,
		{
			-- (1-2-3-4)
			OCGL.newVector3(-halfSize, -halfSize, -halfSize),
			OCGL.newVector3(-halfSize, halfSize, -halfSize),
			OCGL.newVector3(halfSize, halfSize, -halfSize),
			OCGL.newVector3(halfSize, -halfSize, -halfSize),
			-- (5-6-7-8)
			OCGL.newVector3(halfSize, -halfSize, halfSize),
			OCGL.newVector3(halfSize, halfSize, halfSize),
			OCGL.newVector3(-halfSize, halfSize, halfSize),
			OCGL.newVector3(-halfSize, -halfSize, halfSize),
		},
		{
			-- Front
			OCGL.newIndexedTriangle(1, 2, 3),
			OCGL.newIndexedTriangle(1, 4, 3),
			-- Left
			OCGL.newIndexedTriangle(4, 3, 6),
			OCGL.newIndexedTriangle(4, 5, 6),
			-- Back
			OCGL.newIndexedTriangle(5, 6, 7),
			OCGL.newIndexedTriangle(5, 8, 7),
			-- Right
			OCGL.newIndexedTriangle(8, 7, 2),
			OCGL.newIndexedTriangle(8, 1, 2),
			-- Top
			OCGL.newIndexedTriangle(2, 7, 6),
			OCGL.newIndexedTriangle(2, 3, 6),
			-- Bottom
			OCGL.newIndexedTriangle(1, 8, 5),
			OCGL.newIndexedTriangle(1, 4, 5),
		},
		material
	)
end

-------------------------------------------------------- Grid lines --------------------------------------------------------

function OCGL.newGridLines(vector3Position, range, step)
	local objects = {}
	-- Grid
	for x = -range, range, step do
		table.insert(objects, 1, OCGL.newLine(
			OCGL.newVector3(vector3Position[1] + x, vector3Position[2], vector3Position[3]),
			OCGL.newVector3(0, 0, -range),
			OCGL.newVector3(0, 0, range),
			0x444444
		))
	end
	for z = -range, range, step do
		table.insert(objects, 1, OCGL.newLine(
			OCGL.newVector3(vector3Position[1], vector3Position[2], vector3Position[3] + z),
			OCGL.newVector3(-range, 0, 0),
			OCGL.newVector3(range, 0, 0),
			0x444444
		))
	end

	-- Axis
	table.insert(objects, OCGL.newLine(
		vector3Position,
		OCGL.newVector3(-range, 0, 0),
		OCGL.newVector3(range, 0, 0),
		OCGL.colors.axis.x
	))
	table.insert(objects, OCGL.newLine(
		vector3Position,
		OCGL.newVector3(0, -range, 0),
		OCGL.newVector3(0, range, 0),
		OCGL.colors.axis.y
	))
	table.insert(objects, OCGL.newLine(
		vector3Position,
		OCGL.newVector3(0, 0, -range),
		OCGL.newVector3(0, 0, range),
		OCGL.colors.axis.z
	))

	return objects
end

-------------------------------------------------------- ObjectGroup object --------------------------------------------------------

local function objectGroupAddObject(objectGroup, object)
	table.insert(objectGroup.objects, object)
	return object
end

local function objectGroupAddObjects(objectGroup, objects)
	for objectIndex = 1, #objects do
		table.insert(objectGroup.objects, objects[objectIndex])
	end
	return objects
end

local function objectGroupRotate(objectGroup, rotationMatrix)
	for objectIndex = 1, #objectGroup.objects do
		objectGroup.objects[objectIndex]:rotateRelativeToSpecifiedAxisPosition(objectGroup.pivotPoint.position, rotationMatrix)
	end
	return objectGroup
end

local function objectGroupTranslate(objectGroup, vector3Translation)
	for objectIndex = 1, #objectGroup.objects do
		objectGroup.objects[objectIndex]:translate(vector3Translation)
	end
	objectGroup.pivotPoint.position = OCGL.newVector3(
		objectGroup.pivotPoint.position[1] + vector3Translation[1],
		objectGroup.pivotPoint.position[2] + vector3Translation[2],
		objectGroup.pivotPoint.position[3] + vector3Translation[3]
	)

	return objectGroup
end

local function objectGroupScale(objectGroup, scaleMatrix)
	for objectIndex = 1, #objectGroup.objects do
		objectGroup.objects[objectIndex]:scaleRelativeToSpecifiedAxisPosition(objectGroup.pivotPoint.position, scaleMatrix)
	end

	return objectGroup
end

local function objectGroupRender(objectGroup, renderMode)
	for objectIndex = 1, #objectGroup.objects do
		objectGroup.objects[objectIndex]:render(renderMode)
	end

	return objectGroup
end

function OCGL.newObjectGroup(vector3Position, ...)
	local objectGroup = {}

	objectGroup.pivotPoint = OCGL.newPivotPoint(vector3Position)
	objectGroup.objects = {}

	objectGroup.rotate = objectGroupRotate
	objectGroup.translate = objectGroupTranslate
	objectGroup.scale = objectGroupScale

	objectGroup.addObject = objectGroupAddObject
	objectGroup.addObjects = objectGroupAddObjects
	objectGroup.render = objectGroupRender

	return objectGroup
end


-------------------------------------------------------- FPS BITCH --------------------------------------------------------

local function drawSegments(x, y, segments, color)
	for i = 1, #segments do
		if segments[i] == 1 then
			buffer.semiPixelSquare(x, y, 3, 1, color)
		elseif segments[i] == 2 then
			buffer.semiPixelSquare(x + 2, y, 1, 3, color)
		elseif segments[i] == 3 then
			buffer.semiPixelSquare(x + 2, y + 2, 1, 3, color)
		elseif segments[i] == 4 then
			buffer.semiPixelSquare(x, y + 4, 3, 1, color)
		elseif segments[i] == 5 then
			buffer.semiPixelSquare(x, y + 2, 1, 3, color)
		elseif segments[i] == 6 then
			buffer.semiPixelSquare(x, y, 1, 3, color)
		elseif segments[i] == 7 then
			buffer.semiPixelSquare(x, y + 2, 3, 1, color)
		else
			error("Че за говно ты сюда напихал? Переделывай!")
		end
	end
end

--   1
-- 6   2
--   7
-- 5   3
--   4

function OCGL.renderFPSCounter(x, y, renderMethod, color)
	local numbers = {
		["0"] = { 1, 2, 3, 4, 5, 6 },
		["1"] = { 2, 3 },
		["2"] = { 1, 2, 4, 5, 7 },
		["3"] = { 1, 2, 3, 4, 7 },
		["4"] = { 2, 3, 6, 7 },
		["5"] = { 1, 3, 4, 6, 7 },
		["6"] = { 1, 3, 4, 5, 6, 7 },
		["7"] = { 1, 2, 3 },
		["8"] = { 1, 2, 3, 4, 5, 6, 7 },
		["9"] = { 1, 2, 3, 4, 6, 7 },
	}

	-- clock sec - 1 frame
	-- 1 sec - x frames

	local oldClock = os.clock()
	renderMethod()
	local fps = tostring(math.ceil(1 / (os.clock() - oldClock) / 10))

	for i = 1, #fps do
		drawSegments(x, y, numbers[fps:sub(i, i)], color)
		x = x + 4
	end

	return x - 3
end

-------------------------------------------------------- Playground --------------------------------------------------------



-------------------------------------------------------- Constants --------------------------------------------------------

return OCGL
