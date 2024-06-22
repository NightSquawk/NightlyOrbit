FROM ubuntu:22.04

# Set the working directory in the container
WORKDIR /usr/src/app

# Update package list and install curl
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y curl git sudo

# Download setup.sh
RUN curl -LJO https://raw.githubusercontent.com/NightSquawk/NightlyOrbit/development/setup.sh

# Make setup.sh executable
RUN chmod +x setup.sh

# Set TERM environment variable and run setup.sh, then keep the container running with an interactive shell
CMD ["bash", "-c", "export TERM=xterm && ./setup.sh -b development && exec bash"]
