cut -f7 assembly_summary.txt | sort -u > taxids.txt
cat taxids.txt | xargs -n 1 -P 20 ~/Programs/panDBtest/reprDBscript/xarg_custom_reprDB.sh
