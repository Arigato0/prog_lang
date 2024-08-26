project('prog', 'c')

compiler = meson.get_compiler('c')

incdir = include_directories('src/')

executable(
  'prog',
  [
    'src/main.c',
    'src/frontend/lexer.h',
    'src/frontend/lexer.c',
    'src/frontend/parser.h',
    'src/frontend/parser.c',
    'src/ds/array.h',
    'src/ds/array.c',
    'src/ds/trie.h',
    'src/ds/trie.c',
    'src/util/io.h',
    'src/util/io.c',
  ],
  include_directories: incdir,
  c_args: [],
)
