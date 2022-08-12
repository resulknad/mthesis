#!/bin/bash
source lib.sh

# source: http://tech.franzone.blog/2008/08/25/bash-script-init-style-status-message/
# Column number to place the status message
RES_COL=70
# Command to move out to the configured column number
MOVE_TO_COL="echo -en \\033[${RES_COL}G"
# Command to set the color to SUCCESS (Green)
SETCOLOR_SUCCESS="echo -en \\033[1;32m"
# Command to set the color to FAILED (Red)
SETCOLOR_FAILURE="echo -en \\033[1;31m"
# Command to set the color back to normal
SETCOLOR_NORMAL="echo -en \\033[0;39m"

# Function to print the SUCCESS status
echo_success() {
    $MOVE_TO_COL
    echo -n "["
    $SETCOLOR_SUCCESS
    echo -n $" OK "
    $SETCOLOR_NORMAL
    echo -n "]"
    echo -ne "\r"
    echo ""
}

# Function to print the FAILED status message
echo_failure() {
    $MOVE_TO_COL
    echo -n "["
    $SETCOLOR_FAILURE
    echo -n $"FAILED"
    $SETCOLOR_NORMAL
    echo -n "]"
    echo -ne "\r"
    echo ""
}

programname=$0

function usage {
    echo "usage: $programname"
    echo "runs all tests"
#    echo "  -f [Cachew service config yaml]"
    exit 1
}

testid=0
function run_test {
  echo -n "$1"
  log_name="${programname}_${testid}_log"
  eval "$2" > "$log_name" 2>&1
  if grep -q "epochs match sorted: False" "$log_name" || ! grep -q "epochs match sorted: True" "$log_name" ; then
    echo_failure
  else
    echo_success
  fi
  testid=$((testid+1))
}


while getopts "h?" opt; do
  case "$opt" in
    h|\?)
      usage
      ;;
  esac
done

print_title "Running all tests"
run_test "Testing w/o any failures" "./func_exp.sh imagenet nofail"
run_test "Testing failure during GET" "./func_exp.sh imagenet getfail"
run_test "Testing failure during PUT" "./func_exp.sh imagenet getfail"
run_test "Testing worker failover" "./func_exp.sh imagenet failover"
run_test "Testing recovering worker" "./func_exp.sh imagenet recover"
run_test "Testing failing dispatcher" "./func_exp.sh imagenet killall"
