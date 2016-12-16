--dofile'parser-c-test1.lua'

StrongTypeDeclaration = false

require'parser-c'

package.cpath = [[C:\dev\utf8\re2c\release\?.dll;]]..package.cpath
package.path = [[?.lua;?\init.lua;]]..package.path

local lexer=require'lexer'
local lex_mem = require'lm'


scope = require('ast.scope')()
scope:define('int', { kind='type', sizeof=4, name='int' })
scope:define('char', { kind='type', sizeof=1, name='char' })
scope:define('bool', { kind='type', sizeof=1, name='bool' })
scope:define('void', { kind='type', sizeof=0, name='void' })



function Assign:onMatch(obj, tok0, tok)
	local sym = tok0.scope:find(tostring(obj.Var))
	if sym and sym.kind=='var' then
	end
end

local function e1(obj)
	if #obj==1 then
		return tostring(obj)
	end
	local s = ''
	for k, v in ipairs(obj) do
		s = s..k..': '..tostring(v)..'\n'
--		print(k, v)
		s = s..' '..e1(v):gsub('\n', '\n ')
	end
	return s
end

function Expr:onMatch(obj, tok0, tok)
--	for k, v in ipairs(obj) do
--		print(k, v)
--		Expr.onMatch(obj, v)
--	end
--	local src = tostring(obj)
--	local fn, err = load('return '..src, src, 't', _G)
--	if not fn then
--		print('syntax error', err)
--	else
--		local stat, res = pcall(fn)
--		if not stat then
--			print('runtime error', res)
--		else
--			obj.res=res
--		end
----	print(e1(obj))
----		print(stat, res)
--	end
end

--function Expr.capt_mt:onMatch(obj, tok0, tok)
----	for k, v in ipairs(obj) do
----		print(k, v)
----		Expr.onMatch(obj, v)
----	end

--	print(e1(obj))
--end

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

local function test_expr(ll, l)
	lm=lex_mem(lexer.new(ll))
	lm.scope = scope:sub()
	local l = l or ''
	local i, new = Expr(lm())
	if i~=false then
		if i then
			print(string.rep('-',i.pos-1)..'^')
			print('syntax error at', i.locate, '`', new, '`')
		else
			print('syntax error', l)
		end
	else
		local r = load('return '..ll, ll, 't', _G)()
		local src = tostring(new)
		local fn, err = load('return '..src, src, 't', _G)
		if not fn then
			print('syntax error', err)
		else
			local stat, res = pcall(fn)
			if not stat then
				print('runtime error', res)
			elseif r==res then
				if r==new:eval() then
					print('ok  ', l, (tostring(new):match('^%s*(.*)')))
				else
					print('fail', l, (tostring(new):match('^%s*(.*)')), r, new:eval())
				end
			else
				print('fail', l, (tostring(new):match('^%s*(.*)')), r, res)
			end
		end
	end
end

test_expr'5+6+7+8*9/2-3+4'
test_expr'3/2*5+6+7+8*9/2-3+4'
test_expr'3/(2*5)+99'
test_expr'6+7+8*9/2-3+4'

repeat
	local l=io.read'l'
	test_expr(l, '')
--	lm=lex_mem(lexer.new(l))
--	lm.scope = scope:sub()
--	local i, new = Expr(lm())
--	if i~=false then
--		if i then
--			print(string.rep('-',i.pos-1)..'^')
--			print('syntax error at', i.locate, '`', new, '`')
--		else
--			print('syntax error')
--		end
--	else
--		print((tostring(new):match('^%s*(.*)')),
--			load('return '..l, l, 't', _G)(), new.res)
--	end
until #l==0


--i, new = Chunks( lm())
--print(i, #new)
--local s = tostring(new)
--local s1 = [[int i=(--((int*)(*(arr.count))) + (5 * 6 /  ((2 + 11) ? 1 : (6 + ++(i))) )), i1, i2=0;
--const int2 i3=((size_t)4 + (size_t)1 + ((size_t)8 * (size_t)8 / (size_t)80));
--if((i <= 0)) {
--	i = 0;
--	if((i2 < 50)) {
--		i2 += 1;
--		if((i2 / 2)) goto l1;
--	}
--	if(i3) ; else i3 = 1;
--} else {
--	i -= 1;
--	i2 += 2;
--}
--void* v, vv=((y += (x > 5)) && ((6 << (99 + (7 * 2))) == f((7 | 2), x)));
--l1:
--printf("%p, %d\n", v, i, ...);
--x += i3;
--for(int i=0;; i; )printf("%d\n", (i)++);
--return ((v)++ || (char)((s1.f((7 | 2), x))--));
--int* ip(char* );
--int2* ip(const char* c_ptr){
--	return (int*)(c_ptr);
--}
--char[30]* s;
--sl = (size_t)240;
--struct struct1 {
--	int i:8, i2:9;
--	void* v;
--} ss1;
--int ii=((size_t)10 + (size_t)10);
--p(s.f.fd[99].cb[1](((5 * 6) << (6 * 2))));]]

--print(s)
--assert(s:gsub('%s*\n', '\n')==s1)