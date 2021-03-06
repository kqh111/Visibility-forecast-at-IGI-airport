#!/bin/bash

# -s,   --sectionFile
#       write the undecoded section string to 'file'
#
# -d,   --date
#       consider the input file to be reading of date provided as argument
#
# -r,   --readingNo
#       GTS files are available every 30 mins(48 files, numbered from 0 to 47). consider the input to be reading of provided argument
#
# -o    --toDB
#        push decoded data to database also. note: if -DSQL was not used during compilation of the program, it will give error
#
# -u,   --sqlusername
#           username with which to log in sql server. note: if -DSQL was not used during compilation of the program, it will give error
#
# -p,   --sqlpassword
#          password of username provided. note: if -DSQL was not used during compilation of the program, it will give error
#
# -p,   --sqldbname
#           database name in which relevant data is stored. note: if -DSQL was not used during compilation of the program, it will give error
#
# -f    --fieldListFile
#           file that contains which fields are to be printed to output
#
# -t    --stationListFile
#           file that contains which stations are to be printed to output
#
# -v    --verbose
#           prints verbose field value

#if 1, 48 files of one day will be concatenated to one file
catCSV=1

#enableSQL=0 disables pushing decodings to database, enableSQL=1 enables it
enableSQL=1

# =1 enables printing verbose field value
enableVerbose=0

# dir where input files are present
initialInputDir="../Input-Output/AfterCat"

# dir where section files are to be written
sectionsDir="../Input-Output/Sections"

# dir where output csv files are be writted
csvDir="../Input-Output/CSV"

fieldListFile="fieldListFile.txt"
stationListFile="stationListFile.txt"

#file where stderror will be redirected
stderror="/dev/null"

rm -Rf "../Input-Output/catCSV/"

# check for existence of sqlDetails.config file
if [ ! -e ./a.out ] ;then
    echo "bash: ./a.out not found. run ./build.sh first"
    exit 1    
elif [ ! -e "../sqlDetails.config" ] ;then
    echo "bash: ../sqlDetails.config not found"
    exit 1
elif [ ! -e "fieldListFile.txt" ] ;then
    echo "bash: fieldListFile.txt not found"
    exit 1
elif [ ! -e "stationListFile.txt" ] ;then
    echo "bash: stationListFile.txt not found"
    exit 1    
elif [ ! -e "./stationData.csvToStationDataHash/stationDataHash" ] ;then
    echo "bash: ./stationData.csvToStationDataHash/stationDataHash not found. first run ./stationData.csvToStationDataHash/build.sh"
    exit 1        
elif [ ! -e "catCSV.sh" ] ;then
    echo "bash: catCSV.sh not found"
    exit 1
fi

#read config
source ../sqlDetails.config

#clean dirs
rm -R -f $sectionsDir/* $csvDir/*
mkdir -p $sectionsDir $csvDir

if [ "$stderror" != "/dev/null" ] ;then
    rm -f "$stderror"
fi


dateDirs=$(ls -v $initialInputDir)
totalFiles=$( echo "$dateDirs" | wc -w )
currentFileNo=1

for currDate in $dateDirs; do
    fileList=$(ls -v $initialInputDir/$currDate)
    readingNo=0
    echo "($currentFileNo/$totalFiles)bash: running for: $currDate"
    currentFileNo=$((currentFileNo+1))
    for x in $fileList; do
        echo $currDate/$x >>"$stderror"
        
        mkdir -p "$sectionsDir/$currDate" "$csvDir/$currDate"
        flag="--readingNo=$readingNo --fieldListFile=$fieldListFile --stationListFile=$stationListFile --sectionFile=$sectionsDir/$currDate/$x --date=$currDate"
        if [ $enableSQL -eq 1 ] ;then
            flag="$flag --sqlusername=$sqlusername --sqlpassword=$sqlpassword --sqldbname=$sqldbname --toDB"
        fi
        
        if [ $enableVerbose -eq 1 ] ;then
            flag="$flag --verbose"
        fi #enableVerbose
        
        ./a.out $flag < "$initialInputDir/$currDate/$x" > "$csvDir/$currDate/$x.csv" 2>>"$stderror"
        
        #if program did not terminate successfully, echo message
        if [ $? -ne 0 ] ;then
            echo "failed for $currDate/$x" >>"$stderror"
        fi
        echo "" >>"$stderror"
        readingNo=$((readingNo + 1))
    done;
done;

#cat csv
if [ $catCSV -eq 1 ] ;then
    echo "started cat csv"
    source catCSV.sh
fi

echo "done"
exit 0
