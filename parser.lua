function table.concat(tbl, sep)
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


local __rule_mt = {

}

rule_start_tok=nil


function __rule_mt.__div(a, b)
	return Alt(a, b)
end

function __rule_mt.__mul(a, b)
	return ListSep(a, b)
end

function __rule_mt:__eq(that)
	if rawequal(self, that) then return true end
	if not self.raweq then error(tostring(self)) end
	return self:raweq(that)
end

function __rule_mt.__lt(a, b)
	if not b.subset then error(tostring(b)) end
	return b:subset(a) or (a==b)
end

function __rule_mt.__le(a, b) -- a <= b
	if not a.subset then error(tostring(a)) end
	if a:subset(b) or (a==b) then return true end
	if b:subset(a) then return false end
end

function __rule_mt:__bxor(that)
	return self:wrapper(function(rule, tok0)
		local tok, obj = rule(tok0)
		if tok and (that(tok))~=nil then return else return tok, obj end
	end)
end

RulesCallStack = setmetatable({},{
	__call=function(self, idx) return self[#self+(idx or 0)] end
})


function rule_mt(mt)
	for k,v in pairs(__rule_mt) do
		if not mt[k] then mt[k]=v end
	end
	mt.__metatable = mt.__metatable or {}
	mt.__metatable.rule = true

	mt.__index = mt.__index or {}
	mt.__index.call = mt.__call

	mt.__call=function(self, idx, ...)
		if self.expected_cntr then rule_start_tok=idx end
		local i, c = self:call(idx, ...)

		if i~=nil and self.onMatch then
			local r, err = self:onMatch(c, idx, i)
			if r==false then error(err) end
			c = r or c
--			if type(r)=='table' and not r.__rule then r.__rule=self end
--			return i, r
		end
		if type(c)=='table' then
			if not c.__rule then c.__rule=self end
			c.begin_tok = idx--.nextws
			c.end_tok = i and i or idx.last
		end
		return i, c
	end
	return mt
end

local Rule = {}


function newRule(constructor, parser, methods)
	local methods = methods or {}
	local mt = rule_mt{
		__index=setmetatable(methods, { __index=Rule }),
		__call=function(self, idx, ...)
			local i, c = parser(self, idx, ...)
			if type(c)=='table' and not getmetatable(c) then
				setmetatable(c, self.capt_mt)
			end
			return i, c
		end
	}
	return setmetatable({
		methods=methods, mt=mt
	}, {
		__call=function(self, ...)
			local r = constructor(...)
			return setmetatable(r, self.mt)
		end,
	})
end

--local error_mode = {}

--function Rule:error(idx, ...)
--	if opt_counter~=0 then
--		return
--	elseif alt_counter~=0 then
--		table.insert(RulesCallStack(),
--			idx.locate..' parse error '..table.concat({...}, '\t'))
--	else
--	end
--end


function Rule:resume(idx, c)
	local i2, c2 = self( idx)
	if not i2 then return i2, c2 end
	table.insert(c2, 1, c)
	return i2, c2
end

function Rule.ends() 	 end
function Rule.begins() end
function Rule.intersect(a, b) return a:subset(b) or b:subset(a) end

function Rule.correlate(a, b, opts)
	local opts = opts or 'e'
	if a.correlation==nil then a.correlation={} end
	local cr = a.correlation[b]
	if cr==nil then cr={} a.correlation[b]=cr end
	if b.correlation==nil then b.correlation={} end
	local cr_rev = b.correlation[a]
	if cr_rev==nil then cr_rev={} b.correlation[a]=cr_rev end
	if opts:find('e', 1, false) and cr.equal==nil then
		cr.equal=(a==b)
		cr_rev.equal=cr.equal
	end
	if opts:find('i', 1, false) and cr.intersept==nil then --and not cr.equal
		cr.intersept=a:intersept(b)
		cr_rev.intersept=cr.intersept
	end
	if opts:find('s', 1, false) and cr.subset==nil then --and not cr.equal
		cr.subset=a:subset(b)
	end
	return a:subset(b) or b:subset(a)
end

function Rule:prefixof(that)
	return false
end

function __tmpl(tmpl, capt, undef_val)
	assert(type(capt)=='table', type(capt)..'\t'..(tonumber(capt) or ''))
	return ( tmpl
		:gsub("@([%a%d_]+)%s*(%b())", function(func_name, func_args)
			local func = assert(_G[func_name], 'function '..func_name..' not defined')
			local argv = {}
			for a in (func_args:sub(2, -2)..','):gmatch'%s*(.-)%s*,' do
				local av
				local param_name = a:match"%$([%a%d_]+)"
				if param_name then
					av=capt[tonumber(param_name) or param_name] or false
				else
					av=__tmpl(a, capt)
				end
				table.insert(argv, tonumber(av) or av)
			end
			return tostring(func(table.unpack(argv)) or (undef_val or ''))
		end)
		:gsub("(.?)%$([%a%d_]+)", function(is_tab, name)
			if is_tab=='\t' then
				local s, i = string.gsub(	is_tab..
					tostring(capt[tonumber(name) or name] or
						(undef_val or '')), '\n', '\n\t')
				if i>0 then s=s..'\n' end
				return s
			end
			return is_tab..tostring(capt[tonumber(name) or name] or (undef_val or ''))
		end)
		:gsub("(.?)%$(%b{})", function(is_tab, sep)
			if is_tab=='\t' then
				local s, i = string.gsub(is_tab..table.concat(
						capt, sep:sub(2, -2)), '\n', '\n\t')
				if i>0 then s=s..'\n' end
				return s
			end
			return is_tab..table.concat(capt, sep:sub(2, -2))
		end)
	)
end

function Rule:tmpl(tmpl)
	self.capt_mt=self.capt_mt or {}
	local t=type(tmpl)
	if t=='string' then
		self.capt_mt.__tostring=function(capt)
			return __tmpl(tmpl, capt)
		end
	elseif t=='function' then
		self.capt_mt.__tostring=tmpl
	end
	return self
end



local ProxyRule = setmetatable({
	rule_type='?ProxyRule?',
	raweq=function(a, b) return a.rule==b.rule end,
	subset=function(self, a) return self.rule:subset(a) end,
	prefixof=function(self, that) return self.rule:prefixof(that) end,
	toseq=function(self) return self.rule:toseq() end,
	resolve=function(self, gmr) gmr(self, 'rule') end,
}, { __index=Rule })

local rule_nm_mt = rule_mt{
__tostring=function(self)
	return self.capt_name..'='..tostring(self.rule)
end,
__index=setmetatable({
	rule_type='nm',
}, { __index=ProxyRule }),
__call=function(self,  idx)
	return self.rule( idx)
end}

function __rule_mt:__pow(name)
	return setmetatable({ rule=self, capt_name=name }, rule_nm_mt)
end


function Rule:hndl(fn, low)
	local r = { rule_type=self.rule_type, rule=self, handler_fn=fn, low=low }

	return setmetatable(r, rule_mt{
	__tostring=function(self)
		return '@('..tostring(self.rule)..')'
	end,
	__index=setmetatable({
		rule_type='hndl',
	}, { __index=ProxyRule }),
	__call=function(self, idx)
		if self.low and self.low(idx, self)==false then return end
		local i, a = self.rule(idx)
		if i~=nil then
			local i2, a2 = self.handler_fn(idx, i, a)
			return i, i2 or a--i2 or i, a2 or a
		end
	end})
end

function Rule:wrapper(fn, rule_type)
	local r = { rule=self, fn=fn, rule_type=rule_type or 'wrapper' }

	return setmetatable(r, rule_mt{
	__tostring=function(self)
		return '('..tostring(self.rule)..')'
	end,
	__index=setmetatable({
		rule_type=rule_type or 'wrapper',
	}, { __index=ProxyRule }),
	__call=function(self, idx)
		return self.fn(self.rule, idx)
	end})
end

function Rule:expected(msg)
	return self:wrapper(function(s, tok)
		local t, a = s(tok)
		if t==nil then
			print((rule_start_tok or tok).source_file_name..':'..
				(rule_start_tok or tok).line..': '..
				(rule_start_tok~=nil and (rule_start_tok.locate..' - ') or '')..
				(tok and tok.locate or 'eof')..'. '..(msg or ('expected 	`'..tostring(s)..'`')), a or '')
			os.exit(-3)
		end
		return t, a
	end, 'expected')
end

function Rule:opt(def_value)
	local r = { rule=self, def_value=def_value }

	return setmetatable(r, rule_mt{
	__tostring=function(self)
		return '['..tostring(self.rule)..']'
	end,
	__index=setmetatable({
		rule_type='opt',
	}, { __index=ProxyRule }),
	__call=function(self,  idx)
		local i, v = self.rule( idx)
		if i==nil then return idx, self.def_value else return i, v end
	end})
end



local function compact_capt(capt_mt, i, a)
	if i==nil then return i, a end
	if #a==1 then return i, a[1] end
	if #a==0 then
		if capt_mt.capt_mt and capt_mt.capt_mt.__tostring  then
			return i, capt_mt.capt_mt.__tostring(a)
		else
			return i
		end
	end
	return i, setmetatable(a, capt_mt.capt_mt)
end


local counter = 1
index={}



function Alt(...)
	local r = { ... }
	for k,v in ipairs(r) do
		if v.def_value~=nil or v.rule_type=='opt' then
			error('Optional rule not allowed in Alt member '..k, 2)
		end
	end
	r.capt_mt={
		ruleof=r,
					__tostring=function(self)
						return tostring(self.value or self.alt_type)
					end
	}
		return setmetatable(r, rule_mt{
			__tostring=function(self)
				return 'alt'

			end,
			__index=setmetatable({
				rule_type='alt',
				prefixof=function(self, that)
					if self==that then return true, 0 end
					for k,v in ipairs(self) do
						if v:prefixof(that) then return true, k end
					end
				end,
				subset=function(self, a)
					for _,v in ipairs(self) do
						if (v==a) or v:subset(a) then return true end
					end
					return false
				end,
				toalt=function(self) return self end,
				add=function(self, a, ...)
					if not a then return self end
					table.insert(self, a)
					return self:add(...)
				end,
				insert=function(self, a, ...)
					if not a then return self end
					table.insert(self, 1, a)
					return self:insert(...)
				end,
				raweq=function(self, a)
					if getmetatable(a)==getmetatable(self) then
						for _,v in ipairs(self) do
							for _,vv in ipairs(a) do
								if (vv==v) then return true end
							end
						end
					end
					return false
				end,
				resolve=function(self, gmr)
					for k in ipairs(self) do gmr(self, k) end
				end,

			}, { __index=Rule }),
			__call=function(self,  idx)
				local i, ov
				for k=1,#self do
					local v = self[k]
					if not v.call then
						print(v, k)
					end
					i, ov = v(idx)
					if i~=nil then
						if ov==nil then
							return i, k
						else
							return i, ov
						end
					end
				end
				return
			end
		})
end

function Seq(first, ...)
	local r = { first, ... }
	for k,v in ipairs(r) do
		if v.rule_type=='expected' then
			r.expected_cntr = true
		end
	end
	return setmetatable(r, rule_mt{
	__tostring=function(self)
		return 'seq'

	end,
	__index=setmetatable({
		rule_type='Seq',
		capt_mt={
			__tostring=function(self)
				local s = ''
				for k=1, #self do
					local si, ii = tostring(self[k]):gsub('\n', '\n  ')
					s = s..si..(ii>0 and '' or ' ')
				end
				return (s:gsub(' $', ''))--table.concat(self, ' ')
			end
		},
		prefixof=function(self, that)
			if self[1]==that then return true end
			return self[1]:prefixof(that)
		end,
		toseq=function(self, t)
			local r = t or {}
			for _,v in ipairs(self) do
				if v.rule_type=='Seq' then v:toseq(r) else table.insert(r, v) end
			end
			return r
		end,
		append=function(self, a, ...)
			if not a then return self end
			table.insert(self, 1, a)
			return self:append(...)
		end,
		insert=function(self, a, ...)
			if not a then return self end
			table.insert(self, a)
			return self:insert(...)
		end,
		raweq=function(self, a)
			if getmetatable(a)==getmetatable(self) then
				if #self~=#a then return false end
				for k,v in ipairs(self) do
					if (a[k]~=v) then return false end
				end
				return true
			end
			return false
		end,
		check=function(self)--self[1]==nil
			if self:prefixof(self) then return false, '<=' end
			return true
		end,
		subset=function(self, a)
			if getmetatable(a)==getmetatable(self) then
				if #self~=#a then return false end
				for k,v in ipairs(self) do
					if (v~=a[k]) and not v:subset(a[k]) then return false end
				end
				return true
			end
			return false
		end,
		resolve=function(self, gmr)
			for k in ipairs(self) do gmr(self, k) end
		end,
	}, { __index=Rule }),
	__call=function(self, idx)
		local new, use_capt_names = {}
		for k=1,#self do
			local v = self[k]
			if idx==false then
				return nil, 'unexpected eof'
			end
			local i, ov = v(idx)
			if i==nil then
				return nil, ov
			end
			if type(ov)=='table' then ov.parent = new end
			if type(v)=='table' and v.capt_name then
				new[v.capt_name] = ov==nil and true or ov
				use_capt_names=true
			else
				table.insert(new, ov)
			end
			idx=i
		end
			return idx, setmetatable(new, self.capt_mt)
	end})
end

function List(items)
	local r = {
		items=items
	}

	return setmetatable(r, rule_mt{
	__tostring=function(self)
		return '{'..tostring(self.items)..'}'
	end,
	__index=setmetatable({
		rule_type='List',
		capt_mt={ __tostring=function(self)
			return '\n  '..table.concat(self, '\n  ')..'\n'
		end },
		opt=function(self, a) self.optional=a or 0 return self end,
		subset=function(self, a) return self.items:subset(a) end,
		raweq=function(self, a) return self.items==a.items end,
		resolve=function(self, gmr)
			gmr(self, 'items')
		end,
	}, { __index=Rule }),
	__call=function(self, idx)
		local new, len, err = {}, 0
		while idx do
			local i, iv = self.items(idx)
			if i==nil then
				err=iv break
			end
			if self.onEach then
				iv = self:onEach(new, iv)
			end
			if iv~=nil then
				table.insert(new, iv)
				if type(iv)=='table' then iv.parent = new end
			end
			len=len+1
			idx=i
		end
		if #new==0 then
			if len==0 then
				if self.optional~=nil then
					return idx, self.optional
				else
					return nil, err
				end
			end
			return idx, len
		end
		return compact_capt(self, idx, new)
	end})
end

function ListSep(items, sep)
	local r = {
		items=(items),
		sep=sep,
		capt_mt={ __tostring=function(self)
			return table.concat(self, tostring(sep)..' ')
		end }
	}
	if items.rule_type=='expected' or sep.rule_type=='expected' then
		r.expected_cntr = true
	end
	return setmetatable(r, rule_mt{
	__tostring=function(self)
		return '{'..tostring(self.items)..','..tostring(self.sep)..'}'
	end,
	__index=setmetatable({
		rule_type='ListSep',
		expected=function(self, msg)
			self.expected_cntr = true
			self.items = self.items:expected(msg)

			return self
		end,
		raweq=function(self, a)
			return self.items==a.items and self.sep==a.sep
		end,
		resolve=function(self, gmr)
			gmr(self, 'items', 'sep')
		end,
		subset=function(self, a) return self.items:subset(a) end,
	}, { __index=Rule }),
	__call=function(self,  idx)
		local new = {}
		while true do
			local i, iv = self.items( idx)
			if i==nil then
				return nil, iv
			end
			if type(iv)=='table' then iv.parent = new end
			table.insert(new, iv)
			idx=i
			if i==false then break end
			local isep, ivsep = self.sep( idx)
			if isep==nil then break end
			if isep==false then break end
			if ivsep then
				if type(ivsep)=='table' then ivsep.parent = new end
				table.insert(new, ivsep)
			end
			idx=isep
		end
		return idx, setmetatable(new, self.capt_mt)
	end})
end


function ListSepLast(items, sep, last)
	local r = {
		items=(items),
		sep=sep, last=last
	}

	return setmetatable(r, rule_mt{
	__tostring=function(self)
		return '{'..tostring(self.items)..','..tostring(self.sep)..'}'
	end,
	__index=setmetatable({
		rule_type='ListSepLast',
		raweq=function(self, a)
			return self.items==a.items and self.sep==a.sep and self.last==a.last
		end,
		resolve=function(self, gmr)
			gmr(self, 'items') gmr(self, 'sep') gmr(self, 'last')
		end,
		subset=function(self, a) return self.items:subset(a) end,
		capt_mt={ __tostring=function(self) return table.concat(self, ' ') end }
	}, { __index=Rule }),
	__call=function(self,  idx)
		local new = {}
		while true do
			local i, iv = self.items( idx)

			if i==nil then
				i, iv = self.last(idx)
				if i==nil then return end
				if self.last.capt_name then
					new[self.last.capt_name]=iv or true
				else
					table.insert(new, iv)
				end
				idx=i
				break
			end
			table.insert(new, iv)
			idx=i
			if i==false then break end
			local isep, ivsep = self.sep( idx)
			if isep==nil then break end
			if isep==false then break end
			if ivsep then table.insert(new, ivsep) end
			idx=isep
		end
		return idx, setmetatable(new, self.capt_mt)
	end})
end



function ptrn(p)
	local r = {
		pattern=p,
	}

	return setmetatable(r, rule_mt{
		__tostring=function(self)
			return '`'..self.pattern..'`'
		end,
		__index=setmetatable({
			rule_type='ptrn',
			raweq=function(a, b) return a.pattern==b.pattern end,
		}, { __index=Rule }),
		__call=function(self,  idx)
			local a = { src:match('^%s*'..self.pattern..'()', idx) }
			if #a==0 then return end
			local i = a[#a]
			a[#a]=nil
			if #a==1 and not self.capt_mt then return i, a[1] end
			if #a==0 then
				if self.capt_mt and self.capt_mt.__tostring  then
					return i, self.capt_mt.__tostring(a)
				else
					return i
				end
			end
			return i, setmetatable(a, self.capt_mt)
		end
	})
end


function lexeme(p)
	local r = {
		pattern=assert(tonumber(tonumber(p) or lexemes[p:match'%s*(.+)']), p),
		is_capture=tostring(p):sub(1,1)~=' '
	}
	r.name='lexeme('..lexemes[r.pattern]..')'
	return setmetatable(r, rule_mt{
		__tostring=function(self)
			return assert(lexemes[self.pattern])
		end,
		__index=setmetatable({
			rule_type='lexeme',
			raweq=function(a, b)
				return (getmetatable(a)==getmetatable(b)) and a.pattern==b.pattern
			end,
			subset=function() return false end,
		}, { __index=Rule }),
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
						})
					end
				else
					return tok.next or false
				end
			end
		end
	})
end

function usrkwrd(p)
	local r = {
		usrkwrd=p:match'%s*(.+)',
		is_capture=tostring(p):sub(1,1)~=' '
	}
	r.name='usrkwrd('..r.usrkwrd..')'
	return setmetatable(r, rule_mt{
		__tostring=function(self)
			return assert(self.usrkwrd)
		end,
		__index=setmetatable({
			rule_type='usrkwrd',
			raweq=function(a, b)
				return (getmetatable(a)==getmetatable(b)) and a.usrkwrd==b.usrkwrd
			end,
			subset=function() return false end,
		}, { __index=Rule }),
		__call=function(self, tok)
			if tok and tok.lexeme==lexemes'ident' and tok.str==self.usrkwrd then
				if self.is_capture then
					if self.capt_mt then
						return tok.next or false, setmetatable({ tok=tok }, self.capt_mt)
					else
						return tok.next or false, setmetatable({ tok=tok }, {
							__tostring=function(s) return tostring(s.tok) end,
							__index={ __rule=self },
						})
					end
				else
					return tok.next or false
				end
			end
		end
	})
end

function kwrd(p)
	local r = {
		pattern=assert(tonumber(tonumber(p) or keywords[p:match'%s*(.+)']), p),
		is_capture=tostring(p):sub(1,1)~=' '
	}
	r.name='kwrd('..keywords[r.pattern]..')'
	return setmetatable(r, rule_mt{
		__tostring=function(self)
			return assert(keywords[self.pattern])
		end,
		__index=setmetatable({
			rule_type='kwrd',
			raweq=function(a, b)
				return (getmetatable(a)==getmetatable(b)) and a.pattern==b.pattern
			end,
			subset=function() return false end,
		}, { __index=Rule }),
		__call=function(self, tok)
			if tok and tok.lexeme==self.pattern then
				if self.is_capture then
				return tok.next or false, setmetatable({ tok=tok }, {
					__tostring=function(s) return tostring(s.tok) end,
					__index={ __rule=self },
				})
			else
				return tok.next or false
				end
			end
		end
	})
end




local typeof = require('mtmix').typeof


BinOp = {}
local binop_mt = {
	__index=BinOp,
	__metatable={ binop=true, expr=true },
}

function binop_mt:__tostring()
	return '('..tostring(self.l)..' '..
		tostring(self.op)..' '..tostring(self.r)..')'
end

function binop_mt.__index:eval()
	local o, l, r = tostring(self.op),
		assert(typeof(self.l).expr and self.l:eval() or tonumber(tostring(self.l))),
		assert(typeof(self.r).expr and self.r:eval() or tonumber(tostring(self.r)))
	if o=='+'  then return l+r  end
	if o=='-'  then return l-r  end
	if o=='*'  then return l*r  end
	if o=='/'  then return l/r  end
	if o=='|'  then return l|r  end
	if o=='&'  then return l&r  end
	if o=='>>' then return l>>r end
	if o=='<<' then return l<<r end
	if o=='^' then return l^r end
	error('unknown op: `'..o..'`')
end

local function bin_op(l, op, r, __rule, parent)
	if type(l)=='number' then
		print(l, op, r)
	end
	local new = setmetatable({
		l=l, op=op, r=r, parent=parent, __rule=__rule,
--		begin_tok=l.begin_tok
	}, binop_mt)
	if type(l)=='table' then l.parent = new end
	if type(r)=='table' then r.parent = new end
	return new
end


Precedence = newRule(
	function(value, ...) return { value=value, op={...}, capt_mt={} } end,
	function(self, tok, larg, op)

		if not larg then
			local i, l = self.value(tok)
			if i==nil then
				return nil, 'left operand expected'
			elseif i==false then
				return i, l
			end

			local op1_tok, op1_pr
			for pr, op in ipairs(self.op) do
				op1_tok = op(i)
				if op1_tok then op1_pr=pr break end
			end
			if not op1_pr then return i, l end
			assert(op1_tok)

			return self(op1_tok, l, op1_pr)
		else
			local i, r = self.value(tok)
			if i==false then
				return i, self.bin_op(larg, tok.prev, r, self)
			end
			if not i then
--				print(tok.locate..
--					'. operation sign expected after `'..tostring(larg))
--				os.exit(-3)
				return nil, 'operation `'..tostring(tok.prev)..'` with rigth arg'
			end

			local op1_tok, op1_pr
			for pr, op in ipairs(self.op) do
				op1_tok = op(i)
				if op1_tok then op1_pr=pr break end
			end
			if not op1_pr then return i, self.bin_op(larg, tok.prev, r, self) end
			assert(op1_tok)

			if op<=op1_pr then -- a*b+c
				local new1 = self.bin_op(larg, tok.prev, r, self)
				local i2, new2 = self(op1_tok, new1, op1_pr)
				new1.parent = new2
				new1.begin_tok = tok.prev
				new1.end_tok = i
				if i2==nil then return nil, new2 end
				if new2 then new2.begin_tok = tok end
				return i2, new2
			elseif op>op1_pr then -- a+b*c
				local i2, r2 = self(op1_tok, r, op1_pr)
				return i2, self.bin_op(larg, tok.prev, r2, self)
			end
		end
	end,
	{--self.value:subset(a)
		rule_type='Precedence',
		bin_op=bin_op,
		subset=function(self, a) return false end,
		raweq=function(self, a)
			if getmetatable(a)==getmetatable(self) then return self.value==a.value end
		end,
		resolve=function(self, gmr)
			gmr(self, 'value')
			for pr, op in ipairs(self.op) do
				gmr(self.op, pr)
			end
		end,
	}
)

function NewRule(fn)
	return setmetatable({}, rule_mt{
		__call=function(self, tok)
			local t,v = fn(tok)
			if self.capt_mt and type(v)=='table' then
				setmetatable(v, self.capt_mt)
			end
			return t, v
		end,
		__index=setmetatable({
			rule_type='custom',
		}, { __index=Rule }),
	})
end

Wrap = newRule(
	function(open, body, close) return { open=open, body=body, close=close } end,
	function(self, tok)

		local open_tok = self.open(tok)
		if open_tok==nil then
			return
		elseif open_tok==false then
			return self:error(tok,
				'open wrap `'..tostring(self.open)..'` at end of file')
		end

		local close_tok, body_value = self.body(open_tok)
		if close_tok==nil then
			return self:error(open_tok,
				'wrap body expected `'..tostring(self.body)..'`')
		end

		local end_tok = self.close(close_tok)
		if end_tok==nil then
			return nil, 'close wrap `'..tostring(self.close)..'` expected after '..
				tostring(close_tok)
		end
		if self.capt_mt then
			return end_tok, setmetatable({ body=body_value }, self.capt_mt)
		end
		return end_tok, body_value
	end,
	{
		rule_type='Wrap',
		subset=function(self, a) return self.body:subset(a) end,
		raweq=function(self, a)
			if getmetatable(a)==getmetatable(self) then return self.body==a.body end
		end,
		resolve=function(self, gmr)
			gmr(self, 'open')
				gmr(self, 'body')
				gmr(self, 'close')
		end,
	}
)

function WrapAlt(open, body, close)
	return Alt(body, Wrap(open, body, close))
end

Ident = lexeme'ident'--ptrn'([%a_][%a%d_]*)%f[^%a%d_]'





local grammar_mt = {}
local grammar_rule_mt = rule_mt{}

function grammar_mt:__index(name)
	local forward_rule = rawget(self, false)[name]
	if not forward_rule then
		forward_rule = setmetatable({ forward=name, global=true }, grammar_rule_mt)
		rawget(self, false)[name] = forward_rule
	end
	return forward_rule
end

function grammar_mt:__newindex(name, rule)
	rule.name=name
	rule.global=true
	rawset(self, name, rule)
end

			local lexer=require'lexer'
			local lex_mem = require'lm'
			local scope = require('ast.scope')

local function grammar_call(root_rule)
	return function(src)
		if src~=nil then
			local tok0
			local src_t = type(src)
			if src_t=='string' then
				local lm = lex_mem(lexer.new(src))
				lm.scope = scope()
				tok0 = lm()
			elseif src_t=='table' then
				tok0 = src
			end
			return root_rule(tok0)
		end
	end
end

local function grammar_resolve(self, rule_name)
		local function fn(rule, name, name2, ...)
			local rf=assert(rule[name], (rule.name or tostring(rule))..'.'..name)
			assert(type(rf)=='table', name)
			if rf.forward then
				rule[name]=assert(self[rf.forward], rf.forward)
			end

			local resolve = rule[name].resolve
			if resolve then
				rule[name].resolve=false
				resolve(rule[name], fn)
			end
			if name2 then fn(rule, name2, ...) end
		end

		local resolve = assert(rawget(self, rule_name),
			'root rule `'..tostring(rule_name)..'` not defined').resolve
		if resolve then
			self[rule_name].resolve=false
			resolve(self[rule_name], fn)
		end
end


function grammar_mt:__call(src)
	local root_rule = assert(rawget(self, true))
	if type(root_rule)=='function' then
		if src~=nil then return root_rule(src) else return root_rule end
	end





	for k in pairs(self) do grammar_resolve(self, k) end
	local c_fn = grammar_call(self[root_rule])
	rawset(self, true, c_fn)
	if src~=nil then return c_fn(src) else return c_fn end
end

function Grammar(root)
	local t = { [false]={} }
	t[true] = root--grammar_resolve(t, root)
	return setmetatable(t, grammar_mt)
end
