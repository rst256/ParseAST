StrongTypeDeclaration = 1

local gmr=require'parser-c2'


local lexer=require'lexer'
local lex_mem = require'lm'


scope = require('ast.scope')()
scope:define('int', { kind='type', sizeof=4, name='int' })
scope:define('char', { kind='type', sizeof=1, name='char' })
scope:define('unsigned', { kind='type', sizeof=4, name='unsigned' })
scope:define('bool', { kind='type', sizeof=1, name='bool' })

scope:define('void', { kind='type', sizeof=0, name='void' })

--[[ булево: контекст, тип
да
нет
вирт. иное
]]--


--[[ multiclass
одновременно явл. предст. одного из классов
одновременно -/-/ нескольких классов

]]--

--[[ Х прин. к кат К
да
нет

иное
	смотря какие, для тип(Х)==множ
	незнаю
	неприменимо
]]--




function gmr.Assign:onMatch(obj, tok0, tok)
	local sym = tok0.scope:find(tostring(obj.Var))
	if sym and sym.kind=='var' then
	end
end

function gmr.Define:onMatch(obj, tok0, tok)
	for _, v in ipairs(obj.Vars) do
		assert(tok0.scope:define(tostring(v.Var or v), { kind='var', type=obj.Type }), tok0.locate..'. redefine `'..tostring(v.Var or v)..
		'` ')
	end
end

function gmr.FuncDecl:onMatch(obj, tok0, tok)
	assert(tok0.scope:define(tostring(obj.FuncName), {
		kind='func', rtype=obj.ReturnType, args=obj.Args
	}), tok0.locate..'. redefine `'..tostring(obj.FuncName)..
		'` ')
end

function gmr.FuncDef:onMatch(obj, tok0, tok)
	local sym=tok0.scope:find(tostring(obj.FuncName))
	if sym then

	else
		tok0.scope:define(tostring(obj.FuncName), {
			kind='func', rtype=obj.ReturnType, args=obj.Args
		})
	end
end

function gmr.ComplexType:onMatch(obj, tok0, tok)

		local sym = tok0.scope:define(tostring(obj.Name), {
			kind='type', name=obj.Name, ComplexType=obj.ComplexType
		})
	obj.Fields = {}
	local k, sz = 0, 0
	for _, v in ipairs(obj.Body) do
		local bfsz=0
		for _, vv in ipairs(v.Vars) do

			if vv.BitField then
				bfsz=bfsz+tonumber(tostring(vv.BitField))
			else
				sz=sz+v.Type.sizeof
			end
			k=k+1
			assert(obj.Fields[tostring(vv.Var or vv)]==nil, tostring(vv.Var or vv))
			obj.Fields[tostring(vv.Var or vv)]={
				type=v.Type, order=k, bitfield=vv.BitField
			}
		end
		sz=sz+bfsz//8
	end
	sym.fields = obj.Fields
	sym.sizeof = sz

	obj.sym = sym
end

local typeof = require('mtmix').typeof


local fmt = '%.7s  %-40.40s  %10.10s    %-30.30s  %f'

local function test(f)
	lm=lex_mem(lexer.new(io.readall('test/src'..f)))
	lm.source_file_name = 'test/src'..f
	lm.scope = scope:sub()
	local clock0=os.clock()
	i, new = gmr( lm())
	local clock=os.clock()-clock0
	local s = tostring(new):gsub('%s*\n', '\n')
	local s1 = io.readall('test/req'..f, '')
	io.writeall('test/ans'..f, s)
	if s:gsub('%s+', ' ')==s1:gsub('%s+', ' ') then
		print('ok  ', 'test/src'..f, clock)
	elseif i==false then
		print('modf', 'test/src'..f, clock)
		io.write'update test file? (y/n): '
		local ans = io.read(1)
		if ans:find'^%s*[yY]%s*$' then
			io.writeall('test/req'..f, s)
		end
	else
		print('fail', 'test/src'..f, clock)
	end
	return i, new
end

local function test_expr(ll, l)
	lm=lex_mem(lexer.new(ll))
	lm.scope = scope:sub()
	local l = l or ''
	local clock0=os.clock()
	local i, new = gmr.Expr(lm())
	local clock=os.clock()-clock0
	if i~=false then
		if i then
			print(string.rep('-',i.pos-1)..'^')
			print('syntax error at', i.locate, '`', new, '`', clock)
		else
			print('syntax error', l, clock)
		end

	else
		local r = load('return '..ll, ll, 't', _G)()
		local src = tostring(new)
		local fn, err = load('return '..src, src, 't', _G)
		if not fn then
			print('eval error', err, clock)
			print(src)
		else
			local stat, res = pcall(fn)
			if not stat then
				print('runtime error', res)
			elseif r==res then
				local re = new:eval()
				if typeof(re).expr then re2 = assert(load('return '..tostring(re), ll..'\t'..tostring(re), 't', _G))() end
				if r==re or r==re2 or r-re2<1e-016 then
					print(fmt:format('ok  ', (tostring(new):match('^%s*(.*)')), r, tostring(re), clock))
				else
					print(fmt:format('fail', (tostring(new):match('^%s*(.*)')), r, tostring(re), clock))
				end
			else
				print(fmt:format('fail1', (tostring(new):match('^%s*(.*)')), r, tostring(re), clock))
			end
		end
	end
end

assert(gmr.Goto:check())
test_expr'5+6+7+8*9/2-3+4'
test_expr'3/2*5+6+7+8*9/2-3+4'
test_expr'3/(2*5)+99'
test_expr'6+7+8*9/2-3+4'
i=9 j=-1 x=9
test_expr'(2*3+i-2)*2*j+1'
test_expr'(6+i-2)'
test_expr'(2*3+i-2)*2*j+666'
test_expr'(2*3+i-2)*2*j-666'
test_expr'(2*3*i)*2*j+666'
test_expr'(2*3*i)*2'
test_expr'2-(2*3+i-2)+1'
test_expr'(x*2+6-3)/(x/2+33-3-30)'
test_expr'(x*3)^2'
test_expr'(x*3+6)^2'
test_expr'(x*3)^(0-2)'
test_expr'2*3*i'
test_expr'2*3*i*j'
test_expr'2*3*i*j+3'
test_expr'.5*6*i*j+3'
test_expr'0xFe<<1'
test_expr'0xFe>>1'

test'1.c'
test'2.c'
test'3.c'
--local symmath = require'symmath'

--local x = symmath.var'x'
--local i = symmath.var'i'
--local j = symmath.var'j'
--local xa, xb = (x*2+6-3), x/0.5+33-3-30
--print('(x*2+6-3)/(x/0.5+33-3-30)', xa, xb, xa/xb,(x*3)^2)
--print(xa:calc{x=-7})
--print( ((((((2 * 3) + i) - 2) * 2) * j) + 1) )
--print( ((2*3+i-2)*2*j)-1 ==2*i*j+8*j-1 )

--		el=[(" else" el=chunks)^'\n\telse\n\t\t$el\t']
--		" end"!'if end expected'

local clock0=os.clock()
local g=require'parser-g2'
print('require g2', os.clock()-clock0)


local g_src = [[
	lvalue_indexof:= id='ident' ' [' index=expr ' ]'
	lvalue:= ( lvalue_indexof / 'ident' )*' .'
	assign_op := '='/'+='/ '/=' /'-='/'*='
	value:= (' ('<expr>' )')/		unop/
		'hex'/'real'/'int'/'string1'/call/lvalue/'string2'
	unop:= op=('-'/'!'/'&'/'*'/'~') arg=(value!'unop arg expected')

	expr:= binop value {
		'*' / '/' / '%',
		'+' / '-',
		'&'/'|'/'^'/'~',
		'=='/'>='/'<='/'!='/'<'/'>'/'~=',
		'&&'/'||',
		assign_op
	}

	_if:=" if" cond=(expr!'cond expected') " then"!'`then` expected'
		th=[chunks]
		el=(
			((" else" el=chunks " end"!'if end expected')^'\n\telse\n\t\t$el')/
			" end"!'if end expected')

	chunks:=*chunk

	assign:= var=lvalue op=assign_op value=expr

	define:= " local" var='ident' var_type=[type_def] value=('assign'?expr)

	expr_list:=[expr*' ,']
	call:=fn=lvalue ' (' args=((expr*' ,')!'call func next arg expected')
		' )'!'call func end expected'
	metacall:= ' @' fn='ident' ' (' args=((expr*' ,')!'call func next arg expected')
		' )'!'call func end expected'
	ret:=" return" values=expr_list
	type_def:= ' <-' argtype='ident'
	type_defs:= ' <-' argtypes=('ident'*' ,')
	var_def:= argname='ident' argtype=[type_def]
	func:=" function" fn=lvalue ' ('
		args=[(var_def)*' ,']	' )'!'define func arg list end expected'
		rettype=[type_defs]
		body=[chunks] " end"!'func end expected'
	metafunc:=' @' " function"
		fn='ident' ' ('
		args=[('ident')*' ,']	' )'!'define metafunc arg list end expected'
		body=[chunks] (' @' " end")!'func end expected'
	macrodef:=' @' " macros"
		fn='ident' ' ('
		args=[('ident')*' ,']	' )'!'define metafunc arg list end expected'
		body=expr (' @' " end")!'func end expected'
	_for:=" for" var=assign " do" body=[chunks] " end"!'for end expected'
	_while:=" while" cond=expr " do" body=[chunks] " end"!'while end expected'
	gfor:=" for"
		args=[(var_def)*' ,']
		" in" iter=(expr!'gfor iter expected')
		" do" body=[chunks] " end"!'for end expected'

	chunk:=gfor/_while/_for/_if/func/assign/call/ret/define/
		macrodef/metafunc/metacall
]]

lm=lex_mem(lexer.new(g_src))
lm.scope = scope:sub()

clock0=os.clock()
local i, new = g(lm())
print('parse gg', os.clock()-clock0)

if i~=false then
	print(i, '\n'..tostring(new))
	os.exit()
end

clock0=os.clock()
io.writeall('ast.lua',
	"dofile'keyword.lua'\nrequire'parser'\nlocal g = Grammar'chunks'\n\n"..
	tostring(new)..[[

g()
g.assign:tmpl'$var $op $value'
g._if:tmpl'if $cond then\n		$th$el\n\tend'
g.call:tmpl'$fn($args)'
g.metacall:tmpl'@$fn($args)'
g.unop:tmpl'$op$arg'
g.ret:tmpl'return $values'
g.func:tmpl'function $fn($args)$rettype\n$body\nend'
g.metafunc:tmpl'@function $fn($args)$rettype	$body	end'
g.macrodef:tmpl'@macros $fn($args)	$body	@end'
g.type_def:tmpl'<-$argtype'
g.type_defs:tmpl'<-$argtypes'
g.var_def:tmpl'$argname$argtype'
g._for:tmpl'for $var do $body	end'
g._while:tmpl'while $cond do\n\t$body\tend'
g.gfor:tmpl'for $args in $iter do $body	end'
g.lvalue_indexof:tmpl'$id[$index]'
g.lvalue:tmpl'${.}'
g.define:tmpl'local $var$var_type $value'


--print(g'a=5+6*x printf("%d") if x<5 then x=5 end')
return g
	]]
)
print('write gg', os.clock()-clock0)

clock0=os.clock()
local gg=require'ast'
print('require gg', os.clock()-clock0)
--print(gg.eb.rule_type)


--g

gmr = gg
test'3gg.lua'
local gg_i3, gg_a3 = test'1gg.lua'
--print( gg_i3, gg_a3)
local ts = '  '
local function fp(a, tab)
	for k,v in pairs(a) do
		if v.__rule and k~='parent' then
			if v.parent then
				if not v.begin_tok then
					print(v)
				end
				print(('%s %20s %20.20s %30s  %.30s'):format(ts:rep(tab or 0)..k,
					v.__rule.name,
					v.begin_tok.locate..'-'..v.end_tok.locate,
					'"'..tostring(v)..'"',
					v.parent.__rule~=nil and v.parent.__rule.name or
					('"'..tostring(v.parent)..'"')))
--					v.parent.begin_tok.locate, v.parent.end_tok.locate)
			else
				print(('%s %20s %20.20s %30s'):format(ts:rep(tab or 0)..k,
					v.__rule.name,
					v.begin_tok.locate..'-'..v.end_tok.locate, '"'..tostring(v)..'"'))
			end
--			fp(v, (tab or 0)+1)
		end
	end
end
--fp(gg_a3)

--print(gg_a3[1].value.r.l.__rule)
os.exit()
mtmix=require'mtmix'
local t_mt=mtmix.mtmix()

local t=t_mt()--setmetatable({}, t_mt)
function t_mt.ctor(...) return {...} end
local t1=t_mt(1,20)
print(t_mt.index)
t_mt.index=print
print(t.tf1)
print(t[2], t1[2])

os.exit()
print'\nA:iC	C:iA	A:iA	C:iC'
print(
	Assign:intersect(gmr.Chunks), gmr.Chunks:intersect(Assign),
	Assign:intersect(Assign),	gmr.Chunks:intersect(gmr.Chunks)
)

print'\nA>=C	C>=A	C==A	A==C	A>=A	C>=C	A<=A	C<=C'
print(	Assign>=gmr.Chunks, gmr.Chunks>=Assign,
	gmr.Chunks==Assign, Assign==gmr.Chunks,
	Assign>=Assign, gmr.Chunks>=gmr.Chunks,
	Assign<=Assign, gmr.Chunks<=gmr.Chunks
)

print'\nA>C	C>A	A<C	C<A	C<A	A<C	A>A	C>C'
print(
	Assign>gmr.Chunks, gmr.Chunks>Assign, Assign<gmr.Chunks, gmr.Chunks<Assign,
	gmr.Chunks<Assign, Assign<gmr.Chunks,

	Assign>Assign, gmr.Chunks>gmr.Chunks
)
print'true	false	false	true	true	false	true	true'

print'\n!A>=C	!C>=A	!C==A	!A==C	!A>=A	!C>=C	!A<=A	!C<=C'
print(
	not (Assign>=gmr.Chunks), not (gmr.Chunks>=Assign),
	not (gmr.Chunks==Assign), not (Assign==gmr.Chunks),
	not (Assign>=Assign), not (gmr.Chunks>=gmr.Chunks),
	not (Assign<=Assign), not (gmr.Chunks<=gmr.Chunks)
)

print'\nA:sC\tC:sA'
print(Assign:subset(gmr.Chunks), gmr.Chunks:subset(Assign) )



print'\nE:sC	C:sE	E:sE	C:sC'
print(
	Expr:subset(gmr.Chunks), gmr.Chunks:subset(Expr),
	Expr:subset(Expr),	gmr.Chunks:subset(gmr.Chunks)
)


print'\nE:iC	C:iE	E:iE	C:iC'
print(
	Expr:intersect(gmr.Chunks), gmr.Chunks:intersect(Expr),
	Expr:intersect(Expr),	gmr.Chunks:intersect(gmr.Chunks)
)



print'\nE>=C	C>=E	C==E	E==C	E>=E	C>=C	E<=E	C<=C'
print(
	Expr>=gmr.Chunks, gmr.Chunks>=Expr,
	gmr.Chunks==Expr, Expr==gmr.Chunks,
	Expr>=Expr, gmr.Chunks>=gmr.Chunks,
	Expr<=Expr, gmr.Chunks<=gmr.Chunks
)


