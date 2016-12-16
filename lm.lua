--lexemes, keywords

local keywords_lexeme_id = lexemes.ident


local function lexer_memoryzator(lex, offset)
	local tok_mt = { __index={} }

	function tok_mt:__eq(x)
		if type(x)=='table' and x.lexeme==self.lexeme then return true end
		return false
	end

--	function tok_mt.__index:expect(what, msg)
--		local what_i = tonumber(what) or lexemes[what]
--		if self.lexeme~=what_i then
--			error(msg or ('`'..lexemes[what_i]..'` expected, got'..tostring(self)), 2)
--		end
--		return self
--	end

	function tok_mt:__tostring()
		return self.str--string.format("%d:%d.%s`%s`", self.line, self.pos,
--			lexemes[self.lexeme] or tostring(self.lexeme), self.str)
	end



	local offset = offset or 0
	local fn = function(self, idx)
		local cash, li = self.cash
		if idx==nil then
			self.index=self.index+1
			idx=self.index--#cash+1
		else
			idx = assert(tonumber(idx), "idx not a number "..tostring(idx))
			if idx<=0 then
				idx=self.index+idx--#cash-idx
			elseif idx>0 then
				idx=idx-offset
			end
		end
		assert(idx>0)
--		if idx<=#cash then return rawget(cash, idx) end
		while idx>#cash do
			local line, pos = lex:get_pos()
			local li=lex:next()
			if not li then return li end
			if dont_skip_whitespace or li~=0 then

				if li==keywords_lexeme_id then
					li = keywords[lex:str()] or li
				end
				local vindex
				if li~=0 then
					self.vindex = self.vindex + 1
					vindex = self.vindex
				end
				rawset(cash, #cash+1, setmetatable({
					lexeme=li, line=line, pos=pos+1, str=lex:str(), idx=#cash+1,
					vindex = vindex
				}, tok_mt))
			end
		end
		return rawget(cash, idx)
	end

	local lm = setmetatable({
		index = 0,
		vindex = 0,
		cash = {},
		flush = function(self)
			if #self.cash>0 then
				offset = offset+#self.cash-1
				self.cash = {self.cash[#self.cash]}
			end
		end,
		rewind = function(self)
			self.cash = {}
			self.index = 0
			self.vindex = 0
			lex:rewind()
		end,
		seek = function(self, shift)
			if shift<0 then
				self.index = (self.index + shift)
				assert(self.index>0)
			elseif shift>0 then
				self.index = assert((self.index + shift))
			end
		end,
		look = function(self, shift)
			local index = (self.index + shift)
			assert(index>0)
			return self(self.index + shift)
		end,
	}, {
		__call = fn, __index = fn,
		__newindex=function(self, name, value)
			if tonumber(name) then error(self, name, value) end
			rawset(self, name, value)
		end,
		__len = function(self) return #self.cash+offset end,
		__ipairs = function(self)
			return function(lm, idx)
				local ln = lm(idx+1)
				if not ln then return nil end
				return idx+1, ln
			end, self, 0
		end,
		__add = function(self, idx)
			return self(#self+assert(tonumber(idx)))
		end
	})

	local tok_prop = {}

	function tok_prop:nextws()
		return lm(self.idx+1)--(pos or 1))
	end

	function tok_prop:locate()
		return string.format("%3d:%-3d", self.line, self.pos)
	end

	function tok_prop:next()
		local i = self.idx+1
		local tok = lm(i)
		while tok and tok.lexeme==0 do i=i+1 tok = lm(i) end
		return tok
	end

	function tok_prop:prev()
		local i = self.idx-1 --assert(i>1)assert(i>1)
		local tok = lm(i)
		while tok and tok.lexeme==0 do i=i-1 tok = lm(i) end
		return tok
	end

	function tok_prop:prevws(pos)
		assert(self.idx>1)--(pos or 1))
		return lm(self.idx-1)--(pos or 1))
	end

	function tok_prop:scope()
		return assert(lm.scope)--(pos or 1))
	end

	function tok_mt:__index(name)
		local prop_getter = tok_prop[name]--, 'tok.`'..tostring(name)..'`')
		if prop_getter then return prop_getter(self) end
	end

	return lm
end

return lexer_memoryzator
