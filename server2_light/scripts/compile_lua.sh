#! /bin/sh

cd /home/jh/ddev/cw/lua
rm */*.luac
cd base
ls *.lua|awk '{print "../luac -o",$1"c",$1}'|sh
cd ../cell
ls *.lua|awk '{print "../luac -o",$1"c",$1}'|sh
cd ../common
ls *.lua|awk '{print "../luac -o",$1"c",$1}'|sh

