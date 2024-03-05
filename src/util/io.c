#include "io.h"
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>

const char* read_file(const char *path, int *len)
{
    FILE *file = fopen(path, "r");

    if (file == NULL)
    {
        return NULL;
    }

    struct stat st;

    stat(path, &st);

    char *buff = malloc(st.st_size);

    int read_len = fread(buff, 1, st.st_size, file);

    if (len != NULL)
    {
        *len = read_len;
    }

    return buff;
}