# Sets base image to Miniconda3
FROM continuumio/miniconda3
# Changes default shell to Bash
SHELL ["/bin/bash", "-c"]

WORKDIR /build
RUN apt update && apt-get install -y libltdl7 screen && apt upgrade -y && apt-get purge -y && apt-get clean

# Make RUN commands use the new environment:
#SHELL ["conda", "run", "-n", "myenv", "/bin/bash", "-c"]

COPY docker_pipeline.sh /app/docker_pipeline.sh
COPY natrix.yaml /build
COPY docker_dummyfiles/units.tsv /build/docker_dummy.tsv
COPY create_dataframe.py /build
COPY docker_dummyfiles/ /build/docker_dummyfiles
COPY Snakefile /build/
COPY schema /build/schema
COPY rules /build/rules
COPY envs /build/envs
RUN mkdir docker_dummy_env1
RUN mkdir docker_dummy_env2
RUN touch docker_dummy_env1.csv
RUN touch docker_dummy_env2.csv

RUN conda env create -f natrix.yaml

RUN env_loc=$(conda info --base)/etc/profile.d/conda.sh && source $env_loc && conda activate natrix \
    && python create_dataframe.py docker_dummyfiles/docker_dummy_env1.yaml

RUN env_loc=$(conda info --base)/etc/profile.d/conda.sh && source $env_loc && conda activate natrix \
    && snakemake --configfile docker_dummyfiles/docker_dummy_env1.yaml --cores 1 --use-conda --conda-create-envs-only

RUN env_loc=$(conda info --base)/etc/profile.d/conda.sh && source $env_loc && conda activate natrix \
    && python create_dataframe.py docker_dummyfiles/docker_dummy_env2.yaml

RUN env_loc=$(conda info --base)/etc/profile.d/conda.sh && source $env_loc && conda activate natrix \
    && snakemake --configfile docker_dummyfiles/docker_dummy_env2.yaml --cores 1 --use-conda --conda-create-envs-only

COPY Nanopore.yaml /build
COPY Nanopore.csv /build
COPY Nanopore_data /build/Nanopore_data

RUN env_loc=$(conda info --base)/etc/profile.d/conda.sh && source $env_loc && conda activate natrix \
    && python create_dataframe.py Nanopore.yaml

RUN env_loc=$(conda info --base)/etc/profile.d/conda.sh && source $env_loc && conda activate natrix \
    && snakemake --configfile Nanopore.yaml --cores 10 --use-conda --conda-create-envs-only

# RUN rm -rf /build

COPY . /build
WORKDIR /build
