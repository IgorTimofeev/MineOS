
-- Returns first available component with given type
function component.get(type)
	local address = component.list(type)()
	if address then
		return component.proxy(address)
	end

	return nil, "component with type \"" .. type .. "\" doesn't exists"
end

-- Checks if component with gieven type is available in computer environment
function component.isAvailable(type)
	return component.list(type)() and true or false
end
