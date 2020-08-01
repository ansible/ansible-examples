#!/bin/bash
source venv/bin/activate
pip install -r ./requirements.txt
deactivate
$@
