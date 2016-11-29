
local matrix = {}

------------------------------------------------------------------------------------------------------------------------

function matrix.debug(object)
	print( "Matrix dimensions: ", #object, #object[1], "\n" )

	if ( #object == 0 ) then
		print("Empty matrix.")
		return
	end

	for y = 1, #object do
		for x = 1, #object[y] do
			io.write( tostring( (not object[y]) and "nil" or object[y][x] ) )
			io.write( ' ' )
		end
		print("")
	end

	return object
end

function matrix.addRow(object, row)
	if (#object[1] ~= #row) then error("Insertion row size doesn't match matrix row size: " .. #row .. " vs " .. #object[1]) end
	table.insert(object, row)

	return object
end

function matrix.addColumn(object, column)
	if (#object ~= #column ) then error("Insertion column size doesn't match matrix column size: " .. #column .. " vs " .. #object) end
	for y = 1, #column do
		table.insert(object[y], column[y])
	end

	return object
end

function matrix.multiply(object, object2)
	if ( #object[1] ~= #object2 ) then error("Couldn't multiply matrixes AxB: A[columns] ~= B[rows]") end

	local result = matrix.newFilledMatrix(#object, #object2[1], nil)

	for i = 1, #object do
		result[i] = {}

		for j = 1, #object2[1] do
			local resultElement = 0

			for k = 1, #object[1] do
				resultElement = resultElement + (object[i][k] * object2[k][j])
			end

			result[i][j] = resultElement
		end
	end

	return result
end

function matrix.clear(object)
	for y = 1, #object do object[y] = nil end
	return object
end

function matrix.fill(object, width, height, value)
	object:clear()

	for y = 1, height do
		for x = 1, width do
			object[y][x] = value
		end
	end

	return object
end

------------------------------------------------------------------------------------------------------------------------

function matrix.new(array)
	local object = array or {}
	
	object.debug = matrix.debug
	object.addRow = matrix.addRow
	object.addColumn = matrix.addColumn
	object.multiply = matrix.multiply
	object.fill = matrix.fill
	object.clear = matrix.clear
	
	return object
end

function matrix.newIdentityMatrix(size)
	local object = matrix.new()

	for y = 1, size do
		object[y] = {}
		for x = 1, size do
			object[y][x] = (x == y) and 1 or 0
		end
	end

	return object
end

function matrix.newFilledMatrix(width, height, value)
	local object = matrix.new()

	for y = 1, height do
		object[y] = {}
		for x = 1, width do
			object[y][x] = value
		end
	end

	return object
end

------------------------------------------------------------------------------------------------------------------------

return matrix

