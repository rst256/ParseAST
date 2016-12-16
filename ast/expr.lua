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
_G.new_fncall=new_fncall
AST.call=new_fncall

function fncall_mt:__tostring()
	local s = tostring(self.fn)..'('
	for _, a in ipairs(self.args) do s = s..tostring(a or '')..', ' end
	return s:gsub(' ?, $', '')..')'
end

function fncall_mt.__index:typeof()
	return self.signature.ret_type
end

function fncall_mt.__index:declare(scope)
	local sym = assert(scope:find(self.fn) or false,
		'function `'..tostring(self.fn)..'` is not defined in scope '..
		tostring(scope))
	assert(sym.kind=='fn', 'call `'..self.fn..'` is not a function')-- or sym.kind=='tfn')
	self.signature = sym
end






local index_mt = { __index={} }

local function new_index(cntr, idx)
	return setmetatable({ cntr=cntr, idx=idx }, index_mt)
end
AST.index=new_index

function index_mt:__tostring()
	return tostring(self.cntr)..'['..tostring(self.idx)..']'
end

function index_mt.__index:typeof()
	return self.signature.ret_type
end

function index_mt.__index:declare(scope)
	local sym = assert(scope:find(self.cntr) or false,
		'container var `'..tostring(self.cntr)..'` is not defined in scope '..
		tostring(scope))
	assert(sym.kind=='var')
	self.cntr_sym = sym
end





function _G.parse_list(tok, parse_item, close_lexeme_id, sep_lexeme_id, list)
	local args = list or {}
	local sep_lexeme_id = sep_lexeme_id or lexemes[',']
	local tok3 = tok:next()
			if tok3.lexeme~=close_lexeme_id then
				while 1 do
					if allow_opt_args and tok3.lexeme==sep_lexeme_id then
--						tok3 = tok3:next()
						table.insert(args, false)

					else
						local arg, arg_end = parse_item(tok3)
						table.insert(args, arg)
						tok3 = arg_end:next()
					end
					if tok3.lexeme==close_lexeme_id then break end
--					tok3:expect(sep_lexeme_id)
					if allow_opt_args or allow_opt_argsep then
						if tok3.lexeme==sep_lexeme_id then
							tok3 = tok3:next()
							if allow_opt_args then
								while tok3.lexeme==sep_lexeme_id do
									tok3 = tok3:next()
									table.insert(args, false)
								end
								if tok3.lexeme==close_lexeme_id then
									table.insert(args, false)
									break
								end
							end
						end
					else
						tok3 = tok3:expect(sep_lexeme_id):next()
					end
				end
			end
	return args, tok3
end

function parse.call(tok)
	if tok.lexeme==ident_lexeme_id then
		local tok2 = tok:next()
		if tok2.lexeme==open_subexpr_lexeme_id then
			local args, tok3 = parse_list(tok2, parse_expr, 41)
			if args then return new_fncall(tok.str, args), tok3 end
		end
	end
end

local function parse_value(tok)
--	local tok = lm[0]
	if tok.lexeme==ident_lexeme_id then
		local tok1 = tok:next()
		if tok1.lexeme==open_subexpr_lexeme_id then
--			local args, tok3 = parse_list(tok1, parse_expr, 41)
--			return new_fncall(tok.str, args), tok3
			return parse.call(tok)
		elseif tok1.lexeme==lexemes['['] then
			local idx, end_tok = parse_expr(tok1:next())
			assert(idx)
			end_tok = end_tok:next():expect']'
			return new_index(tok.str, idx), end_tok
		else
			return tok.str, tok--{ tok.str }
		end
	elseif tok.lexeme==int_lexeme_id then
		return tonumber(tok.str), tok
	elseif tok.lexeme==string_lexeme_id then
		return tok.str, tok
	elseif tok.lexeme==open_subexpr_lexeme_id then
--		lm()
		local v, exp_end_tok = parse_expr(tok:next())
		local sub_exp_end_tok = exp_end_tok:next()
		sub_exp_end_tok:expect(close_subexpr_lexeme_id)
		return v, sub_exp_end_tok
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
	return '('..tostring(self.larg)..lexemes[self.op]..tostring(self.rarg)..')'
end

function binop_mt.__index:declare(scope)
	if type(self.larg)=='table' and self.larg.declare then self.larg:declare(scope) end
	if type(self.rarg)=='table' and self.rarg.declare then self.rarg:declare(scope) end
end

function binop_mt.__index:typeof()
	local op_pr = bin_ops[self.op]
	if op_pr==19 or op_pr==100 then
		return AST.texpr('bool')
	else
	end
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
	local larg, larg_end = assert(parse_value(lm))	--lm()
	if larg then
		local tok_op = larg_end:next()
		local op1_pr = bin_ops[tok_op.lexeme]
		if op1_pr then
--			lm()
			local l, l_end=parse_expr(tok_op:next())
			if typeof(l, binop_mt) then
				local op_pr2 = bin_ops[l.op]
				if op_pr2>op1_pr then
					return new_binop(
						new_binop(larg, tok_op.str, l.larg), l.op , l.rarg), l_end
				elseif typeof(l.larg, binop_mt) and bin_ops[l.larg.op]>op1_pr then
					l.larg = new_binop(larg, tok_op.str, l.larg)
					return l, l_end
				end

			end
			return new_binop(larg, tok_op.str, l), l_end
		else
			return larg, larg_end
		end
	end
end
parse.expr = parse_expr

return parse_expr