FROM ruby:2.5.7

RUN apt-get update -qq && apt-get install -y nodejs postgresql-client

COPY . /opt/app
WORKDIR /opt/app/api

RUN gem update --system
RUN gem install bundler
RUN bundle config build.nokogiri --use-system-libraries
RUN bundle check || bundle install

COPY ./api/entrypoint.sh /usr/bin/entrypoint_api.sh
RUN chmod +x /usr/bin/entrypoint_api.sh

ENTRYPOINT ["entrypoint_api.sh"]
