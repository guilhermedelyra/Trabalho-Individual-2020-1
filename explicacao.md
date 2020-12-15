# [Trabalho Individual 2020.1](https://github.com/guilhermedelyra/Trabalho-Individual-2020-1)

|       aluno       |  matrícula |                 :octocat: github                       |
| ----------------- | ---------- | ------------------------------------------------------ |
| Guilherme de Lyra | 15/0128231 | [@guilhermedelyra](https://github.com/guilhermedelyra) |

## Tabela de Conteudos

1. Containerização
    1. Docker-compose
    1. Dockerfiles
1. Integração Contínua
    1. Integration
    1. Coverage
1. Deploy Contínuo
    1. Deploy

## Containerização

### Docker-Compose

#### Serviços comuns

<details>
<summary>
Expandir ⤵️
</summary>

[networks e volumes em `docker-compose.yml`](https://github.com/guilhermedelyra/Trabalho-Individual-2020-1/blob/master/docker-compose.yml)
```yml
networks:
  app_network:

volumes:
  gem_cache:
  db_data:
  node_modules:
```
</details>

#### Variaveis de ambiente

<details>
<summary>
Expandir ⤵️
</summary>

[`.env`](https://github.com/guilhermedelyra/Trabalho-Individual-2020-1/blob/master/.env)
```yml
APP_CLIENT_NAME=client
APP_CLIENT_PORT=8080
NODE_ENV=development

APP_API_NAME=api
APP_API_PORT=3000
RAILS_ENV=development

DATABASE_USER=postgres
DATABASE_PASSWORD=password
DATABASE_PORT=5432
DATABASE_HOST=api-db
```

</details>



#### Subsistema Banco de Dados
<details>
<summary>
Expandir ⤵️
</summary>

[api-db em `docker-compose.yml`](https://github.com/guilhermedelyra/Trabalho-Individual-2020-1/blob/master/docker-compose.yml)
```yml
  api-db:
    image: postgres
    container_name: ${DATABASE_HOST}
    ports:
      - ${DATABASE_PORT}:${DATABASE_PORT}
    volumes:
      - db_data:/var/lib/postgresql/data
      - ./api/log/db:/logs
    env_file: .env
    environment:
      - POSTGRES_USER=${DATABASE_USER}
      - POSTGRES_PASSWORD=${DATABASE_PASSWORD}
    networks:
      - app_network
```

</details>



#### Subsistema Back End
<details>
<summary>
Expandir ⤵️
</summary>

[api em `docker-compose.yml`](https://github.com/guilhermedelyra/Trabalho-Individual-2020-1/blob/master/docker-compose.yml)
```yml
  api:
    build: 
      context: .
      dockerfile: ./api/Dockerfile
    container_name: ${APP_API_NAME}
    ports:
      - ${APP_API_PORT}:${APP_API_PORT}
    volumes:
      - ./api:/opt/app/api
      - gem_cache:/usr/local/bundle/gems
    depends_on:
      - api-db
    env_file: .env
    environment:
      RAILS_ENV: ${RAILS_ENV}
    networks:
      - app_network
```

</details>



#### Subsistema Front End
<details>
<summary>
Expandir ⤵️
</summary>

[client em `docker-compose.yml`](https://github.com/guilhermedelyra/Trabalho-Individual-2020-1/blob/master/docker-compose.yml)
```yml
  client:
    build: 
      context: .
      dockerfile: ./client/Dockerfile
    container_name: ${APP_CLIENT_NAME}
    ports:
      - ${APP_CLIENT_PORT}:${APP_CLIENT_PORT}
    volumes:
      - ./client:/opt/app/client
      - node_modules:/opt/app/client/node_modules  
    env_file: .env
    environment:
      NODE_ENV: ${NODE_ENV}
```

</details>


### Dockerfiles


#### API
<details>
<summary>
Expandir ⤵️
</summary>

[`api/Dockerfile`](https://github.com/guilhermedelyra/Trabalho-Individual-2020-1/blob/master/api/Dockerfile)
```dockerfile
FROM ruby:2.5.7

RUN apt-get update -qq && apt-get install -y nodejs postgresql-client

RUN mkdir -p /opt/app/api
WORKDIR /opt/app/api

COPY ./api/Gemfile .
COPY ./api/Gemfile.lock .

RUN gem update --system
RUN gem install bundler
RUN bundle config build.nokogiri --use-system-libraries
RUN bundle check || bundle install

COPY ./api/ /opt/app/api

COPY ./api/entrypoint.sh /usr/bin/entrypoint_api.sh
RUN chmod +x /usr/bin/entrypoint_api.sh

ENTRYPOINT ["entrypoint_api.sh"]
```

</details>



##### Entrypoint API
<details>
<summary>
Expandir ⤵️
</summary>

[`api/entrypoint.sh`](https://github.com/guilhermedelyra/Trabalho-Individual-2020-1/blob/master/api/entrypoint.sh)
```bash
#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -rf /opt/app/tmp/pids/server.pid

rake db:create
rake db:migrate 

if [ "$RAILS_ENV" = "development" ]
then
    rails server -p 3000 -b 0.0.0.0
elif [ "$RAILS_ENV" = "test" ]
then
    rake test
else
    echo "Unknown RAILS_ENV value..."
fi
```

</details>



#### Client
<details>
<summary>
Expandir ⤵️
</summary>

[`client/Dockerfile`](https://github.com/guilhermedelyra/Trabalho-Individual-2020-1/blob/master/client/Dockerfile)
```dockerfile
FROM node:14

RUN mkdir -p /opt/app/client
WORKDIR /opt/app/client

COPY ./client/package.json .
COPY ./client/yarn.lock .

RUN yarn global add @vue/cli@4.4.6
RUN yarn install

COPY ./client/ /opt/app/client

COPY ./client/entrypoint.sh /usr/bin/entrypoint_client.sh
RUN chmod +x /usr/bin/entrypoint_client.sh

ENTRYPOINT ["entrypoint_client.sh"]
```

</details>



##### Entrypoint Client
<details>
<summary>
Expandir ⤵️
</summary>

[`client/entrypoint.sh`](https://github.com/guilhermedelyra/Trabalho-Individual-2020-1/blob/master/client/entrypoint.sh)
```bash
#!/bin/bash
set -e

if [ "$NODE_ENV" = "build" ]
then
    yarn build
elif [ "$NODE_ENV" = "test" ]
then
    yarn test:unit
elif [ "$NODE_ENV" = "development" ]
then
    yarn dev
else
    echo "Unknown NODE_ENV value... serving it anyway"
    yarn serve
fi
```

</details>



## Integração Contínua


### Integration
<details>
<summary>
Expandir ⤵️
</summary>

[`.github/workflows/integration.yml`](https://github.com/guilhermedelyra/Trabalho-Individual-2020-1/blob/master/.github/workflows/integration.yml)
```yml
name: ci/cd deploy

# tho i could push those containers built at the integration job
# and then use them as containers images for the coverage job
# i prefer not to, since docker is currently limiting pulls and pushes, so idk

# other option would be to simulate the same path from docker containers
# within gh action instance and then 'docker cp' the coverage folders into
# it.
#
# but it would also be slower (since currently integration (+ tests)
# takes ~6min to complete it's job [while coverage job takes up to ~4m])

on:
  push: # any branch
  pull_request:
    branches:
      - master

jobs:
  integration:
    name: CI  &&  Test inside docker
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: directory          
        run: ls -a          

      - name: build
        run: docker-compose up --build -d

      - name: test_api
        run: docker-compose run -e "RAILS_ENV=test" api
      
      - name: test_client
        run: docker-compose run -e "NODE_ENV=test" client
```
</details>


### Coverage
<details>
<summary>
Expandir ⤵️
</summary>

[`.github/workflows/coverage.yml`](https://github.com/guilhermedelyra/Trabalho-Individual-2020-1/blob/master/.github/workflows/coverage.yml)
```yml
name: coverage

# refer to integration.yml comment

on:
  push: # any branch
  pull_request:
    branches:
      - master

jobs:
  coverage:
    name: Test front/back && Coverage
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres
        env:
          POSTGRES_PASSWORD: password
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v2
        with:
          fetch-depth: 0
      - uses: actions/setup-node@v1
        with:
          node-version: 14.x
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '2.5.7'

      - name: retrieve client coverage
        env:
          NODE_ENV: test
        run: |
          yarn install
          yarn test:unit
        working-directory: client

      - name: retrieve api coverage
        env:
          DATABASE_HOST: localhost
          DATABASE_PORT: 5432
          DATABASE_USER: postgres
          DATABASE_PASSWORD: password
          RAILS_ENV: test
        run: |
          sudo apt-get -yqq install libpq-dev
          gem install bundler
          bundle install --jobs 4 --retry 3
          bundle exec rails db:create
          bundle exec rails db:migrate
          bundle exec rails test
        working-directory: api

      - name: SonarCloud Scan
        uses: SonarSource/sonarcloud-github-action@master
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}

      - name: CodeClimate - publish Coverage
        uses: paambaati/codeclimate-action@v2.7.5
        env:
          CC_TEST_REPORTER_ID: ${{secrets.CC_TEST_REPORTER_ID}}
        with:
          coverageLocations: |
            ${{github.workspace}}/client/coverage/lcov.info:lcov
            ${{github.workspace}}/api/coverage/.resultset.json:simplecov              
```
</details>


## Deploy Contínuo

### Deploy API
<details>
<summary>
Expandir ⤵️
</summary>

**Link**: [https://backend-gces.herokuapp.com/api/v1/](https://backend-gces.herokuapp.com/api/v1/)

[`.github/workflows/deploy.yml`](https://github.com/guilhermedelyra/Trabalho-Individual-2020-1/blob/master/.github/workflows/deploy.yml)
```yml
name: Push api to Heroku

on: [push]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Release API
      uses: akhileshns/heroku-deploy@v3.0.4
      with:
        heroku_api_key: ${{ secrets.HEROKU_API_KEY }}
        heroku_app_name: "backend-gces"
        heroku_email: "guilyra12@gmail.com"
      env:
        HD_APP_BASE: "api"              
```

</details>

### Deploy Client
<details>
<summary>
Expandir ⤵️
</summary>

**Link**: [https://trabalho-individual-2020-1.guilhermedelyra.vercel.app](https://trabalho-individual-2020-1.guilhermedelyra.vercel.app/#/)

Foi utilizado a integração com o [`now.sh`](http://now.sh/) (da Vercel).
![Deploy Front](https://i.imgur.com/U68zmAn.png)
</details>
