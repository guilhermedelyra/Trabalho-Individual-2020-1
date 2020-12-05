#!/bin/bash
set -e

if [ "$CLIENT_MODE" = "build" ]
then
    yarn build
elif [ "$CLIENT_MODE" = "test" ]
then
    yarn test:unit
elif [ "$CLIENT_MODE" = "dev" ]
then
    yarn dev
else
    echo "Unknown CLIENT_MODE value..."
fi
