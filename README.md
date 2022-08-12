![cachew-logo](https://github.com/resulknad/mthesis/raw/main/res/cachew_logo.png)

[ [Cachew](https://github.com/eth-easl/cachew#readme) ] | [ [Presentation](https://github.com/resulknad/mthesis/raw/main/res/presentation.pdf) ] | [ [Report](https://github.com/resulknad/mthesis/raw/main/res/report.pdf) ] | [ [Code](https://github.com/resulknad/ml-input-data-service/tree/dkluser/fault_tolerance) ]
 # Fault Tolerant and Reproducible Preprocessing for Machine Learning
In this repository are some basic functional tests for my work on fault-tolerance done over the course of my master thesis at ETH Zurich. Everything is built on top of Cachew [1], which in turn was built on tf.data [2].


## Tests
- **Nofail** Cachew is run without inducing any failures. For this tests, and for all the tests to follow, we will be checking that every input element was presented to the learner exactly once by storing hashes of the input elements on the file system and at the end ensuring that all the epochs contain every input element exactly once.
- **Getfail** Here we run Cachew in a special mode to enforce caching. In the first epoch, where we write everything to cache, no failures happen. Then in the second epoch, where a GetOp is inserted, we make all workers fail. After a few seconds, we restart all of the previously killed workers. We aim to test the GetOps checkpointing mechanism in this test.
- **Putfail** We again run Cachew in this special mode to enforce the caching.In the first epoch, a Put operation is inserted at the very end of the pipeline. About halfway through processing the dataset, we kill all workers. We get them back up after a few seconds. Here we test primarily the checkpointing mechanism for the PutOp.
- **Failover** A single worker starts processing the dataset. The first epoch is without failures. In the second epoch, we make the worker fail a bit after making a checkpoint. Then we wait for the dispatcher to notice the missing heartbeats and perform a failover to a different worker waiting in standby.
- **Recover** Again a single worker processes the dataset. We make it fail in the second epoch, but this time restart it again. The worker will come up under the same address / port and start recovering from the local checkpoint.
- **Killall** In the second epoch we kill all nodes except the client. So the dispatcher and three workers go down. They are all restarted. The dispatcher will recover its state from the journal and the workers will recover from their local checkpoints.



### Env
Setting up the environement for running the tests is documented in the `Dockerfile`. It downloads a pre-compiled version of my TensorFlow fork, installs all other dependencies and downloads some test data.

Build it after cloning this repo using `docker build -t mthesis .`.

### Running the Tests
Make sure the Docker image was built successfully, then you may run all tests by executing `docker run --rm -it mthesis /home/makepkg/test_all.sh`

![tests](https://github.com/resulknad/mthesis/raw/main/res/out.svg)

`[1]: Graur, Dan, Damien Aymon, Dan Kluser, Tanguy Albrici, Chandramohan A. Thekkath, and Ana Klimovic. "Cachew: Machine Learning Input Data Processing as a Service." In 2022 USENIX Annual Technical Conference (USENIX ATC 22), pp. 689-706. 2022.`

`[2]: Murray, Derek G., Jiri Simsa, Ana Klimovic, and Ihor Indyk. "tf. data: A machine learning data processing framework." arXiv preprint arXiv:2101.12127 (2021).`
