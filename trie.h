#ifndef __TRIE__H
#define __TRIE__H

// #include "allocator/stack.h"

#include <assert.h>
#include "uthash.h"

#ifdef ENABLE_DEBUG
	#define DEBUG(...) __VA_ARGS__
#else
	#define DEBUG(...) 
#endif


static struct LinearBuffer trieAllocator;


#undef uthash_malloc
#undef uthash_free
#define uthash_malloc(sz) linearAlloc(&trieAllocator, (sz))
#define uthash_free(ptr,sz) 
//linearFree(&trieAllocator, (ptr))





struct TrieNodeChild;

typedef unsigned TrieItemGroupMask;
typedef unsigned KeywordId;

typedef struct TrieNode{
	union{
		struct TrieNodeChild* childs;
		struct TrieNode* ref;
	};
	unsigned type:2, id:20, is_attr:1, is_ref:1, is_keyword:1;
	TrieItemGroupMask item_group_mask;  
	char *str;
} *TrieNode;

struct TrieNodeChild{
	UT_hash_handle hh;
	unsigned key;
	struct TrieNode node;
};


TrieNode trie_node_find(const TrieNode node, unsigned ch){
	if( node->is_ref ) return trie_node_find(node->ref, ch);
	struct TrieNodeChild* child;
	HASH_FIND(hh, node->childs, &ch, sizeof(ch), child);
	return (child ? &(child->node) : NULL);
}

TrieNode trie_node_new(const TrieNode node, unsigned ch){
	assert( !node->is_ref );
	struct TrieNodeChild* child=uthash_malloc(sizeof(*child));
	child->key = ch;
	child->node.childs=NULL;
	child->node.type=0;
	child->node.is_ref=0;
	child->node.is_keyword=0;	
	child->node.str=NULL;
	HASH_ADD(hh, node->childs, key, sizeof(ch), child);
	return &(child->node);
}

TrieNode trie_loop_new(const TrieNode node, unsigned ch){
	assert( !node->is_ref );
	struct TrieNodeChild* child=uthash_malloc(sizeof(*child));
	child->key = ch;
	child->node.ref=node;
	child->node.is_ref=1;
	HASH_ADD(hh, node->childs, key, sizeof(ch), child);
	return &(child->node);
}

TrieNode trie_ref_new(const TrieNode node, unsigned ch, const TrieNode ref){
	assert( !node->is_ref );
	struct TrieNodeChild* child=uthash_malloc(sizeof(*child));
	child->key = ch;
	child->node.ref=ref;
	child->node.is_ref=1;
	HASH_ADD(hh, node->childs, key, sizeof(ch), child);
	return &(child->node);
}

TrieNode trie_new(void){
	TrieNode trie=uthash_malloc(sizeof(struct TrieNode));
	trie->childs=NULL;
	trie->type=3;
	trie->is_ref=0;
	trie->str=NULL;
	return trie;
}

// #undef UTHASH_H
// #undef uthash_malloc
// #undef uthash_free
// #define uthash_malloc(sz) linearAlloc(&trieAllocator, (sz))
// #define uthash_free(ptr,sz) 
// //linearFree(&trieAllocator, (ptr))


#endif // __TRIE__H