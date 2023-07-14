#!/bin/bash
# Write some commands here that will run on root user before startup.
# For example, to clone transformers and install it in dev mode:
# git clone https://github.com/huggingface/transformers.git
# cd transformers && pip install -e ".[dev]"
# useradd -m aku && adduser aku sudo && echo 'aku:aku' | sudo chpasswd && sed -i 's/\/bin\/sh/\/bin\/bash/g' /etc/passwd
# /usr/bin/newuidmap 1500 0 1000 1 1 100000 65536
git clone https://github.com/ckt1031/one-api/

# Build the frontend
cd one-api/web
npm install
npm run build

# Build the backend
cd ..
export GO111MODULE=on
export CGO_ENABLED=1
export GOOS=linux
python ./i18n/translate.py --repository_path . --json_file_path ./i18n/en.json
go mod download
go build -ldflags "-s -w -X 'one-api/common.Version=$(cat VERSION)' -extldflags '-static'" -o one-api
chmod u+x one-api
#./one-api --port 3000 --log-dir ./logs
