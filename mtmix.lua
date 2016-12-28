local M = {}

local mtmix = {}
local mtmix_mt = { __index=mtmix }

function mtmix_mt:__tostring()
	return '('..tostring(self.l)..' '..
		tostring(self.op)..' '..tostring(self.r)..')'
end

function mtmix:eval()
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

local function mtmix_default_constructor(t)
	if t~=nil then
		assert(type(t)=='table')
		return t
	else
		return {}
	end
end

function M.mtmix(this, constructor)
	local this = this or {}
--	local ctor = constructor or mtmix_default_constructor
	return setmetatable({
		ctor = constructor or mtmix_default_constructor
	}, {
		__call=function(self, ...)
			local t = self.ctor(...) assert(type(t)=='table')
			return setmetatable(t, self)
		end,
		__index=print,
		__newindex=function(self, name, value)
			rawset(self, '__'..name, value)
		end
	})--mtmix_mt
end

return M