package.cpath = [[?.dll;]]..package.cpath
--package.path = [[?.lua;?\init.lua;]]..package.path

local lexer=require'lexer'

lexemes = setmetatable({
	[0] = "ws",
	["ws"] = 0,
	[64] = "@",
	["@"] = 64,
	[8193] = "ident",
	["ident"] = 8193,
	[32813] = "--",
	["--"] = 32813,
	[8194] = "string",
	["string"] = 8194,
	[8196] = "ml_comm",
	["ml_comm"] = 8196,
	[125] = "}",
	["}"] = 125,
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

}, {
	__call = function(self, name) return self[name] end,
	__index = function(self, name)
		local l = lexer.new(name):next()
		if l then print('\t['..l..']="'..name..'",\n\t["'..name..'"]='..l..',') end
		return l
	end
})

local utf8=require'lua-utf8'


function keyword_list(s, start_id)
	local lst, next_id = {}, start_id or 1
	for k in utf8.gmatch(s, '%s*(%S+)%s*') do
		assert(not lst[k])
		lst[k] = next_id
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
]], 300)

