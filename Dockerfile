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

#nginx
RUN mkdir -p /var/cache/nginx /var/log/nginx /var/lib/nginx && \
    touch /var/run/nginx.pid && \
    chown -R user:user /var/cache/nginx /var/log/nginx /var/lib/nginx /var/run/nginx.pid

# Fetch the latest version of OpenVSCode Server
RUN curl -s https://api.github.com/repos/gitpod-io/openvscode-server/releases/latest \
    | grep "browser_download_url.*linux-x64.tar.gz" \
    | cut -d : -f 2,3 \
    | tr -d \" \
    | wget -qi - -O /tmp/openvscode-server.tar.gz && \
    # Install OpenVSCode Server
    mkdir -p /app/openvscode-server && \
    tar -xzf /tmp/openvscode-server.tar.gz --strip-components=1 -C /app/openvscode-server \
    # Clean up the temporary file
    && rm /tmp/openvscode-server.tar.gz \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/tmp/*

# Fetch the latest version of OpenVSCode Server
RUN echo "**** install code-server ****" && \
  CODE_RELEASE=$(curl -sX GET "https://api.github.com/repos/coder/code-server/releases/latest" \
    | grep 'browser_download_url.*linux-x64.tar.gz"' \
    | cut -d : -f 2,3 \
    | tr -d \") && \
  mkdir -p /app/code-server && \
  curl -o \
    /tmp/code-server.tar.gz -L \
    "$CODE_RELEASE" && \
  tar xf /tmp/code-server.tar.gz -C \
    /app/code-server --strip-components=1 && \
  echo "**** clean up ****" && \
  apt-get clean && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

# Install Node.js and configurable-http-proxy
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g configurable-http-proxy \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/tmp/*
    
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

# Install VS Code
RUN wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | apt-key add - \
    && apt-get update \
    && apt-get install -y apt-transport-https \
    && echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" | tee /etc/apt/sources.list.d/vscode.list \
    && apt-get update \
    && apt-get install -y code \
    && rm -rf /var/cache/apt/* \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/tmp/*

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
    && rm -rf /var/lib/apt/lists/*

RUN --mount=target=/root/npm_packages.txt,source=npm_packages.txt \
    xargs -r -a /root/npm_packages.txt /usr/bin/npm install -g

RUN --mount=target=/root/on_startup.sh,source=on_startup.sh,readwrite \
	bash /root/on_startup.sh

#######################################
# End root user section
#######################################

USER user

# Python packages
RUN --mount=target=requirements.txt,source=requirements.txt \
    pip install --no-cache-dir --upgrade -r requirements.txt

# Copy the current directory contents into the container at $HOME/app setting the owner to the user
COPY --chown=user . $HOME/app
COPY --chown=user nginx.conf /etc/nginx/sites-available/default

RUN chmod +x start_server.sh

#FROM ckt1031/one-api-en:latest

ENV PYTHONUNBUFFERED=1 \
	GRADIO_ALLOW_FLAGGING=never \
	GRADIO_NUM_PORTS=1 \
	GRADIO_SERVER_NAME=0.0.0.0 \
	GRADIO_THEME=huggingface \
	SYSTEM=spaces \
	SHELL=/bin/bash

CMD ["./start_server.sh"]
