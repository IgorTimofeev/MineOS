
-------------------------------------------------------- Libraries --------------------------------------------------------

local matrix = require("matrix")
local buffer = require("doubleBuffering")

-------------------------------------------------------- Constants --------------------------------------------------------

local OCGL = {}

OCGL.axis = {
	x = 0,
	y = 1,
	z = 2,
}

OCGL.axisColors = {
	x = 0xFF0000,
	y = 0x00FF00,
	z = 0x0000FF,
}

OCGL.renderModes = {
	wireframe = 0,
	filled = 1,
}

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

function OCGL.convertVector3ArrayToVerticesMatrix(vector3Vertices)
	checkArg(1, vector3Vertices, "table")
	
	local verticesMatrix = matrix.new()
	for i = 1, #vector3Vertices do
		verticesMatrix[i] = OCGL.newVector3(vector3Vertices[i][1], vector3Vertices[i][2], vector3Vertices[i][3])
	end

	-- Костыль, добавляющий нулевые координаты в матрицу в том случае, если количество вертексов меньше 4, чисто для заполнения моссивоса
	if #vector3Vertices < 4 then
		for i = 1, 4 - #vector3Vertices do
			table.insert(verticesMatrix, OCGL.newVector3(0, 0, 0))
		end
	end
	
	return verticesMatrix
end

-------------------------------------------------------- Main objects --------------------------------------------------------

local function rotateObjectAroundAxis(object, axis, angle)
	checkArg(2, axis, "number")
	checkArg(3, angle, "number")

	local rotationMatrix, sin, cos = {}, math.sin(angle), math.cos(angle)

	if axis == OCGL.axis.x then
		rotationMatrix = matrix.new({
			{ 1, 0, 0 },
			{ 0, cos, -sin },
			{ 0, sin, cos },
		})
	elseif axis == OCGL.axis.y then
		rotationMatrix = matrix.new({
			{ cos, 0, sin },
			{ 0, 1, 0 },
			{ -sin, 0, cos }
		})
	elseif axis == OCGL.axis.z then
		rotationMatrix = matrix.new({
			{ cos, -sin, 0 },
			{ sin, cos, 0 },
			{ 0, 0, 1 },
		})
	else
		error("Axis enum " .. tostring(axis) .. " doesn't exists")
	end

	object.verticesMatrix = matrix.multiply(object.verticesMatrix, rotationMatrix)

	return object
end

local function translateObject(object, x, y, z)
	for i = 1, #object.verticesMatrix do
		object.verticesMatrix[i][1], object.verticesMatrix[i][2], object.verticesMatrix[i][3] = object.verticesMatrix[i][1] + x, object.verticesMatrix[i][2] + y, object.verticesMatrix[i][3] + z
	end

	return object
end

local function scaleObject(object, x, y, z)
	local scaleMatrix = matrix.new({
		{ x, 0, 0 },
		{ 0, y, 0 },
		{ 0, 0, z },
	})

	object.verticesMatrix = matrix.multiply(object.verticesMatrix, scaleMatrix)
	
	return object
end

local function rotateObject(object, x, y, z, angle)
	local sin, cos = math.sin(angle), math.cos(angle)
	local rotationMatrix = {
		{ cos + (1 - cos) * x^2, (1 - cos) * x * y - sin * z, (1 - cos) * x * z + sin * y},
		{ (1 - cos) * y * x }
	}

	object.verticesMatrix = matrix.multiply(object.verticesMatrix, rotationMatrix)

	return object
end

function OCGL.newObject(vector3Vertices)
	local object = {}

	object.verticesMatrix = OCGL.convertVector3ArrayToVerticesMatrix(vector3Vertices)
	object.rotateAroundAxis = rotateObjectAroundAxis
	object.translate = translateObject
	object.scale = scaleObject
	object.rotate = rotateObject

	return object
end

-------------------------------------------------------- Primitive rendering --------------------------------------------------------

function OCGL.renderLineBetweenTwoVertices(vertex1, vertex2, color)
	local x, y = math.floor(buffer.screen.width / 2), math.floor(buffer.screen.height)
	buffer.semiPixelLine(
		math.floor(x + vertex1[1]),
		math.floor(y + vertex1[2]),
		math.floor(x + vertex2[1]),
		math.floor(y + vertex2[2]),
		color
	)
	
	-- buffer.line(
	-- 	math.floor(x + vertex1[1]),
	-- 	math.floor(y + vertex1[2]),
	-- 	math.floor(x + vertex2[1]),
	-- 	math.floor(y + vertex2[2]),
	-- 	0x0, color, "█"
	-- )
end

function OCGL.renderTriangle(vertex1, vertex2, vertex3, renderMode, color)
	if renderMode == OCGL.renderModes.wireframe then
		OCGL.renderLineBetweenTwoVertices(vertex1, vertex2, color)
		OCGL.renderLineBetweenTwoVertices(vertex2, vertex3, color)
		OCGL.renderLineBetweenTwoVertices(vertex1, vertex3, color)
	else
		error("Rendermode enum " .. tostring(renderMode) .. " doesn't exists")
	end
end

-------------------------------------------------------- Mesh object --------------------------------------------------------

function OCGL.newIndexedTriangle(indexOfVertex1, indexOfVertex2, indexOfVertex3)
	return {
		indexOfVertex1,
		indexOfVertex2,
		indexOfVertex3
	}
end

local function renderMesh(mesh, renderMode)
	for triangleIndex = 1, #mesh.triangles do
		OCGL.renderTriangle(
			mesh.verticesMatrix[mesh.triangles[triangleIndex][1]],
			mesh.verticesMatrix[mesh.triangles[triangleIndex][2]],
			mesh.verticesMatrix[mesh.triangles[triangleIndex][3]],
			renderMode, 0xFFFFFF
		)
	end

	return mesh
end

function OCGL.newMesh(vector3Vertices, triangles)
	local mesh = OCGL.newObject(vector3Vertices)

	mesh.triangles = triangles
	mesh.render = renderMesh

	return mesh
end

-------------------------------------------------------- Line object --------------------------------------------------------

local function renderLine(line)
	OCGL.renderLineBetweenTwoVertices(
		line.verticesMatrix[1],
		line.verticesMatrix[2],
		line.color
	)
end

function OCGL.newLine(point1, point2, color)
	local line = OCGL.newObject({ point1, point2 })

	line.color = color
	line.render = renderLine

	return line
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

-------------------------------------------------------- Plane object --------------------------------------------------------

function OCGL.newPlane(startPoint, width, height)
	return OCGL.newMesh(
		{
			OCGL.newVector3(startPoint[1], startPoint[2], startPoint[3]),
			OCGL.newVector3(startPoint[1], startPoint[2], startPoint[3] + height),
			OCGL.newVector3(startPoint[1] + width, startPoint[2], startPoint[3] + height),
			OCGL.newVector3(startPoint[1] + width, startPoint[2], startPoint[3]),
		},
		{
			OCGL.newIndexedTriangle(1, 2, 3),
			OCGL.newIndexedTriangle(1, 4, 3)
		}
	)
end

-------------------------------------------------------- Cube object --------------------------------------------------------

-- Start point is a bottom left nearest corner of cube
function OCGL.newCube(startPoint, size)
	return OCGL.newMesh(
		{
			-- (1-2-3-4)
			OCGL.newVector3(startPoint[1]       , startPoint[2]       , startPoint[3]       ),
			OCGL.newVector3(startPoint[1]       , startPoint[2] + size, startPoint[3]       ),
			OCGL.newVector3(startPoint[1] + size, startPoint[2] + size, startPoint[3]       ),
			OCGL.newVector3(startPoint[1] + size, startPoint[2]       , startPoint[3]       ),
			-- (5-6-7-8)
			OCGL.newVector3(startPoint[1] + size, startPoint[2]       , startPoint[3] + size),
			OCGL.newVector3(startPoint[1] + size, startPoint[2] + size, startPoint[3] + size),
			OCGL.newVector3(startPoint[1]       , startPoint[2] + size, startPoint[3] + size),
			OCGL.newVector3(startPoint[1]       , startPoint[2]       , startPoint[3] + size),
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
		}
	)
end

-------------------------------------------------------- Scene object --------------------------------------------------------

local function iterateThroughSceneObjects(scene, method, ...)
	for objectIndex = 1, #scene.objects do scene.objects[objectIndex][method](scene.objects[objectIndex], ...) end
end

local function renderScene(scene, renderMode)
	iterateThroughSceneObjects(scene, "render", renderMode)
	return scene
end

local function rotateSceneAroundAxis(scene, axis, angle)
	iterateThroughSceneObjects(scene, "rotateAroundAxis", axis, angle)
	return scene
end

local function translateScene(scene, x, y, z)
	iterateThroughSceneObjects(scene, "translate", x, y, z)
	return scene
end

local function scaleScene(scene, x, y, z)
	iterateThroughSceneObjects(scene, "scale", x, y, z)
	return scene
end

local function addObjectToScene(scene, object)
	table.insert(scene.objects, object)
	return scene
end

function OCGL.newScene(...)
	local scene = {}

	scene.objects = {...}
	scene.addObject = addObjectToScene
	scene.rotateAroundAxis = rotateSceneAroundAxis
	scene.translate = translateScene
	scene.scale = scaleScene
	scene.render = renderScene

	return scene
end

-------------------------------------------------------- Axis lines --------------------------------------------------------

function OCGL.addAxisLinesToScene(scene, range)
	scene:addObject(OCGL.newLine(OCGL.newVector3(0, 0, -range), OCGL.newVector3(0, 0, range), OCGL.axisColors.x))
	scene:addObject(OCGL.newLine(OCGL.newVector3(0, -range, 0), OCGL.newVector3(0, range, 0), OCGL.axisColors.y))
	scene:addObject(OCGL.newLine(OCGL.newVector3(-range, 0, 0), OCGL.newVector3(range, 0, 0), OCGL.axisColors.z))
	return scene
end

-------------------------------------------------------- Playground --------------------------------------------------------



-------------------------------------------------------- Constants --------------------------------------------------------

return OCGL
