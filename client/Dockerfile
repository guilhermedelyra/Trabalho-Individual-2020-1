FROM node:14

RUN mkdir -p /opt/app/client
WORKDIR /opt/app/client

COPY ./client/package.json .
COPY ./client/yarn.lock .
RUN yarn

COPY . /opt/app

COPY ./client/entrypoint.sh /usr/bin/entrypoint_client.sh
RUN chmod +x /usr/bin/entrypoint_client.sh

ENTRYPOINT ["entrypoint_client.sh"]
