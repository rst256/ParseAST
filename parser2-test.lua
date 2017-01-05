dofile'keyword.lua'
local p = require'parser2'

local lm = require'lm'



local g = p.gmr'rules'

local g_src = [[
	lvalue_indexof:= 'ident' ' [' index=expr!'index expected' ' ]'!'`]` expected'
	lvalue:=lvalue_indexof/'ident'
	expr:= lvalue  / 'int' ['.' 'int'] / 'int' / 'string1'
	nil:=

]]
local g_src_tok0 = lm(g_src)()
--print(g.val)
g.alt1 = p.alt{
	p.enx(p.tok'ident', p.tok' :=')
		:mt{ __tostring=function(r)	return 'g.'..tostring(r.tok) end },
	p.tok'string1'
		:mt{ __tostring=function(r)	return 'p.tok'..tostring(r.tok) end },
	p.tok'string2',
	p.wrap( p.tok' (', g.value, p.tok' )'),
	p.seq{ p.tok' [', g.value, p.tok' ]' }
		:mt{ __tostring=function(r)	return ''..r[1]..':opt()' end },
}

g.field = p.seq()
	:add(p.tok'ident', 'field'):add(p.tok' ='):add(g.alt1, 'value')
	:add(p.iif(p.tok' !', p.tok'string1':opt''), 'err')
	:mt{ __tostring=function(r)
		local s = tostring(r.value)
		if r.err then s=s..':expect('..tostring(r.err)..')' end
		return ''..s..', \''..r.field..'\''
	end }

g.val = p.alt{g.field,
	p.seq():add(g.alt1, 'rule' )
	:add(p.iif(p.tok' !', p.tok'string1':opt''), 'err')
	:mt{ __tostring=function(r)
		local s = tostring(r.rule)
		if r.err then s=s..':expect('..tostring(r.err)..')' end
		return s
	end }
}

g._value = p.list(
p.rep(g.val):mt{
	__tostring=function(r)
		if #r==1 then return tostring(r[1]) end
		local s = 'p.seq()'
		for _, v in ipairs(r) do s=s..':add('..v..')' end
		return s--	'p.seq('..table.concat(r, ', ')..')'
	end },
	p.tok' /'
):mt{
	__tostring=function(r)
		if #r==1 then return tostring(r[1]) end
		return	'p.alt{'..table.concat(r, ', ')..'}'
	end }

g.value = p.seq()
	:add(g._value, '_value')
	:add(p.iif(p.tok' ?', g._value:expect'then expected'), 'th')
		:mt{ __tostring=function(r)
			local s = tostring(r._value)
			if r.th then s='p.iif('..s..', '..tostring(r.th)..')' end
			return s
		end }

g.rule = p.seq()
	:add(p.tok'ident', 'name')
	:add(p.tok' :=')
	:add(g.value:opt'', 'value')
	:mt{ __tostring=function(r) return 'g.'..r.name..' = '..r.value end }

--local seq1_end, seq1_res = g.val(g_src_tok0.next.next)
g.rules = p.rep(g.rule)--:items()
:mt{ __tostring=function(r)
	return table.concat(r, '\n\n')
end }


g.lvalue_indexof = p.seq():add(p.tok'ident'):add(p.tok'['):add(g.expr:expect('index expected')):add(p.tok']':expect('`]` expected'))

g.lvalue = p.alt{g.lvalue_indexof, p.tok'ident'}

g.expr = p.alt{g.lvalue, p.seq():add(p.tok'int'):add(p.seq():add(p.tok'.'):add(p.tok'int')), p.tok'int', p.tok'string1'}

local seq1_end, seq1_res = g(g_src_tok0)
print(seq1_end, seq1_res)

for k,v in ipairs(seq1_res) do
	print(k, v.name, ':=', (v.self[3]))
end

print(g.field:tostr())
print(g.expr(lm('array[55 . 666]')()))