#!/bin/bash

cd $(dirname $0)

if [[ ! -e oio_rest/settings.py ]]; then
    NO_SETTINGS=true
    cp oio_rest/settings.py.base oio_rest/settings.py
fi

virtualenv -p python venv

venv/bin/python setup.py test
venv/bin/python setup.py flake8 || true

if [[ "$NO_SETTINGS" = true ]]; then
    rm oio_rest/settings.py
fi
