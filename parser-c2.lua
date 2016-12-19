dofile'keyword.lua'

require'parser'
gmr=Grammar'Chunks'
--LValue = ListSep(Ident^'id', lexeme' .'):tmpl'${.}'
_LValue = Alt(Seq(Ident, lexeme' [',
--	(lexeme'int'),
	gmr.Expr,
lexeme' ]'):tmpl'$1[$2]', Ident)
LValue = Alt(_LValue)
LValue:insert(
	Seq(_LValue, lexeme' .', LValue):tmpl'$1.$2'
)


FuncIdent=LValue

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


_TypeExpr = Alt(TypeIdent)
--_TypeExprArray = Alt(Seq(lexeme' [', (lexeme'int'), lexeme' ]'):opt(false)^'ArrayDim')
TypeExpr = Seq(
	(kwrd'const'):opt(false)^'Const',
	_TypeExpr^'BaseType',
	Wrap(lexeme' [', gmr.Expr, lexeme' ]'):opt(false)^'ArrayDim',
	List(lexeme' *')^'Pointer'
)



Value = Alt(
	Seq(lexeme' (', TypeExpr, lexeme' )', gmr.Expr)
		:tmpl'($1)$2',
	Seq(FuncIdent, lexeme' (', gmr.args, lexeme' )'):tmpl'$1($2)',

	lexeme'int',
	lexeme'string',
	LValue^'lval',
	Seq( lexeme' (', gmr.Expr^'Cond', lexeme' ?',
		gmr.Expr^'Then', lexeme' :', gmr.Expr^'Else', lexeme' )'
	):tmpl' ($Cond ? $Then : $Else) ',
	Wrap(lexeme' (', gmr.Expr, lexeme' )')
)
gmr.Value=Value



TypeExpr.capt_mt = {}--__index={} }
local TypeExprProp = {}

function TypeExpr.capt_mt:__tostring()
	return (self.Const and 'const ' or '')..
		tostring(self.BaseType)..
		(self.ArrayDim and '['..tostring(self.ArrayDim)..']' or '')..
		string.rep('*', self.Pointer)
end

function TypeExpr:onMatch(obj, tok0, tok)
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
function TypeExpr.capt_mt:__index(name)
		local prop_getter = TypeExprProp[name]--, 'tok.`'..tostring(name)..'`')
		if prop_getter then return prop_getter(self) end
end


UnExpr = Alt(Value)
UnExpr:insert(
	Seq(
		Alt(lexeme'-', lexeme'++', lexeme'--',
			lexeme'*', lexeme'&', lexeme'!'),
		UnExpr):tmpl'$1($2)',
	Seq(Value, Alt(lexeme'++', lexeme'--')):tmpl'($1)$2',
	Wrap(Seq(kwrd' sizeof', lexeme' ('), Alt(TypeExpr, Ident), lexeme' )'):hndl(function(tok0, tok, obj)
		if tok~=nil then
--			local t = assert(tok0.scope:find(tostring(obj.Expr)),
--				tostring(obj.Expr)).type
			if obj.sizeof then return tok, obj.sizeof end
			local t = assert(tok.scope:find(tostring(obj)),
				tostring(obj))--.type
--			local t = assert(obj.type, tostring(obj))
			return tok, t and t.sizeof or -1
		end
--		return tok, obj
	end)
)

--Value:add(
--	Seq( lexeme' (', gmr.Expr^'Cond', lexeme' ?',
--		gmr.Expr^'Then', lexeme' :', gmr.Expr^'Else', lexeme' )'
--	):tmpl' ($Cond ? $Then : $Else) ',
--	Wrap(lexeme' (', gmr.Expr, lexeme' )')
--)

Expr = Precedence(UnExpr,
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
gmr.Expr=Expr


--Value:add( Seq(lexeme' (', Expr, lexeme' )'):tmpl'( $1 )' --, lexeme'(%b{})'
--)


local args = ListSepLast(Expr, lexeme' ,', lexeme'...'):tmpl'${, }':opt('')
gmr.args=args

local var_list = ListSepLast(
	Seq(TypeExpr, Ident):tmpl'$1 $2',
	lexeme' ,', lexeme'...'
):tmpl'${, }':opt('')

local var_list_decl = ListSepLast(
	Seq(TypeExpr, Ident:opt('')):tmpl'$1 $2',
	lexeme' ,', lexeme'...'
):tmpl'${, }':opt('')



Assign = Seq(
	LValue^'Var',
	Alt(lexeme'assign',
		lexeme'+=', lexeme'-=', lexeme'*=', lexeme'/=', --lexeme'%=',
		lexeme'&=', lexeme'|='--, lexeme'^='
	)^'AssignOp',
	Expr^'Value',	lexeme' ;'
):tmpl'$Var $AssignOp $Value;'



--Value:insert(
--	Seq(FuncIdent, lexeme' (', args, lexeme' )'):tmpl'$1($2)',
--	Seq(lexeme' (', TypeExpr, lexeme' )', Expr)
--		:tmpl'($1)$2'
--)





Define = Seq(
--	Alt(TypeExpr, Define),
	TypeExpr^'Type',
	ListSep(Alt(
			Seq(	Ident^'Var', lexeme' assign', Expr^'Value'):tmpl'$Var=$Value', Ident
		), lexeme' ,'):tmpl'${, }'^'Vars', lexeme' ;'
):tmpl'$Type $Vars;'-- = $Values

Label = Seq(Ident, lexeme' :'):tmpl'$1:'
Goto = Seq(kwrd' goto', Ident, lexeme' ;'):tmpl'goto $1;'
local Return = Seq(kwrd' return', Expr, lexeme' ;'):tmpl'return $1;'
local Break = Seq(kwrd' break', lexeme' ;'):tmpl'break;'
local Continue = Seq(kwrd' continue', lexeme' ;'):tmpl'goto __continue__;'
local Call = Seq(FuncIdent,
	Seq(lexeme' (', args, lexeme' )'),
	lexeme';'
):tmpl'$1($2);'


Chunk = Alt(
	Label, Goto, Define, Return, Continue, Break, Call
	, Assign

)

Chunks = List(Chunk):tmpl'${\n}'
gmr.Chunks=Chunks

Block = Alt(
	lexeme';',
	Chunk,
	Seq( lexeme' {', List(Chunk):tmpl'\t${\n}',	lexeme' }'):tmpl'{\n$1\n}'
)

local function Scoped(r)
	return r:wrapper(function(self, tok)
		tok.scope:sub()
		local t, a = self(tok)
		tok.scope:up()
		return t, a
	end)
end

ComplexType_Member = Seq(
	TypeExpr^'Type',
	ListSep(Alt(
			Seq(Ident^'Var', lexeme' :', Expr^'BitField'):tmpl'$Var:$BitField', Ident
		), lexeme' ,'):tmpl'${, }'^'Vars', lexeme' ;'
):tmpl'$Type $Vars;'

ComplexType = Seq( Alt(kwrd'struct', kwrd'union')^'ComplexType',
	Ident:opt(false)^'Name',
	lexeme' {',	(List(ComplexType_Member):tmpl'\t${\n}')^'Body',--Scoped
	lexeme' }'
):tmpl'$ComplexType $Name {\n$Body\n}'

_TypeExpr:insert(ComplexType)


local ScopedFuncOpen = (lexeme' ('):hndl(function(tok0)
	tok0.scope:sub()
end)
local ScopedElseOpen = (kwrd' else'):hndl(function(tok0)
	tok0.scope:sub()
end)
local ScopedBlock = (Block):hndl(function(tok0)
	tok0.scope:up()
end)

If = Seq(kwrd' if', ScopedFuncOpen, Expr^'If', lexeme' )',
	ScopedBlock^'Then',
	Seq(ScopedElseOpen, ScopedBlock ):tmpl'else $1':opt('')^'Else'
):tmpl'if($If) $Then $Else'


FuncDef = Seq(TypeExpr^'ReturnType',
	Ident^'FuncName',
	lexeme' (', var_list^'Args', lexeme' )',
	Seq(lexeme' {', List(Chunk):tmpl'${\n}', lexeme' }'):tmpl'{\n\t$1\n}'^'Body'
):tmpl'$ReturnType $FuncName($Args)$Body'

FuncDecl = Seq(TypeExpr^'ReturnType',
	Ident^'FuncName',
	lexeme' (', var_list_decl^'Args', lexeme' )',
	lexeme' ;'
):tmpl'$ReturnType $FuncName($Args);'


local For = Seq(kwrd' for', ScopedFuncOpen,
	Alt(Define, Assign, lexeme' ;')^'Init',
	Expr:opt('')^'Cond', lexeme' ;',
	Expr:opt('')^'Iter',
	lexeme' )', ScopedBlock^'Body'
):tmpl'for($Init; $Cond; $Iter)$Body'





Chunk:add(If, For, FuncDecl, FuncDef)--, Func, ChunkFn, Repeat,




return gmr

