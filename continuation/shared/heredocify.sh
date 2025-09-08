#!/bin/bash

FILE=$1

#sed -i -e 's/[^a-zA-Z0-9,._+@%/-]/\\&/g; 1{$s/^$/""/}; 1!s/^/"/; $!s/$/"/' $FILE
#sed -i -e 's/[^a-zA-Z0-9,._+@%/-]/\\&/g' $FILE
# sed -i -e 's/[$"`]/\\&/g' $FILE
# sed -i -e 's/\$/\\&/g' $FILE
# sed -i -e "s/'/\\&/g" $FILE
sed -i -e 's/\$/\\&/g' $FILE
sed -i -e 's/["'\''`]/"&/' $FILE
sed -i -e '/"/ s/$/"/' $FILE
