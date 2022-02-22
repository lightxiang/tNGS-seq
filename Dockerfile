FROM nfcore/base
LABEL authors="sagene" \
      description="Docker image containing all requirements for sagene-plugins/rpdseq-reborn pipeline" 

WORKDIR /
COPY environment.yml /

RUN apt-get --allow-releaseinfo-change  update && apt-get install -y libtbb2
RUN conda env create -f /environment.yml && conda clean -a
RUN /opt/conda/envs/sagene-plugins-rpdseq-reborn/bin/pip install zipfile37
COPY bin/* /opt/conda/envs/sagene-plugins-rpdseq-reborn/bin/
RUN chmod a+xr -R /opt/conda/envs/sagene-plugins-rpdseq-reborn/bin
RUN useradd -d /home/sagene -ms /bin/bash -g users sagene

USER sagene
ENV PATH /opt/conda/envs/sagene-plugins-rpdseq-reborn/bin:$PATH
ENV AWS_DEFAULT_REGION cn-north-1
WORKDIR /home/sagene
