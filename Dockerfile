FROM ruby:3.1.2

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs

RUN mkdir /myapp

WORKDIR /myapp

COPY Gemfile Gemfile

# COPY Gemfile.lock Gemfile.lock

RUN bundle install

COPY . .

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]

EXPOSE 3000
