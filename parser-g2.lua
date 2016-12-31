local gmr=require'parser'


local lexer=require'lexer'
local lex_mem = require'lm'


scope = require('ast.scope')()
--scope:define('int', { kind='type', sizeof=4, name='int' })
--scope:define('char', { kind='type', sizeof=1, name='char' })
--scope:define('bool', { kind='type', sizeof=1, name='bool' })
--scope:define('void', { kind='type', sizeof=0, name='void' })

local temp_rule_mt = {}

--function temp_rule_mt:
function tempRule(fn)
	return setmetatable({}, rule_mt{
		__call=function(self, tok)
			local t,v = fn(tok)
			if self.capt_mt and type(v)=='table' then
				setmetatable(v, self.capt_mt)
			end
			return t, v
		end,
		__index=setmetatable({
			rule_type='custom',
--			capt_mt={},
		}, { __index=Rule }),
	})
end

local g=Grammar('rules')

g.rules=List(g.rule):tmpl'${\n}'

--g.def=Seq(lexeme' :', lexeme' assign')

g.rule=Seq(
	Ident^'Name', lexeme' :=', --g.def,, lexeme' ;'
	g.ra^'Body')
	:tmpl'g.$Name = $Body;\n\n'


local g_binop_mt = {
	__index={},
	__metatable={ binop=true, expr=true },
}

function g_binop_mt:__tostring()
	local op, l, r = tostring(self.op), tostring(self.l), tostring(self.r)
	if op=='/' then
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
	return '('..l..op..r..')'
end

function g_binop_mt.__index:eval()
	local o, l, r = tostring(self.op),
--		assert(tonumber(tostring(self.l)) or self.l:eval()),
--		assert(tonumber(tostring(self.r)) or self.r:eval())
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
g.ra.bin_op=g_binop
--
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
	--		__call=function(self,  idx)
	--			return self.rule( idx)
	--		end
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
--	if c.R.global then
		return setmetatable( { opt=true }, {
			__tostring=function(self)
				return tostring(rule)..':opt\'\''
			end,
			__index=rule,
	--		__call=function(self,  idx)
	--			return self.rule( idx)
	--		end
		})
--	else--if type()
--		rule.opt=true
--		return c.R
--	end
end

g.r= Alt(
--	Wrap(lexeme' {', ListSep(g.ra, lexeme' ,'):tmpl'${, }',
--	lexeme' }'):tmpl'ListSep($body)',
	Seq(usrkwrd'binop', g.ra^'Items', Wrap(lexeme' {', ListSep(g.ra, lexeme' ,'):tmpl'${, }', lexeme' }')^'Ops'):tmpl'Precedence($Items, $Ops)',

	Wrap(lexeme' (', g.ra, lexeme' )'),
--	Wrap(lexeme' [', g.ra, lexeme' ]')
--		:tmpl(function(s) return '('..tostring(s.body)..'):opt(\'\')' end),
	g.opt, g.field,
	g.ruleID~lexeme' :=',
	lexeme'string1':tmpl(function(s) return 'lexeme'..tostring(s.tok) end),
	lexeme'string2':tmpl(function(s) return 'kwrd'..tostring(s.tok) end)
)

g.rs=Alt(
	Seq( lexeme' *', g.r):tmpl'List($1)',
	List(g.r):tmpl(function(self)
		local s = 'NewRule(function(tok)\n\tlocal t, v\n\tlocal this = {}\n\t'
		for k=1,#self do
			local v = self[k]
			s=s..'t, v = ('..tostring(v)..
			')(tok)\n\tif t==nil then return else tok = t end\n\t'
			if type(v)=='table' and v.field_name then
				s=s..'this["'..tostring(v.field_name)..'"] = (v==nil and true or v)\n\t'
			end
		end
		return s..'return tok, this\nend)'
	end)

)


--g()
--g'rule'

return g