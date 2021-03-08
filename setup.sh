#!/bin/bash

#install firefox
sudo apt install firefox && sudo apt install firefox

#download selenium firefox driver
wget -N https://github.com/mozilla/geckodriver/releases/download/v0.29.0/geckodriver-v0.29.0-linux64.tar.gz

#extract and delete tar
tar xzvf geckodriver-v0.29.0-linux64.tar.gz && rm geckodriver-v0.29.0-linux64.tar.gz
