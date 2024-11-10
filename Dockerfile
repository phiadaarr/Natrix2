# Sets base image to Miniconda3
FROM continuumio/miniconda3
# Changes default shell to Bash
SHELL ["/bin/bash", "-c"]

RUN apt update && apt-get install -y libltdl7 screen && apt upgrade -y && apt-get purge -y && apt-get clean

RUN mkdir /app
WORKDIR /app

COPY Snakefile /app/
COPY schema/ /app/schema
COPY rules/ /app/rules
COPY envs/ /app/envs
COPY natrix.yaml /app
COPY docker_pipeline.sh /app/docker_pipeline.sh
RUN chmod +x /app/docker_pipeline.sh

COPY create_dataframe.py /app
COPY docker_dummyfiles/ /app/docker_dummyfiles
COPY input_data/ /app/input_data
COPY primer_table/ /app/primer_table

RUN conda env create -f natrix.yaml

RUN env_loc=$(conda info --base)/etc/profile.d/conda.sh && source $env_loc && conda activate natrix && \
    mkdir docker_dummy_env1 && touch docker_dummy_env1.csv && cp docker_dummyfiles/units.tsv docker_dummy.tsv && \
    python create_dataframe.py docker_dummyfiles/docker_dummy_env1.yaml && \
    snakemake --configfile docker_dummyfiles/docker_dummy_env1.yaml --cores 1 --use-conda --conda-create-envs-only && \
    rm -rf docker_dummy_env1 && rm docker_dummy_env1.csv && rm docker_dummy.tsv

RUN env_loc=$(conda info --base)/etc/profile.d/conda.sh && source $env_loc && conda activate natrix && \
    mkdir docker_dummy_env2 && touch docker_dummy_env2.csv && cp docker_dummyfiles/units.tsv docker_dummy.tsv && \
    python create_dataframe.py docker_dummyfiles/docker_dummy_env2.yaml && \
    snakemake --configfile docker_dummyfiles/docker_dummy_env2.yaml --cores 1 --use-conda --conda-create-envs-only && \
    rm -rf docker_dummy_env2 && rm docker_dummy_env2.csv && rm docker_dummy.tsv
    
RUN env_loc=$(conda info --base)/etc/profile.d/conda.sh && source $env_loc && conda activate natrix && \
    mkdir docker_dummy_nanopore && touch docker_dummy_nanopore.csv && cp docker_dummyfiles/units.tsv docker_dummy.tsv && \
    python create_dataframe.py docker_dummyfiles/docker_dummy_nanopore.yaml && \
    snakemake --configfile docker_dummyfiles/docker_dummy_nanopore.yaml --cores 1 --use-conda --conda-create-envs-only && \
    rm -rf docker_dummy_nanopore && rm docker_dummy_nanopore.csv && rm docker_dummy.tsv


CMD ["sh","-c", "./docker_pipeline.sh $PROJECT_NAME"]
