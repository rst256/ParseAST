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


function Assign:onMatch(obj, tok0, tok)
	local sym = tok0.scope:find(tostring(obj.Var))
	if sym and sym.kind=='var' then
	end
end

function Define:onMatch(obj, tok0, tok)
	for _, v in ipairs(obj.Vars) do
		tok0.scope:define(tostring(v.Var or v), { kind='var', type=obj.Type })
	end
end

function FuncDecl:onMatch(obj, tok0, tok)
	tok0.scope:define(tostring(obj.FuncName), {
		kind='func', rtype=obj.ReturnType, args=obj.Args
	})
end

function FuncDef:onMatch(obj, tok0, tok)
	local sym=tok0.scope:find(tostring(obj.FuncName))
	if sym then

	else
		tok0.scope:define(tostring(obj.FuncName), {
			kind='func', rtype=obj.ReturnType, args=obj.Args
		})
	end
end

function ComplexType:onMatch(obj, tok0, tok)

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



local function test(f)
	lm=lex_mem(lexer.new(io.readall('test/src'..f..'.c')))
	lm.scope = scope:sub()
	local clock0=os.clock()
	i, new = Chunks( lm())
	local clock=os.clock()-clock0
	local s = tostring(new)
	local s1 = io.readall('test/req'..f..'.c', false)
	io.writeall('test/ans'..f..'.c', s)
--	print(s)
--	assert(s:gsub('%s*\n', '\n')==s1)
--	if s~=s1 then
	print(s:gsub('%s*\n', '\n')==s1 and 'ok  ' or 'fail', 'test/src'..f..'.c', clock)
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
			print('syntax error', err, clock)
		else
			local stat, res = pcall(fn)
			if not stat then
				print('runtime error', res)
			elseif r==res then
				local re = new:eval()
				if r==re then
					print('ok  ', l, (tostring(new):match('^%s*(.*)')), clock)
				else
					print('fail', l, (tostring(new):match('^%s*(.*)')), r, re, clock)
				end
			else
				print('fail', l, (tostring(new):match('^%s*(.*)')), r, res, clock)
			end
		end
	end
end

gmr()
gmr'Expr'
gmr'Value'
assert(Goto:check())
test_expr'5+6+7+8*9/2-3+4'
test_expr'3/2*5+6+7+8*9/2-3+4'
test_expr'3/(2*5)+99'
test_expr'6+7+8*9/2-3+4'

test'1'
test'2'


os.exit()
print'\nA:iC	C:iA	A:iA	C:iC'
print(
	Assign:intersect(Chunks), Chunks:intersect(Assign),
	Assign:intersect(Assign),	Chunks:intersect(Chunks)
)

print'\nA>=C	C>=A	C==A	A==C	A>=A	C>=C	A<=A	C<=C'
print(	Assign>=Chunks, Chunks>=Assign,
	Chunks==Assign, Assign==Chunks,
	Assign>=Assign, Chunks>=Chunks,
	Assign<=Assign, Chunks<=Chunks
)
--print'true	true	false	false	true	true	true	true'

print'\nA>C	C>A	A<C	C<A	C<A	A<C	A>A	C>C'
print(
	Assign>Chunks, Chunks>Assign, Assign<Chunks, Chunks<Assign,
	Chunks<Assign, Assign<Chunks,

	Assign>Assign, Chunks>Chunks
)
print'true	false	false	true	true	false	true	true'

print'\n!A>=C	!C>=A	!C==A	!A==C	!A>=A	!C>=C	!A<=A	!C<=C'
print(
	not (Assign>=Chunks), not (Chunks>=Assign),
	not (Chunks==Assign), not (Assign==Chunks),
	not (Assign>=Assign), not (Chunks>=Chunks),
	not (Assign<=Assign), not (Chunks<=Chunks)
)

print'\nA:sC\tC:sA'
print(Assign:subset(Chunks), Chunks:subset(Assign) )



print'\nE:sC	C:sE	E:sE	C:sC'
print(
	Expr:subset(Chunks), Chunks:subset(Expr),
	Expr:subset(Expr),	Chunks:subset(Chunks)
)


print'\nE:iC	C:iE	E:iE	C:iC'
print(
	Expr:intersect(Chunks), Chunks:intersect(Expr),
	Expr:intersect(Expr),	Chunks:intersect(Chunks)
)



print'\nE>=C	C>=E	C==E	E==C	E>=E	C>=C	E<=E	C<=C'
print(
	Expr>=Chunks, Chunks>=Expr,
	Chunks==Expr, Expr==Chunks,
	Expr>=Expr, Chunks>=Chunks,
	Expr<=Expr, Chunks<=Chunks
)


--lm=lex_mem(lexer.new'l1:')
--lm.scope = scope:sub()
--print( Label( lm()))
