
local matrixLibrary = {}

---------------------------------------------------- Matrix tables creation ----------------------------------------------------------------

function matrixLibrary.newIdentityMatrix(size)
	local matrix = {}

	for y = 1, size do
		matrix[y] = {}
		for x = 1, size do
			matrix[y][x] = (x == y) and 1 or 0
		end
	end

	return matrix
end

function matrixLibrary.newCofactorMatrix(matrix)
	local cofactorMatrix = {}
	for y = 1, #matrix do
		cofactorMatrix[y] = {}
		for x = 1, #matrix[y] do
			cofactorMatrix[y][x] = matrixLibrary.getCofactor(matrix, y, x)
		end
	end

	return cofactorMatrix
end

function matrixLibrary.newAdjugateMatrix(matrix)
	return matrixLibrary.transpose(matrixLibrary.newCofactorMatrix(matrix))
end

function matrixLibrary.newFilledMatrix(width, height, value)
	local matrix = {}

	for y = 1, height do
		matrix[y] = {}
		for x = 1, width do
			matrix[y][x] = value
		end
	end

	return matrix
end

function matrixLibrary.copy(matrix)
	local newMatrix = {}

	for y = 1, #matrix do
		newMatrix[y] = {}
		for x = 1, #matrix[y] do
			newMatrix[y][x] = matrix[y][x]
		end
	end

	return newMatrix
end

function matrixLibrary.print(matrix)
	print("Matrix size: " .. #matrix .. "x" .. #matrix[1])
	for y = 1, #matrix do
		for x = 1, #matrix[y] do
			io.write(tostring((not matrix[y]) and "nil" or matrix[y][x]))
			io.write(' ')
		end
		print("")
	end

	return matrix
end

---------------------------------------------------- Matrix arithmetic operations ----------------------------------------------------------------

function matrixLibrary.multiply(matrix, data)
	local dataType = type(data)
	if dataType == "table" then
		if (#matrix[1] ~= #data) then error("Couldn't multiply matrixes AxB: A[columns] ~= B[rows]") end
		
		local result = {}
		for i = 1, #matrix do
			result[i] = {}
			for j = 1, #data[1] do
				local resultElement = 0
				for k = 1, #matrix[1] do
					resultElement = resultElement + (matrix[i][k] * data[k][j])
				end
				result[i][j] = resultElement
			end
		end

		return result
	elseif dataType == "number" then
		for y = 1, #matrix do
			for x = 1, #matrix[y] do
				matrix[y][x] = matrix[y][x] * data
			end
		end

		return matrix
	else
		error("Unsupported operation data type: " .. tostring(dataType))
	end
end

function matrixLibrary.divide(matrix, data)
	local dataType = type(data)
	if dataType == "table" then
		error("Matrix by matrix division doesn't supported yet")
	elseif dataType == "number" then
		for y = 1, #matrix do
			for x = 1, #matrix[y] do
				matrix[y][x] = matrix[y][x] / data
			end
		end

		return matrix
	else
		error("Unsupported operation data type: " .. tostring(dataType))
	end
end

---------------------------------------------------- Matrix resizing methods ----------------------------------------------------------------

function matrixLibrary.addRow(matrix, row)
	if (#matrix[1] ~= #row) then error("Insertion row size doesn't match matrix row size: " .. #row .. " vs " .. #matrix[1]) end
	
	table.insert(matrix, row)

	return matrix
end

function matrixLibrary.addColumn(matrix, column)
	if (#matrix ~= #column ) then error("Insertion column size doesn't match matrix column size: " .. #column .. " vs " .. #matrix) end
	
	for y = 1, #column do
		table.insert(matrix[y], column[y])
	end

	return matrix
end

function matrixLibrary.removeRow(matrix, row)
	if row > #matrix then error("Can't remove row that is bigger then matrix height") end
	
	table.remove(matrix, row)

	return matrix
end

function matrixLibrary.removeColumn(matrix, column)
	if column > #matrix[1] then error("Can't remove column that is bigger then matrix width") end
	
	for y = 1, #matrix do
		table.remove(matrix[y], column)
	end

	return matrix
end

---------------------------------------------------- Matrix advanced manipulation methods ----------------------------------------------------------------

function matrixLibrary.transpose(matrix)
	local transposedMatrix = {}
	for x = 1, #matrix[1] do
		transposedMatrix[x] = {}
		for y = 1, #matrix do
			transposedMatrix[x][y] = matrix[y][x]
		end
	end
	return transposedMatrix
end

function matrixLibrary.getMinor(matrix, row, column)
	return matrixLibrary.getDeterminant(matrixLibrary.removeColumn(matrixLibrary.removeRow(matrixLibrary.copy(matrix), row), column))
end

function matrixLibrary.getCofactor(matrix, row, column)
	return (-1) ^ (row + column) * matrixLibrary.getMinor(matrix, row, column)
end

function matrixLibrary.getDeterminant(matrix)
	local matrixSize = #matrix
	if matrixSize ~= #matrix[1] then error("Can't find determinant for matrix, row count != column count: " .. #matrix .. "x" .. #matrix[1]) end
	
	if matrixSize == 1 then
		return matrix[1][1]
	elseif matrixSize == 2 then
		return matrix[1][1] * matrix[2][2] - matrix[1][2] * matrix[2][1]
	else
		local determinant = 0
		for j = 1, matrixSize do
			determinant = determinant + matrixLibrary.getCofactor(matrix, 1, j) * matrix[1][j]
		end

		return determinant
	end
end

function matrixLibrary.invert(matrix)
	local determinant = matrixLibrary.getDeterminant(matrix)
	if determinant == 0 then error("Can't invert matrix with determinant equals 0") end

	return matrixLibrary.divide(matrixLibrary.newAdjugateMatrix(matrix), determinant)
end

------------------------------------------------------------------------------------------------------------------------

-- local m = {
-- 	{2, 5, 4},
-- 	{-5, 5, 6},
-- 	{1, 3, 7},
-- }
-- matrixLibrary.print(m)
-- m = matrixLibrary.invert(m)
-- matrixLibrary.print(m)

------------------------------------------------------------------------------------------------------------------------

return matrixLibrary

