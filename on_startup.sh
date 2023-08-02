#!/bin/bash
# Write some commands here that will run on root user before startup.
# For example, to clone transformers and install it in dev mode:
# git clone https://github.com/huggingface/transformers.git
# cd transformers && pip install -e ".[dev]"
conda install -c conda-forge gh
export NVM_DIR="/app/.nvm" ; curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash \
  && . "$NVM_DIR/nvm.sh" && nvm install 16 && nvm alias default 16
. "$NVM_DIR/nvm.sh" && node -v && which npm
