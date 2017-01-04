function table.concat(tbl, sep)
	local sep = sep or ', '
	local s, i, v = '', 1, tbl[1]
	while v do
		s=s..tostring(v)
		i=i+1
		v=tbl[i]
		if not v then break end
		s=s..sep
	end
	return s
end

function table:index(parent)
	return setmetatable(self, { __index=parent })
end

function io.readall(file, def)
	if type(file)=='string' then
		if def~=nil then
			file = io.open(file)
			if not file then return def end
		else
			file = assert(io.open(file), 'can\'t open file"'..file..'"')
		end
	end
	local res = file:read'*a'
	file:close()
	return res
end

function io.writeall(file, str)
	if type(file)=='string' then
		file = assert(io.open(file, 'w+'), 'can\'t open file"'..file..'"')
	end
	file:write(str)
	file:close()
end




function string:esc_pattern()
	local res = self:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
	return res
end



local lex_mem = require'lm'
local scope = require('ast.scope')








local function parse_rule(self, tok)
	local t, v = self:parse(tok)
	if t==nil then
		if self.optional then return tok, self.default else return end
	end
	if self.rule_mt then setmetatable(v, self.rule_mt) end
	return t, v
end


local function proxy(orig, new)
	return setmetatable(new or {}, {
		__call=parse_rule,
		__index=orig,
		__len=function() return #orig end,
		__concat=function(a, b) return tostring(a)..tostring(b) end,
	})
end





local rule = { temp=true }

function rule:opt(default)
	local v
	if self.temp then
		v = self
	else
		v = proxy(self, { temp=true })
	end
	v.optional = true
	v.default = default
	return v
end

function rule:mt(mt)
	if not mt.__concat then
		mt.__concat=function(a, b) return tostring(a)..tostring(b) end
	end
	local v
	if self.temp then
		v = self
	else
		v = proxy(self, { temp=true })
	end
	v.rule_mt = mt
	return v
end

--function rule:mt(mt)
--	self.rule_mt = mt
--	return self
--end


local function gen_rule_mt(mtd)
	return {
		__call=parse_rule,
		__index=table.index(mtd, rule),
		__concat=function(a, b) return tostring(a)..tostring(b) end,
	}
end

local function gen_rule_ctor(mtd, ctor)
	local mt = gen_rule_mt(mtd)
	if ctor then
		return function(...)
			return setmetatable(assert(ctor(...)), mt)
		end
	else
		return function(this)
			return setmetatable(this or {}, mt)
		end
	end
end

local function gen_rule(mtd)
	local mt = {
		__call=parse_rule,
		__index=table.index(mtd, rule),
		__concat=function(a, b) return tostring(a)..tostring(b) end,
	}
	return function(this)
		if this then assert(getmetatable(this)==nil) end
		return setmetatable(this or {}, mt)
	end
end

local sequence = { rules_nm={} } local sequence_mt = { __index=sequence }
local alt = {} local iif = {}
local rep = {} local rep_mt = { __index=rep }
local enx = {} local enx_mt = { __index=enx }

local M = {
	seq=gen_rule_ctor(sequence),
	alt=gen_rule_ctor(alt, function(alts)
		local alts = alts or {}
		for k=1, #alts do
			assert(not alts[k].optional)
		end
		return alts
	end),
	rep=gen_rule_ctor(rep, function(items)
		return { items=assert(items) }
	end),
	enx=gen_rule(enx),
	iif=gen_rule_ctor(iif, function(cond, th, el)
		assert(not cond.optional)
		return { cond=cond, th=th, el=el }
	end),
}

function sequence:add(rule, name, ...)
	table.insert(self, assert(rule))
	if type(name)=='string' then
		self.rules_nm = rawget(self, 'rules_nm') or {}
		self.rules_nm[#self] = name
	elseif type(name)=='table' then
		return self:add(name, ...)
	end
	return self
end

function sequence:parse(tok0)
	local rs, rn = assert(self), assert(self.rules_nm)
	local tok, this = tok0, {}
	for k=1, #rs do
--		if not tok then return end
		local t, v = rs[k](tok)
		if t==nil then return end
		if v~=nil then
			this[rn[k] or (#this+1)] = v
		end
		tok = t
	end
	return tok, this
end




function alt:add(...)
	for k=1, select('#', ...) do
		local rule = select(k, ...)
		assert(not rule.optional)
		table.insert(self, rule)
	end
	return self
end

function alt:parse(tok)
	local rs = assert(self)
--	if not tok then return end
	for k=1, #rs do
		local t, v = rs[k](tok)
		if t~=nil then
			return t, v
		end
	end
end


rep.default = setmetatable({}, {
	__tostring=function() return '' end,
	__concat=function(a, b) return tostring(a)..tostring(b) end,
	__newindex=error,
})

--function rep:items(rule)
--	self.items = assert(rule)
--	return self
--end

function rep:parse(tok0)
	local ri = assert(self.items)
	local tok, val = ri(tok0)
	if tok==nil then
		return
	end
	local this = { val }
	while tok do
		local t, v = ri(tok)
		if t==nil then break end
		table.insert(this, v or t)
		tok = t
	end
	return tok, this
end




function enx:parse(tok)
	local t, v = assert(self.rule)(tok)
	if t==nil then return end
	if t==false then return t, v end
	local te = assert(self.ex_rule)(t)
	if te==nil then return t, v end
end








function iif:parse(tok)
	if not tok then return tok end
	local t, v = assert(self.cond)(tok)
	if t==nil then
		if self.el then return self.el(tok) else return tok end
	else
		if t==false then return end
		return assert(self.th)(t)
	end
end





function M.lexeme(p)
	local r = {
		pattern=assert(tonumber(tonumber(p) or lexemes[p:match'%s*(.+)']), p),
		is_capture=tostring(p):sub(1,1)~=' '
	}

	return setmetatable(r, {
		__tostring=function(self)
			return assert(lexemes[self.pattern])
		end,
		__index={
			rule_type='lexeme',
		},
		__call=function(self, tok)
			if tok and tok.lexeme==self.pattern then
				if self.is_capture then
					if self.capt_mt then
						self.capt_mt.__index=self.capt_mt.__index or {}
						self.capt_mt.__index.__rule=self
						return tok.next or false, setmetatable({ tok=tok }, self.capt_mt)
					else
						return tok.next or false, setmetatable({ tok=tok }, {
							__tostring=function(s) return tostring(s.tok) end,
							__index={ __rule=self },
							__concat=function(a, b) return tostring(a)..tostring(b) end,
						})
					end
				else
					return tok.next or false
				end
			end
		end
	})
end


M.new = setmetatable({}, {
	__index=function(_, name) return M[name]() end,
})


local gmr_mt = {}
local gmr_frwd_rule_mt = gen_rule_mt({ temp=false })

function gmr_mt:__index(name)
	local frwd_rules = rawget(self, true)
	local frwd_rule = frwd_rules[name]
	if not frwd_rule then
		frwd_rule = setmetatable({ name=name }, gmr_frwd_rule_mt)
		frwd_rules[name] = frwd_rule
	end
	return frwd_rule
end


function gmr_mt:__newindex(name, value)
	local frwd_rules = rawget(self, true)
	local frwd_rule = frwd_rules[name]
	if frwd_rule then
		value = proxy(value, frwd_rule)
		frwd_rules[name] = nil
	else
		value.name = name
	end
	value.temp = false
	rawset(self, name, value)
end

function gmr_mt:__call(...)
	local root_rule = rawget(self, false)
	return assert(rawget(self, root_rule))(...)
end

function M.gmr(root_rule, t)
	local new = t or {}
	new[true] = {}
	new[false] = root_rule
	return setmetatable(new, gmr_mt)
end


return M
