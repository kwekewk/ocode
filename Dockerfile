FROM ubuntu 

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Jakarta

# Remove any third-party apt sources to avoid issues with expiring keys.
# Install some basic utilities
RUN rm -f /etc/apt/sources.list.d/*.list && \
    apt-get update && apt-get install -y \
    curl \
    wget \
    ca-certificates \
    sudo \
    git \
    git-lfs \
    zip \
    unzip \
    htop \
    bzip2 \
    libx11-6 \
    build-essential \
    libsndfile-dev \
    software-properties-common \
  && rm -rf /var/lib/apt/lists/*

# Install openvscode-server runtime dependencies
RUN apt-get update && \
    apt-get install -y \
    jq \
    libatomic1 \
    nano \
    net-tools \
    netcat 

COPY root/ /

# Create a working directory
WORKDIR /app

# Create a non-root user and switch to it
RUN adduser --disabled-password --gecos '' --shell /bin/bash user \
 && chown -R user:user /app
RUN echo "user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-user

# Fetch the latest version of OpenVSCode Server
RUN curl -s https://api.github.com/repos/gitpod-io/openvscode-server/releases/latest \
    | grep "browser_download_url.*linux-x64.tar.gz" \
    | cut -d : -f 2,3 \
    | tr -d \" \
    | wget -qi - -O /tmp/openvscode-server.tar.gz && \
    # Install OpenVSCode Server
    mkdir -p /app/openvscode-server && \
    tar -xzf /tmp/openvscode-server.tar.gz --strip-components=1 -C /app/openvscode-server 

# Install NVM and set 16 as default 
RUN mkdir /app/.nvm ; export NVM_DIR="/app/.nvm" && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash && . "$NVM_DIR/nvm.sh" && nvm install 16 && nvm alias default 16

# Install Golang
ARG GOLANG_VERSION="1.20"
RUN curl -LO "https://golang.org/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz" && \
    tar -C /usr/local -xzf "go${GOLANG_VERSION}.linux-amd64.tar.gz" && \
    rm "go${GOLANG_VERSION}.linux-amd64.tar.gz" && \
    mkdir /go && \
    chown -R user:user /go && \  
    chmod -R 777 /go

# Set Golang environment variables
ENV PATH="/usr/local/go/bin:${PATH}" \
    GOPATH="/go" \
    GOBIN="/go/bin"

USER user

# All users can use /home/user as their home directory
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH
RUN mkdir $HOME/.cache $HOME/.config \
&& chown -R user:user $HOME \
&& chmod 700 $HOME/.cache $HOME/.config

# Set up the Conda environment
ENV CONDA_AUTO_UPDATE_CONDA=false \
    PATH=$HOME/miniconda/bin:$PATH
RUN curl -sLo ~/miniconda.sh https://repo.continuum.io/miniconda/Miniconda3-py39_4.10.3-Linux-x86_64.sh \
 && chmod +x ~/miniconda.sh \
 && ~/miniconda.sh -b -p ~/miniconda \
 && rm ~/miniconda.sh \
 && conda clean -ya

WORKDIR $HOME/app

#######################################
# Start root user section
#######################################

USER root

# User Debian packages
## Security warning : Potential user code executed as root (build time)
RUN --mount=target=/root/packages.txt,source=packages.txt \
    apt-get update && \
    xargs -r -a /root/packages.txt apt-get install -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \     
    && rm -rf /var/cache/apt/* \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/tmp/* \
    && rm -rf /tmp/*

RUN --mount=target=/root/on_startup.sh,source=on_startup.sh,readwrite \
	bash /root/on_startup.sh

# NPM Global
RUN --mount=target=/root/npm_packages.txt,source=npm_packages.txt \
    xargs -r -a /root/npm_packages.txt /usr/bin/npm install -g


#######################################
# End root user section
#######################################

USER user

# Python packages
RUN --mount=target=requirements.txt,source=requirements.txt \
    pip install --no-cache-dir --upgrade -r requirements.txt

# Copy the current directory contents into the container at $HOME/app setting the owner to the user
COPY --chown=user . $HOME/app
COPY --chown=user --from=caddy:2-alpine /usr/bin/caddy /usr/bin/caddy

RUN chmod +x start_server.sh

USER root

ENV PYTHONUNBUFFERED=1 \
	GRADIO_ALLOW_FLAGGING=never \
	GRADIO_NUM_PORTS=1 \
	GRADIO_SERVER_NAME=0.0.0.0 \
	GRADIO_THEME=huggingface \
	SYSTEM=spaces \
	SHELL=/bin/bash

CMD ["./start_server.sh"]
