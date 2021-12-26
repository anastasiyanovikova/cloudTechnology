#!/usr/bin/bash

sudo apt-get update
sudo apt install -y python3-pip
sudo apt install -y python3-venv

python3 -m venv ubuntu_env

source ubuntu_env/bin/activate

pip install -r requirements.txt
pip install uwsgi
deactivate

chmod +x run.sh

sudo ln -s /opt/serverlogic/serverlogic.service /etc/systemd/system/serverlogic.service
chmod 664 /etc/systemd/system/serverlogic.service
systemctl daemon-reload

systemctl enable serverlogic
systemctl status serverlogic
