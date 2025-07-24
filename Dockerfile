# syntax=docker/dockerfile:1
FROM mambaorg/micromamba:1.5.7 AS base

# Set up environment
ENV MAMBA_DOCKERFILE_ACTIVATE=1 \
    CONDA_ENV_PATH=/opt/conda/envs/ibuilder \
    PATH=/opt/conda/envs/ibuilder/bin:$PATH

# Create environment and install conda dependencies
RUN micromamba create -y -n ibuilder \
    -c conda-forge -c bioconda -c defaults \
    python=3.10 \
    openmm \
    pdbfixer \
    anarci \
    numpy \
    scipy \
    einops \
    requests \
    && micromamba clean -a -y

# Set environment
SHELL ["/bin/bash", "-c"]
RUN echo "conda activate ibuilder" >> ~/.bashrc
ENV CONDA_DEFAULT_ENV=ibuilder

# Install PyTorch (CPU only for minimal image)
RUN pip install torch --extra-index-url https://download.pytorch.org/whl/cpu

# Copy code
WORKDIR /app
COPY ImmuneBuilder ImmuneBuilder
COPY setup.py .
COPY MANIFEST.in .
COPY README.md .

RUN chown -R mambauser:mambauser /app
USER mambauser

# Install package
RUN pip install .

# Set entrypoints for the three main console scripts
ENTRYPOINT ["/bin/bash"]
CMD ["-c", "echo 'Available commands: ABodyBuilder2, TCRBuilder2, NanoBodyBuilder2' && exec bash"]

# Example usage (mount weights at runtime):
# docker run --rm -it -v /path/to/weights:/app/ImmuneBuilder/trained_model <image> ABodyBuilder2 --help 