dofile'keyword.lua'
local p = require'parser2'

local lm = require'lm'



local g = p.gmr'rules'

local g_src = [[
	lvalue_indexof:= 'ident' ' [' index=expr!'index expected' ' ]'!'`]` expected'

	expr:= binop value
	nil:=

]]
local g_src_tok0 = lm(g_src)()
--print(g.val)
g.alt1 = p.alt{
	p.enx{ rule=p.lexeme'ident', ex_rule=p.lexeme' :=' },
	p.lexeme'string1', p.lexeme'string2',
	p.seq{ p.lexeme' (', g.val, p.lexeme' )'}
}

g.field = p.seq()
	:add(p.lexeme'ident', 'field'):add(p.lexeme' ='):add(g.alt1, 'value')
	:mt{ __tostring=function(r) return r.field..'='..r.value end }

g.val = p.seq()
	:add( p.alt{g.field, g.alt1}, 'rule' )
	:add(p.iif(p.lexeme' !', p.lexeme'string1'), 'err')
	:mt{ __tostring=function(r)
		local s = tostring(r.rule)
		if r.err then s=s..' ! '..r.err end
		return s
	end }

g.rule = p.seq()
	:add(p.lexeme'ident', 'name')
	:add(p.lexeme' :=')
	:add(p.rep(g.val):opt():mt{ __tostring=table.concat }, 'value')
	:mt{ __tostring=function(r) return r.name..':='..r.value end }

--local seq1_end, seq1_res = g.val(g_src_tok0.next.next)
g.rules = p.rep(g.rule)--:items()
:mt{ __tostring=function(r) return table.concat(r, '\n') end }

local seq1_end, seq1_res = g(g_src_tok0)
print(seq1_end, seq1_res)
--print(g.val(seq1_end))
--while g_src_tok0 do
--	local seq1_end, seq1_res = g(g_src_tok0)
--	if seq1_end==nil then break end
--	print(seq1_res.name, ':=', (seq1_res.value))
--	g_src_tok0 = seq1_end
--end
