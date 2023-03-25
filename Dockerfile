FROM ruby:3.1.2

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs

RUN apt list --installed google*

RUN sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'

RUN ls -l /etc/apt/sources.list.d
RUN cat /etc/apt/sources.list.d/google.list

RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN apt update

RUN apt-get install google-chrome-stable -y

RUN ln -s /usr/bin/google-chrome-stable /usr/local/bin/chrome
RUN ln -s /usr/bin/google-chrome-stable /usr/bin/chrome

RUN apt-get install -y libappindicator1 fonts-liberation

RUN curl -O https://chromedriver.storage.googleapis.com/111.0.5563.64/chromedriver_linux64.zip

RUN unzip chromedriver_linux64.zip
RUN chmod +x chromedriver
RUN mv -f chromedriver /usr/local/share/chromedriver
RUN ln -s /usr/local/share/chromedriver /usr/local/bin/chromedriver
RUN ln -s /usr/local/share/chromedriver /usr/bin/chromedriver

RUN apt-cache search libnss
RUN apt --fix-broken install
RUN apt install -y libgconf-2-4 libatk1.0-0 libatk-bridge2.0-0 libgdk-pixbuf2.0-0 libgtk-3-0 libgbm-dev libnss3-dev libxss-dev

RUN apt install -y ffmpeg
RUN ffmpeg -version
# RUN apt install -y software-properties-common
# RUN apt install -y python3.9
RUN apt install -y tor
RUN apt-install firefox-geckodriver -y
RUN apt-get install -y firefox
RUN wget https://github.com/mozilla/geckodriver/releases/download/v0.28.0/geckodriver-v0.28.0-linux64.tar.gz
RUN tar zxvf geckodriver-v0.32.2-linux64.tar.gz
RUN chmod +x geckodriver
RUN mv -f geckodriver /usr/local/share/geckodriver
RUN ln -s /usr/local/share/geckodriver /usr/local/bin/geckodriver
RUN ln -s /usr/local/share/geckodriver /usr/bin/geckodriver

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A6DCF7707EBC211F
RUN apt-add-repository "deb http://ppa.launchpad.net/ubuntu-mozilla-security/ppa/ubuntu focal main"
RUN apt update
RUN apt install firefox -y


RUN mkdir /myapp

WORKDIR /myapp

COPY Gemfile Gemfile

COPY Gemfile.lock Gemfile.lock

RUN bundle install

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]

EXPOSE 3000
