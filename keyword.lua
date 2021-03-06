package.cpath = [[?.dll;]]..package.cpath
--package.path = [[?.lua;?\init.lua;]]..package.path

local lexer=require'lexer'

lexemes = setmetatable({
	[0] = "ws",
	["ws"] = 0,
	[0x2013] = "real",
	["real"] = 0x2013,
	[64] = "@",
	["@"] = 64,
	[8193] = "ident",
	["ident"] = 8193,
	[32813] = "--",
	["--"] = 32813,
	[39] = "string1",
	["string1"] = 39,
	[34] = "string2",
	["string2"] = 34,
	[0x2] = "ml_comm",
	["ml_comm"] = 0x2,
	[0x1] = "sl_comm",
	["sl_comm"] = 0x1,
	[125] = "}",
	["}"] = 125,
	[16442]=":=",
	[":="]=16442,
	[16508] = "|=",
	["|="] = 16508,
	[92] = "\\",
	["\\"] = 92,
	[32814] = "...",
	["..."] = 32814,
	[123] = "{",
	["{"] = 123,
	[32806] = "&&",
	["&&"] = 32806,
	[32892] = "||",
	["||"] = 32892,
	[91] = "[",
	["["] = 91,
	[8220] = "hex",
	["hex"] = 8220,
	[8221] = "int",
	["int"] = 8221,
	[94] = "^",
	["^"] = 94,
	[16422] = "&=",
	["&="] = 16422,
	[43] = "+",
	["+"] = 43,
	[16417] = "!=",
	["!="] = 16417,
	[32826] = "::",
	["::"] = 32826,
	[35] = "#",
	["#"] = 35,
	[36] = "$",
	["$"] = 36,
	[93] = "]",
	["]"] = 93,
	[38] = "&",
	["&"] = 38,
	[33] = "!",
	["!"] = 33,
	[40] = "(",
	["("] = 40,
	[41] = ")",
	[")"] = 41,
	[42] = "*",
	["*"] = 42,
	[16427] = "+=",
	["+="] = 16427,
	[44] = ",",
	[","] = 44,
	[45] = "-",
	["-"] = 45,
	[46] = ".",
	["."] = 46,
	[16431] = "/=",
	["/="] = 16431,
	[62] = ">",
	[">"] = 62,
	[60] = "<",
	["<"] = 60,
	[0x23] = "<-",
	["<-"] = 0x23,
	[16426] = "*=",
	["*="] = 16426,
	[32811] = "++",
	["++"] = 32811,
	[32830] = ">>",
	[">>"] = 32830,
	[16429] = "-=",
	["-="] = 16429,
	[47] = "/",
	["/"] = 47,
	[32828] = "<<",
	["<<"] = 32828,
	[16444] = "<=",
	["<="] = 16444,
	[61] = "assign",
	assign = 61,
	['='] = 61,
	[58] = ":",
	[":"] = 58,
	[59] = ";",
	[";"] = 59,
	[124] = "|",
	["|"] = 124,
	[32829] = "==",
	["=="] = 32829,
	[16446] = ">=",
	[">="] = 16446,
	[63] = "?",
	["?"] = 63,
	[8195] = "arrow",
	["arrow"] = 8195,
	[37]="%",
	["%"]=37,
	[16421]="%=",
	["%="]=16421,
	[16478]="^=",
	["^="]=16478,
	[126]="~",
	["~"]=126,
	[16510]="~=",
	["~="]=16510,
}, {
	__call = function(self, name) return self[name] end,
	__index = function(self, name)
		local l = lexer.new(name):next()
		if l and rawget(self, name)==nil then
			print('\t['..l..']="'..name..'",\n\t["'..name..'"]='..l..',')
			rawset(self, name, l)
			rawset(self, l, name)
			return l
		end
	end
})

local utf8=require'lua-utf8'


function keyword_list(s, start_id)
	local lst, next_id = {}, start_id or 1
	for k in utf8.gmatch(s, '%s*(%S+)%s*') do
		assert(lst[k]==nil and lst[next_id]==nil,
			'keyword redefine '..k..':'..next_id)
		lst[k] = next_id
		lst[next_id] = k
		next_id = next_id + 1
	end
	return lst
end


local keywords_lexeme_id = lexemes.ident

keywords = keyword_list([[
	if else return for while break switch case default goto
	typedef struct union enum type
		const static extern typeof sizeof
		continue
		then end
		function do in macros
		local
]], 300)

