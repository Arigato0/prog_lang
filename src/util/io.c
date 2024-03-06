#include "io.h"
#include "ds/array.h"
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>

void read_file(const char *path, Array *buffer)
{
    FILE *file = fopen(path, "r");

    if (file == NULL)
    {
        return;
    }

    struct stat st;

    stat(path, &st);

    array_resize(buffer, st.st_size);

    buffer->len = fread(buffer->data, 1, st.st_size, file);
}