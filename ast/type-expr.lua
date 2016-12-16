local ident_lexeme_id = lexemes.ident
local typedef_lexeme_id = keywords['typedef']
local pointer_lexeme_id = lexemes['*']

local function parse_type(lm)
	local tok = lm[0]
--	if tok.lexeme==ident_lexeme_id then
--		return tok.str--{ tok.str }
--	elseif tok.lexeme==int_lexeme_id then
--		return tonumber(tok.str)
--	elseif tok.lexeme==string_lexeme_id then
--		return tok.str
--	else
--		return nil
--	end
end

local attribs = {
	[keywords['const']] = 0x1,
	[keywords['static']] = 0x2,
	[keywords['extern']] = 0x4,
}

local attrib_names = {
	[0x1] = 'const',
	[0x2] = 'static',
	[0x4] = 'extern',
}

local complex_type = {
	[keywords['struct']] = 0x1,
	[keywords['union']] = 0x2,
	[keywords['enum']] = 0x4,
--	[keywords['void']] = function(tok, attr),
}

local texpr_mt = { __index={ pointer=0 } }

local function new_texpr(basetype, attrib)
	return setmetatable({ basetype=basetype, attrib=attrib or 0 }, texpr_mt)
end
AST.texpr = new_texpr

function texpr_mt:__tostring()
	local s = ''
	for v, k in pairs(attrib_names) do
		if self.attrib & v ~= 0 then s = s..k..' ' end
	end
	s = s..tostring(self.basetype)
	if self.pointer then s = s..string.rep('*', self.pointer) end
	return s
end

function texpr_mt.__index:lmin()

end

function texpr_mt.__index:tol()

end







local function parse_texpr(tok)
	if tok.lexeme==keywords.type then return 'type', tok end

	local attrib, tok1 = 0, tok
	while 1 do
		local a = attribs[tok1.lexeme]
		if not a then break else
			attrib = attrib | a end
		tok1 = tok1:next()
	end
	local tok_bt = tok1
	--(attrib==0 and tok1:next() or tok1)
	local cpx_t, te, tok_end = complex_type[tok_bt.lexeme]
	if cpx_t then
		return 'complex_type: '..tok_bt.str, tok_bt
	elseif tok_bt.lexeme==ident_lexeme_id then
		local sym = lm.scope:find(tok_bt.str)
		if not sym then return end
		if sym.kind=='type' then
			te = new_texpr(tok_bt.str, attrib)
			tok_end = tok_bt
--			return te, tok_bt
		elseif sym.kind=='tfn' then
--			tok_bt = tok_bt:next():expect'('
			local args, tok3 = parse_list(tok_bt:next():expect'(', parse.texpr|parse.expr, 41)--parse.call(tok_bt)
			local tfn = AST.call(tok_bt.str, args)
			tfn.sym=sym
			te = new_texpr((tfn), attrib)
			tok_end = tok3
		end
		if not te then return end
		local tok3 = tok_end:next()
		while tok3.lexeme==pointer_lexeme_id do
			te.pointer = (te.pointer or 0) + 1
			tok_end = tok3
			tok3 = tok3:next()

		end
		return te, tok_end
	end
end
parse.texpr = parse_texpr

return parse_texpr