local open_lexeme_id = lexemes['{']
local close_lexeme_id = lexemes['}']
local empty_lexeme_id = lexemes[';']




local block_mt = { __index={} }

local function new_block(scope)
	return setmetatable({ scope=scope }, block_mt)
end

function block_mt:__tostring()
	local s = ''
	for i, a in ipairs(self) do s=s..tostring(a)..'\n' end
	return s:gsub('\n$', '')
end

function block_mt.__index:insert(...)
	for k=1, select('#', ...) do
		local item = select(k, ...)
		if item.declare then item:declare(self.scope) end
		table.insert(self, item)
	end
end

function block_mt.__index:tol()

end





local parse_expr = require'ast.expr'
local parse_texpr = require'ast.type-expr'
local parse_assign = require'ast.assign'



local ident_lexeme_id = lexemes.ident

local function expect_tok(tok, what, msg)
	if tok.lexeme~=lexemes[what] then
		error(msg or ('`'..what..'` expected at'..tostring(tok)), 2)
	end
end


local assign_mt = { __index={} }

local function new_assign(var, value)
	return setmetatable({ var=var, value=value }, assign_mt)
end

function assign_mt.__index:declare(scope)
	local sym = assert(scope:find(self.var) or false,
		'variable `'..tostring(self.var)..'` is not defined in scope '..
		tostring(scope))
	assert(sym.kind=='var', 'assignment to `'..self.var..'` '..sym.kind)
	if self.value and self.value.declare then self.value:declare(scope) end
end

function assign_mt:__tostring()
	return tostring(self.var)..' = '..tostring(self.value)
end


function parse.assign(tok)
	if tok.lexeme==ident_lexeme_id then
		local tok2 = tok:next()
		if tok2.lexeme==lexemes.assign then
			local expr, end_expr = parse_expr(tok2:next())
			if expr then return new_assign(tok.str, expr), end_expr end
		end
	end
end


local function parse_alt(alts)
	return function(tok)
		for i, a in ipairs(alts) do
			local ast_item, end_tok = a(tok)
			if ast_item then return ast_item, end_tok end
		end
	end
end







local define_var_mt = { __index={} }

local function new_define_var(texpr, var, value)
	return setmetatable({ texpr=texpr, var=var, value=value }, define_var_mt)
end

function define_var_mt:__tostring()
	local s = tostring(self.texpr)..' '..tostring(self.var)
	if self.value then s=s..' = '..tostring(self.value) end
	return s--..';'
end

function define_var_mt.__index:declare(scope)
	scope:define(self.var, {
		kind='var',--self.texpr=='type' and 'type' or 'var',
		type=self.texpr
	})
	if self.value and self.value.declare then self.value:declare(scope) end
end


local typedef_mt = { __index={} }

local function new_typedef(name, texpr)
	return setmetatable({ texpr=texpr, name=name }, typedef_mt)
end

function typedef_mt:__tostring()
	return 'typedef '..tostring(self.texpr)..' '..tostring(self.name)..';'
end

function typedef_mt.__index:declare(scope)
	scope:define(self.name, {
		kind='type',--self.texpr=='type' and 'type' or 'var',
		type=self.texpr
	})
end


local define_func_mt = { __index={} }

local function new_define_func(ret_type, name, args, body)
	return setmetatable({
		ret_type=ret_type, name=name, args=args, body=body
	}, define_func_mt)
end

function define_func_mt.__index:declare(scope)
	scope:define(self.name, {
		kind=self.ret_type=='type' and 'tfn' or 'fn',
		ret_type=self.ret_type
	})
end

function define_func_mt:__tostring()
	local s = tostring(self.ret_type)..' '..tostring(self.name)..'('
	for i, a in ipairs(self.args) do s=s..tostring(a or '')..', ' end
	if self.args.varargs then s=s..'...' end
	s=s:gsub(' ?, $', '')..')'
	if self.body then
		s=s..'{\n\t'..tostring(self.body):gsub('\n', '\n\t')..'\n}'
	end
	return s--..';'
end


local sep_lexeme_id = lexemes[';']

function parse.define_var(tok)
	local texpr, texpr_end = parse_texpr(tok)
	if texpr then
		local tok1 = texpr_end:next():expect(ident_lexeme_id)

		local tok2 = tok1:next()
		if tok2.lexeme==lexemes.assign then
			local expr, end_expr = parse_expr(tok2:next())
			if expr then return new_define_var(texpr, tok1.str, expr), end_expr end
		else
			return new_define_var(texpr, tok1.str), tok1
		end
	end
end




local function parse_block(t, scope)
	local scope = scope or t:scope()
	local tok_bt = t
	if tok_bt.lexeme==empty_lexeme_id then
		return new_block(), tok_bt

	elseif tok_bt.lexeme==open_lexeme_id then
		local block = new_block(scope:sub())





	local tok = tok_bt:next()
while tok do
	local texpr, texpr_end = parse_texpr(tok)
	if texpr then
		local tok2 = texpr_end:next():expect(ident_lexeme_id)



		local tok3 = tok2:next()
--		local texpr2, end_texpr2
--		if texpr=='type' then
--			texpr2, end_texpr2 = parse_texpr(tok3)
--			assert(texpr2~='type')
--		end
--		if texpr2 then
--			tok = end_texpr2:next():expect';':next()
--			local def = new_typedef(tok2.str, texpr2)
--			block:insert(def)
----			block.scope:define(tok2.str, {
----				kind='type',
----				texpr=texpr2
----			})
--	else
		if tok3.lexeme==lexemes.assign then

			local expr, end_expr = parse_expr(tok3:next())
			local def = new_define_var(texpr, tok2.str, expr)
			tok = end_expr:next():expect';':next()
			block:insert(def)
		elseif tok3.lexeme==lexemes['('] then
			local args = {}--, tok4parse_list(tok3, parse.define_var, 41)

			local tok4 = tok3:next()
			if tok4.lexeme~=41 then
				while 1 do
					if tok4.lexeme==lexemes['...'] then
						args.varargs = true
						tok4 = tok4:next():expect(')', 'another arg after varargs declared')
						break
					else
						local arg, arg_end = parse_texpr(tok4)

						tok4 = arg_end:next()
						if tok4.lexeme==41 then
							table.insert(args, new_define_var(arg, ''))
							break
						elseif tok4.lexeme==ident_lexeme_id then
							table.insert(args, new_define_var(arg, tok4.str))
							tok4 = tok4:next()
							if tok4.lexeme==41 then break end
						else
							table.insert(args, new_define_var(arg, ''))
						end
						tok4 = tok4:expect',':next()
					end
				end
			end

			local tok_end, block2 = tok4:next()
			if tok_end.lexeme==open_lexeme_id then
				block2, tok_end = parse_block(tok_end, scope);
			else
				tok_end:expect';'
			end
			local def = new_define_func(texpr, tok2.str, args, block2)

			block:insert(def)
			tok = tok_end:next()
		elseif tok3.lexeme==lexemes[';'] then --define
			local def = new_define_var(texpr, tok2.str)
			block:insert(def)
			tok = tok3:next()
		end
	elseif tok.lexeme==keywords.typedef then

		local texpr, end_texpr = parse_texpr(tok:next())
		assert(texpr and texpr~='type')
		local tok2 = end_texpr:next():expect(ident_lexeme_id)
		tok = tok2:next():expect';':next()
		local def = new_typedef(tok2.str, texpr)
		block:insert(def)
	elseif tok.lexeme==close_lexeme_id then
		return block, tok
	elseif tok.lexeme==ident_lexeme_id then
		local tok2 = tok:next()
		local ast_item, end_tok
		if tok2.lexeme==lexemes.assign then
			ast_item, end_tok = parse.assign(tok)
			print(ast_item.value:typeof())
		elseif tok2.lexeme==lexemes['('] then
			ast_item, end_tok = parse.call(tok)
		else
			print('syntax error `(` or `=` expected after ', tok)
			return nil
		end
		tok = end_tok:next()
		if allow_opt_sep then
			if tok.lexeme==sep_lexeme_id then
				tok = tok:next()
			end
		else
			tok = tok:expect(sep_lexeme_id):next()
		end
		block:insert(ast_item)
--		tok = end_tok:next():expect';':next()
else
--	function choice
		local ch = {
			[64] = {
				[8193] = parse.call.___call
			}
		}

			print('syntax error', tok, parse.choice(tok, ch))
			return nil
	end
end
		return nil
	end
end

function parse.choice(tok, choice)
	local ch, tok2 = choice[tok.lexeme]
	if ch then
		local t = type(ch)
		if t=='table' then
			return parse.choice(tok2 or tok:next(), ch)
		elseif t=='function' then
			return ch(tok)
		end
	end
end

return parse_block