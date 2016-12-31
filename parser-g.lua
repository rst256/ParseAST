local gmr=require'parser'


local lexer=require'lexer'
local lex_mem = require'lm'


scope = require('ast.scope')()
--scope:define('int', { kind='type', sizeof=4, name='int' })
--scope:define('char', { kind='type', sizeof=1, name='char' })
--scope:define('bool', { kind='type', sizeof=1, name='bool' })
--scope:define('void', { kind='type', sizeof=0, name='void' })



local g=Grammar('rules')

g.rules=List(g.rule):tmpl'${\n}'

--g.def=Seq(lexeme' :', lexeme' assign')

g.rule=Seq(
	Ident^'Name', lexeme' :=', --g.def,, lexeme' ;'
	g.ra^'Body')
	:tmpl'$Name = $Body;'

g.ra=
	Precedence(g.rs, lexeme'/', lexeme'*')
--


g.r= Alt(
--	Wrap(lexeme' {', ListSep(g.ra, lexeme' ,'):tmpl'${, }',
--	lexeme' }'):tmpl'ListSep($body)',
	Seq(usrkwrd'binop', g.ra^'Items', Wrap(lexeme' {', ListSep(g.ra, lexeme' ,'):tmpl'${, }', lexeme' }')^'Ops'):tmpl'Precedence($Items, $Ops)',

	Wrap(lexeme' (', g.ra, lexeme' )'),
	Wrap(lexeme' [', g.ra, lexeme' ]')
		:tmpl(function(s) return '('..tostring(s.body)..'):opt()' end),
	Seq(Ident^'Field', lexeme' assign', g.r^'R'):tmpl'$R^"$Field"',
	Ident~lexeme' :=',
	lexeme'string1':tmpl(function(s) return 'lexeme'..tostring(s.tok) end),
	lexeme'string2':tmpl(function(s) return 'kwrd'..tostring(s.tok) end)
)

g.rs=Alt(
	Seq( lexeme' *', g.r):tmpl'List($1)',
	List(g.r):tmpl'Seq(${, })'

)


--g()
--g'rule'

return g