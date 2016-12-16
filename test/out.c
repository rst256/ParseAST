
#include "lexer.h"
// user charclass: "+%-"$+-/*|&^%!=<>
статик структ range_table usr_1_charset[] = {
	{ 0x2B, 0x2D, 2 },
};
define_category(usr_1)

// user charclass: "\r\n"
статик структ range_table usr_3_charset[] = {
	{ 0xA, 0xD, 3 },
};
define_category(usr_3)

// user charclass: "?%^%%!<>=%^:"
статик структ range_table usr_5_charset[] = {
	{ 0x21, 0x25, 4 },
	{ 0x3A, 0x3C, 2 },
	{ 0x3D, 0x3F, 1 },
	{ 0x5E, 0x5E, 0 },
};
define_category(usr_5)

// user charclass: "^\r\n"
статик структ range_table usr_2_charset[] = {
	{ 0xA, 0xD, 3 },
};
define_category(usr_2)

// user charclass: "\n\r"
статик структ range_table usr_4_charset[] = {
	{ 0xA, 0xD, 3 },
};
define_category(usr_4)


целое anon_pattern_fn2(source *src){
	unsigned ch=getch(src); целое matched;
	source old_ctx = *src;
	//matcher for pattern: "%*/"
	
	//pattern: "%*/"
;	match_single( (0x2A==(ch)) )
;	match_single( (0x2F==(ch)) )
;
	возврат 0;
}

целое anon_pattern_fn1(source *src){
	unsigned ch=getch(src); целое matched;
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
	возврат 0;
}
целое real(source* src);
целое hex(source* src);
целое integer(source* src);
целое id(source* src);
целое sl_comm(source* src);
целое preproc(source* src);
целое ml_comm(source* src);
целое str(source* src);
целое assign(source* src);
целое star(source* src);
целое add_op(source* src);
целое sub_op(source* src);
целое div_op(source* src);
целое band_op(source* src);
целое bor_op(source* src);
целое oper(source* src);
целое point(source* src);
целое argsep(source* src);
целое sep(source* src);
целое Block(source* src);
целое block(source* src);
целое Idx(source* src);
целое idx(source* src);
целое Sub(source* src);
целое sub(source* src);
целое lessth(source* src);
целое bigth(source* src);
целое ws(source* src);

статик пост matcher_table matchers[] = {
	{ real, "real" },
	{ hex, "hex" },
	{ integer, "integer" },
	{ id, "id" },
	{ sl_comm, "sl_comm" },
	{ preproc, "preproc" },
	{ ml_comm, "ml_comm" },
	{ str, "str" },
	{ assign, "assign" },
	{ star, "star" },
	{ add_op, "add_op" },
	{ sub_op, "sub_op" },
	{ div_op, "div_op" },
	{ band_op, "band_op" },
	{ bor_op, "bor_op" },
	{ oper, "oper" },
	{ point, "point" },
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
	{NULL, NULL}
};
статик пост matcher_fn ALL[] = {
	 real,
	 hex,
	 integer,
	 id,
	 sl_comm,
	 preproc,
	 ml_comm,
	 str,
	 assign,
	 star,
	 add_op,
	 sub_op,
	 div_op,
	 band_op,
	 bor_op,
	 oper,
	 point,
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
	NULL
};

целое real(source *src){
	unsigned ch=getch(src); целое matched;
	source old_ctx = *src;
	//matcher for pattern: "%d*"
	
	//pattern: "%d*"
;	match_repopt( (is_charclass_sys_d(ch)) )
;целое has_num=matched;	
		//matcher for pattern: "%.?"
	
	//pattern: "%.?"
;	match_opt(    (0x2E==(ch)) )
;целое has_point=matched;	
		//matcher for pattern: "%d*"
	
	//pattern: "%d*"
;	match_repopt( (is_charclass_sys_d(ch)) )
;	если(!(has_num || matched) )notmatch; 
		//matcher for pattern: "e?"
	
	//pattern: "e?"
;	match_opt(    (0x65==(ch)) )
;
	если(matched){ 	//matcher for pattern: "[+%-]?%d+"
	
	//pattern: "[+%-]?%d+"
;	match_opt(    (is_charclass_usr_1(ch)) )
;	match_rep(    (is_charclass_sys_d(ch)) )
;}иначе{ если( !has_point )notmatch; };
	возврат 0;
}


целое hex(source *src){
	unsigned ch=getch(src); целое matched;
	source old_ctx = *src;
	//matcher for pattern: "0x%h+"
	
	//pattern: "0x%h+"
;	match_single( (0x30==(ch)) )
;	match_single( (0x78==(ch)) )
;	match_rep(    (is_charclass_sys_h(ch)) )
;;
	возврат 0;
}


целое integer(source *src){
	unsigned ch=getch(src); целое matched;
	source old_ctx = *src;
	//matcher for pattern: "%d+"
	
	//pattern: "%d+"
;	match_rep(    (is_charclass_sys_d(ch)) )
;;
	возврат 0;
}


целое id(source *src){
	unsigned ch=getch(src); целое matched;
	source old_ctx = *src;
	//matcher for pattern: "%I+%i*"
	
	//pattern: "%I+%i*"
;	match_rep(    (is_charclass_sys_I(ch)) )
;	match_repopt( (is_charclass_sys_i(ch)) )
;;
	возврат 0;
}

		
целое sl_comm(source *src){
	unsigned ch=getch(src); целое matched;
	source old_ctx = *src;
	//matcher for pattern: "//[^\r\n]*"
	
	//pattern: "//[^\r\n]*"
;	match_single( (0x2F==(ch)) )
;	match_single( (0x2F==(ch)) )
;	match_repopt( (!is_charclass_usr_2(ch)) )
;;
	возврат 0;
}


целое preproc(source *src){
	unsigned ch=getch(src); целое matched;
	source old_ctx = *src;
	//matcher for pattern: "[\n\r]+#%s*%a+"
	
	//pattern: "[\n\r]+#%s*%a+"
;	match_rep(    (is_charclass_usr_4(ch)) )
;	match_single( (0x23==(ch)) )
;	match_repopt( (is_charclass_sys_s(ch)) )
;	match_rep(    (is_charclass_sys_a(ch)) )
;
	// match_while(1, anon_pattern_fn1);
	возврат 0;
}


целое ml_comm(source *src){
	unsigned ch=getch(src); целое matched;
	source old_ctx = *src;
	//matcher for pattern: "/%*"
	
	//pattern: "/%*"
;	match_single( (0x2F==(ch)) )
;	match_single( (0x2A==(ch)) )
;
	match_while(1, anon_pattern_fn2);
	возврат 0;
}


целое str(source *src){
	unsigned ch=getch(src); целое matched;
	source old_ctx = *src;
	//matcher for pattern: """
	
	//pattern: """
;	match_single( (0x22==(ch)) )
;
	целое is_esc=0;
		//matcher for pattern: ".*"
	
	//pattern: ".*"
;	match_repopt( 1 )
если(is_esc){ 
		выбор(ch){
		  // case '"': putchar('"'); break;
		  // case 92: putchar(92); break;
		  // case 110: putchar(10); break;
		  при 13