local M = {}

local mtmix = require'mtmix'

local var_mt = {
	__metatable={ expr=true, single_nom=true, 'single_nom' },
}

local function snom(mul, var)
	if mul==0 then return nil end
	return setmetatable({ var=var, mul=mul or 1	}, var_mt)
end
M.term = snom

function M.var(name, mul, pow)
	return setmetatable({ var={ [name]=pow or 1 }, mul=mul or 1	}, var_mt)
end

function var_mt:__tostring ()
	local s = (self.mul==1 and '' or self.mul..'*')
	for k, v in pairs(self.var or {}) do
		s = s..tostring(k)..(v==1 and '' or '^'..v)..'*'
	end
	return s:gsub('%*$', ''):gsub('^$', '1')
end



var_mt.__add = mtmix.overload{
	single_nom={
		number=function(s, n) return M.polynom(s, snom(n)) end,
		single_nom=function(s, s2) return M.polynom(s, s2) end
	},
	number={
		single_nom=function(n, s) return M.polynom(s, snom(n)) end
	},
}

var_mt.__sub = mtmix.overload{
	single_nom={
		number=function(s, n) return M.polynom(s, snom(-n)) end
	},
	number={
		single_nom=function(n, s) return M.polynom(s, snom(-n)) end
	},
}

var_mt.__mul = mtmix.overload{
	single_nom={
		number=function(s, n) return snom(s.mul*n, s.var) end,
		single_nom=function(s, s2)
			local var = {}
			for k,v in pairs(s.var or {}) do var[k]=v end
			for k,v in pairs(s2.var or {}) do
				if var[k] then var[k]=var[k]+v else	var[k]=v end
				if var[k]==0 then var[k]=nil end
			end
			return snom(s.mul*s2.mul, var)
		end,
		polynom=function(s, p)
			local n = {}
			for k,v in ipairs(p) do
				local var = {}
				for ks,vs in pairs(s.var or {}) do var[ks]=vs end
				for ks,vs in pairs(v.var or {}) do
					if var[ks] then var[ks]=var[ks]+vs else var[ks]=vs end
					if var[ks]==0 then var[ks]=nil end
				end
				table.insert(n, snom(s.mul*v.mul, var))
			end
			return M.polynom(table.unpack(n))
		end,
	},
	number={
		single_nom=function(n, s) return snom(s.mul*n, s.var) end,
	},
}

var_mt.__div = mtmix.overload{
	single_nom={
		number=function(s, n) return snom(s.mul/n, s.var) end,
		single_nom=function(s, s2)
			local var = {}
			for k,v in pairs(s.var or {}) do var[k]=v end
			for k,v in pairs(s2.var or {}) do
				if var[k] then
					var[k]=var[k]-v
					if var[k]==0 then var[k]=nil end
				else
					var[k]=-v
				end
			end
			return snom(s.mul/s2.mul, var)
		end,
		polynom=function(s, p)
			local n = {}
			for k,v in ipairs(p) do
				local var = {}
				for ks,vs in pairs(s.var or {}) do var[ks]=vs end
				for ks,vs in pairs(v.var or {}) do
					if var[ks] then var[ks]=var[ks]-vs else var[ks]=-vs end
					if var[ks]==0 then var[ks]=nil end
				end
				table.insert(n, snom(s.mul/v.mul, var))
			end
			return M.polynom(table.unpack(n))
		end,
	},
	number={
		single_nom=function(n, s) return snom(n/s.mul, s.var) end,
	},
}

var_mt.__pow = mtmix.overload{
	single_nom={
		number=function(s, n)
			local var = {}
			for k,v in pairs(s.var or {}) do
				var[k]=v*n
				if var[k]==0 then var[k]=nil end
			end
			return snom(s.mul^n, var)
		end,
	},
}


var_mt.__index={	eval=function(self) return self end  }

function var_mt.__index.vareq(a, b)
	if b.var==nil and a.var==nil then return true end
	for ka, va in pairs(a.var or {}) do
		if b.var and b.var[ka]~=va then return false end
	end
	for kb, vb in pairs(b.var or {}) do
		if a.var and a.var[kb]~=vb then return false end
	end
	return true
end

function var_mt.__eq(a, b)
	if b.var==nil and a.var==nil then return a.mul==b.mul end
	for ka, va in pairs(a.var or {}) do
		if b.var and b.var[ka]~=va then return false end
	end
	for kb, vb in pairs(b.var or {}) do
		if a.var and a.var[kb]~=vb then return false end
	end
	return a.mul==b.mul
end



function var_mt.__index:calc(vars)
	local r = self.mul
	for k, v in pairs(self.var or {}) do
		local r1 = assert(tonumber(vars[k]), k)^v
		r = r*r1
	end
	return r
end




local polynom_mt = { __index={}, __metatable={ expr=true, polynom=true, 'polynom' } }

function M.polynom(...)
	local m = { ... }
	if #m==1 then return m[1] end
	if #m==0 then return 0 end
	return setmetatable(m, polynom_mt)
end

function polynom_mt:__tostring()
	local s = ''
	for k=1, #self do
		s=s..tostring(self[k]):gsub('^([^%-])', '+%1')
	end
	return s:gsub('^%+', '')
end

function polynom_mt.__index:term(x)
	for k=1, #self do
		local v = self[k]
		if v==x then return v end
	end
end

polynom_mt.__add = mtmix.overload{
	polynom={
		number=function(s, n)
			local p, is_find = {}, false
			for _,v in ipairs(s) do
				if next(v, next(v))==nil then
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
				if v:vareq(s) then
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

polynom_mt.__sub = mtmix.overload{
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
				if v:vareq(s) then
					table.insert(p, snom(v.mul-s.mul, s.var)) is_find=true
				else
					table.insert(p, v)
				end
			end
			if not is_find then table.insert(p, snom(-s.mul, s.var)) end
			return M.polynom(table.unpack(p))
		end,
	},
	number={
		polynom=function(n, s)
			return n+(-1*s)
		end
	},
}

polynom_mt.__mul = mtmix.overload{
	polynom={
		number=function(s, n)
			local p = {}
			for _,v in ipairs(s) do
				table.insert(p, v*n)
			end
			return M.polynom(table.unpack(p))
		end,
		polynom=function(s, s2)
			local p = {}
			for _,v in ipairs(s) do table.insert(p, v*s2) end
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

polynom_mt.__div = mtmix.overload{
	polynom={
		number=function(s, n)
			local p = {}
			for _,v in ipairs(s) do
				table.insert(p, v/n)
			end
			return M.polynom(table.unpack(p))
		end,
		polynom=function(s, s2)
			local p = {}
			for _,v in ipairs(s) do table.insert(p, v/s2) end
			return M.polynom(table.unpack(p))
		end,
		single_nom=function(s, s2)
			local p = {}
			for _,v in ipairs(s) do table.insert(p, v/s2) end
			return M.polynom(table.unpack(p))
		end,
	},
	number={
		polynom=function(n, s)
			local p = {}
			for _,v in ipairs(s) do
					table.insert(p, n/v)
			end
			return M.polynom(table.unpack(p))
		end
	},
}

polynom_mt.__pow = mtmix.overload{
	polynom={
		number=function(s, n)
			if math.type(n)=='integer' then
				local p = s
				if n>0 then
					for k=2, n do p=p*s end
				elseif n<0 then
				elseif n==0 then
					p=snom(1)
				end
				return p
			end
		end,
	},
}

polynom_mt.__eq = mtmix.overload()

function polynom_mt.__eq.polynom.number(p, n)
	return #p==1 and p[1].var==nil and p[1].mul==n
end

function polynom_mt.__eq.polynom.single_nom(p, s)
	return #p==1 and p[1]==s
end

function polynom_mt.__eq.polynom.polynom(p1, p2)
	if #p1~=#p2 then return false end
	for _,v in ipairs(p1) do
		local is_find
		for _,v2 in ipairs(p2) do
			if v2==v then is_find=true break end
		end
		if not is_find then return false end
	end
	return true
end



function polynom_mt.__index:eval()
	return self
end

function polynom_mt.__index:calc(vars)
	local r = 0
	for k=1, #self do
		r=r+self[k]:calc(vars)
	end
	return r
end





local equation_mt = { __index={}, __metatable={ expr=true, equation=true, 'equation' } }

function M.equation(l, r)
	return setmetatable({l=l, r=r}, equation_mt)
end

function equation_mt:__tostring()
	return tostring(self.l)..'=='..tostring(self.r)
end

equation_mt.__add = mtmix.overload{
	equation={
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
			return M.equation(table.unpack(p))
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
			return M.equation(table.unpack(p))
		end,
		equation=function(p1, p2)
			local p, is_find = {}, false
			for _,v in ipairs(p1) do
				table.insert(p, p2+v)
			end
			return M.equation(table.unpack(p))
		end
	},
	number={
		equation=function(n, s)
			local p, is_find = {}, false
			for _,v in ipairs(s) do
				if next(v, next(v))==nil then
					table.insert(p, snom(n+v.mul)) is_find=true
				else
					table.insert(p, v)
				end
			end
			if not is_find then table.insert(p, snom(n)) end
			return M.equation(table.unpack(p))
		end
	},
}

equation_mt.__sub = mtmix.overload{
	equation={
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
			return M.equation(table.unpack(p))
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
			return M.equation(table.unpack(p))
		end,
	},
	number={
		equation=function(n, s)
			return n+(-1*s)
		end
	},
}

equation_mt.__mul = mtmix.overload{
	equation={
		number=function(s, n)
			local p = {}
			for _,v in ipairs(s) do
				table.insert(p, v*n)
			end
			return M.equation(table.unpack(p))
		end,
		equation=function(s, s2)
			local p = {}
			for _,v in ipairs(s) do table.insert(p, v*s2) end
			return M.equation(table.unpack(p))
		end,
		single_nom=function(s, s2)
			local p = {}
			for _,v in ipairs(s) do table.insert(p, v*s2) end
			return M.equation(table.unpack(p))
		end,
	},
	number={
		equation=function(n, s)
			local p = {}
			for _,v in ipairs(s) do
					table.insert(p, v*n)
			end
			return M.equation(table.unpack(p))
		end
	},
}

equation_mt.__div = mtmix.overload{
	equation={
		number=function(s, n)
			local p = {}
			for _,v in ipairs(s) do
				table.insert(p, v/n)
			end
			return M.equation(table.unpack(p))
		end,
		equation=function(s, s2)
			local p = {}
			for _,v in ipairs(s) do table.insert(p, v/s2) end
			return M.equation(table.unpack(p))
		end,
		single_nom=function(s, s2)
			local p = {}
			for _,v in ipairs(s) do table.insert(p, v/s2) end
			return M.equation(table.unpack(p))
		end,
	},
	number={
		equation=function(n, s)
			local p = {}
			for _,v in ipairs(s) do
					table.insert(p, n/v)
			end
			return M.equation(table.unpack(p))
		end
	},
}

equation_mt.__pow = mtmix.overload{
	equation={
		number=function(s, n)
			if math.type(n)=='integer' then
				local p = s
				if n>0 then
					for k=2, n do p=p*s end
				elseif n<0 then
				elseif n==0 then
					p=snom(1)
				end
				return p
			end
		end,
	},
}

function equation_mt.__index:eval()
	return self
end

function equation_mt.__index:calc(vars)
	local r = 0
	for k=1, #self do
		r=r+self[k]:calc(vars)
	end
	return r
end

return M