SOURCE_DIR = ./src/
RELEASE_FLAGS = -o:speed -warnings-as-errors
DEBUG_FLAGS = -debug -o:none
DEBUG_MEMORY_FLAG = -define=DEBUG_MEMORY=true
DEBUG_PRINT_FLAGS = -define=DEBUG_TOKENS=true -define=DEBUG_AST=true $(DEBUG_MEMORY_FLAG)

default: run

debug_memory:
	odin run $(SOURCE_DIR) $(DEBUG_MEMORY_FLAG)

run:
	odin run $(SOURCE_DIR)

build:
	odin build $(SOURCE_DIR) $(DEBUG_FLAGS)

release:
	odin build $(SOURCE_DIR) $(RELEASE_FLAGS)

debug_print:
	clear
	odin run $(SOURCE_DIR) $(DEBUG_PRINT_FLAGS)
 
