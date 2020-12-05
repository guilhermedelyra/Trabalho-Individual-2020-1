#!/bin/bash
set -e

if [ "$BUILD" = "true" ]
then
    yarn build
else
    yarn dev
fi
