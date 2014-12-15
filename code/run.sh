#!/bin/bash

# Runs all required scripts which generates the tables and graphs for the paper
# Divenyi: The Effect of Retirement on Cognitive Performance

if [ $# -eq 0 ]; then
    echo "Path to folder with raw data was not supplied."
    exit 1
fi

echo -n "Check whether data available... "
waves=(1 2 4)
for wave in "${waves[@]}"
do
    datafiles=$(shopt -s nullglob dotglob; echo $1/w${wave}/*)
    if (( ! ${#datafiles} )); then
        echo "Data files not found!"
        exit 1
    fi
done

if [ ! -f $1/w1/sharew1_rel2-6-0_cv_r.dta ]; then
    echo -e "\nProbably you have other version of the data. The script uses release 2.6.0 for waves 1 and 2 and release 1.0.0 for wave 4."
    exit 1
fi
if [ ! -f $1/w4/sharew4_rel1-0-0_cv_r.dta ]; then
    echo -e "\nProbably you have other version of the data. The script uses release 2.6.0 for waves 1 and 2 and release 1.0.0 for wave 4."
    exit 1
fi
echo -e "OK \n"

echo "Running Stata do files"
echo "----------------------"
STATAPATH=/usr/local/stata13
statafiles=( derive_clean replication_MP replication_B panel_graphs panel_regressions )

echo -n "Running merge.do... "
$STATAPATH/stata -b merge.do $1
echo "Done."

for file in "${statafiles[@]}"
do
    echo -n "Running ${file}.do... "
    $STATAPATH/stata -b $file.do
    echo "Done."
done
