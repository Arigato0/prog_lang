#include "trie.h"

#include <stdlib.h>
#include <string.h>

#define TRIE_GET_INDEX(c) (c) - TRIE_ALPHABET_START

TrieNode* trie_new_node()
{
    TrieNode *node = malloc(sizeof(TrieNode));

    for (int i = 0; i < TRIE_ALPHABET_SIZE; i++)
    {
        node->next[i] = NULL;
    }

    return node;
}

void trie_set(TrieNode *root, Keyword *keywords, int keyword_size)
{
    for (int i = 0; i < keyword_size; i++)
    {
        Keyword keyword = keywords[i];

        size_t len = strlen(keyword.str);

        TrieNode *node = root;

        for (int i = 0; i < len; i++)
        {
            char c = TRIE_GET_INDEX(keyword.str[i]);

            node->next[c] = trie_new_node();

            node = node->next[c];
        }

        node->tk_type = keyword.type;
    }
}

TOKEN_TYPE trie_match(TrieNode *root, const char *key)
{
    TrieNode *node = root;
    size_t len = strlen(key);

    for (int i = 0; i < len; i++)
    {
        char c = TRIE_GET_INDEX(key[i]);

        if (node->next[c] == NULL)
        {
            return 0;
        }

        node = node->next[c];
    }

    return node->tk_type;
}

void trie_free(TrieNode *node)
{
    for (int i = 0; i < TRIE_ALPHABET_SIZE; i++)
    {
        if (node->next[i])
        {
            trie_free(node->next[i]);
        }
    }

    free(node);
}