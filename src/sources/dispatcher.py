import os

os.environ["TF_CPP_MIN_LOG_LEVEL"] = "0"
os.environ["TF_CPP_MAX_VLOG_LEVEL"] = "0"

import tensorflow as tf

print("scale policy: ", int(os.getenv("SCALE_POLICY", 2)))
dispatcher_config = tf.data.experimental.service.DispatcherConfig(
    port=4444,
    cache_policy=int(os.getenv("CACHE_POLICY", 2)),
    protocol="grpc",
    cache_format=2,
    cache_compression=1,
    cache_ops_parallelism=8,
    cache_path="./outputs/",
    scaling_policy=int(os.getenv("SCALE_POLICY", 2)),
    fault_tolerant_mode=True,
    work_dir="work/",
)
dispatcher = tf.data.experimental.service.DispatchServer(dispatcher_config)
print("> (Dan) The dispatcher address", dispatcher.target)

# Wait until killed
dispatcher.join()
