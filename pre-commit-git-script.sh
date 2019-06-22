#!/bin/sh

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
no_color='\033[0m'

PROJECT=`php -r "echo dirname(dirname(dirname(realpath('$0'))));"`
STAGED_FILES_CMD=`git diff --cached --name-only --diff-filter=ACMR HEAD | grep \\\\.php`
SONAR_STAGED_FILES_CMD=`git diff --cached --name-only --diff-filter=ACMR HEAD | grep '\.php\|\.ts\|\.js\|\.css\|\.html'`

# Determine if a file list is passed
if [ "$#" -eq 1 ]
then
    oIFS=$IFS
    IFS='
    '
    SFILES="$1"
    SSFILES="$1"
    IFS=$oIFS
fi
SFILES=${SFILES:-$STAGED_FILES_CMD}
SSFILES=${SSFILES:-$SONAR_STAGED_FILES_CMD}

# PHP lint Scanning
#echo "\n${yellow}Checking PHP Lint...${red}"
for FILE in $SFILES
do
    #php -l -d display_errors=0 $PROJECT/$FILE
    if [ $? != 0 ]
    then
        echo "\n${red}Fix the error before commit."
        exit 1
    fi
    FILES="$FILES $PROJECT/$FILE"
done

# Sonar Scanning
for SCANFILE in $SSFILES
do
    echo "File name : "
    echo $SCANFILE
    SCANFILES="$SCANFILES$PROJECT/$SCANFILE,"
done

echo "Running Sonar Scanner to generate the result of coding standard report.."
sonar-scanner -Dsonar.projectKey=TestCode -Dsonar.sources=$SCANFILES -Dsonar.host.url=http://localhost:8000 -Dsonar.login=d91fc0b5f1eedb7ea3e6c61ff7831875a4ad1831

# PHPCBF, PHPCS Scanning
if [ "$FILES" != "" ]
then
    echo "${yellow}Running PHPBF for automatically fix issues.."
    echo "/usr/bin/phpcbf $FILES"
    /usr/bin/phpcbf $FILES
    echo "\n${yellow}Running PHP Code Sniffer.. Code Standard PSR2.${no_color}${red}"
    /usr/bin/phpcs --standard=PSR2 --encoding=utf-8 -p $FILES
    if [ $? != 0 ]
    then
        echo "\n${red}Fix the error(s) before commit!\n"
        exit 1
    fi
fi
    
exit $?
