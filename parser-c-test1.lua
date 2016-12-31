StrongTypeDeclaration = 1

local gmr=require'parser-c2'

--package.cpath = [[?.dll;]]..package.cpath
--package.path = [[?.lua;?\init.lua;]]..package.path

local lexer=require'lexer'
local lex_mem = require'lm'


scope = require('ast.scope')()
scope:define('int', { kind='type', sizeof=4, name='int' })
scope:define('char', { kind='type', sizeof=1, name='char' })
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


 BinOp.sizeof=-666
BinOp.type={}
--function--	print(self.l, self.r)
--	local o, l, r = tostring(self.op),
--		(tonumber(tostring(self.l)) or self.l:eval()),
--		assert(tonumber(tostring(self.r)) or self.r:eval())
--	if o=='+'  then return l+r  end
--	if o=='-'  then return l-r  end
--	if o=='*'  then return l*r  end
--	if o=='/'  then return l/r  end
--	if o=='|'  then return l|r  end
--	if o=='&'  then return l&r  end
--	if o=='>>' then return l>>r end
--	if o=='<<' then return l<<r end
--end


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
	lm=lex_mem(lexer.new(io.readall('test/src'..f..'.c')))
	lm.scope = scope:sub()
	local clock0=os.clock()
	i, new = gmr( lm())
	local clock=os.clock()-clock0
	local s = tostring(new):gsub('%s*\n', '\n')
	local s1 = io.readall('test/req'..f..'.c', '')
	io.writeall('test/ans'..f..'.c', s)
--	print(s)
--	assert(s:gsub('%s*\n', '\n')==s1)
--	if s~=s1 then
	if s:gsub('%s+', ' ')==s1:gsub('%s+', ' ') then
		print('ok  ', 'test/src'..f..'.c', clock)
	elseif i==false then
		print('modf', 'test/src'..f..'.c', clock)
		io.write'update test file? (y/n): '
		local ans = io.read(1)
		if ans:find'^%s*[yY]%s*$' then
			io.writeall('test/req'..f..'.c', s)
		end
	else
		print('fail', 'test/src'..f..'.c', clock)
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

--gmr()
--gmr'Expr'
--gmr'Value'
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

test'1'
test'2'

local symmath = require'symmath'

local x = symmath.var'x'
local i = symmath.var'i'
local j = symmath.var'j'
local xa, xb = (x*2+6-3), x/0.5+33-3-30
print('(x*2+6-3)/(x/0.5+33-3-30)', xa, xb, xa/xb,(x*3)^2)
print(xa:calc{x=-7})
print( ((((((2 * 3) + i) - 2) * 2) * j) + 1) )
print( ((2*3+i-2)*2*j)-1 ==2*i*j+8*j-1 )
--os.exit()


local g=require'parser-g2'

local g_src = [[
	assign_op := '='/'+='/ '/=' /'-='/'*='
	value:= 'hex'/'real'/'int'/'string1'/call/'ident'/'string2'
	unop:= op=['-'/'!'/'&'/'*'] arg=(value/unop)

	expr:= binop unop {
		'*' / '/',
		'+' / '-',
		'&'/'|'/'^',
		'=='/'>='/'<='/'!='/'<'/'>',
		'&&'/'||',
		assign_op
	}

	_if:=" if" cond=expr " then" th=chunks " end"
	chunks:=*chunk
	assign:= var='ident' op=assign_op value=expr
	call:=fn='ident' ' (' args=(expr*' ,') ' )'
	chunk:=_if/assign/call
]]

	lm=lex_mem(lexer.new(g_src))
	lm.scope = scope:sub()
--g() g'rule'

local i, new = g(lm())--lm())
--print(new)
assert(i==false, tostring(i))
io.writeall('ast.lua',
	"dofile'keyword.lua'\nrequire'parser'\nlocal g = Grammar'chunks'\n\n"..
	tostring(new)..[[

g()
g.assign:tmpl'$var $op $value'
g._if:tmpl'if $cond then $th end'
g.call:tmpl'$fn ( $args )'
g.unop:tmpl'$op$arg'

print(g'a=5+6*x printf("%d") if x<5 then x=5 end')
return g
	]]
)

--local gg=Grammar('chunks')
--local fn, err = load(
--	"local g=Grammar('chunks')\n"..tostring(new)..'\nreturn g',
--	g_src, 't', _G)-- setmetatable({}, {
--	__index=function(self, name)
--		return _G[name] or gg[name]
--	end,
--	__newindex=function(self, name, value)
--		gg[name]=value
--	end,
--}))
--if not fn then error(tostring(err)..'\n'..tostring(new), 1) end

--local gg=fn()
----local gg_fn=gg()
--gg()
--gg.assign:tmpl'$var $op $value'
--gg._if:tmpl'if $cond then $th end'
--gg.call:tmpl'$fn ( $args )'

local gg=require'ast'

--gg'expr' gg'chunks'
--print(gg)
--local gg_src=[[
--	a='fjhfdjh'+
--	666.78*2-';'
--	if 6+7+8*9/2-3+4 then
--		b= 6+7+8*9/2-3+4
--		if b>300 then b=300 a=0 end
--		print(a, b, -0x5eA)
--	end
--	c=88+rawlen(t)/.9e-5
--]]

--local gg_req=([[
--  a = ('fjhfdjh' + ((666.78 * 2) - ';'))
--  if ((6 + 7) + ((((8 * 9) / 2) - 3) + 4)) then
--  b = ((6 + 7) + ((((8 * 9) / 2) - 3) + 4))
--	if (b > 300) then
--		b = 300
--		a = 0
--	end
--  print ( a, b, - 0x5eA )
-- end
--  c = (88 + (rawlen ( t ) / .9e-5))
--]]):gsub('%s+', ' ')

--local lgg=lex_mem(lexer.new(gg_src))
--local gg_i1, gg_a1 = gg.chunks(lgg())
--local gg_i2, gg_a2 = gg(gg_src)
--local gg_i3, gg_a3 = gg_fn(gg_src)
--assert(gg_i1==false, tostring(gg_i1))
--local gg_a1_str = tostring(gg_a1)
--print(gg_i1, gg_a1_str)
----print(gg_i2, gg_a2)
--assert(gg_a1_str:gsub('%s+', ' ')==gg_req, gg_req)
--assert(gg_a1_str==tostring(gg_a2), tostring(gg_a2))
--assert(gg_a1_str==tostring(gg_a3), tostring(gg_a3))
gg.unop:tmpl'$op$arg'
gmr = gg
local gg_i3, gg_a3 = test'1gg'
print( gg_i3, gg_a3)
for k,v in ipairs(gg_a3) do
	print(k, v.__rule.name, v.var)
end


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
--print'true	true	false	false	true	true	true	true'

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


--lm=lex_mem(lexer.new'l1:')
--lm.scope = scope:sub()
--print( Label( lm()))
