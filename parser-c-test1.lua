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
		tok0.scope:define(tostring(v.Var or v), { kind='var', type=obj.Type })
	end
end

function gmr.FuncDecl:onMatch(obj, tok0, tok)
	tok0.scope:define(tostring(obj.FuncName), {
		kind='func', rtype=obj.ReturnType, args=obj.Args
	})
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


local fmt = '%.7s  %-40.40s  %10.10s    %-30.30s  %f'
local function test(f)
	lm=lex_mem(lexer.new(io.readall('test/src'..f..'.c')))
	lm.scope = scope:sub()
	local clock0=os.clock()
	i, new = gmr.Chunks( lm())
	local clock=os.clock()-clock0
	local s = tostring(new):gsub('%s*\n', '\n')
	local s1 = io.readall('test/req'..f..'.c', false)
	io.writeall('test/ans'..f..'.c', s)
--	print(s)
--	assert(s:gsub('%s*\n', '\n')==s1)
--	if s~=s1 then
	print(s==s1 and 'ok  ' or 'fail', 'test/src'..f..'.c', clock)
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
				if typeof(re).expr then re2 = assert(load('return '..tostring(re):gsub('^%+', ''), ll..'\t'..tostring(re), 't', _G))() end
				if r==re or r==re2 then
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

gmr()
gmr'Expr'
gmr'Value'
assert(gmr.Goto:check())
test_expr'5+6+7+8*9/2-3+4'
test_expr'3/2*5+6+7+8*9/2-3+4'
test_expr'3/(2*5)+99'
test_expr'6+7+8*9/2-3+4'
i=9 j=-1
test_expr'(2*3+i-2)*2*j+1'
test_expr'(6+i-2)'
test_expr'(2*3+i-2)*2*j+666'
test_expr'(2*3+i-2)*2*j-666'
test_expr'(2*3*i)*2*j+666'
test_expr'(2*3*i)*2'
test_expr'2-(2*3+i-2)+1'

test_expr'2*3*i'
test_expr'2*3*i*j'
test_expr'2*3*i*j+3'


test'1'
test'2'

os.exit()


local g=require'parser-g'
--Grammar('rules')

--g.rules=List(g.rule):tmpl'${\n}'

----g.def=Seq(lexeme' :', lexeme' assign')

--g.rule=Seq(
--	Ident^'Name', lexeme' :=', --g.def,, lexeme' ;'
--	g.ra^'Body')
--	:tmpl'$Name := $Body;'

--g.ra=
--	Precedence(g.rs, lexeme'/')
----


--g.r= Alt(
--	Wrap(lexeme' (', g.ra, lexeme' )'),
--	Wrap(lexeme' [', g.ra, lexeme' ]')
--		:tmpl(function(s) return '('..tostring(s.body)..'):opt()' end),
--	Seq(Ident^'Field', lexeme' assign', g.r^'R'):tmpl'$R^"$Field"',
--	Ident~lexeme' :=',
--	lexeme'string':tmpl(function(s) return 'lexeme'..tostring(s.tok) end)

--)

--g.rs=Alt(

--	List(g.r):tmpl'Seq(${, })'

--)


	lm=lex_mem(lexer.new[[
		expr:= binop value { '*'/'/', '+'/'-' }
		value:= ('int' ',''int')/'int'/'string1'/call/'ident'/'string2'
		_if:="if" expr "then" chunks "end"
		chunks:=*chunk
		assign:='ident' 'assign' expr
		call:='ident' '(' (expr*' ,') ')'
		chunk:=_if/assign/call
	]])
	lm.scope = scope:sub()
--g() g'rule'

local i, new = g.rules(lm())--lm())
print(new)
print(i)
local gg=Grammar()
local fn, err = load(tostring(new), '', 't', setmetatable({}, {
	__index=function(self, name)
		return _G[name] or gg[name]
	end,
	__newindex=function(self, name, value)
		gg[name]=value
	end,
}))
print(fn, err)

local gg_res=fn()
gg'expr' gg'chunks'
print(gg)
local lgg=lex_mem(lexer.new[[a='fjhfdjh'+
		666,7*2-';'
		if 6+7+8*9/2-3+4 then
			b= 6+7+8*9/2-3+4
			print(a, b)
		end
		c=88+rawlen(t)
	]])
print(gg.chunks(lgg()))

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
