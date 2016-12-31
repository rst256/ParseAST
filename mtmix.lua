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



local _mt = {
	__index=function() return false end,
	__tostring=function(self)
		return self[1] or '?'
	end,
}

local base_typeof = {
	['function'] = setmetatable({ ['function']=true, callable=true, 'function' }, _mt),
	['number'] = setmetatable({ ['number']=true, 'number' }, _mt),
	['nil'] = setmetatable({ ['nil']=true, 'nil' }, _mt),
	['string'] = setmetatable({ ['string']=true, 'string' }, _mt),
	['boolean'] = setmetatable({ ['boolean']=true, 'boolean' }, _mt),
	['userdata'] = setmetatable({ ['userdata']=true, 'userdata' }, _mt),
	['thread'] = setmetatable({ ['thread']=true, 'thread' }, _mt),
}

function M.typeof(self)
	local t = type(self)
	if t=='table' then
		local mt = getmetatable(self)
		if type(mt)=='table' then
			if mt.callable==nil and mt.__call then rawset(mt, 'callable', true) end
			return setmetatable(mt, _mt)
		else
			return setmetatable({ table=true, 'table' }, _mt)
		end
	else
		return base_typeof[t]
	end
end

local overload_mt = {
	__metatable={ overload=true, callable=true, 'overload' },
	__index=function(self, name)
		local v=self.ovl_list[name] or {}
		rawset(self.ovl_list, name, v)
		return v
	end,
	__newindex=function(self, name, v)
		rawset(self.ovl_list, name, v)
	end,
}

function overload_mt:__call(...)
	local ct, err = self.ovl_list, ''
	for k=1, select('#', ...) do

		local t = M.typeof(select(k, ...))
		for t1, ct1 in pairs(ct) do
			if t[t1] then ct=ct1 err=err..t1..', ' goto next_ct end
		end
		for j=k, select('#', ...) do
			err=err..tostring(M.typeof(select(j, ...)))..', '
		end
		error(err:gsub(', $', '')..'\n'..tostring(self), 2)
		::next_ct::
	end
	return ct(...)
end

local function ovl_tostr(list, prefix, node)
	if type(node)~='table' or next(node)==nil then
		table.insert(list, (#list+1)..'. '..(prefix:gsub(', $', '')))
	else
		for k,v in pairs(node) do ovl_tostr(list, prefix..tostring(k)..', ', v) end
	end
end

function overload_mt:__tostring()
	local list = {}
	ovl_tostr(list, '', self.ovl_list)
	return table.concat(list, '\n')
end

function M.overload(ovl_list)
	return setmetatable({ ovl_list=ovl_list or {} }, overload_mt)
end

return M