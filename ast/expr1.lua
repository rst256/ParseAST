local ident_lexeme_id = lexemes.ident
local int_lexeme_id = lexemes.int
local string_lexeme_id = lexemes.string
local open_subexpr_lexeme_id = lexemes['(']
local close_subexpr_lexeme_id = lexemes[')']

local parse_expr


local fncall_mt = { __index={} }

local function new_fncall(fn, args)
	return setmetatable({ fn=fn, args=args }, fncall_mt)
end

function fncall_mt:__tostring()
	local s = tostring(self.fn)..'('
	for _, a in ipairs(self.args) do s = s..tostring(a)..', ' end
	return s:gsub(', $', '')..')'
end

function fncall_mt.__index:lmin()
	local l = self
	while type(l.larg)=='table' do l = l.larg end
	return l
end

function fncall_mt.__index:tol()
	local lmin = self:lmin()
	if type(lmin.rarg)~='table' then return lmin.op, lmin.rarg end
	return lmin.op, new_fncall(lmin.rarg.larg, lmin.rarg:tol())
end

function _G.parse_list(lm, close_lexeme_id, sep_lexeme_id, list)
	local list = list or {}
	local sep_lexeme_id = sep_lexeme_id or lexemes[',']
	if lm[0].lexeme~=close_lexeme_id then
		while 1 do
			table.insert(list, parse_expr(lm))
			local tok2 = lm[-1]
			if tok2.lexeme==close_lexeme_id then break end
			tok2:expect(sep_lexeme_id)
		end
	end
	lm:seek(-1)
	return list
end

local function parse_value(lm)
	local tok = lm[0]
	if tok.lexeme==ident_lexeme_id then
		if lm().lexeme==open_subexpr_lexeme_id then
			local args = {}--parse_list(lm, close_subexpr_lexeme_id)--{}
			if lm[0].lexeme~=close_subexpr_lexeme_id then
				while 1 do
					table.insert(args, parse_expr(lm))
					local tok2 = lm[-1]
					if tok2.lexeme==close_subexpr_lexeme_id then break end
					tok2:expect','
				end
			end
			lm:seek(-1)
			return new_fncall(tok.str, args)
		else
			lm:seek(-1)
			return tok.str--{ tok.str }
		end
	elseif tok.lexeme==int_lexeme_id then
		return tonumber(tok.str)
	elseif tok.lexeme==string_lexeme_id then
		return tok.str
	elseif tok.lexeme==open_subexpr_lexeme_id then
		lm()
		local v = parse_expr(lm)
		lm[0]:expect(close_subexpr_lexeme_id)
		return v
	else
		return nil
	end
end

local bin_ops = {
	[lexemes['+']] = 10,
	[lexemes['-']] = 10,

	[lexemes['*']] = 2,
	[lexemes['/']] = 2,

	[lexemes['!=']] = 19,
	[lexemes['==']] = 19,
	[lexemes['<=']] = 19,
	[lexemes['>=']] = 19,
	[lexemes['<']] = 19,
	[lexemes['>']] = 19,

	[lexemes['&&']] = 100,
	[lexemes['||']] = 100,
}

local binop_mt = { __index={} }

local function new_binop(larg, op, rarg)
	return setmetatable({ larg=larg, op=tonumber(op) or lexemes[op], rarg=rarg }, binop_mt)
end

function binop_mt:__tostring()
	return ' ('..tostring(self.larg)..lexemes[self.op]..tostring(self.rarg)..')'
end

function binop_mt.__index:lmin()
	local l = self
	while typeof(l.larg, binop_mt) do l = l.larg end
	return l
end

function binop_mt.__index:tol()
	local lmin = self:lmin()
	if type(lmin.rarg)~='table' then return lmin.op, lmin.rarg end
	return lmin.op, new_binop(lmin.rarg.larg, lmin.rarg:tol())
end







parse_expr = function (lm)
	local larg = assert(parse_value(lm))	--lm()
	if larg then
		local tok_op = lm()
		local op1_pr = bin_ops[tok_op.lexeme]
		if op1_pr then
			lm()
			local l=parse_expr(lm)
			if typeof(l, binop_mt) then
				local op_pr2 = bin_ops[l.op]
				if op_pr2>op1_pr then
					return new_binop(
						new_binop(larg, tok_op.str, l.larg), l.op , l.rarg)
				elseif typeof(l.larg, binop_mt) and bin_ops[l.larg.op]>op1_pr then
					l.larg = new_binop(larg, tok_op.str, l.larg)
					return l
				end

			end
			return new_binop(larg, tok_op.str, l)
		else
			return larg
		end
	end
end


return parse_expr