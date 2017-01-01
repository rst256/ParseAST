local gmr=require'parser'


local lexer=require'lexer'
local lex_mem = require'lm'


scope = require('ast.scope')()

local temp_rule_mt = {}

function tempRule(fn)
	return setmetatable({ call=fn }, {
		__call=function(self, tok)
			local t,v = self.call(tok)
			if t==nil and self.def_val then return tok, self.def_val end
			if self.capt_mt and type(v)=='table' then
				setmetatable(v, self.capt_mt)
			end
			return t, v
		end,
		__index=setmetatable({
			rule_type='custom',
			opt=function(self, v) self.def_val=v or '' return self end,
		}, { __index={} }),
	})
end

local g=Grammar('rules')

g.rules=List(g.rule):tmpl'${\n}'


g.rule=Seq(
	Ident^'Name', lexeme' :=', --g.def,, lexeme' ;'
	g.ra^'Body')
	:tmpl'g.$Name = $Body;\n\n'


local g_binop_mt = {
	__index={},
	__metatable={ binop=true, expr=true },
}

function binop_alt(l, r)
	return tempRule(function(tok)
		local t,v = (l)(tok)
		if t==nil then
			t,v = (r)(tok)
		end
		return t, v
	end)
end

function g_binop_mt:__tostring()
	local op, l, r = tostring(self.op), tostring(self.l), tostring(self.r)
	if op=='//' then
		assert(l.def_value==nil)
		assert(r.def_value==nil)
		return 'NewRule(function(tok)\n\tlocal t,v = ('..l:gsub('\n', '\n\t')..
			')(tok)\n\tif t==nil then\n\t\tt,v = ('..
			r:gsub('\n', '\n\t\t')..')(tok)\n\tend\n\treturn t, v\nend)'
	elseif op=='*' then
		return 'ListSep('..l..', '..r..')'
	elseif op=='^=' then
		return 'NewRule(function(tok)\n\tlocal t,v = ('..l:gsub('\n', '\n\t')..
		')(tok)\n\tif t~=nil then\n\t\tlocal tn = ('..
		r:gsub('\n', '\n\t\t')..
		')(t)\n\t\tif tn==nil then return t, v end\n\tend\nend)'
	end
	return ''..l..op..r..''
end

function g_binop_mt.__index:eval()
	local o, l, r = tostring(self.op),
		assert(typeof(self.l).expr and self.l:eval() or tonumber(tostring(self.l))),
		assert(typeof(self.r).expr and self.r:eval() or tonumber(tostring(self.r)))
	if o=='+'  then return l+r  end
	if o=='-'  then return l-r  end
	if o=='*'  then return l*r  end
	if o=='/'  then return l/r  end
	if o=='|'  then return l|r  end
	if o=='&'  then return l&r  end
	if o=='>>' then return l>>r end
	if o=='<<' then return l<<r end
	if o=='^' then return l^r end
	error('unknown op: `'..o..'`')
end

local function g_binop(l, op, r)
	return setmetatable({ l=l, op=op, r=r }, g_binop_mt)
end

g.ra=Precedence(g.rs, lexeme'/', lexeme'*', lexeme'^=')
--g.ra.bin_op=g_binop
g.ruleID = NewRule(function(tok)
	local t,v = Ident(tok)
	if t~=nil then
		return t, setmetatable({ name=v}, {
			__tostring=function(self) return 'g.'..tostring(self.name) end,
			__index={ global=true },
		})
	end
end)

local function ruleset(rule, name, value)
	if rule[name]==value then return rule end
	if rule.global then
		return setmetatable({ [name]=value }, {
			__tostring=function(self)
				return tostring(rule)
			end,
			__index=rule,
					})
	else--if type()
		rule[name]=value
		return rule
	end
end


g.field=Seq(Ident^'Field', lexeme' assign', g.r^'R'):tmpl'$R'--^"$Field"

function g.field:onMatch(c, idx, i)
	return ruleset(c.R, 'field_name', c.Field)
end



g.opt = Wrap(lexeme' [', g.ra, lexeme' ]')
function g.opt:onMatch(rule)
	rule.def_value=''
		return setmetatable( { def_value='' }, {
			__tostring=function(self)
				return tostring(rule)..':opt\'\''
			end,
			__index=rule,
					})
end

g._r= Alt(
	Seq(usrkwrd'binop', g.ra^'Items', Wrap(lexeme' {', ListSep(g.ra, lexeme' ,'):tmpl'${, }', lexeme' }')^'Ops'):tmpl'Precedence($Items, $Ops)',

	Wrap(lexeme' (', g.ra, lexeme' )'),

	g.opt,
	g.field,
	g.ruleID~lexeme' :=',
	lexeme'string1':tmpl(function(s) return 'lexeme'..tostring(s.tok) end),
	lexeme'string2':tmpl(function(s) return 'kwrd'..tostring(s.tok) end)
)
g.r=Alt(
		Seq(g._r, lexeme' !', lexeme'string1'):tmpl'($1):expected($2)',
--		Seq(lexeme' !', g.r):tmpl'($1):expected()',
		g._r
	)
--('fjhfdjh' + ((666.78 * 2) - ';'))
--(('fjhfdjh' + (666.78 * 2)) - ';')
g.rs=Alt(
	Seq( lexeme' *', g.r):tmpl'List($1)',
		Seq(g.r^'open', lexeme' <', g.ra^'body', lexeme' >', g.r^'close')
		:tmpl(function(s)
			return 'Wrap('..tostring(s.open)..', '..
				tostring(s.body)..', '..tostring(s.close)..')'
			end),
	List(g.r):tmpl(function(self)
		local s = 'NewRule(function(tok0)\n\tlocal tok, t, v = tok0\n\tlocal this = {}\n\t'
		for k=1,#self do
			local v = self[k]
			s=s..'local rl=('..tostring(v)..
			') if rl.rule_type=="expected" then rule_start_tok=tok0.next end\n\t'..
			't, v = rl(tok)\n\tif t==nil then return nil, "'..tostring(v.field_name or k)..'" else tok = t end\n\t'
			if type(v)=='table' and v.field_name then
				s=s..'this["'..tostring(v.field_name)..'"] = (v==nil and true or v)\n\t'
			end
		end
		return s..'return tok, this\nend)'
	end)

)



return g