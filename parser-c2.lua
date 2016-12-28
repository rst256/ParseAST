dofile'keyword.lua'

require'parser'
gmr=Grammar'Chunks'


local symmath = require'symmath'

gmr.LValue = ListSep( Alt(
		Seq(Ident, lexeme' [', gmr.Expr, lexeme' ]'):tmpl'$1[$2]',
--		Seq(Ident, lexeme' (', gmr.args, lexeme' )'):tmpl'$1($2)',
		Ident
--		:hndl(function(tok0, tok, obj)
--		return symmath.term(1, { [obj]=1 })
--	end)
),
lexeme' .'

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

	lexeme'int',
--	:hndl(function(tok0, tok, obj)
--		return obj
--	end),
	lexeme'string1', lexeme'string2',
	(gmr.LValue^'lval')
	:hndl(function(tok0, tok, obj)
		return symmath.term(1, { [tostring(obj)]=1 })
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
			if t.sizeof then
				return t.sizeof
			elseif t.type and t.type.sizeof then
				return t.type.sizeof
			else
				return obj
			end
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
	Alt( lexeme'|', lexeme'&' ),


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
	gmr.Call, gmr.Assign, gmr.If, gmr.For, gmr.FuncDef, gmr.FuncDecl
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
local ScopedFuncClose = (lexeme' }'):hndl(function(tok0)
	tok0.scope:up()
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
	ScopedFuncOpen, gmr.var_list^'Args', lexeme' )',
	ScopedBlock:expected'func body'^'Body'
--	Seq(lexeme' {', (List(gmr.Chunk):tm--pl'${\n}'):expected'func body', ScopedFuncClose):tmpl'{\n\t$1\n}'^'Body'
):tmpl'$ReturnType $FuncName($Args)$Body'

gmr.FuncDecl = Seq(gmr.TypeExpr^'ReturnType',
	Ident^'FuncName',
	lexeme' (', gmr.var_list_decl^'Args', lexeme' )',
	lexeme' ;'
):tmpl'$ReturnType $FuncName($Args);'


gmr.For = Seq(kwrd' for', ScopedFuncOpen,
	Alt(lexeme';', gmr.Define, gmr.Assign)^'Init',
	gmr.Expr:opt('')^'Cond', lexeme' ;',
	gmr.Expr:opt('')^'Iter',
	lexeme' )', ScopedBlock^'Body'
):tmpl'for($Init $Cond; $Iter)$Body'





--gmr.Chunk:add(gmr.If, gmr.For, gmr.FuncDecl, gmr.FuncDef)--, Func, ChunkFn, Repeat,




return gmr

