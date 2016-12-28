dofile'keyword.lua'

require'parser'
gmr=Grammar'Chunks'

local overload_mt = { __metatable={ overload=true, callable=true } }

function overload_mt:__call(...)
	local ct, err = self.ovl_list, ''
	for k=1, select('#', ...) do

		local t = typeof(select(k, ...))
		for t1, ct1 in pairs(ct) do
			if t[t1] then ct=ct1 err=err..t1..', ' goto next_ct end
		end
		error(err..', ?')
		::next_ct::
	end
--	local fn = self[at]
--	if ct then
		return ct(...)
end

local function overload(ovl_list)
	return setmetatable({ ovl_list=ovl_list or {} }, overload_mt)
end


local var_mt = { __metatable={ expr=true, single_nom=true } }

local function snom(mul, var)
	return setmetatable({ var=var, mul=mul or 1	}, var_mt)
end

function var_mt:__tostring ()
	local s = (self.mul==1 and '' or (self.mul<0 and '' or '+')..self.mul..'*')
	for k, v in pairs(self.var or {}) do
		s = s..tostring(k)..(v==1 and '' or '^'..v)..'*'
	end
	return s:gsub('%*$', ''):gsub('^$', '+1')
end



var_mt.__add = overload{
	single_nom={
		number=function(s, n) return polynom(s, snom(n)) end,
		single_nom=function(s, s2) return polynom(s, s2) end
	},
	number={
		single_nom=function(n, s) return polynom(s, snom(n)) end
	},
}

var_mt.__sub = overload{
	single_nom={
		number=function(s, n) return polynom(s, snom(-n)) end
	},
	number={
		single_nom=function(n, s) return polynom(s, snom(-n)) end
	},
}

var_mt.__mul = overload{
	single_nom={
		number=function(s, n) return snom(s.mul*n, s.var) end,
		single_nom=function(s, s2)
			local var = {}
			for k,v in pairs(s.var or {}) do var[k]=v end
			for k,v in pairs(s2.var or {}) do
				if var[k] then var[k]=var[k]+v else var[k]=v end
			end
			return snom(s.mul*s2.mul, var)
		end,
	},
	number={
		single_nom=function(n, s) return snom(s.mul*n, s.var) end,
--		number=function(s, n) return snom(s.var, s.add, s.mul*n) end,
	},
}

function var_mt.__eq(a, b)
	for ka, va in pairs(a.var) do
		if b.var[ka]~=va then return false end
	end
	for kb, vb in pairs(b.var) do
		if a.var[kb]~=vb then return false end
	end
	return true
end

var_mt.__index={ eval=function(self) return self end }




local polynom_mt = { __index={}, __metatable={ expr=true, polynom=true } }

function polynom(...)
	return setmetatable({ ... }, polynom_mt)
end

function polynom_mt:__tostring ()
	return table.concat(self, '')
end

--function polynom_mt.__index:term()
--	return table.concat(self.var, '+')
--end

polynom_mt.__add = overload{
	polynom={
		number=function(s, n)
			local p, is_find = {}, false
			for _,v in ipairs(s) do
				if next(v, next(v))==nil then
					table.insert(p, snom(v.mul+n)) is_find=true
				else
					table.insert(p, v)
				end
			end
			if not is_find then table.insert(p, snom(n)) end
			return polynom(table.unpack(p))
		end,
		single_nom=function(P, s)
			local p, is_find = {}, false
			for _,v in ipairs(P) do
				if v==s then
					table.insert(p, snom(s.mul+v.mul, s.var)) is_find=true
				else
					table.insert(p, v)
				end
			end
			if not is_find then table.insert(p, s) end
			return polynom(table.unpack(p))
		end,
		polynom=function(p1, p2)
			local p, is_find = {}, false
			for _,v in ipairs(p1) do
				table.insert(p, p2+v)
			end
--			if not is_find then table.insert(p, snom(n)) end
			return polynom(table.unpack(p))
		end
	},
	number={
		polynom=function(n, s)
			local p, is_find = {}, false
			for _,v in ipairs(s) do
				if next(v, next(v))==nil then
					table.insert(p, snom(n+v.mul)) is_find=true
				else
					table.insert(p, v)
				end
			end
			if not is_find then table.insert(p, snom(n)) end
			return polynom(table.unpack(p))
		end
	},
}

polynom_mt.__sub = overload{
	polynom={
		number=function(s, n)
			local p, is_find = {}, false
			for _,v in ipairs(s) do
				if next(v, next(v))==nil then
					table.insert(p, snom(v.mul-n)) is_find=true
				else
					table.insert(p, v)
				end
			end
			if not is_find then table.insert(p, snom(-n)) end
			return polynom(table.unpack(p))
		end,
		single_nom=function(P, s)
			local p, is_find = {}, false
			for _,v in ipairs(P) do
				if v==s then
					table.insert(p, snom(v.mul-s.mul, s.var)) is_find=true
				else
					table.insert(p, v)
				end
			end
			if not is_find then table.insert(p, s) end
			return polynom(table.unpack(p))
		end,
	},
	number={
		polynom=function(n, s)
			return n+(-1*s)
		end
	},
}

polynom_mt.__mul = overload{
	polynom={
		number=function(s, n)
			local p = {}
			for _,v in ipairs(s) do
				table.insert(p, v*n)
			end
			return polynom(table.unpack(p))
		end,
		polynom=function(s, s2)
			local p, is_find = {}, false
			for _,v in ipairs(s) do table.insert(p, v) end
			for _,v in ipairs(s2) do
				if next(v, next(v))==nil then
					table.insert(p, snom(v.mul)) is_find=true
				else
					table.insert(p, v)
				end
			end
			if not is_find then table.insert(p, snom(n)) end
			return polynom(table.unpack(p))
		end,
		single_nom=function(s, s2)
			local p = {}
			for _,v in ipairs(s) do table.insert(p, v*s2) end
			return polynom(table.unpack(p))
		end,
	},
	number={
		polynom=function(n, s)
			local p = {}
			for _,v in ipairs(s) do
					table.insert(p, v*n)
			end
			return polynom(table.unpack(p))
		end
	},
}

polynom_mt.__index={ eval=function(self) return self end }




gmr.LValue = ListSep( Alt(
		Seq(Ident, lexeme' [', gmr.Expr, lexeme' ]'):tmpl'$1[$2]',
--		Seq(Ident, lexeme' (', gmr.args, lexeme' )'):tmpl'$1($2)',
		Ident:hndl(function(tok0, tok, obj)
		return snom(1, { [obj]=1 })
	end)
	), lexeme' .'

):tmpl'${.}'
--print(lexeme' ]')

FuncIdent=gmr.LValue

if StrongTypeDeclaration then
	TypeIdent = newRule(
		function() return {} end,
		function(_, tok)
			if tok.lexeme==lexemes.ident then
				local sym = tok.scope:find(tok.str)
				if sym and sym.kind=='type' then return tok.next, tok end
			end
		end
	)()
else
	TypeIdent = Ident
end


--_TypeExpr = Alt(gmr.ComplexType, TypeIdent)
--_TypeExprArray = Alt(Seq(lexeme' [', (lexeme'int'), lexeme' ]'):opt(false)^'ArrayDim')
gmr.TypeExpr = Seq(
	(kwrd'const'):opt(false)^'Const',
	Alt(gmr.ComplexType, TypeIdent)^'BaseType',
	Wrap(lexeme' [', gmr.Expr, lexeme' ]'):opt(false)^'ArrayDim',
	List(lexeme' *'):opt()^'Pointer'
)


Value = Alt(
	Seq(lexeme' (', gmr.TypeExpr, lexeme' )', gmr.Expr)
		:tmpl'($1)$2',
	Seq(FuncIdent, lexeme' (', gmr.args, lexeme' )'):tmpl'$1($2)',

	lexeme'int':hndl(function(tok0, tok, obj)
		return obj
	end),
	lexeme'string1', lexeme'string2',
	(gmr.LValue^'lval'):hndl(function(tok0, tok, obj)
		return snom(1, { [obj]=1 })
	end),
	Seq( lexeme' (', gmr.Expr^'Cond', lexeme' ?',
		gmr.Expr^'Then', lexeme' :', gmr.Expr^'Else', lexeme' )'
	):tmpl' ($Cond ? $Then : $Else) ',
	Wrap(lexeme' (', gmr.Expr, lexeme' )')
)
gmr.Value=Value



gmr.TypeExpr.capt_mt = {}--__index={} }
local TypeExprProp = {}

function gmr.TypeExpr.capt_mt:__tostring()
	return (self.Const and 'const ' or '')..
		tostring(self.BaseType)..
		(self.ArrayDim and '['..tostring(self.ArrayDim)..']' or '')..
		string.rep('*', self.Pointer)
end

function gmr.TypeExpr:onMatch(obj, tok0, tok)
	local sym = tok0.scope:find(tostring(obj.BaseType))
	if not sym then
		obj.sym = obj.BaseType.sym
	else
		obj.sym = sym
	end
end

function TypeExprProp:sizeof()
	local size
	if self.Pointer>0 then
		size=8
	else
		size=assert(self.sym, tostring(self)).sizeof
	end
	if self.ArrayDim then
		size=size*tonumber(tostring(self.ArrayDim))
	end
	return size
end
function gmr.TypeExpr.capt_mt:__index(name)
		local prop_getter = TypeExprProp[name]--, 'tok.`'..tostring(name)..'`')
		if prop_getter then return prop_getter(self) end
end


gmr.UnExpr = Alt(
	Wrap(Seq(kwrd' sizeof', lexeme' ('), Alt(gmr.TypeExpr, Ident), lexeme' )')
	:hndl(function(tok0, tok, obj)
		if tok~=nil then
			if obj.sizeof then return obj.sizeof end
			local t = assert(tok.scope:find(tostring(obj)),
				tostring(obj))--.type
			return t and t.sizeof or -1
		end
	end),
	Seq(Value, Alt(lexeme'++', lexeme'--')):tmpl'($1)$2',
	Seq(
		Alt(lexeme'-', lexeme'++', lexeme'--',
			lexeme'*', lexeme'&', lexeme'!'),
	gmr.UnExpr):tmpl'$1($2)',
	Value
)




gmr.Expr = Precedence(gmr.UnExpr,
	lexeme'^',
	Alt( lexeme'*', lexeme'/', lexeme'%'),
	Alt( lexeme'+', lexeme'-' ),
	Alt( lexeme'|', lexeme'&', lexeme'^' ),


--{ op_ptrn=Alt(lexeme'>>', lexeme'<<'), recursive=true },
Alt(lexeme'>>', lexeme'<<'),



	Alt(lexeme'==', lexeme'!=', lexeme'<=', lexeme'>=', lexeme'<', lexeme'>'),

	Alt(lexeme'assign',
		lexeme'+=', lexeme'-=', lexeme'*=', lexeme'/=', lexeme'%=',
		lexeme'&=', lexeme'|=', lexeme'^='
	),

	Alt( lexeme'||', lexeme'&&' )--	lexeme'&',
)
--gmr.Expr=gmr.Expr


--Value:add( Seq(lexeme' (', gmr.Expr, lexeme' )'):tmpl'( $1 )' --, lexeme'(%b{})'
--)


gmr.args = ListSepLast(gmr.Expr, lexeme' ,', lexeme'...'):tmpl'${, }':opt('')


gmr.var_list = ListSepLast(
	Seq(gmr.TypeExpr, Ident):tmpl'$1 $2',
	lexeme' ,', lexeme'...'
):tmpl'${, }':opt('')

gmr.var_list_decl = ListSepLast(
	Seq(gmr.TypeExpr, Ident:opt('')):tmpl'$1 $2',
	lexeme' ,', lexeme'...'
):tmpl'${, }':opt('')



gmr.Assign = Seq(
	gmr.LValue^'Var',
	Alt(lexeme'assign',
		lexeme'+=', lexeme'-=', lexeme'*=', lexeme'/=', --lexeme'%=',
		lexeme'&=', lexeme'|='--, lexeme'^='
	)^'AssignOp',
	gmr.Expr^'Value',	lexeme' ;'
):tmpl'$Var $AssignOp $Value;'







gmr.Define = Seq(
--	Alt(gmr.TypeExpr, gmr.Define),
	gmr.TypeExpr^'Type',
	ListSep(Alt(
			Seq(	Ident^'Var', lexeme' assign', gmr.Expr^'Value'):tmpl'$Var=$Value', Ident
		), lexeme' ,'):tmpl'${, }'^'Vars', lexeme' ;'
):tmpl'$Type $Vars;'-- = $Values

gmr.Label = Seq(Ident, lexeme' :'):tmpl'$1:'
gmr.Goto = Seq(kwrd' goto', Ident, lexeme' ;'):tmpl'goto $1;'
gmr.Return = Seq(kwrd' return', gmr.Expr, lexeme' ;'):tmpl'return $1;'
gmr.Break = Seq(kwrd' break', lexeme' ;'):tmpl'break;'
gmr.Continue = Seq(kwrd' continue', lexeme' ;'):tmpl'goto __continue__;'
gmr.Call = Seq(FuncIdent,
	Seq(lexeme' (', gmr.args, lexeme' )'),
	lexeme';'
):tmpl'$1($2);'


gmr.Chunk = Alt(
	gmr.Label, gmr.Goto, gmr.Define, gmr.Return, gmr.Continue, gmr.Break,
	gmr.Call, gmr.Assign, gmr.If, gmr.For, gmr.FuncDecl, gmr.FuncDef
)

gmr.Chunks = List(gmr.Chunk):tmpl'${\n}'


gmr.Block = Alt(
	lexeme';',
	gmr.Chunk,
	Seq( lexeme' {', List(gmr.Chunk):tmpl'\t${\n}',	lexeme' }'):tmpl'{\n$1\n}'
)

local function Scoped(r)
	return r:wrapper(function(self, tok)
		tok.scope:sub()
		local t, a = self(tok)
		tok.scope:up()
		return t, a
	end)
end

gmr.ComplexType_Member = Seq(
	gmr.TypeExpr^'Type',
	ListSep(Alt(
			Seq(Ident^'Var', lexeme' :', gmr.Expr^'BitField'):tmpl'$Var:$BitField', Ident
		), lexeme' ,'):tmpl'${, }'^'Vars', lexeme' ;'
):tmpl'$Type $Vars;'

gmr.ComplexType = Seq( Alt(kwrd'struct', kwrd'union')^'ComplexType',
	Ident:opt(false)^'Name',
	lexeme' {',	(List(gmr.ComplexType_Member):tmpl'\t${\n}')^'Body',--Scoped
	lexeme' }'
):tmpl'$ComplexType $Name {\n$Body\n}'

--_TypeExpr:insert(gmr.ComplexType)


local ScopedFuncOpen = (lexeme' ('):hndl(function(tok0)
	tok0.scope:sub()
end)
local ScopedElseOpen = (kwrd' else'):hndl(function(tok0)
	tok0.scope:sub()
end)
local ScopedBlock = (gmr.Block):hndl(function(tok0)
	tok0.scope:up()
end)

gmr.If = Seq(kwrd' if', ScopedFuncOpen, gmr.Expr^'If', lexeme' )',
	ScopedBlock^'Then',
	Seq(ScopedElseOpen, ScopedBlock ):tmpl'else $1':opt('')^'Else'
):tmpl'if($If) $Then $Else'


gmr.FuncDef = Seq(gmr.TypeExpr^'ReturnType',
	Ident^'FuncName',
	lexeme' (', gmr.var_list^'Args', lexeme' )',
	Seq(lexeme' {', List(gmr.Chunk):tmpl'${\n}', lexeme' }'):tmpl'{\n\t$1\n}'^'Body'
):tmpl'$ReturnType $FuncName($Args)$Body'

gmr.FuncDecl = Seq(gmr.TypeExpr^'ReturnType',
	Ident^'FuncName',
	lexeme' (', gmr.var_list_decl^'Args', lexeme' )',
	lexeme' ;'
):tmpl'$ReturnType $FuncName($Args);'


gmr.For = Seq(kwrd' for', ScopedFuncOpen,
	Alt(gmr.Define, gmr.Assign, lexeme' ;')^'Init',
	gmr.Expr:opt('')^'Cond', lexeme' ;',
	gmr.Expr:opt('')^'Iter',
	lexeme' )', ScopedBlock^'Body'
):tmpl'for($Init; $Cond; $Iter)$Body'





--gmr.Chunk:add(gmr.If, gmr.For, gmr.FuncDecl, gmr.FuncDef)--, Func, ChunkFn, Repeat,




return gmr

