dofile'keyword.lua'
require'parser'
local g = Grammar'chunks'

g.assign_op = NewRule(function(tok)
	local t,v = (NewRule(function(tok)
		local t,v = (NewRule(function(tok)
			local t,v = (NewRule(function(tok)
				local t,v = (lexeme'=')(tok)
				if t==nil then
					t,v = (lexeme'+=')(tok)
				end
				return t, v
			end))(tok)
			if t==nil then
				t,v = (lexeme'/=')(tok)
			end
			return t, v
		end))(tok)
		if t==nil then
			t,v = (lexeme'-=')(tok)
		end
		return t, v
	end))(tok)
	if t==nil then
		t,v = (lexeme'*=')(tok)
	end
	return t, v
end);


g.value = NewRule(function(tok)
	local t,v = (NewRule(function(tok)
		local t,v = (NewRule(function(tok)
			local t,v = (NewRule(function(tok)
				local t,v = (NewRule(function(tok)
					local t,v = (NewRule(function(tok)
						local t,v = (lexeme'hex')(tok)
						if t==nil then
							t,v = (lexeme'real')(tok)
						end
						return t, v
					end))(tok)
					if t==nil then
						t,v = (lexeme'int')(tok)
					end
					return t, v
				end))(tok)
				if t==nil then
					t,v = (lexeme'string1')(tok)
				end
				return t, v
			end))(tok)
			if t==nil then
				t,v = (g.call)(tok)
			end
			return t, v
		end))(tok)
		if t==nil then
			t,v = (lexeme'ident')(tok)
		end
		return t, v
	end))(tok)
	if t==nil then
		t,v = (lexeme'string2')(tok)
	end
	return t, v
end);


g.unop = NewRule(function(tok)
	local t, v
	local this = {}
	t, v = (NewRule(function(tok)
	local t,v = (NewRule(function(tok)
		local t,v = (NewRule(function(tok)
			local t,v = (lexeme'-')(tok)
			if t==nil then
				t,v = (lexeme'!')(tok)
			end
			return t, v
		end))(tok)
		if t==nil then
			t,v = (lexeme'&')(tok)
		end
		return t, v
	end))(tok)
	if t==nil then
		t,v = (lexeme'*')(tok)
	end
	return t, v
end):opt'')(tok)
	if t==nil then return else tok = t end
	this["op"] = (v==nil and true or v)
	t, v = (NewRule(function(tok)
	local t,v = (g.value)(tok)
	if t==nil then
		t,v = (g.unop)(tok)
	end
	return t, v
end))(tok)
	if t==nil then return else tok = t end
	this["arg"] = (v==nil and true or v)
	return tok, this
end);


g.expr = Precedence(g.unop, NewRule(function(tok)
	local t,v = (lexeme'*')(tok)
	if t==nil then
		t,v = (lexeme'/')(tok)
	end
	return t, v
end), NewRule(function(tok)
	local t,v = (lexeme'+')(tok)
	if t==nil then
		t,v = (lexeme'-')(tok)
	end
	return t, v
end), NewRule(function(tok)
	local t,v = (NewRule(function(tok)
		local t,v = (lexeme'&')(tok)
		if t==nil then
			t,v = (lexeme'|')(tok)
		end
		return t, v
	end))(tok)
	if t==nil then
		t,v = (lexeme'^')(tok)
	end
	return t, v
end), NewRule(function(tok)
	local t,v = (NewRule(function(tok)
		local t,v = (NewRule(function(tok)
			local t,v = (NewRule(function(tok)
				local t,v = (NewRule(function(tok)
					local t,v = (lexeme'==')(tok)
					if t==nil then
						t,v = (lexeme'>=')(tok)
					end
					return t, v
				end))(tok)
				if t==nil then
					t,v = (lexeme'<=')(tok)
				end
				return t, v
			end))(tok)
			if t==nil then
				t,v = (lexeme'!=')(tok)
			end
			return t, v
		end))(tok)
		if t==nil then
			t,v = (lexeme'<')(tok)
		end
		return t, v
	end))(tok)
	if t==nil then
		t,v = (lexeme'>')(tok)
	end
	return t, v
end), NewRule(function(tok)
	local t,v = (lexeme'&&')(tok)
	if t==nil then
		t,v = (lexeme'||')(tok)
	end
	return t, v
end), g.assign_op);


g._if = NewRule(function(tok)
	local t, v
	local this = {}
	t, v = (kwrd" if")(tok)
	if t==nil then return else tok = t end
	t, v = (g.expr)(tok)
	if t==nil then return else tok = t end
	this["cond"] = (v==nil and true or v)
	t, v = (kwrd" then")(tok)
	if t==nil then return else tok = t end
	t, v = (g.chunks)(tok)
	if t==nil then return else tok = t end
	this["th"] = (v==nil and true or v)
	t, v = (kwrd" end")(tok)
	if t==nil then return else tok = t end
	return tok, this
end);


g.chunks = List(g.chunk);


g.assign = NewRule(function(tok)
	local t, v
	local this = {}
	t, v = (lexeme'ident')(tok)
	if t==nil then return else tok = t end
	this["var"] = (v==nil and true or v)
	t, v = (g.assign_op)(tok)
	if t==nil then return else tok = t end
	this["op"] = (v==nil and true or v)
	t, v = (g.expr)(tok)
	if t==nil then return else tok = t end
	this["value"] = (v==nil and true or v)
	return tok, this
end);


g.call = NewRule(function(tok)
	local t, v
	local this = {}
	t, v = (lexeme'ident')(tok)
	if t==nil then return else tok = t end
	this["fn"] = (v==nil and true or v)
	t, v = (lexeme' (')(tok)
	if t==nil then return else tok = t end
	t, v = (ListSep(g.expr, lexeme' ,'))(tok)
	if t==nil then return else tok = t end
	this["args"] = (v==nil and true or v)
	t, v = (lexeme' )')(tok)
	if t==nil then return else tok = t end
	return tok, this
end);


g.chunk = NewRule(function(tok)
	local t,v = (NewRule(function(tok)
		local t,v = (g._if)(tok)
		if t==nil then
			t,v = (g.assign)(tok)
		end
		return t, v
	end))(tok)
	if t==nil then
		t,v = (g.call)(tok)
	end
	return t, v
end);


g()
g.assign:tmpl'$var $op $value'
g._if:tmpl'if $cond then $th end'
g.call:tmpl'$fn ( $args )'
g.unop:tmpl'$op$arg'

print(g'a=5+6*x printf("%d") if x<5 then x=5 end')
return g
	