
#include "lexer.h"
// user charclass: "\t"
static struct range_table usr_6_charset[] = {
	{ 0x9, 0x9, 1 },
};
define_category(usr_6)

// user charclass: "\r\n"
static struct range_table usr_3_charset[] = {
	{ 0xA, 0xD, 3 },
};
define_category(usr_3)

// user charclass: "^\r\n"
static struct range_table usr_2_charset[] = {
	{ 0xA, 0xD, 3 },
};
define_category(usr_2)

// user charclass: "+%-"
static struct range_table usr_1_charset[] = {
	{ 0x2B, 0x2D, 2 },
};
define_category(usr_1)

// user charclass: "\n\r"
static struct range_table usr_4_charset[] = {
	{ 0xA, 0xD, 3 },
};
define_category(usr_4)

// user charclass: "?%^%%!<>=%^:"
static struct range_table usr_5_charset[] = {
	{ 0x21, 0x25, 4 },
	{ 0x3A, 0x3C, 2 },
	{ 0x3D, 0x3F, 1 },
	{ 0x5E, 0x5E, 1 },
};
define_category(usr_5)


int anon_pattern_fn2(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "%*/"
	
	//pattern: "%*/"
;	match_single( (0x2A==(ch)) )
;	match_single( (0x2F==(ch)) )
;
	return 0;
}

int anon_pattern_fn1(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "[\r\n]+#%s*end"
	
	//pattern: "[\r\n]+#%s*end"
;	match_rep(    (is_charclass_usr_3(ch)) )
;	match_single( (0x23==(ch)) )
;	match_repopt( (is_charclass_sys_s(ch)) )
;	match_single( (0x65==(ch)) )
;	match_single( (0x6E==(ch)) )
;	match_single( (0x64==(ch)) )
;
	return 0;
}
int real(source* src);
int hex(source* src);
int integer(source* src);
int id(source* src);
int sl_comm(source* src);
int preproc(source* src);
int ml_comm(source* src);
int str(source* src);
int assign(source* src);
int assign_add(source* src);
int assign_sub(source* src);
int assign_mul(source* src);
int assign_div(source* src);
int assign_bor(source* src);
int star(source* src);
int add_op(source* src);
int sub_op(source* src);
int div_op(source* src);
int band_op(source* src);
int bor_op(source* src);
int oper(source* src);
int point(source* src);
int varArgs(source* src);
int argsep(source* src);
int sep(source* src);
int Block(source* src);
int block(source* src);
int Idx(source* src);
int idx(source* src);
int Sub(source* src);
int sub(source* src);
int lessth(source* src);
int bigth(source* src);
int ws(source* src);
int concat_line(source* src);

static const matcher_table matchers[] = {
	{ real, "real" },
	{ hex, "hex" },
	{ integer, "integer" },
	{ id, "id" },
	{ sl_comm, "sl_comm" },
	{ preproc, "preproc" },
	{ ml_comm, "ml_comm" },
	{ str, "str" },
	{ assign, "assign" },
	{ assign_add, "assign_add" },
	{ assign_sub, "assign_sub" },
	{ assign_mul, "assign_mul" },
	{ assign_div, "assign_div" },
	{ assign_bor, "assign_bor" },
	{ star, "star" },
	{ add_op, "add_op" },
	{ sub_op, "sub_op" },
	{ div_op, "div_op" },
	{ band_op, "band_op" },
	{ bor_op, "bor_op" },
	{ oper, "oper" },
	{ point, "point" },
	{ varArgs, "varArgs" },
	{ argsep, "argsep" },
	{ sep, "sep" },
	{ Block, "Block" },
	{ block, "block" },
	{ Idx, "Idx" },
	{ idx, "idx" },
	{ Sub, "Sub" },
	{ sub, "sub" },
	{ lessth, "lessth" },
	{ bigth, "bigth" },
	{ ws, "ws" },
	{ concat_line, "concat_line" },
	{ NULL, "eq" },
	{ NULL, "not_eq" },
	{ NULL, "increment" },
	{ NULL, "decrement" },
	{NULL, NULL}
};
enum matchers_id {
	tokid_real=0, tokid_hex, tokid_integer, tokid_id, 
	tokid_sl_comm, tokid_preproc, tokid_ml_comm, tokid_str, 
	tokid_assign, tokid_assign_add, 
	tokid_assign_sub, tokid_assign_mul, tokid_assign_div, tokid_assign_bor, 
	tokid_star, tokid_add_op, tokid_sub_op, tokid_div_op, tokid_band_op, 
	tokid_bor_op, tokid_oper, tokid_point, tokid_varArgs, tokid_argsep, 
	tokid_sep, tokid_Block, tokid_block, tokid_Idx, tokid_idx, tokid_Sub, 
	tokid_sub, tokid_lessth, tokid_bigth, tokid_ws, tokid_concat_line, tokid_eq, tokid_not_eq, 
	tokid_inc_op, tokid_dec_op
};
static const matcher_fn ALL[] = {
	 real,
	 hex,
	 integer,
	 id,
	 sl_comm,
	 preproc,
	 ml_comm,
	 str,
	 assign,
	 assign_add,
	 assign_sub,
	 assign_mul,
	 assign_div,
	 assign_bor,
	 star,
	 add_op,
	 sub_op,
	 div_op,
	 band_op,
	 bor_op,
	 oper,
	 point,
	 varArgs,
	 argsep,
	 sep,
	 Block,
	 block,
	 Idx,
	 idx,
	 Sub,
	 sub,
	 lessth,
	 bigth,
	 ws,
	 concat_line,
	NULL
};

int real(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "%d*"
	
	//pattern: "%d*"
;	match_repopt( (is_charclass_sys_d(ch)) )
;int has_num=matched;	
		//matcher for pattern: "%.?"
	
	//pattern: "%.?"
;	match_opt(    (0x2E==(ch)) )
;int has_point=matched;	
		//matcher for pattern: "%d*"
	
	//pattern: "%d*"
;	match_repopt( (is_charclass_sys_d(ch)) )
;	if(!(has_num || matched) )notmatch; 
		//matcher for pattern: "e?"
	
	//pattern: "e?"
;	match_opt(    (0x65==(ch)) )
;
	if(matched){ 	//matcher for pattern: "[+%-]?%d+"
	
	//pattern: "[+%-]?%d+"
;	match_opt(    (is_charclass_usr_1(ch)) )
;	match_rep(    (is_charclass_sys_d(ch)) )
;}else{ if( !has_point )notmatch; };
	return 0;
}


int hex(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "0x%h+"
	
	//pattern: "0x%h+"
;	match_single( (0x30==(ch)) )
;	match_single( (0x78==(ch)) )
;	match_rep(    (is_charclass_sys_h(ch)) )
;;
	return -1;
}


int integer(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "%d+"
	
	//pattern: "%d+"
;	match_rep(    (is_charclass_sys_d(ch)) )
;;
	return -1;
}


int id(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "%I+%i*"
	
	//pattern: "%I+%i*"
;	match_rep(    (is_charclass_sys_I(ch)) )
;	match_repopt( (is_charclass_sys_i(ch)) )
;;
	return -1;
}

		
int sl_comm(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "//[^\r\n]*"
	
	//pattern: "//[^\r\n]*"
;	match_single( (0x2F==(ch)) )
;	match_single( (0x2F==(ch)) )
;	match_repopt( (!is_charclass_usr_2(ch)) )
;;
	return -1;
}


int preproc(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "[\n\r]+#%s*%a+"
	
	//pattern: "[\n\r]+#%s*%a+"
;	match_rep(    (is_charclass_usr_4(ch)) )
;	match_single( (0x23==(ch)) )
;	match_repopt( (is_charclass_sys_s(ch)) )
;	match_rep(    (is_charclass_sys_a(ch)) )
;
	// match_while(1, anon_pattern_fn1);
	return 0;
}


int ml_comm(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "/%*"
	
	//pattern: "/%*"
;	match_single( (0x2F==(ch)) )
;	match_single( (0x2A==(ch)) )
;
	match_while(1, anon_pattern_fn2);
	return 0;
}


int str(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: """
	
	//pattern: """
;	match_single( (0x22==(ch)) )
;
	int is_esc=0;
		//matcher for pattern: ".*"
	
	//pattern: ".*"
;	match_repopt( 1 )
if(is_esc){ 
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
		switch(ch){
		  case 34: nextch(src); match_fn_matched; break;
		  case 92: is_esc=1; break;
		  // default: putchar(ch); break;
		}
	}
	// putchar(10);;
	return 0;
}


int assign(source *src){

	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//pattern: "="
	match_single( (0x3D==(ch)) );
	match_opt( (0x3D==(ch)) ) else return -1;
	return tokid_eq;
}


int assign_add(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "%+="
	
	//pattern: "%+="
;	match_single( (0x2B==(ch)) )
;	match_single( (0x3D==(ch)) )
;;
	return -1;
}


int assign_sub(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "%-="
	
	//pattern: "%-="
;	match_single( (0x2D==(ch)) )
;	match_single( (0x3D==(ch)) )
;;
	return -1;
}


int assign_mul(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "%*="
	
	//pattern: "%*="
;	match_single( (0x2A==(ch)) )
;	match_single( (0x3D==(ch)) )
;;
	return -1;
}


int assign_div(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "/="
	
	//pattern: "/="
;	match_single( (0x2F==(ch)) )
;	match_single( (0x3D==(ch)) )
;;
	return -1;
}


int assign_bor(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "|="
	
	//pattern: "|="
;	match_single( (0x7C==(ch)) )
;	match_single( (0x3D==(ch)) )
;;
	return -1;
}


int star(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "%*"
	
	//pattern: "%*"
;	match_single( (0x2A==(ch)) )
;;
	return -1;
}


int add_op(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "%+"
	
	//pattern: "%+"
	match_single( (0x2B==(ch)) );
	match_opt( (0x2B==(ch)) ) else return -1;
	return tokid_inc_op;
}


int sub_op(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "%-"
	
	//pattern: "%-"
;	match_single( (0x2D==(ch)) );
	match_opt( (0x2D==(ch)) ) else return -1;
	return tokid_dec_op;
}


int div_op(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "/"
	
	//pattern: "/"
;	match_single( (0x2F==(ch)) )
;;
	return -1;
}


int band_op(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "&"
	
	//pattern: "&"
;	match_single( (0x26==(ch)) )
;;
	return -1;
}


int bor_op(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "|"
	
	//pattern: "|"
;	match_single( (0x7C==(ch)) )
;;
	return -1;
}


int oper(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "[?%^%%!<>=%^:]+"
	// "%-+*?/%^&|%%!<>=%^!"
	//pattern: "[?%^%%!<>=%^:]+"
	match_rep(    (is_charclass_oper(ch)) );
	// match_rep(    (is_charclass_usr_5(ch)) );

	return -1;
}
// 
// int oper(source *src){
// 	unsigned ch=getch(src); int matched;
// 	source old_ctx = *src;
// 	switch(ch){
// 	  case '!':
// 	    switch(ch=nextch(src)){
// 	      case '=': return not_eq; break;
// 	      default: *src=old_ctx; break;
// 	    }
// 	    return not_op; break;
// 	  case '<':
// 	    switch(ch=nextch(src)){
// 	      case '=': return less_or_eq; break;
// 	      default: *src=old_ctx; break;
// 	    }
// 	    return less_than; break;
// 	}
// 	return 0;
// }

int point(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "%."
	
	//pattern: "%."
;	match_single( (0x2E==(ch)) )
;;
	return -1;
}


int varArgs(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "%.%.%."
	
	//pattern: "%.%.%."
;	match_single( (0x2E==(ch)) )
;	match_single( (0x2E==(ch)) )
;	match_single( (0x2E==(ch)) )
;;
	return -1;
}


int argsep(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: ","
	
	//pattern: ","
;	match_single( (0x2C==(ch)) )
;;
	return -1;
}


int sep(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: ";"
	
	//pattern: ";"
;	match_single( (0x3B==(ch)) )
;;
	return -1;
}


int Block(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "%{"
	
	//pattern: "%{"
;	match_single( (0x7B==(ch)) )
;;
	return -1;
}


int block(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "%}"
	
	//pattern: "%}"
;	match_single( (0x7D==(ch)) )
;;
	return -1;
}


int Idx(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "%["
	
	//pattern: "%["
;	match_single( (0x5B==(ch)) )
;;
	return -1;
}


int idx(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "%]"
	
	//pattern: "%]"
;	match_single( (0x5D==(ch)) )
;;
	return -1;
}


int Sub(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "%("
	
	//pattern: "%("
;	match_single( (0x28==(ch)) )
;;
	return -1;
}


int sub(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "%)"
	
	//pattern: "%)"
;	match_single( (0x29==(ch)) )
;;
	return -1;
}


int lessth(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "<"
	
	//pattern: "<"
;	match_single( (0x3C==(ch)) )
;;
	return -1;
}


int bigth(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: ">"
	
	//pattern: ">"
;	match_single( (0x3E==(ch)) )
;;
	return -1;
}
// int ws(source *src){
// 	unsigned ch=getch(src); int matched, is_newline=0;
// 	source old_ctx = *src;
// 	for(matched=0;; matched=1, ch = nextch(src) ){
// 		if( !(is_charclass_sys_s(ch)) || is_eof(src) ){
// 			if((is_newline || src->line==1) && ch=='#'){
// 				const char *s_pp=src->s;
// 				for(;ch!='\n'; ch = nextch(src) ); src->sh=0;
// 				printf("PP: \"%.*s\"\n", src->s-s_pp, s_pp);
// 				return 0;
// 			}
// 			return matched ? 0 : ( *src = old_ctx, 1);
// 		}else if(ch=='\n') is_newline=1;
// 	}
// }

int ws(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "%s+"
	
	//pattern: "%s+"
;	match_rep(    (is_charclass_sys_s(ch)) )
;;
	return -1;
}


int concat_line(source *src){
	unsigned ch=getch(src); int matched;
	source old_ctx = *src;
	//matcher for pattern: "\[\t]*\r?\n"
	
	//pattern: "\[\t]*\r?\n"
;	match_single( (0x5C==(ch)) )
;	match_repopt( (is_charclass_usr_6(ch)) )
;	match_opt(    (0xD==(ch)) )
;	match_single( (0xA==(ch)) )
;;
	return -1;
}
