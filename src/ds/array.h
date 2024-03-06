#pragma once

#include <stddef.h>

typedef struct 
{
    void *data;
    size_t elem_size;
    size_t len;
    size_t cap;
} Array;

void array_new(Array *array, size_t elem_size);

void array_reserve(Array *array, size_t cap);

void array_resize(Array *array, size_t new_size);

void array_append(Array *array, void *data);

void array_remove(Array *array);

void array_free(Array *array);

void* array_get(Array *array, size_t index);

void array_copy(Array *array, void *buffer, size_t index);