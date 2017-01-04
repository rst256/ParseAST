dofile'keyword.lua'
require'parser'
local g = Grammar'chunks'

g.lvalue_indexof = NewRule(function(tok0)
	local tok, t, v = tok0
	local this = {}
	local rl=(lexeme'ident') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "id" else tok = t end
	this["id"] = v
	local rl=(lexeme' [') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "2" else tok = t end
	local rl=(g.expr) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "index" else tok = t end
	this["index"] = v
	local rl=(lexeme' ]') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "4" else tok = t end
	return tok, this
end);


g.lvalue = ((g.lvalue_indexof / lexeme'ident') * lexeme' .');


g.assign_op = ((((lexeme'=' / lexeme'+=') / lexeme'/=') / lexeme'-=') / lexeme'*=');


g.value = ((((((((Wrap(lexeme' (', g.expr, lexeme' )') / g.unop) / lexeme'hex') / lexeme'real') / lexeme'int') / lexeme'string1') / g.call) / g.lvalue) / lexeme'string2');


g.unop = NewRule(function(tok0)
	local tok, t, v = tok0
	local this = {}
	local rl=(((((lexeme'-' / lexeme'!') / lexeme'&') / lexeme'*') / lexeme'~')) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "op" else tok = t end
	this["op"] = v
	local rl=((g.value):expected('unop arg expected')) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "arg" else tok = t end
	this["arg"] = v
	return tok, this
end);


g.expr = Precedence(g.value, ((lexeme'*' / lexeme'/') / lexeme'%'), (lexeme'+' / lexeme'-'), (((lexeme'&' / lexeme'|') / lexeme'^') / lexeme'~'), ((((((lexeme'==' / lexeme'>=') / lexeme'<=') / lexeme'!=') / lexeme'<') / lexeme'>') / lexeme'~='), (lexeme'&&' / lexeme'||'), g.assign_op);


g._if = NewRule(function(tok0)
	local tok, t, v = tok0
	local this = {}
	local rl=(kwrd" if") if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "1" else tok = t end
	local rl=((g.expr):expected('cond expected')) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "cond" else tok = t end
	this["cond"] = v
	local rl=((kwrd" then"):expected('`then` expected')) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "3" else tok = t end
	local rl=(g.chunks:opt'') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "th" else tok = t end
	this["th"] = v
	local rl=(((NewRule(function(tok0)
	local tok, t, v = tok0
	local this = {}
	local rl=(kwrd" else") if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "1" else tok = t end
	local rl=(g.chunks) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "el" else tok = t end
	this["el"] = v
	local rl=((kwrd" end"):expected('if end expected')) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "3" else tok = t end
	return tok, this
end)):tmpl('\n\telse\n\t\t$el') / (kwrd" end"):expected('if end expected'))) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "el" else tok = t end
	this["el"] = v
	return tok, this
end);


g.chunks = List(g.chunk);


g.assign = NewRule(function(tok0)
	local tok, t, v = tok0
	local this = {}
	local rl=(g.lvalue) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "var" else tok = t end
	this["var"] = v
	local rl=(g.assign_op) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "op" else tok = t end
	this["op"] = v
	local rl=(g.expr) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "value" else tok = t end
	this["value"] = v
	return tok, this
end);


g.define = NewRule(function(tok0)
	local tok, t, v = tok0
	local this = {}
	local rl=(kwrd" local") if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "1" else tok = t end
	local rl=(lexeme'ident') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "var" else tok = t end
	this["var"] = v
	local rl=(g.type_def:opt'') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "var_type" else tok = t end
	this["var_type"] = v
	local rl=(IfThen(lexeme'assign', g.expr)) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "value" else tok = t end
	this["value"] = v
	return tok, this
end);


g.expr_list = (g.expr * lexeme' ,'):opt'';


g.call = NewRule(function(tok0)
	local tok, t, v = tok0
	local this = {}
	local rl=(g.lvalue) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "fn" else tok = t end
	this["fn"] = v
	local rl=(lexeme' (') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "2" else tok = t end
	local rl=(((g.expr * lexeme' ,')):expected('call func next arg expected')) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "args" else tok = t end
	this["args"] = v
	local rl=((lexeme' )'):expected('call func end expected')) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "4" else tok = t end
	return tok, this
end);


g.metacall = NewRule(function(tok0)
	local tok, t, v = tok0
	local this = {}
	local rl=(lexeme' @') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "1" else tok = t end
	local rl=(lexeme'ident') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "fn" else tok = t end
	this["fn"] = v
	local rl=(lexeme' (') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "3" else tok = t end
	local rl=(((g.expr * lexeme' ,')):expected('call func next arg expected')) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "args" else tok = t end
	this["args"] = v
	local rl=((lexeme' )'):expected('call func end expected')) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "5" else tok = t end
	return tok, this
end);


g.ret = NewRule(function(tok0)
	local tok, t, v = tok0
	local this = {}
	local rl=(kwrd" return") if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "1" else tok = t end
	local rl=(g.expr_list) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "values" else tok = t end
	this["values"] = v
	return tok, this
end);


g.type_def = NewRule(function(tok0)
	local tok, t, v = tok0
	local this = {}
	local rl=(lexeme' <-') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "1" else tok = t end
	local rl=(lexeme'ident') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "argtype" else tok = t end
	this["argtype"] = v
	return tok, this
end);


g.type_defs = NewRule(function(tok0)
	local tok, t, v = tok0
	local this = {}
	local rl=(lexeme' <-') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "1" else tok = t end
	local rl=((lexeme'ident' * lexeme' ,')) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "argtypes" else tok = t end
	this["argtypes"] = v
	return tok, this
end);


g.var_def = NewRule(function(tok0)
	local tok, t, v = tok0
	local this = {}
	local rl=(lexeme'ident') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "argname" else tok = t end
	this["argname"] = v
	local rl=(g.type_def:opt'') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "argtype" else tok = t end
	this["argtype"] = v
	return tok, this
end);


g.func = NewRule(function(tok0)
	local tok, t, v = tok0
	local this = {}
	local rl=(kwrd" function") if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "1" else tok = t end
	local rl=(g.lvalue) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "fn" else tok = t end
	this["fn"] = v
	local rl=(lexeme' (') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "3" else tok = t end
	local rl=((g.var_def * lexeme' ,'):opt'') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "args" else tok = t end
	this["args"] = v
	local rl=((lexeme' )'):expected('define func arg list end expected')) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "5" else tok = t end
	local rl=(g.type_defs:opt'') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "rettype" else tok = t end
	this["rettype"] = v
	local rl=(g.chunks:opt'') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "body" else tok = t end
	this["body"] = v
	local rl=((kwrd" end"):expected('func end expected')) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "8" else tok = t end
	return tok, this
end);


g.metafunc = NewRule(function(tok0)
	local tok, t, v = tok0
	local this = {}
	local rl=(lexeme' @') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "1" else tok = t end
	local rl=(kwrd" function") if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "2" else tok = t end
	local rl=(lexeme'ident') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "fn" else tok = t end
	this["fn"] = v
	local rl=(lexeme' (') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "4" else tok = t end
	local rl=((lexeme'ident' * lexeme' ,'):opt'') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "args" else tok = t end
	this["args"] = v
	local rl=((lexeme' )'):expected('define metafunc arg list end expected')) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "6" else tok = t end
	local rl=(g.chunks:opt'') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "body" else tok = t end
	this["body"] = v
	local rl=((NewRule(function(tok0)
	local tok, t, v = tok0
	local this = {}
	local rl=(lexeme' @') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "1" else tok = t end
	local rl=(kwrd" end") if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "2" else tok = t end
	return tok, this
end)):expected('func end expected')) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "8" else tok = t end
	return tok, this
end);


g.macrodef = NewRule(function(tok0)
	local tok, t, v = tok0
	local this = {}
	local rl=(lexeme' @') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "1" else tok = t end
	local rl=(kwrd" macros") if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "2" else tok = t end
	local rl=(lexeme'ident') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "fn" else tok = t end
	this["fn"] = v
	local rl=(lexeme' (') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "4" else tok = t end
	local rl=((lexeme'ident' * lexeme' ,'):opt'') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "args" else tok = t end
	this["args"] = v
	local rl=((lexeme' )'):expected('define metafunc arg list end expected')) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "6" else tok = t end
	local rl=(g.expr) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "body" else tok = t end
	this["body"] = v
	local rl=((NewRule(function(tok0)
	local tok, t, v = tok0
	local this = {}
	local rl=(lexeme' @') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "1" else tok = t end
	local rl=(kwrd" end") if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "2" else tok = t end
	return tok, this
end)):expected('func end expected')) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "8" else tok = t end
	return tok, this
end);


g._for = NewRule(function(tok0)
	local tok, t, v = tok0
	local this = {}
	local rl=(kwrd" for") if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "1" else tok = t end
	local rl=(g.assign) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "var" else tok = t end
	this["var"] = v
	local rl=(kwrd" do") if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "3" else tok = t end
	local rl=(g.chunks:opt'') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "body" else tok = t end
	this["body"] = v
	local rl=((kwrd" end"):expected('for end expected')) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "5" else tok = t end
	return tok, this
end);


g._while = NewRule(function(tok0)
	local tok, t, v = tok0
	local this = {}
	local rl=(kwrd" while") if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "1" else tok = t end
	local rl=(g.expr) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "cond" else tok = t end
	this["cond"] = v
	local rl=(kwrd" do") if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "3" else tok = t end
	local rl=(g.chunks:opt'') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "body" else tok = t end
	this["body"] = v
	local rl=((kwrd" end"):expected('while end expected')) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "5" else tok = t end
	return tok, this
end);


g.gfor = NewRule(function(tok0)
	local tok, t, v = tok0
	local this = {}
	local rl=(kwrd" for") if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "1" else tok = t end
	local rl=((g.var_def * lexeme' ,'):opt'') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "args" else tok = t end
	this["args"] = v
	local rl=(kwrd" in") if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "3" else tok = t end
	local rl=((g.expr):expected('gfor iter expected')) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "iter" else tok = t end
	this["iter"] = v
	local rl=(kwrd" do") if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "5" else tok = t end
	local rl=(g.chunks:opt'') if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "body" else tok = t end
	this["body"] = v
	local rl=((kwrd" end"):expected('for end expected')) if rl.rule_type=="expected" then rule_start_tok=tok0.next end
	t, v = rl(tok)
	if t==nil then return nil, "7" else tok = t end
	return tok, this
end);


g.chunk = (((((((((((g.gfor / g._while) / g._for) / g._if) / g.func) / g.assign) / g.call) / g.ret) / g.define) / g.macrodef) / g.metafunc) / g.metacall);


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
	