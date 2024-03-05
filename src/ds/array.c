#include "array.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

void array_new(Array *array, size_t elem_size)
{
    if (array == NULL)
    {
        return;
    }

    memset(array, 0, sizeof(Array));

    array->elem_size = elem_size;
}

void array_resize(Array *array, size_t new_size)
{
    if (array == NULL)
    {
        return;
    }

    array->cap = new_size * array->elem_size;

    array->data = realloc(array->data, array->cap);

    if (new_size < array->len)
    {
        array->len = new_size;
    }
}

void array_append(Array *array, void *data)
{
    if (array == NULL)
    {
        return;
    }

    int offset = array->len++ * array->elem_size;

    if (offset >= array->cap)
    {
        array_resize(array, array->len * 2);
    }

    memcpy(array->data + offset, data, array->elem_size);
}

void array_remove(Array *array)
{
    if (array == NULL)
    {
        return;
    }

    array->len--;
}

void array_free(Array *array)
{
    if (array == NULL || array->data == NULL)
    {
        return;
    }

    free(array->data);

    array->data = NULL;
    array->len = 0;
    array->cap = 0;
}

void* array_get(Array *array, size_t index)
{
    if (array == NULL || array->data == NULL)
    {
        return NULL;
    }

    size_t offset = array->elem_size * index;

    void *data = array->data + offset;

    return data;
}

void array_copy(Array *array, void *buffer, size_t index)
{
    if (array == NULL || array->data == NULL)
    {
        return;
    }

    size_t offset = array->elem_size * index;

    memcpy(buffer, array->data + offset, array->elem_size);
}