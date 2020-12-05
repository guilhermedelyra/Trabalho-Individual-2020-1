FROM ruby:2.5.7

RUN apt-get update -qq && apt-get install -y nodejs postgresql-client
RUN gem update --system
RUN gem install bundler

RUN mkdir -p /opt/app/api
WORKDIR /opt/app/api

COPY ./api/Gemfile .
COPY ./api/Gemfile.lock .

RUN bundle config build.nokogiri --use-system-libraries
RUN bundle check || bundle install

COPY . /opt/app

COPY ./api/entrypoint.sh /usr/bin/entrypoint_api.sh
RUN chmod +x /usr/bin/entrypoint_api.sh

ENTRYPOINT ["entrypoint_api.sh"]
