#include <stdio.h>
#include <assert.h>

#include "lex-pp.h"

#include "uthash.h"
struct Symbol;
typedef struct Ident{
	UT_hash_handle hh;
	const char *name;
	struct Symbol *symbol;
	int index:20, is_untransl:1;
} *Ident;

typedef struct IdentUndef{
	UT_hash_handle hh;
	const char *name;
} *IdentUndef;

typedef struct Symbol{
	UT_hash_handle hh;
	Ident idents[2];
	int id;
} *Symbol;

int get_next_token1(source *src, const matcher_fn matchers[]){
	// struct TrieNodeChild* child;
	// HASH_FIND(hh, node->childs, &ch, sizeof(ch), child);
	int res_i=0;
	if( is_eof(src) ) return -1;
	for(int i=0; matchers[i]; i++){
		if( (res_i=matchers[i](src)) ){
			return res_i==-1 ? i : res_i;
		} 
	}
	return -2;
}


	

Ident ident_db = NULL;
IdentUndef undef_db = NULL;
Symbol sym_db = NULL;

int fread_symbols(const char* src_file, int index){ //FILE *f
	// char data[200000];
	// const char* s=data; 
	// FILE* f = fopen(src_file, "r");
	// 
	// if(!f){
	// 	printf("can't open test source code file: \"%s\"\n", src_file);
	// 	return 7;
	// }
	// 
	// size_t l = fread(data, 1, sizeof(data)-1, f);
	// data[l] = 0;
	// const char * se=data+l;
	// source src = new_source(s, se);
	// nextch(&src);
	// source src_prev = src;
	source src;
	new_source_from_file(src_file, &src);
	source src_prev = src;
	int i;

	while ( (i=get_next_token1(&src, ALL))>=0 ){
		if(i!=tokid_id){
			fprintf(stderr, "%3d:%3d\tSyntax error: need keyword literal, got %d (\"%.*s\")\n", 
				src_prev.line, src_prev.pos, i, src.s-src_prev.s, src_prev.s); 
			return 6;
		}
		Ident ident;
		HASH_FIND(hh, ident_db, src_prev.s, src.s-src_prev.s, ident);
		if(ident){
			fprintf(stderr, "%3d:%3d\tSyntax error: conflict keywords names \"%.*s\"[%d] already defined\n", 
				src_prev.line, src_prev.pos, src.s-src_prev.s, src_prev.s, ident->symbol->id); 
			return 5;
		}
		char c = *(src.s);
		*(char *)(src.s) = 0;
		ident = (Ident)malloc(sizeof(struct Ident));
		ident->name = strdup(src_prev.s);
		*(char *)(src.s) = c;
		src_prev = src;
		
		if( (i=get_next_token1(&src, ALL))<0 ) break;
		if(i!=tokid_ws){
			fprintf(stderr, "%3d:%3d Syntax error: need ws after keyword literal, got %d (\"%.*s\")\n", 
				src_prev.line, src_prev.pos, i, src.s-src_prev.s, src_prev.s); 
			free((char *)ident->name);
			free(ident);
			return 4;
		}
		src_prev = src;
		
		if( (i=get_next_token1(&src, ALL))<0 ) break;
		if(i!=tokid_integer){
			fprintf(stderr, "%3d:%3d\tSyntax error: need keyword id, got %d (\"%.*s\")\n", 
				src_prev.line, src_prev.pos, i, src.s-src_prev.s, src_prev.s); 
			free((char *)ident->name);
			free(ident);
			return 3;
		}
		c = *(src.s); *(char *)(src.s) = 0;
		int id = atoi(src_prev.s);
		*(char *)(src.s) = c; src_prev = src;
		src_prev = src;
		
		Symbol sym;
		HASH_FIND_INT(sym_db, &(id), sym);
		if(!sym){
			sym = calloc(1, sizeof(*sym));
			sym->id = id;
			HASH_ADD_INT(sym_db, id, sym);
		}
		
		sym->idents[index] = ident;
		ident->symbol = sym;
		ident->index = index;
		HASH_ADD_KEYPTR( hh, ident_db, ident->name, strlen(ident->name), ident);
		
		if( (i=get_next_token1(&src, ALL))<0 ) break;
		if(i!=tokid_ws){
			fprintf(stderr, "%3d:%3d\tSyntax error: need ws after keyword id, got %d (\"%.*s\")\n", 
				src_prev.line, src_prev.pos, i, src.s-src_prev.s, src_prev.s); 
			return 1;
		}
		src_prev = src;
	}

	if(i!=-1){
		fprintf(stderr, "Unknown token, started at: %3d:%3d\n\"%.*s\"\n", 
			src_prev.line, src_prev.pos, src.se-src.s>10 ? 10 : src.se-src.s , src.s);
		return 2;
	}
	return 0;
}

#include <alloca.h>

int main(int argc, const char * argv[]){
	
	if(argc<=1){
		fprintf(stderr, "require source file\n");
		return -1;
	}
	// char data[400000];
	// const char* s=data; 	// FILE* f = fopen(argv[1], "r");
	// 
	// if(!f){
	// 	fprintf(stderr, "can't open test source code file: \"%s\"\n", argv[1]);
	// 	return -1;
	// }
	// 
	// size_t l = fread(data, 1, sizeof(data)-1, f);
	// data[l] = 0;
	// const char * se=data+l;
	source src;// = new_source(s, se);
	new_source_from_file(argv[1], &src);
	source src_prev = src;
	
	int pcs=-1; unsigned ch;
	printf("%x, %x\n",   2>>5,3>>5);
// assert((punct2&punctuation) && (punctuation & punct1));

	for(int cs=charclass_id(ch=getch(&src)); !is_eof(&src); pcs=cs, cs=charclass_id(ch=nextch(&src)) )
	//	if(pcs!=cs) 
		printf("`%c` \t 0x%-6x \t [%c%c%c%c%c%c%c]\n", ch, ch,
			cs & ident_first ? (assert(cs&ident_next), 'I') : ' ', 
			cs & ident_next ? (assert((cs&digit)^(cs&ident_first)), 'i') : ' ', 
			cs & digit ? (assert((cs&hex_digit)&&(cs&ident_next)), 'd') : ' ', 
			cs & hex_digit ? (assert((cs&digit)^(cs&ident_next&&cs&ident_first)), 'x') : ' ', 		
			cs & white_space ? (assert((cs&white_space)==white_space), 'w') : ' ',
			(cs & punctuation ? 'p' : ' '), 
			((cs & punctuation) ? (((cs & punctuation)>>5)+'0') : ' ')
			
		);
	src=src_prev;
	
	
	int i;
	fread_symbols("kwrd-en.txt", 1);
	fread_symbols("kwrd-ru.txt", 0);

	if(!ident_db){
		fprintf(stderr, "Error in keywords file\n");
		return -2;
	}

	FILE* f_undef, *f_untrans, *f_out;
	assert(f_undef = fopen("test\\undefined.list", "w+"));
	assert(f_untrans = fopen("test/untranslated.list", "w+"));
	assert(f_out = fopen(argc<3 ? "out.c" : argv[2], "w+"));


	while ( (i=get_next_token1(&src, ALL))>=0 ){
		if(i==tokid_id){ // ident or keyword
			Ident ident;
			HASH_FIND(hh, ident_db, src_prev.s, src.s-src_prev.s, ident);
				if(ident){ // ident
					if(ident->index){
						if(ident->symbol->idents[0]){
	 						printf ("%3d:%3d\t kw[%6d]   \"%s\" \"%.*s\"\n", src_prev.line, src_prev.pos, 
	 							ident->symbol->id, ident->symbol->idents[0]->name, src.s-src_prev.s, src_prev.s);
	 						fprintf(f_out, "%s", ident->symbol->idents[0]->name);
	 					}else{
	 						printf ("%3d:%3d\t kw[%6d]   (untranslated) \"%.*s\"\n", src_prev.line, src_prev.pos, 
	 							ident->symbol->id, src.s-src_prev.s, src_prev.s);	
	 						fprintf(f_out, "%.*s", src.s-src_prev.s, src_prev.s);
	 						if(ident->is_untransl==0){
		 						fprintf(f_untrans, "%.*s\t%d\n", src.s-src_prev.s, src_prev.s, ident->symbol->id);	
		 						ident->is_untransl = 1; //fixme
	 						}
	 					}
					}else{
						fprintf(f_out, "%.*s", src.s-src_prev.s, src_prev.s);
						printf ("%3d:%3d\t kw[%6d]   \"%.*s\"\n", src_prev.line, src_prev.pos, 
							ident->symbol->id, src.s-src_prev.s, src_prev.s); 
					}
				}else{
					fprintf(f_out, "%.*s", src.s-src_prev.s, src_prev.s);
					IdentUndef undef;
					HASH_FIND(hh, undef_db, src_prev.s, src.s-src_prev.s, undef);
					if(!undef){
					char c = *(src.s); *(char *)(src.s) = 0;
						undef = malloc(sizeof(struct IdentUndef));
	 					undef->name = strdup(src_prev.s); *(char *)(src.s) = c;
						HASH_ADD_KEYPTR( hh, undef_db, undef->name, strlen(undef->name), undef);
	
						printf ("%3d:%3d\t undefined \"%.*s\"\n", src_prev.line, src_prev.pos, 
							src.s-src_prev.s, src_prev.s);	
		 				fprintf(f_undef, "%.*s\n", src.s-src_prev.s, src_prev.s);		
	 				}
				}
		}else if(i!=tokid_ws){
			printf ("%3d:%3d\t %10s   \"%.*s\"\n", 
				src_prev.line, src_prev.pos, matchers[i].name, src.s-src_prev.s, src_prev.s); 
			fprintf(f_out, "%.*s", src.s-src_prev.s, src_prev.s);
		}else
			fprintf(f_out, "%.*s", src.s-src_prev.s, src_prev.s);
		src_prev = src;
	}
	
	if(i!=-1) fprintf(stderr, "Unknown token, started at: %3d:%3d\n\"%.*s\"\n", src_prev.line, src_prev.pos, src.se-src.s>10 ? 10 : src.se-src.s , src.s);

	return 1;
}
