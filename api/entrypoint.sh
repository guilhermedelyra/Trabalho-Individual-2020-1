#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -rf /opt/app/tmp/pids/server.pid

rake db:create
rake db:migrate 

# if db_version=$(rake db:version 2>/dev/null)
# then
#     if [ "$db_version" = "Current version: 0" ]
#     then
#         echo "DB is empty"
#         rake db:migrate 
#     else
#         echo "DB exists"
#     fi
# else
#     echo "DB does not exist, creating it"
#     rake db:migrate 
# fi

rails server -p 3000 -b 0.0.0.0
