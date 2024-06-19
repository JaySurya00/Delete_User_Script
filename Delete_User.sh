!/bin/bash

function get_answer {
unset ANSWER
ASK_COUNT=0

while [ -z "$ANSWER" ]
do
	ASK_COUNT=$[ $ASK_COUNT + 1 ]
	case $ASK_COUNT in
		2)
			echo
			echo "Please answer the question"
			echo
			;;
		3)
			echo
			echo "One last try...please answer the question."
			echo
			;;
		4)
			echo
			echo "Answer not provided"
			echo "exiting the program"
			exit
			;;
	esac
	echo
	if [ -n "$LINE2" ]
	then
		echo $LINE1
		echo -e $LINE2" \c"
	else
		echo -e $LINE1" \c"
	fi
	read -t 60 ANSWER
	unset LINE1
	unset LINE2
done
}

###########################################################

function process_answer {

case $ANSWER in
	y|Y|YES|yes|Yes|yEs|yeS|yES)
		;;
	*)
		echo
		echo $EXIT_LINE1
		echo $EXIT_LINE2
		echo
		exit
esac
unset EXIT_LINE1
unset EXIT_LINE2

}

#########################################################################

echo "Step #1 - Determine User Account name to Delete "
echo
LINE1="Please enter the username of the user "
LINE2="account you wish to delete from system:"
get_answer
USER_ACCOUNT=$ANSWER
LINE1="Is $USER_ACCOUNT the user account "
LINE2="you wish to delete from the system [y/n] ?"
get_answer

EXIT_LINE1="Because the account, $USER_ACCOUNT, is not "
EXIT_LINE2="the one you wish to delete, we are leaving the script..."
process_answer

####################################

USER_ACCOUNT_RECORD=$(cat /etc/passwd | grep -w $USER_ACCOUNT)
if [ $? -eq 1 ]
then
	echo
	echo "Account, $USER_ACCOUNT, not found,"
	echo "Leaving the script..."
	echo
	exit
fi

echo
echo "I found this record:"
echo $USER_ACCOUNT_RECORD

LINE1="Is this the correct User Account? [y/n]"
get_answer

EXIT_LINE1="Because the account, $USER_ACCOUNT, is not "
EXIT_LINE2="the one you wish to delete, we are leaving the script..."
process_answer

###########################################################

echo
echo "Step #2 - Find process on system belonging to user account"
echo

ps -u $USER_ACCOUNT >/dev/null

case $? in
	1)
		echo "There is no process running for this User Account"
		echo
		;;
	0)
		echo "$USER_ACCOUNT has the following processes running: "
		echo
		ps -u $USER_ACCOUNT
		LINE1="Would you like me to kill the process(es)? [y/n]"
		get_answer
		case $ANSWER in
			y|Y|YES|yes|Yes|yEs|yeS|YEs|yES )
				echo
				echo "Killing off process(es)..."
				COMMAND_1="ps -u $USER_ACCOUNT --no-heading"
				COMMAND_3="xargs -d \\n /usr/bin/sudo /bin/kill -9"
				$COMMAND_1 | awk '{ print $1 }' | $COMMAND_3
				echo
				echo "Process(es) killed."
				;;
			*)
				echo
				echo "Will not kill the process(es)"
				echo
				;;
		esac
		;;
esac

############################################################################

echo "Step #3 - Find files on system belonging to user account"
echo
echo "Creating a report of all files owned by $USER_ACCOUNT."
echo
echo "It is recommended that you backup the files,"
echo "and then do one of the two things:"
echo " 1) Delete the files"
echo " 2) Change the files' ownership to current user account."
echo
echo "Please wait. This may take a while..."

REPORT_DATE=$(date +%y%m%d)
REPORT_FILE=$USER_ACCOUNT"_Files_"$REPORT_DATE".rpt"

find / -user $USER_ACCOUNT > $REPORT_FILE 2>/dev/null

echo
echo "Report is complete."
echo "Name of report: $REPORT_FILE"
echo "Location of report: $(pwd)"
echo

########################################

echo
echo "Step #4 - Remove user account"
echo

LINE1="Remove $USER_ACCOUNT's account from system? [y/n]"
get_answer

EXIT_LINE1="Since you do not wish to remove the user account,"
EXIT_LINE2="$USER_ACCOUNT at this time, exiting the script..."

process_answer

sudo userdel $USER_ACCOUNT
if [ $? -eq 0 ]
then
	echo
	echo "User account, $USER_ACCOUNT, has been removed."
	echo
fi
exit
