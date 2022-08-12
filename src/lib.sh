#!/usr/bin/env bash
collect_results () {
  grep -B 1 -e "Epoch took" -e "epochs match" logs/pipeline.log
}

wait_for_el_produced () {
  tail -n 0 -f logs/worker_1.log | sed "/i=$1/ q" > /dev/null
  sleep 1
}

wait_for_checkpoint_finished () {
  tail -n 0 -f logs/worker_1.log | sed "/ret val: OK/ q" > /dev/null
  sleep 1
}

wait_for_pipeline () {
  tail --pid=`cat pids/pipeline` -f /dev/null
}

wait_for_epoch_start () {
  tail -n 0 -f logs/pipeline.log | sed '/Starting worker thread/ q' > /dev/null
  sleep 1
}

wait_for_epoch () {
  tail -n 0 -f logs/pipeline.log | sed '/Epoch took/ q' > /dev/null
}

wait_for_second_epoch () {
  tail -n 0 -f logs/pipeline.log | sed '/doing/ q' > /dev/null
}

wait_for_dir_creation () {
  inotifywait -e create outputs/ > /dev/null 2>&1
}

print_title () {
  echo ""
  echo -e "\e[1;44m$1\e[0m"
}

start_worker () {
  echo "starting worker $1 ($2)"
	script -a -q -c "python sources/worker.py -p $(( 40000 + ${1} ))  2>&1" -f logs/worker_${1}${2}.log > /dev/null 2>&1 &
#	script -a -q -c "python sources/worker.py -p $(( 40000 + ${1} ))  2>&1" -f logs/worker_${1}${2}.log > /dev/null 2>&1 &
	echo $! > pids/worker_${1}
}

kill_worker () {
  echo "killing worker $1"
  kill `cat pids/worker_$1`
}

start_dispatcher () {
  echo "starting dispatcher"
  script -q -c "python sources/dispatcher.py 2>&1"  -f logs/dispatcher.log > /dev/null 2>&1 &
  echo $! > pids/dispatcher
}

kill_dispatcher () {
  echo "killing dispatcher"
  kill `cat pids/dispatcher`
}
