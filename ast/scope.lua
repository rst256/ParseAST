
local scope_mt = { __index={} }

local function new_scope(up_scope)
	return setmetatable({ scope={ [0]=up_scope } }, scope_mt)
end

function scope_mt:__tostring()
	return 'scope: '..tostring(self.scope[0])..' '
end

function scope_mt.__index:sub()
	self.scope = { [0]=self.scope }
	return setmetatable({ scope=self.scope }, scope_mt)
end

function scope_mt.__index:up()
	self.scope = assert(self.scope[0])
	return self
end

function scope_mt.__index:define(sym_name, value)
	local name
	if type(sym_name)=='table' then name=sym_name.str else name=sym_name end
	assert(self.scope[name]==nil, 'redefine `'..tostring(sym_name)..
		'` '..tostring(self.scope[name]))
	self.scope[name] = value
	return value
end

function scope_mt.__index:find(name, local_only)
	if local_only then
		return self.scope[name], self.scope
	end
	local sc = self.scope
	while sc do
		local sym = sc[name]
		if sym then return sym, sc else sc = sc[0] end
	end
end

function scope_mt:__call(name, local_only)
	if local_only then
		return self.scope[name], self.scope
	end
	local sc = self.scope
	while sc do
		local sym = sc[name]
		if sym then return sym, sc else sc = sc[0] end
	end
end



return new_scope