FROM ruby:3.1.2

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs

RUN apt-get install -y libappindicator1 fonts-liberation

RUN curl -O https://chromedriver.storage.googleapis.com/2.29/chromedriver_linux64.zip

RUN unzip chromedriver_linux64.zip
RUN chmod +x chromedriver
RUN mv -f chromedriver /usr/local/share/chromedriver
RUN ln -s /usr/local/share/chromedriver /usr/local/bin/chromedriver
RUN ln -s /usr/local/share/chromedriver /usr/bin/chromedriver

RUN apt-cache search libnss
RUN apt --fix-broken install
RUN apt install -y libgconf-2-4 libatk1.0-0 libatk-bridge2.0-0 libgdk-pixbuf2.0-0 libgtk-3-0 libgbm-dev libnss3-dev libxss-dev


RUN mkdir /myapp

WORKDIR /myapp

COPY Gemfile Gemfile

# COPY Gemfile.lock Gemfile.lock

RUN bundle install

COPY . .

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]

EXPOSE 3000
