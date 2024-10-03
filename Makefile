SOURCE_DIR = ./src/
PROGRAM_NAME = -out:prog
RELEASE_FLAGS = -o:speed -warnings-as-errors
DEBUG_FLAGS = -debug -o:none
DEBUG_MEMORY_FLAG = -define=DEBUG_MEMORY=true
DEBUG_PRINT_FLAGS = -define=DEBUG_TOKENS=true -define=DEBUG_AST=true $(DEBUG_MEMORY_FLAG)

default: build

debug_memory:
	odin run $(SOURCE_DIR) $(PROGRAM_NAME) $(DEBUG_MEMORY_FLAG)

run:
	odin run $(SOURCE_DIR) $(PROGRAM_NAME) 

build:
	odin build $(SOURCE_DIR) $(PROGRAM_NAME) $(DEBUG_FLAGS)

release:
	odin build $(SOURCE_DIR) $(PROGRAM_NAME) $(RELEASE_FLAGS)

debug_print:
	clear
	odin run $(SOURCE_DIR) $(PROGRAM_NAME) $(DEBUG_PRINT_FLAGS)
 
