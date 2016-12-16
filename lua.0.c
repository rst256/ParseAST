//##en
// #include "ast/ast.h"
#define LUA_LIB

// #include "3pp.c"
#include "lex-pp.h"

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#include <string.h>
#include <stdio.h>
#include <assert.h>
#include "luam/lua5x.h"

// #include "ltrie-lexer.h"
@set 

typedef struct LuaLexer{
  source src;
  source src_prev;
} *LuaLexer;

const char * LuaLexer__typename = "Lexer";

LuaLexer LuaLexer_check(lua_State *L, int i){
	 LuaLexer self = luaL_checkudata(L, i, LuaLexer__typename);
	 if(self==NULL) luaL_error(L, "userdata %s is NULL", LuaLexer__typename);
	 return self;
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
	const char *s = luaL_checklstring(L, 1, &l);
		// new_source_from_file(argv[1], &src);

	LuaLexer self = lua_newuserdata(L, sizeof(struct LuaLexer));
	luaL_setmetatable(L, LuaLexer__typename);

	source src_tmp = new_source( s, s+l );
	nextch(&src_tmp);
	self->src=src_tmp;
	self->src_prev=self->src;
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
	int arg_type = lua_type(L, 2);
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

static int LuaLexer_get_pos(lua_State *L) {//_from_file
	LuaLexer self = LuaLexer_check(L, 1);
	lua_pushinteger(L, self->src_prev.line);
	lua_pushinteger(L, self->src_prev.pos-1);
	return 2;
}

static int LuaLexer_get_str(lua_State *L) {//_from_file
	LuaLexer self = LuaLexer_check(L, 1);
	lua_pushlstring(L, self->src_prev.s, self->src.s - self->src_prev.s);
	return 1;
}


#define DLL_EXPORT __declspec(dllexport)

DLL_EXPORT LUALIB_API int luaopen_lexer(lua_State *L) {
	static luaL_Reg LuaLexer__fn[]={
		{"get_token", LuaLexer_get_token },
		{"get_pos", LuaLexer_get_pos },
		{"str", LuaLexer_get_str },
		{NULL, NULL}
	};
	// 
	static luaL_Reg LuaLexer__mt[]={
	// 	{"__call", LuaLexer_next_token },
	// 	// {"__tostring", NULL },
		{NULL, NULL}
	};
	// 
	// 
	static luaL_Reg LuaLexer__lib[]={
		{"new", LuaLexer_new },
		{"lexeme_name", LuaLexer_lexeme_name },
		{"lexeme_id", LuaLexer_lexeme_id },
		{NULL, NULL}
	};
	
	
	luaL_newlib(L, LuaLexer__lib);
	
	LuaM_userdata_register_class(L, LuaLexer__typename, LuaLexer__fn, LuaLexer__mt);
	// add_keywords(L); lua_setfield(L, -2, "keywords"); 
	// keywords_table_ref =luaX_ref(L, 1, -1);
	// lua_pop(L, 1);

	return 1;
}
