#pragma once 

// reads file into dynamically allocated buffer
// remember to free when done with string
const char* read_file(const char *path, int *len);