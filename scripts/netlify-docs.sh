#!/usr/bin/env bash
set -x
set -e
# Install pip
cd /tmp
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3.8 get-pip.py --user
cd -
# Install Flit to be able to install all
python3.8 -m pip install --user flit
# Install with Flit
python3.8 -m flit install --user --deps develop
# Finally, run mkdocs
python3.8 -m mkdocs build
