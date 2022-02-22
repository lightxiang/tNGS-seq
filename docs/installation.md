> This documentation assumes that you have already read the [introduction](usage/introduction) and are familiar with the tools described below.

# Table of contents
<!-- Install Atom plugin markdown-toc-auto for this ToC -->
<!-- TOC START min:2 max:3 link:true asterisk:true -->
- [Table of contents](#Table-of-contents)
  - [Install nextflow](#Install-nextflow)
  - [Install the pipeline](#Install-the-pipeline)
    - [Automatic](#Automatic)
    - [Offline](#Offline)
    - [Development](#Development)
  - [Pipeline configuration](#Pipeline-configuration)
    - [Docker](#Docker)
    - [Singularity](#Singularity)
    - [Conda](#Conda)
    - [Configuration profiles](#Configuration-profiles)
  - [Reference genomes](#Reference-genomes)
<!-- TOC END -->

## Install nextflow
Nextflow runs on most POSIX systems (Linux, Mac OSX etc). It can be installed by running the following commands:

```bash
# Make sure that Java v8+ is installed:
java -version

# Install Nextflow
curl -fsSL get.nextflow.io | bash

# Add Nextflow binary to your PATH:
mv nextflow ~/bin/
# OR system-wide installation:
# sudo mv nextflow /usr/local/bin
```

See [nextflow.io](https://www.nextflow.io/) for further instructions on how to install and configure Nextflow.

## Install the pipeline

### Automatic
This pipeline itself needs no installation - nextflow will automatically fetch it from GitHub if `nf-core/YOUR_PIPELINE` is specified as the pipeline name.

### Offline
The above method requires an internet connection so that Nextflow can download the pipeline files. If you're running on a system that has no internet connection, you'll need to download and transfer the pipeline files manually:

```bash
wget https://github.com/nf-core/YOUR_PIPELINE/archive/master.zip
mkdir -p ~/my-pipelines/nf-core/
unzip master.zip -d ~/my-pipelines/nf-core/
cd ~/my_data/
nextflow run ~/my-pipelines/nf-core/YOUR_PIPELINE-master
```

To stop nextflow from looking for updates online, you can tell it to run in offline mode by specifying the following environment variable in your ~/.bashrc file:

```bash
export NXF_OFFLINE='TRUE'
```

### Development

If you would like to make changes to the pipeline, it's best to make a fork on GitHub and then clone the files. Once cloned you can run the pipeline directly as above.


## Pipeline configuration
By default, the pipeline loads a basic resource configuration:
```bash
process {

  cpus = { check_max( 2, 'cpus' ) }
  memory = { check_max( 8.GB * task.attempt, 'memory' ) }
  time = { check_max( 2.h * task.attempt, 'time' ) }

  errorStrategy = { task.exitStatus in [143,137,104,134,139] ? 'retry' : 'terminate' }
  maxRetries = 1
  maxErrors = '-1'

  // Process-specific resource requirements
  withName: fastqc {
    time = { check_max( 8.h * task.attempt, 'time' ) }
  }
  withName:toolX {
    cpus = { check_max( 8, 'cpus' ) }
    memory = { check_max( 8.GB * task.attempt, 'memory' ) }
  }
  withName: toolY {
    cpus = { check_max( 10, 'cpus' ) }
    memory = { check_max( 200.GB * task.attempt, 'memory' ) }
    time = { check_max( 5.h * task.attempt, 'time' ) }
  }
}

params {
  // Defaults only, expecting to be overwritten
  max_memory = 128.GB
  max_cpus = 16
  max_time = 240.h
  igenomes_base = 's3://ngi-igenomes/igenomes/'
}
```
This uses a number of sensible defaults for process requirements and is suitable for running
on a simple (if powerful!) local server.

Be warned of two important points about this default configuration:

1. The default profile uses the `local` executor
    * All jobs are run in the login session. If you're using a simple server, this may be fine. If you're using a compute cluster, this is bad as all jobs will run on the head node.
    * See the [nextflow docs](https://www.nextflow.io/docs/latest/executor.html) for information about running with other hardware backends. Most job scheduler systems are natively supported.
2. Nextflow will expect all software to be installed and available on the `PATH`
    * It's expected to use an additional config profile for docker, singularity or conda support. See below.

### Docker
First, install docker on your system: [Docker Installation Instructions](https://docs.docker.com/engine/installation/)

Then, running the pipeline with the option `-profile docker` tells Nextflow to enable Docker for this run.
An image containing all of the software requirements will be automatically fetched and used from dockerhub
([https://hub.docker.com/r/nfcore/YOUR_PIPELINE](https://hub.docker.com/r/nfcore/YOUR_PIPELINE)).

### Singularity
If you're not able to use Docker then [Singularity](http://singularity.lbl.gov/) is a great alternative.
The process is very similar: running the pipeline with the option `-profile singularity` tells Nextflow to enable singularity for this run. An image containing all of the software requirements will be automatically fetched and used from singularity hub.

If running offline with Singularity, you'll need to download and transfer the Singularity image first:

```bash
singularity pull --name nf-core-YOUR_PIPELINE.simg nf-core/YOUR_PIPELINE
```

Once transferred, use `-with-singularity` and specify the path to the image file:

```bash
nextflow run /path/to/nf-core-YOUR_PIPELINE -with-singularity nf-core-YOUR_PIPELINE.simg
```

Remember to pull updated versions of the singularity image if you update the pipeline.

### Conda
If you're not able to use Docker _or_ Singularity, you can instead use conda to manage the software requirements.
This is slower and less reproducible than the above, but is still better than having to install all requirements yourself!
The pipeline ships with a conda environment file and nextflow has built-in support for this.
To use it first ensure that you have conda installed (we recommend [miniconda](https://conda.io/miniconda.html)), then follow the same pattern as above and use the flag `-profile conda`

### Configuration profiles

See [Adding your own configuration profile](usage/adding_own_config).

## Reference genomes

See [Reference genomes](usage/reference_genomes)