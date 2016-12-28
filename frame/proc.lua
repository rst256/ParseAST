local M = {}

local proc = {}
local proc_mt = { __index=proc }

function proc_mt:__tostring()
	return '('..tostring(self.l)..' '..
		tostring(self.op)..' '..tostring(self.r)..')'
end

function proc:run()
	local o, l, r = tostring(self.op),
		(tonumber(tostring(self.l)) or self.l:eval()),
		assert(tonumber(tostring(self.r)) or self.r:eval())
	if o=='+'  then return l+r  end
	if o=='-'  then return l-r  end
	if o=='*'  then return l*r  end
	if o=='/'  then return l/r  end
	if o=='|'  then return l|r  end
	if o=='&'  then return l&r  end
	if o=='>>' then return l>>r end
	if o=='<<' then return l<<r end
end

local function proc_default_constructor(t)
	if t~=nil then
		assert(type(t)=='table')
		return t
	else
		return {}
	end
end

function M.proc(this, constructor)
	local this = this or {}
--	local ctor = constructor or proc_default_constructor
	return setmetatable({
		ctor = constructor or proc_default_constructor
	}, {
		__call=function(self, ...)
			local t = self.ctor(...) assert(type(t)=='table')
			return setmetatable(t, self)
		end,
		__index=print,
		__newindex=function(self, name, value)
			rawset(self, '__'..name, value)
		end
	})--proc_mt
end

return M