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

function io.readall(file)
	if type(file)=='string' then
		file = assert(io.open(file), 'can\'t open file"'..file..'"')
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

function __rule_mt:__pow(name)
	return self:nm(name)
end

function __rule_mt:__eq(that)
	if self.rule_type~=that.rule_type then return false end
	if self.raweq then return self:raweq(that) end
	local self_seq, that_seq = self:toseq(), that:toseq()
	if #self_seq~=#that_seq then return false end
	for k=1, #self_seq do
		if self_seq[k]~=that_seq[k] then return false end
	end
	return true
end

function __rule_mt:__eq(that)
	if self.rule_type~=that.rule_type then return false end
	if self.raweq then return self:raweq(that) end
	local self_seq, that_seq = self:toseq(), that:toseq()
	if #self_seq~=#that_seq then return false end
	for k=1, #self_seq do
		if self_seq[k]~=that_seq[k] then return false end
	end
	return true
end

function __rule_mt:__bxor(that)
	local function alt_le(a, b)
		local self_alt, that_alt = a:toalt(), b:toalt()
		for i=1, #that_alt do
			for j=1, #self_alt do
				if self_alt[j]==that_alt[i] then
					return true
				end
			end
		end
		return false
	end

	if self==that then return true end
	local self_seq, that_seq = self:toseq(), that:toseq()
	if #self_seq>#that_seq then return false end
	for k=1, #self_seq do
			if not alt_le(self_seq[k], that_seq[k]) then return false end
	end

	return true
end

local function rule_mt(mt)
	for k,v in pairs(__rule_mt) do
		if not mt[k] then mt[k]=v end
	end
	local old_call = mt.__call
	mt.__call=function(self, idx, ...)
		local i, c = old_call(self, idx, ...)
		if i~=nil and self.onMatch then
			local r, err = self:onMatch(c, idx, i)
			if r==false then error(err) end
			return i, r or c
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

function Rule:error(idx, ...)
	print(idx.locate, 'parse error', ...)
end


function Rule:resume(idx, c)
	local i2, c2 = self( idx)
	if not i2 then return i2, c2 end
	table.insert(c2, 1, c)
	return i2, c2
end

function Rule:toalt()
	return { self }
end

function Rule:toseq()
	return { self }
end

function Rule:prefixof(that)
	local that_seq = that:toseq()
	if self==that_seq[1] then return 1/#that_seq end
end

local function __tmpl(tmpl, capt, undef_val)
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
				return string.gsub(is_tab..tostring(capt[tonumber(name) or name] or
					(undef_val or '')), '\n', '\n\t')
			end
			return is_tab..tostring(capt[tonumber(name) or name] or (undef_val or ''))
		end)
		:gsub("(.?)%$(%b{})", function(is_tab, sep)
			if is_tab=='\t' then
				return string.gsub(is_tab..table.concat(capt, sep:sub(2, -2)),
					'\n', '\n\t')
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

function Rule:hndl(fn, low)
	local r = { rule_type=self.rule_type, rule=self, handler_fn=fn, low=low }

	return setmetatable(r, rule_mt{
	__tostring=function(self)
		return tostring(self.rule)
	end,
	__index=setmetatable({
		rule_type='hndl',
		raweq=function(a, b) return a.rule==b.rule end,
		prefixof=function(self, that) return self.rule:prefixof(that) end,
		toseq=function(self) return self.rule:toseq() end,
	}, { __index=Rule }),
	__call=function(self, idx)
		if self.low and self.low(idx, self)==false then return end
		local i, a = self.rule(idx)
		if i~=nil then
			local i2, a2 = self.handler_fn(idx, i, a)
			return i2 or i, a2 or a
		end
	end})
end

function Rule:wrapper(fn)
	local r = { rule_type=self.rule_type, rule=self, fn=fn }

	return setmetatable(r, rule_mt{
	__tostring=function(self)
		return tostring(self.rule)
	end,
	__index=setmetatable({
		rule_type='wrapper',
		raweq=function(a, b) return a.rule==b.rule end,
		prefixof=function(self, that) return self.rule:prefixof(that) end,
		toseq=function(self) return self.rule:toseq() end,
	}, { __index=Rule }),
	__call=function(self, idx)
		return self.fn(self.rule, idx)
	end})
end

function Rule:nm(name)
	local r = { rule_type=self.rule_type, rule=self, capt_name=name }

	return setmetatable(r, rule_mt{
	__tostring=function(self)
		return self.capt_name..'='..tostring(self.rule)
	end,
	__index=setmetatable({
		rule_type='nm',
		prefixof=function(self, that) return self.rule:prefixof(that) end,
		raweq=function(a, b) return a.rule==b.rule end,
		toseq=function(self) return self.rule:toseq() end,
	}, { __index=Rule }),
	__call=function(self,  idx)
		return self.rule( idx)
	end})
end

function Rule:opt(def_value)
	local r = { rule=self, def_value=def_value }

	return setmetatable(r, rule_mt{
	__tostring=function(self)
		return '['..tostring(self.rule)..']'
	end,
	__index=setmetatable({
		rule_type='opt',
		prefixof=function(self, that)
			return self.rule:prefixof(that)
		end,
	}, { __index=Rule }),
	__call=function(self,  idx)
		local i, v = self.rule( idx)
		if not i then return idx, self.def_value else return i, v end
	end})
end



local function compact_capt(capt_mt, i, a)
	if i==nil then return i, a end
--	if #a==1 and not capt_mt.capt_mt then return i, a[1] end
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
	r.capt_mt={
		ruleof=r,
					__tostring=function(self)
						return tostring(self.value or self.alt_type)
					end
	}
		return setmetatable(r, rule_mt{
			__tostring=function(self)
				index[self]=counter
				counter=counter+1
				local s = ''
				for _,v in ipairs(self) do
					if index[v] then
						s=s..'<'..index[v]..'> | '
					else
									local s1, l1 = tostring(v):gsub('\n', '\n\t')
				if l1>0 then s=s..'\n\t'..s1..' | ' else s=s..s1..' | ' end

					end
				end
				return index[self]..': '..(s:gsub('%s*| $', ''))
			end,
			__le=function(self, that)
				for _,v in ipairs(self) do
					if v==that then
						return true
					end
				end
			end,
			__index=setmetatable({
				rule_type='Alt',
				prefixof=function(self, that)
					local c = 0
					for _,v in ipairs(self) do
						if  that:prefixof(v) then c=c+1 end
					end
					if c>0 then return c/#self else return 0 end
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



			}, { __index=Rule }),
			__call=function(self,  idx)
				local i, ov
				for k, v in ipairs(self) do
					i, ov = v(idx)
					if i~=nil then


						return i, ov--setmetatable({ value=ov, alt_type=v.capt_name or k }, self.capt_mt)

					end
				end
				return --false, -10
			end
		})
end

function Seq(...)
	local r = { ... }

	return setmetatable(r, rule_mt{
	__tostring=function(self)
		index[self]=counter
		counter=counter+1
		local s = ''
		for _,v in ipairs(self) do
			if index[v] then
				s=s..'<'..index[v]..'> '
			else
				local s1, l1 = tostring(v):gsub('\n', '\n\t')
				if l1>0 then s=s..'\n\t'..s1..' + ' else s=s..s1..' + ' end

			end
		end
		return index[self]..': {'..(s:gsub('%s*%+ $', ''))..'}\n'
	end,
	__index=setmetatable({
		rule_type='Seq',
		capt_mt={
			__tostring=function(self) return table.concat(self, ' ') end
		},
		prefixof=function(self, that)
			if self==that then return 1 end
			local that_seq = that:toseq()
			if #self>#that_seq then return 0 end
			for k=1, #self do
				if self[k]~=that_seq[k] then return 0 end
			end
			return #self/#that_seq
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
	}, { __index=Rule }),
	__call=function(self,  idx)
		local new, use_capt_names = {}
		for k,v in ipairs(self) do
			if not idx then
				return --false, -100*k
			end
			local i, ov = v(idx)
			if i==nil then
				return --false, -100*k
			end
			if type(v)=='table' and v.capt_name then
				new[v.capt_name]=ov==nil and true or ov
				use_capt_names=true
			else
				table.insert(new, ov)
			end
			idx=i
		end
--		if use_capt_names then
			return idx, setmetatable(new, self.capt_mt)
--		else
--			return compact_capt(self, idx, new)
--		end
	end})
end

function Block(items, open, close)
	local r = {
		items=items,
		open=open,
		close=close
	}

	return setmetatable(r, rule_mt{
	__index=setmetatable({ rule_type='Block' }, { __index=Rule }),
	__call=function(self,  idx)
		local new = {}

		local i, ov = self.open( idx)
		if not i then return false, -1
			end
		new.open=ov
		idx=i

		while true do
			local i, iv = self.items( idx)
			if not i then break end
			table.insert(new, iv or i)
			idx=i
		end
		if #new==0 then return false, -2 end

		idx, new.close = self.close( idx)
		if not idx then return false, -3 end
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
	__index=setmetatable({ rule_type='List' }, { __index=Rule }),
	__call=function(self, idx)
		local new, len = {}, 0
		while idx do
			local i, iv = self.items(idx)
			if i==nil then break end
			if self.onEach then
				local r = self:onEach(new, iv)
				if r~=nil then table.insert(new, r) end
			else
				if iv~=nil then table.insert(new, iv) end
			end
			len=len+1
			idx=i
		end
		if #new==0 then return idx, len end
		return compact_capt(self, idx, new)
	end})
end

function ListSep(items, sep, recursive)
	local r = {
		items=Alt(items),
		sep=sep,
		recursive=recursive
	}

	return setmetatable(r, rule_mt{
	__tostring=function(self)
		return '{'..tostring(self.items)..','..tostring(self.sep)..'}'
	end,
	__index=setmetatable({
		rule_type='ListSep',
		capt_mt={ __tostring=function(self) return table.concat(self, ' ') end }
	}, { __index=Rule }),
	__call=function(self,  idx)
		local new = {}
		while true do
--			if self.recursive and #new>0 then
--				local i, iv = self(idx)
--				if not i then return end
--				table.insert(new, iv)
--				idx=i
--				break
--			end
			local i, iv = self.items( idx)
			if i==nil then return end
			table.insert(new, iv or i)
			idx=i
			if i==false then break end
			local isep, ivsep = self.sep( idx)
			if isep==nil then break end
			if isep==false then break end
			if ivsep then table.insert(new, ivsep) end
			idx=isep
		end
		return compact_capt(self, idx, new)
--		return idx, setmetatable(new, self.capt_mt)
	end})
end


function ListSepLast(items, sep, last, recursive)
	local r = {
		items=Alt(items),
		sep=sep, last=last,
		recursive=recursive
	}

	return setmetatable(r, rule_mt{
	__tostring=function(self)
		return '{'..tostring(self.items)..','..tostring(self.sep)..'}'
	end,
	__index=setmetatable({
		rule_type='ListSepLast',
		capt_mt={ __tostring=function(self) return table.concat(self, ' ') end }
	}, { __index=Rule }),
	__call=function(self,  idx)
		local new = {}
		while true do
			if self.recursive and #new>0 then
				local i, iv = self(idx)
				if not i then
					return --false, -7
				end
				table.insert(new, iv)
				idx=i
				break
			end
			local i, iv = self.items( idx)

			if i==nil then
				i, iv = self.last(idx)
				if i==nil then
					return --false, -6
				else
					if self.last.capt_name then
						new[self.last.capt_name]=iv or true
					else
						table.insert(new, iv or i)
					end
					idx=i
					break
				end
			end
			table.insert(new, iv or i)
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


local separators, separators_count = {}, 0
function sep(kw)
	local sep_rule = separators[kw]
	if sep_rule then return sep_rule end
	sep_rule=ptrn(kw:esc_pattern())
	separators_count=separators_count+1
	sep_rule.lexeme_id = separators_count
	separators[kw]=sep_rule
	return sep_rule
end



function lexeme(p)
	local r = {
		pattern=assert(tonumber(p) or lexemes[p:match'%s*(.+)'], p),
		is_capture=tostring(p):sub(1,1)~=' '
	}

	return setmetatable(r, rule_mt{
		__tostring=function(self)
			return lexemes[self.pattern]
		end,
		__index=setmetatable({
			rule_type='lexeme',
			raweq=function(a, b) return a.pattern==b.pattern end,
		}, { __index=Rule }),
		__call=function(self, tok)
			if tok and tok.lexeme==self.pattern then
				if self.is_capture then
				return tok.next or false, tok
			else
				return tok.next or false
				end
			end
		end
	})
end

local __keywords, keywords_count = {}, 0
function kwrd(kw)
	local kw_id = assert(tonumber(kw) or keywords[kw:match'%s*(.+)'], kw)
	if kw:match'^%s+' then kw_id=-kw_id end
	local kw_rule = __keywords[kw_id]
	if kw_rule then return kw_rule end
	kw_rule=lexeme(kw_id<0 and ' '..(-kw_id) or kw_id)
	keywords_count=keywords_count+1
	kw_rule.lexeme_id = keywords_count
	__keywords[kw_id]=kw_rule
	return kw_rule
end




local __value
function Precedence0(items, op1, ...)
	__value=__value or items
	if not op1 then return items end
	local r
	if type(op1)=='table' and op1.op_ptrn then
		if op1.rassoc then
			r = Seq(items, op1.op_ptrn, __value)
		else
			r = ListSep(items, op1.op_ptrn, op1.recursive)
		end
		if op1.tmpl then
			r:tmpl(op1.tmpl)
		end
	else
		r = ListSep(items, op1)
	end
	r.capt_mt=r.capt_mt or {}
	r.capt_mt.__tostring=function(capt)
		if #capt>1 then return '('..table.concat(capt, ' ')..')' end
		return table.concat(capt, ' ')
	end
	return Precedence0(r, ...)
end


local binop_mt = { __index={} }

function binop_mt:__tostring()
	return '('..tostring(self.l)..' '..
		tostring(self.op)..' '..tostring(self.r)..')'
end

function binop_mt.__index:eval()
	print(self.l, self.r)
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

local function bin_op(l, op, r)
	return setmetatable({ l=l, op=op, r=r }, binop_mt)
end


Precedence = newRule(
	function(value, ...) return { value=value, op={...}, capt_mt={} } end,
	function(self, tok, larg, op)

		if not larg then
			local i, l = self.value(tok)
			if i==nil then return elseif i==false then return i, l end

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
			if i==false then return i, bin_op(larg, tok.prev, r) end
			if not i then
				return self:error(tok,
					'operation sign expected after `'..tostring(larg))
			end

			local op1_tok, op1_pr
			for pr, op in ipairs(self.op) do
				op1_tok = op(i)
				if op1_tok then op1_pr=pr break end
			end
			if not op1_pr then return i, bin_op(larg, tok.prev, r) end
			assert(op1_tok)

			if op<=op1_pr then -- a*b+c
				return self(op1_tok, bin_op(larg, tok.prev, r), op1_pr)
			elseif op>op1_pr then -- a+b*c
				local i2, r2 = self(op1_tok, r, op1_pr)
				return i2, bin_op(larg, tok.prev, r2)
			end
		end
	end
)

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
			return self:error(close_tok,
				'close wrap `'..tostring(self.open)..'` expected')
		end

		return end_tok, body_value
	end
)


Ident = lexeme'ident'--ptrn'([%a_][%a%d_]*)%f[^%a%d_]'

