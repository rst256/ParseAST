StrongTypeDeclaration = 1

require'parser-c'

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
	i, new = Chunks( lm())
	local s = tostring(new)
	local s1 = io.readall('test/req'..f..'.c')
	io.writeall('test/ans'..f..'.c', s)
--	print(s)
--	assert(s:gsub('%s*\n', '\n')==s1)
--	if s~=s1 then
	print(s:gsub('%s*\n', '\n')==s1 and 'ok  ' or 'fail', 'test/src'..f..'.c')
end

test'1'

--lm=lex_mem(lexer.new'l1:')
--lm.scope = scope:sub()
--print( Label( lm()))
