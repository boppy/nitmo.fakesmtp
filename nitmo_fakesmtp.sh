#!/bin/bash

LOG_UNKNOWN_COMMANDS="/tmp/nitmoMail_unknown_commands.log"
SENDLOG_PATH="/tmp/nitmoMail"

sender(){
    from=$1
    to=$2
    subject=$3
    text=$4
    headers=$5
    
    # Set TO host to include @log or +log to log the email in $SENDLOG_PATH. Ex: test@log / hello_world@example+log.com
    if [[ "$to" == *@log* ]] || [[ "$to" == *+log* ]]; then
        date=$(date '+%Y-%m-%d')
        datetime=$(date '+%Y-%m-%d %H:%M:%S')

        [ -d $SENDLOG_PATH ] || mkdir -p $SENDLOG_PATH
        file="${SENDLOG_PATH}/${date}.log"

        echo "${datetime}${NL}  ${subject} [F: ${from} | T: ${to}]" >> $file
        while read -r line; do
            echo "  > $line" >> $file
        done <<< $text
        echo "" >> $file
    fi

    # Set TO host to include @drop or +drop to not do any further. Ex: test@log+drop / hello_world@drop.de.vu
    ([[ "$to" == *@drop* ]] || [[ "$to" == *+drop* ]]) && return
    
    
    # Send Message using the telegram-send installed from pip
    #   See https://www.rahielkasim.com/telegram-send/
    #   pip install telegram-send
    if [[ "$to" == telegram@* ]]; then
        send="*${subject}*${NL}${NL}${text}"
        /usr/bin/telegram-send --format markdown "$send"
    fi
    
    # Forward the message to any other type of script, binary, that-so-ever.
    if [[ "$to" == push@* ]]; then
        send="${subject}${NL}${NL}${text}"
        # Using this litte helper: https://github.com/ivkos/Pushbullet-for-PHP
        php /usr/boppy/bin/pushbullet.php "N5X" "$send"
    fi

}












################################################################################
# Library Code starts here. You shouldn't change anything beyond...
################################################################################
trim() {
    echo -e "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

NL="
"
################################################################################
# SMTP Server
################################################################################
echo '220 nitmo mail relay';

receiveData=0
allowFinalize=0
allowBody=0

from=""
to=""
header=""
body=""
subject=""

while true; do 
    if [ $receiveData -eq 0 ]; then
        read -r arg1 arg2 rest
        arg1=$(trim "$arg1")
        arg2=$(trim "$arg2")
        rest=$(trim "$rest")
        
        arg1=$(echo "$arg1" | tr '/a-z/' '/A-Z/')
        if [ "$arg1" = "HELO" ] || [ "$arg1" = "EHLO" ]; then
            echo '250 HELO faithful employee'
        elif [ "$arg1" = "MAIL" ] && [ "$arg2" = "FROM:" ]; then
            from=$rest
            echo '250 2.1.0 Ok'
        elif [ "$arg1" = "RCPT" ] && [ "$arg2" = "TO:" ]; then
            to=$rest
            echo '250 2.1.5 Ok'
        elif [ "$arg1" = "DATA" ]; then
            receiveData=1;
            echo '354 Ok Send data ending with <CRLF>.<CRLF>';
        elif [ "$arg1" = "QUIT" ]; then
            echo '221 2.0.0 Bye faithful employee';
            exit
        else
            echo "502 5.5.2 Error: command not recognized"
            if [ ! -z "$LOG_UNKNOWN_COMMANDS" ]; then
                cur=$(date "+%Y-%m-%d %H:%M:%S")
                echo -e "${cur}: °${arg1}° °${arg2}° °${rest}°" >> $LOG_UNKNOWN_COMMANDS
            fi
        fi
    else
        read -r arg1 input2
        arg1=$(trim "$arg1")
        input2=$(trim "$input2")
        input="$arg1 $input2"
        
        if [ $allowBody -eq 0 ]; then
            if [ "$header" = "" ]; then
                header=$input
            else
                [ "$arg1" = "" ] && allowBody=1
                [ "$arg1" = "Subject:" ] && subject=$input2
                
                header="${header}${NL}${input}"
            fi
        else
            if [ $allowFinalize -eq 1 ] && [ "$input" = ". " ]; then
                receiveData=0
                
                sender "$from" "$to" "$subject" "$body" "$header"
                echo '250 2.0.0 Ok: queued as '$(od -vN 10 -An -tx1 /dev/urandom | tr -d " \n")
            elif [ "$body" = "" ]; then
                body=$input
            else
                if [ "$input" = " " ]; then
                    allowFinalize=1
                else
                    allowFinalize=0
                fi
                
                body="${body}${NL}${input}"
            fi
        fi
    fi
done