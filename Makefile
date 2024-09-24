RELEASE_FLAGS = -o:speed -warnings-as-errors
DEBUG_FLAGS = -debug -o:none
DEBUG_MEMORY_FLAG = -define=DEBUG_MEMORY=true
DEBUG_PRINT_FLAGS = -define=DEBUG_TOKENS=true -define=DEBUG_AST=true $(DEBUG_MEMORY_FLAG)

default: run

debug_memory:
	odin run . $(DEBUG_MEMORY_FLAG)

run:
	odin run .

build:
	odin build . $(DEBUG_FLAGS)

release:
	odin build . $(RELEASE_FLAGS)

debug_print:
	clear
	odin run . $(DEBUG_PRINT_FLAGS)
 
