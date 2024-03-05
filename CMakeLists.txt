
set(CMAKE_C_STANDARD 99)
add_executable(prog 
    src/main.c 
    src/frontend/lexer.h src/frontend/lexer.c 
    src/ds/array.h src/ds/array.c
    src/util/io.h src/util/io.c)