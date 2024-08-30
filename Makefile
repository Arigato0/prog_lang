RELEASE_FLAGS = -o:speed
DEBUG_MEMORY_FLAG = -define=DEBUG_MEMORY=true
DEBUG_PRINT_FLAGS = -define=DEBUG_TOKENS=true -define=DEBUG_AST=true 

default: run

debug_memory:
	odin run . $(DEBUG_MEMORY_FLAG)

run:
	odin run .

build:
	odin build .

release:
	odin build . $(RELEASE_FLAGS)

debug_print:
	odin run . $(DEBUG_PRINT_FLAGS)
 
