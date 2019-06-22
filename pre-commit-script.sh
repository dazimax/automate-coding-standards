#!/bin/sh

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
no_color='\033[0m'

PROJECT=`php -r "echo dirname(dirname(dirname(realpath('$0'))));"`
STAGED_FILES_CMD=`git diff --cached --name-only --diff-filter=ACMR HEAD | grep \\\\.php`

# Determine if a file list is passed
if [ "$#" -eq 1 ]
then
    oIFS=$IFS
    IFS='
    '
    SFILES="$1"
    IFS=$oIFS
fi
SFILES=${SFILES:-$STAGED_FILES_CMD}

echo "\n${yellow}Checking PHP Lint..."
for FILE in $SFILES
do
    php -l -d display_errors=0 $PROJECT/$FILE
    if [ $? != 0 ]
    then
        echo "\n${no_color}${red}Fix the error before commit."
        exit 1
    fi
    FILES="$FILES $PROJECT/$FILE"
done

if [ "$FILES" != "" ]
then
    echo "\n${yellow}Running PHP Code Sniffer. Code Standard PSR2.${no_color}${red}"
    /usr/bin/phpcs --standard=PSR2 --encoding=utf-8 -p $FILES
    if [ $? != 0 ]
    then
        echo "\n${red}Fix the error(s) before commit!\n"
        echo "${yellow}Running PHPBF for automatic fix"
        echo "/usr/bin/phpcbf $FILES"
        /usr/bin/phpcbf $FILES
        exit 1
    fi
fi

exit $?
