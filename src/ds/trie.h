#pragma once

#include <stdbool.h>
#include "frontend/lexer.h"

// trie (prefix tree) for alphabetical keyword lookups
#define TRIE_ALPHABET_START 'A'
#define TRIE_ALPHABET_END 'z'
#define TRIE_ALPHABET_SIZE TRIE_ALPHABET_END - TRIE_ALPHABET_START


typedef struct 
{
    const char *str;
    TOKEN_TYPE type;
} Keyword;

typedef struct
{
    void *next[TRIE_ALPHABET_SIZE];
    TOKEN_TYPE tk_type;
} TrieNode;

TrieNode* trie_new_node();
void trie_set(TrieNode *root, Keyword *keywords, int keyword_size);

TOKEN_TYPE trie_match(TrieNode *root, const char *key);

void trie_free(TrieNode *root);