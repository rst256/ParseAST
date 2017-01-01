//##en
// #include "ast/ast.h"
#define LUA_LIB

// #include "3pp.c"
#include "lex-pp.0.h"

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#include <string.h>
#include <stdio.h>
#include <assert.h>
#include "luam/lua5x.h"

// #include "ltrie-lexer.h"

// typedef struct TokenData {
// 	
// }

typedef struct LuaLexer{
  source src;
  const char * s0;
  source src_prev;
} *LuaLexer;

const char * LuaLexer__typename = "Lexer";

LuaLexer LuaLexer_check(lua_State *L, int i){
	 LuaLexer self = luaL_checkudata(L, i, LuaLexer__typename);
	 if(self==NULL) luaL_error(L, "userdata %s is NULL", LuaLexer__typename);
	 return self;
}

static int LuaLexer_charclass_id(lua_State *L) {
	size_t l; const char *s = luaL_checklstring(L, 1, &l);
	source src_tmp = new_source( s, s+l );
	unsigned ch=nextch(&src_tmp);
	char buff[14];
	int cs = charclass_id(ch);
		buff[0] = cs & ident_first ? (assert(cs&ident_next), 'I') : '-'; 
		buff[1] = cs & ident_next ? (assert((cs&digit)^(cs&ident_first)), 'i') : '-';
		buff[2] = cs & digit ? (assert((cs&hex_digit)&&(cs&ident_next)), 'd') : '-';
		buff[3] = cs & hex_digit ? (assert((cs&digit)^(cs&ident_next&&cs&ident_first)), 'x') : '-';	
		buff[4] = cs & white_space ? (assert((cs&white_space)==white_space), 'w') : '-';
		buff[5] = (cs & punctuation ? 'p' : '-');
		buff[6] = ((cs & punctuation) ? (((cs & punctuation)>>5)+'0') : '-');
		buff[7] = '\0';
	 lua_pushstring(L, buff); lua_pushinteger(L, cs); 
			
	return 2;
}

static int LuaLexer_lexeme_name(lua_State *L) {
	int i = luaL_checkinteger(L, 1);
	if(i>=0 && i<table_size(matchers)-1)
		lua_pushstring(L, matchers[i].name);
	else
		lua_pushnil(L);
		// luaL_error(L, "lexeme_id unknown, valid lexeme_id is [0; %d]", table_size(matchers));
	return 1;
}

static int LuaLexer_lexeme_id(lua_State *L) {
	const char *s = luaL_checkstring(L, 1);
	for(int i=0; matchers[i].name; i++){
		if( strcmp(s, matchers[i].name)==0 ){
			lua_pushinteger(L, i);
			return 1;
		} 
	}
	
	// lua_pushstring(L, matchers[i].name);
	return 0;
}

static int LuaLexer_new(lua_State *L) {//_from_file
	size_t l;
	const char *s0 = luaL_checklstring(L, 1, &l);
		// new_source_from_file(argv[1], &src);
	char *s = malloc(l);
	memcpy(s, s0, l);
	LuaLexer self = lua_newuserdata(L, sizeof(struct LuaLexer));
	luaL_setmetatable(L, LuaLexer__typename);

	source src_tmp = new_source( s, s+l );
	nextch(&src_tmp);
	self->src=src_tmp;
	self->src_prev=self->src;
	self->s0=s;
	// printf("%p:%p\n", self->s, self->se);
	return 1;	
}

int get_tok(LuaLexer self){
	// self->src_prev=self->src;
	int res_i;
	if( is_eof(&(self->src)) ){
		return -1;
	}
	for(int i=0; ALL[i]; i++){
		if( (res_i=ALL[i](&(self->src))) ){
			return res_i==-1 ? i : res_i;
		} 
	}
	return -2;
}

static int LuaLexer_get_token(lua_State *L) {//_from_file
	LuaLexer self = LuaLexer_check(L, 1);
	// int arg_type = lua_type(L, 2);
// LUA_TNONE , LUA_TNIL, LUA_TNUMBER, LUA_TBOOLEAN, LUA_TSTRING, LUA_TTABLE, LUA_TFUNCTION, LUA_TUSERDATA, LUA_TTHREAD, and LUA_TLIGHTUSERDATA. 
	// if(arg_type==
	self->src_prev=self->src;
	int res_i = get_tok(self);
	if( res_i==-1 ){
		lua_pushnil(L);
	} else if( res_i>=0 ){
		lua_pushinteger(L, res_i);
	} else 	if( res_i==-2 ){
		nextch(&(self->src));
		lua_pushboolean(L, 0);
	}
	return 1;	
}







#include "map.h"
#define LUA_LIB_ENTRY(lib_name, fn_name) { #fn_name, lib_name##fn_name }, 
#define newEnum(lib_name, ...) \
	{ MAP_CTX(LUA_LIB_ENTRY, lib_name, __VA_ARGS__) {NULL, NULL} }




enum LexemeID {
	lexid_real=0x2013, lexid_hex=0x201C, lexid_integer=0x201D, lexid_ident=0x2001, 
	lexid_sl_comm, lexid_preproc, lexid_ml_comm, lexid_str=0x2002, 
	lexid_arrow,
	lexid_assign, lexid_assign_add, 
	lexid_assign_sub, lexid_assign_mul, lexid_assign_div, lexid_assign_bor, 
	lexid_star, lexid_add_op, lexid_sub_op, lexid_div_op, lexid_band_op, 
	lexid_bor_op, lexid_oper, lexid_point, lexid_varArgs, lexid_argsep, 
	lexid_sep, lexid_Block, lexid_block, lexid_Index, lexid_index, lexid_Sub, 
	lexid_sub, lexid_lessth, lexid_bigth, lexid_ws=0, lexid_concat_line, lexid_eq, lexid_not_eq, 
	lexid_inc_op, lexid_back_arrow=0x23,
	lexgroup_dbl_form=0x8000, lexgroup_eq_postfix=0x4000, 
	lexgroup_has_value=0x2000, lexgroup_comment=0x1000, 
};

/* type of numbers in Lua */
typedef LUA_NUMBER Lexer_Number;

/* type for integer functions */
typedef unsigned long long Lexer_Integer;

/* unsigned integer type */
typedef LUA_UNSIGNED Lexer_Unsigned;

#define LEXERpush

int parse_integer_literal(source *src, Lexer_Integer *res){
	unsigned char digits[100]; int digits_len=0; unsigned ch;
	source_foreach(src, ch, is_charclass_sys_d(ch))
		if(digits_len<table_size(digits)) digits[digits_len++]=(ch-'0'); else return -2;
	if(!digits_len) return -1;
	Lexer_Integer _res=0; 
	for(Lexer_Integer r=1, i=digits_len; i; i--, r*=10 ) _res+=digits[i-1]*r; 
	*res=_res;
	// printf("Number %ld\n", _res);
	return 0;
}

int parse_string_literal(source *src, const unsigned quotes){
	unsigned ch=getch(src); int is_esc=0;
	// int matched, is_esc=0;
	// source old_ctx = *src;

	match_repopt( 1 ) if(is_esc){ 
		switch(ch){
		  // case '"': putchar('"'); break;
		  // case 92: putchar(92); break;
		  // case 110: putchar(10); break;
		  case 13: continue;
		  case 10: break;
		  // case 116: putchar(9); break;
		  // case 114: putchar(13); break;
		  // default: match_fn_failed(ch); break;
		}
		is_esc=0;
	}else{
		if(ch==quotes){ nextch(src); match_fn_matched; }
		switch(ch){
		  case '\\': is_esc=1; break;
		  // default: putchar(ch); break;
		}
	}
	return 0;
}

#define LEXER_MODE_EXPECT_POSTFIX_UNOP 0x1

int get_next_token(source * src, int mode) {
	if( is_eof(src) ) LEXEMEon_eof;
	unsigned ch = getch(src);
	int cc = charclass_id(ch);
	
	if(cc & ident_first){ 																							// ident or keyword
		int l = 0; nextch(src);
		source_foreach(src, ch, is_charclass_sys_i(ch) ) l++;
		return lexid_ident;
	}else if(cc & digit){ 																							// hex or dec number
		
		if(ch=='0' ){ 												// hex number
			source old_src = *src;
			if(nextch(src)=='x'){
				int l = 0; nextch(src);
				source_foreach(src, ch, is_charclass_sys_h(ch) ) l++;
				// assert(l); 
				// nextch(src);
				return lexid_hex;
			}else{
				*src = old_src;
			}
		}
		 																											// dec number
			Lexer_Integer int_value = 0;
			parse_integer_literal(src, &int_value);
			int res_digit = lexid_integer;
			ch = getch(src);
			if(ch=='.'){ 																								// real number
				Lexer_Integer int2_value = 0;
				nextch(src);
				if(parse_integer_literal(src, &int2_value)!=0) return -2; 
				// printf("real %d\t%llu.%llu\n", r22, int_value, int2_value);
				res_digit = lexid_real; ch = getch(src);
			}
			if(ch=='e' || ch=='E'){  																// real number in E notation 
				ch = nextch(src);
				if(ch=='+' || ch=='-') nextch(src);
				Lexer_Integer int_exp_value = 0;
 				if(parse_integer_literal(src, &int_exp_value)!=0) return -2; 
				res_digit = lexid_real;
			} 
			return res_digit;
		
		// assert(0); 
	}else if(cc & white_space){																				// white space `[ \t\r\n]+`
		int l = 0; nextch(src);
		source_foreach(src, ch, is_charclass_sys_s(ch) ) l++;
		return lexid_ws;
	}else if(cc & punctuation){ 																			// punctuation: `?!"&-*+/#<=>|%(),.:;`
	//`$'?@`

		unsigned ch2=nextch(src);
		switch (ch){
			case '"': case '\'': 																									// string literal	
				return parse_string_literal(src, ch) ? ch : -3;
			case ',': case '?': case ';': case '$': case '@':							// single char tokens
			case '[': case ']': case '{': case '}': case '(': case ')': 							// bracket tokens
			case '#': case '\\': 
				return ch;
			case '/':																										// single->line comment
				switch (ch2){
					case '/':
						nextch(src); 
						source_foreach(src, ch, (ch!='\n') );
						return lexid_sl_comm; 						
					case '*': 
						ch2 = nextch(src); 
						source_foreach(src, ch) if(ch=='/' && ch2=='*') break; else ch2 = ch;
						nextch(src); 
						return lexid_ml_comm; 											
				}
			case '-': 
				if(ch2 == '>'){ nextch(src); return lexid_arrow; }
			case '+': 	
				if(!(mode&LEXER_MODE_EXPECT_POSTFIX_UNOP) && ch2 == ch){
					source old_src = *src;
					if(ch==nextch(src)){ 
						*src = old_src; return ch;
					}else
						return ch | lexgroup_dbl_form;
				}
			case '<': 
				if(ch2 == '-'){ nextch(src); return lexid_back_arrow; }
			case '&': case ':': case '|': 																		// single and double char tokens 
			case '>': case '=':														
				if(ch2 == ch){ nextch(src); return ch | lexgroup_dbl_form; }
			case '!': case '*': case '^': case '%': 														// special assigment tokens
				if(ch2=='='){ nextch(src); return ch | lexgroup_eq_postfix; }
				return ch; 
			case '.': 
				if(ch2==ch){ 
					if(ch2!=nextch(src)) return -2; 
					nextch(src); return ch | lexgroup_dbl_form; 
				} else if(charclass_id(ch2) & digit){
					Lexer_Integer int2_value = 0;
					if(parse_integer_literal(src, &int2_value)!=0) return -2; 
					// printf("real %d\t%llu.%llu\n", r22, int_value, int2_value);
					ch = getch(src);
					if(ch=='e' || ch=='E'){  																// real number in E notation 
						ch = nextch(src);
						if(ch=='+' || ch=='-') nextch(src);
						Lexer_Integer int_exp_value = 0;
		 				if(parse_integer_literal(src, &int_exp_value)!=0) return -2; 
					} 
					return lexid_real;
				}
				return ch; 
				
		}
	}//else if(ch=='\'') return parse_string_literal(src, ch) ? lexid_str : -3;
	return -2;	
}



static int LuaLexer_next(lua_State *L) {//_from_file
	LuaLexer self = LuaLexer_check(L, 1);
	self->src_prev=self->src;
	int tokid = get_next_token(&(self->src), luaL_optinteger(L, 2, 0));	
	if(tokid>=0) lua_pushinteger(L, tokid); 
	else if(tokid==-1) lua_pushnil(L); 
	else if(tokid==-2){ lua_pushboolean(L, 0); nextch(&(self->src)); }
	else luaL_error(L, "get_next_token return unknown retcode %d", tokid);
	return 1;	
}

static int LuaLexer_get_pos(lua_State *L) {//_from_file
	LuaLexer self = LuaLexer_check(L, 1);
	lua_pushinteger(L, self->src_prev.line);
	lua_pushinteger(L, self->src_prev.pos-1);
	return 2;
}

static int LuaLexer_str(lua_State *L) {//_from_file
	LuaLexer self = LuaLexer_check(L, 1);
	lua_pushlstring(L, self->src_prev.s, self->src.s - self->src_prev.s);
	return 1;
}

static int LuaLexer_rewind(lua_State *L) {//_from_file
	LuaLexer self = LuaLexer_check(L, 1);
	self->src.s=self->s0;
	self->src.line=self->src.pos=1;
	self->src.sh=self->src.ch=0;
	nextch(&(self->src));
	self->src_prev=self->src;
	return 0;
}

static int LuaLexer___tostring(lua_State *L) { return LuaLexer_str(L); }

static int LuaLexer___gc(lua_State *L) { 
	LuaLexer self = LuaLexer_check(L, 1);
	free((void*)(self->s0));
	return 0;
}

#define DLL_EXPORT __declspec(dllexport)


union u{
int i:4;
char c;
};

DLL_EXPORT LUALIB_API int luaopen_lexer(lua_State *L) {
   static luaL_Reg LuaLexer__fn[] = newluaL_Reg(LuaLexer_, get_token, get_pos, str, next, rewind);
	static luaL_Reg LuaLexer__mt[]= newluaL_Reg(LuaLexer_, __tostring, __gc);
	// static luaL_Reg LuaLexer__mt[]={
	// // 	{"__call", LuaLexer_next_token },
	// // 	// {"__tostring", NULL },
	// 	{NULL, NULL}
	// };
	// 
	// 
	static luaL_Reg LuaLexer__lib[]={
		{"new", LuaLexer_new },
		{"lexeme_name", LuaLexer_lexeme_name },
		{"lexeme_id", LuaLexer_lexeme_id },
		{"charclass", LuaLexer_charclass_id },
		{NULL, NULL}
	};
	
	
	luaL_newlib(L, LuaLexer__lib);
	
	LuaM_userdata_register_class(L, LuaLexer__typename, LuaLexer__fn, LuaLexer__mt);
	// add_keywords(L); lua_setfield(L, -2, "keywords"); 
	// keywords_table_ref =luaX_ref(L, 1, -1);
	// lua_pop(L, 1);

	return 1;
}
