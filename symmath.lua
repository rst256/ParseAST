local M = {}

local overload_mt = { __metatable={ overload=true, callable=true } }

function overload_mt:__call(...)
	local ct, err = self.ovl_list, ''
	for k=1, select('#', ...) do

		local t = typeof(select(k, ...))
		for t1, ct1 in pairs(ct) do
			if t[t1] then ct=ct1 err=err..t1..', ' goto next_ct end
		end
		error(err..', ?')
		::next_ct::
	end
--	local fn = self[at]
--	if ct then
		return ct(...)
end

local function overload(ovl_list)
	return setmetatable({ ovl_list=ovl_list or {} }, overload_mt)
end


local var_mt = {
	__metatable={ expr=true, single_nom=true },
--	__index={ var={} },
}

local function snom(mul, var)
	return setmetatable({ var=var, mul=mul or 1	}, var_mt)
end
M.term = snom

function M.var(name, mul, pow)
	return setmetatable({ var={ [name]=pow or 1 }, mul=mul or 1	}, var_mt)
end

function var_mt:__tostring ()
	local s = (self.mul==1 and '' or (self.mul<0 and '' or '+')..self.mul..'*')
	for k, v in pairs(self.var or {}) do
		s = s..tostring(k)..(v==1 and '' or '^'..v)..'*'
	end
	return s:gsub('%*$', ''):gsub('^$', '+1')
end



var_mt.__add = overload{
	single_nom={
		number=function(s, n) return M.polynom(s, snom(n)) end,
		single_nom=function(s, s2) return M.polynom(s, s2) end
	},
	number={
		single_nom=function(n, s) return M.polynom(s, snom(n)) end
	},
}

var_mt.__sub = overload{
	single_nom={
		number=function(s, n) return M.polynom(s, snom(-n)) end
	},
	number={
		single_nom=function(n, s) return M.polynom(s, snom(-n)) end
	},
}

var_mt.__mul = overload{
	single_nom={
		number=function(s, n) return snom(s.mul*n, s.var) end,
		single_nom=function(s, s2)
			local var = {}
			for k,v in pairs(s.var or {}) do var[k]=v end
			for k,v in pairs(s2.var or {}) do
				if var[k] then var[k]=var[k]+v else var[k]=v end
			end
			return snom(s.mul*s2.mul, var)
		end,
	},
	number={
		single_nom=function(n, s) return snom(s.mul*n, s.var) end,
--		number=function(s, n) return snom(s.var, s.add, s.mul*n) end,
	},
}

function var_mt.__eq(a, b)
	for ka, va in pairs(a.var) do
		if b.var[ka]~=va then return false end
	end
	for kb, vb in pairs(b.var) do
		if a.var[kb]~=vb then return false end
	end
	return true
end

var_mt.__index={ eval=function(self) return self end }




local polynom_mt = { __index={}, __metatable={ expr=true, polynom=true } }

function M.polynom(...)
	return setmetatable({ ... }, polynom_mt)
end

function polynom_mt:__tostring ()
	return table.concat(self, ''):gsub('^%+', '')
end

--function polynom_mt.__index:term()
--	return table.concat(self.var, '+')
--end

polynom_mt.__add = overload{
	polynom={
		number=function(s, n)
			local p, is_find = {}, false
			for _,v in ipairs(s) do
				if v.var==nil then
					table.insert(p, snom(v.mul+n)) is_find=true
				else
					table.insert(p, v)
				end
			end
			if not is_find then table.insert(p, snom(n)) end
			return M.polynom(table.unpack(p))
		end,
		single_nom=function(P, s)
			local p, is_find = {}, false
			for _,v in ipairs(P) do
				if v==s then
					table.insert(p, snom(s.mul+v.mul, s.var)) is_find=true
				else
					table.insert(p, v)
				end
			end
			if not is_find then table.insert(p, s) end
			return M.polynom(table.unpack(p))
		end,
		polynom=function(p1, p2)
			local p, is_find = {}, false
			for _,v in ipairs(p1) do
				table.insert(p, p2+v)
			end
--			if not is_find then table.insert(p, snom(n)) end
			return M.polynom(table.unpack(p))
		end
	},
	number={
		polynom=function(n, s)
			local p, is_find = {}, false
			for _,v in ipairs(s) do
				if next(v, next(v))==nil then
					table.insert(p, snom(n+v.mul)) is_find=true
				else
					table.insert(p, v)
				end
			end
			if not is_find then table.insert(p, snom(n)) end
			return M.polynom(table.unpack(p))
		end
	},
}

polynom_mt.__sub = overload{
	polynom={
		number=function(s, n)
			local p, is_find = {}, false
			for _,v in ipairs(s) do
				if next(v, next(v))==nil then
					table.insert(p, snom(v.mul-n)) is_find=true
				else
					table.insert(p, v)
				end
			end
			if not is_find then table.insert(p, snom(-n)) end
			return M.polynom(table.unpack(p))
		end,
		single_nom=function(P, s)
			local p, is_find = {}, false
			for _,v in ipairs(P) do
				if v==s then
					table.insert(p, snom(v.mul-s.mul, s.var)) is_find=true
				else
					table.insert(p, v)
				end
			end
			if not is_find then table.insert(p, s) end
			return M.polynom(table.unpack(p))
		end,
	},
	number={
		polynom=function(n, s)
			return n+(-1*s)
		end
	},
}

polynom_mt.__mul = overload{
	polynom={
		number=function(s, n)
			local p = {}
			for _,v in ipairs(s) do
				table.insert(p, v*n)
			end
			return M.polynom(table.unpack(p))
		end,
		polynom=function(s, s2)
			local p, is_find = {}, false
			for _,v in ipairs(s) do table.insert(p, v) end
			for _,v in ipairs(s2) do
				if next(v, next(v))==nil then
					table.insert(p, snom(v.mul)) is_find=true
				else
					table.insert(p, v)
				end
			end
			if not is_find then table.insert(p, snom(n)) end
			return M.polynom(table.unpack(p))
		end,
		single_nom=function(s, s2)
			local p = {}
			for _,v in ipairs(s) do table.insert(p, v*s2) end
			return M.polynom(table.unpack(p))
		end,
	},
	number={
		polynom=function(n, s)
			local p = {}
			for _,v in ipairs(s) do
					table.insert(p, v*n)
			end
			return M.polynom(table.unpack(p))
		end
	},
}

polynom_mt.__index={ eval=function(self) return self end }

return M