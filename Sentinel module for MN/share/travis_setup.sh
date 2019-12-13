#!/bin/bash
set -evx

mkdir ~/.grandmastercoincore

# safety check
if [ ! -f ~/.grandmastercoincore/.grandmastercoin.conf ]; then
  cp share/grandmastercoin.conf.example ~/.grandmastercoincore/grandmastercoin.conf
fi
