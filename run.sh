./build.sh

CWD="./tests/"
USE_CWD=true

if [ $? -ne 0 ] 
then 
    exit 0
fi

clear

if [ "$USE_CWD" = true ];
then
    (cd $CWD && ./../builddir/prog)
else 
    ./prog
fi

