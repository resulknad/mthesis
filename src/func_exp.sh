#!/usr/bin/env bash


export DBK_GET_ELEMENT_TIMEOUT=20000000
export DBK_CHECKPOINT_DIR=checkpoints/
export DBK_CHECKPOINT_FREQ_MS=2000
export DBK_WORKER_TIMEOUT=20
# kill all descendents when we are done...
rm -rf work/
rm -rf outputs/
rm -rf checkpoints/
rm -rf experiments/
./kill_service.sh
trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT
trap "exit" INT

source lib.sh


programname=$0

function usage {
    echo "usage: $programname [simclr/retinanet/imagenet/artificial] [recover/failover/killall/nofail/getfail/putfail]"
    exit 1
}


if [[ "$1" == "artificial" ]]; then
  PIPELINE="pipeline.py"
  WAIT_FOR=4
  out_dir="func_exp/artificial_w1_fails_$2"
elif [[ "$1" == "imagenet" ]]; then
  PIPELINE="resnet_pipeline.py"
  WAIT_FOR=20
  out_dir="func_exp/imagenet_w1_fails_$2"
elif [[ "$1" == "simclr" ]]; then
  PIPELINE="simclr_pipeline.py"
  WAIT_FOR=10
  out_dir="func_exp/simclr_w1_fails_$2"
elif [[ "$1" == "retinanet" ]]; then
  PIPELINE="retinanet_pipeline.py"
  WAIT_FOR=10
  out_dir="func_exp/retinanet_w1_fails_$2"
else
  usage
fi

# second param: failover worker or not
KILLALL=0
NO_WORKERS=3

# how many epochs to wait at the end
WAIT_EPOCHS=2

# make something fail?
FAILURE=2

# by default do not scale or cache
export SCALE_POLICY=2
export CACHE_POLICY=2

KILLALLWORKERS=0

if [[ "$2" == "failover" ]]; then
  NO_WORKERS=1
  START_WORKER=3
export DBK_CHECKPOINT_FREQ_MS=5000
elif [[ "$2" == "recover" ]]; then
  NO_WORKERS=1
  START_WORKER=1
export DBK_CHECKPOINT_FREQ_MS=5000
elif [[ "$2" == "killall" ]]; then
  KILLALLWORKERS=1
  KILLDISPATCHER=1
export DBK_CHECKPOINT_FREQ_MS=5000
elif [[ "$2" == "nofail" ]]; then
  export CACHE_POLICY=3
  START_WORKER=1
  NO_WORKERS=3
  FAILURE=0
elif [[ "$2" == "putfail" ]]; then
  # first epoch put, 2nd get
  export CACHE_POLICY=3
  FAILURE=1
  NO_WORKERS=3
  KILLALLWORKERS=1
elif [[ "$2" == "getfail" ]]; then
  # first epoch put, 2nd get
  export CACHE_POLICY=3
  export DBK_CHECKPOINT_FREQ_MS=5000
  START_WORKER=1
  NO_WORKERS=2
  FAILURE=2
  KILLALLWORKERS=1
else
  usage
fi



print_title "Experiment with out dir $out_dir ($2)"
mkdir -p $out_dir
rm $out_dir/*.log
truncate -s0 logs/*
touch logs/dispatcher.log
touch logs/pipeline.log
touch logs/worker_1.log
touch logs/worker_2.log
touch logs/worker_3.log

# setting up log filters for what is relevant
script -q -c 'tail -f --retry logs/dispatcher.log -n 0 | grep -i -e just_reconnected -e recovery -e "serving split"' -f $out_dir/dispatcher.log >/dev/null &
script -q -c 'tail -f --retry logs/pipeline.log -n 0 | grep -i -e skipping' -f $out_dir/pipeline.log > /dev/null &
script -q -c 'tail -f --retry logs/worker_1.log -n 0 | grep -i -e produced -e registered' -f $out_dir/worker_1.log > /dev/null &
script -q -c 'tail -f --retry logs/worker_2.log -n 0 | grep -i -e produced -e registered' -f $out_dir/worker_2.log > /dev/null &
script -q -c 'tail -f --retry logs/worker_3.log -n 0 | grep -i -e produced -e registered' -f $out_dir/worker_3.log > /dev/null &



export DBK_TARGET_WORKERS=$NO_WORKERS
./start_service.sh $NO_WORKERS $PIPELINE
if [[ "$FAILURE" != "0" ]]; then
    #kill_worker 3 &
    #kill_worker 2 &
    #TODO: testcase with this worker failing here
    # dispatcher needs to remove timed out workers from
    # avail workers...
    #kill_worker 2

    if [[ "$FAILURE" == 2 ]]; then
      echo "Waiting until first epoch is completed. Failing in 2nd epoch."
      wait_for_epoch
      echo "first completed"
    else
      echo "not waiting for first epoch. failing in first epoch"
    fi

    echo "waiting for some el to be produced"
    wait_for_el_produced $WAIT_FOR

    echo "wait for checkpoint"
    wait_for_checkpoint_finished

    if [[ "$KILLDISPATCHER" == "1" ]]; then
      kill_dispatcher
    fi

    if [[ "$KILLALLWORKERS" == "1" ]]; then
      for ((i=1; i<=$NO_WORKERS; i++))
      do
        kill_worker $i
      done
    else
      kill_worker 1
    fi

    sleep 5

    if [[ "$KILLDISPATCHER" == "1" ]]; then
      start_dispatcher
      sleep 5
    fi

    if [[ "$KILLALLWORKERS" == "1" ]]; then
      for ((i=1; i<=$NO_WORKERS; i++))
      do
        start_worker $i
      done
    else
      start_worker $START_WORKER
    fi

    # wait_for_checkpoint_finished
    # kill_worker 1
    # sleep 1
    # start_worker 1
fi

for ((i=0; i<$WAIT_EPOCHS; i++))
do
    echo "waiting for next epoch to finish... ($i)"
    wait_for_epoch
done

sleep 3
# echo "waiting for next epoch to finish..."
# wait_for_epoch
# sleep 1

print_title "$out_dir"
collect_results | tee -a $out_dir/epochs.log

cp -r logs $out_dir/raw
./kill_service.sh
sleep 1
