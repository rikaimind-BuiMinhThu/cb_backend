# Build from EC-ChatBot-Backend:
#   docker build --platform linux/amd64 -f rpa-lambda/Dockerfile -t lexica-rpa:latest .
# Ruby 3.3 is Amazon Linux 2023. Ruby 3.2 is Amazon Linux 2, whose rpm
# cannot install current Chrome (boolean Requires, old libcups).
FROM public.ecr.aws/lambda/ruby:3.3

RUN dnf install -y unzip tar gzip nss atk at-spi2-atk cups-libs gtk3 \
    libXcomposite libXcursor libXdamage libXext libXi libXrandr libXScrnSaver \
    libXtst pango alsa-lib xdg-utils fontconfig \
    && dnf clean all

# dnf on this image does not install the Chrome RPM from a local path
# ("No package matches"). The zip is the same Chrome build as ChromeDriver.
RUN set -eux \
    && CHROME_VERSION="$(curl -fsSL https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_STABLE)" \
    && curl -fsSL -o /tmp/chrome.zip "https://storage.googleapis.com/chrome-for-testing-public/${CHROME_VERSION}/linux64/chrome-linux64.zip" \
    && curl -fsSL -o /tmp/driver.zip "https://storage.googleapis.com/chrome-for-testing-public/${CHROME_VERSION}/linux64/chromedriver-linux64.zip" \
    && unzip -q /tmp/chrome.zip -d /opt \
    && unzip -q /tmp/driver.zip -d /tmp/driver \
    && ln -sf /opt/chrome-linux64/chrome /usr/bin/google-chrome \
    && mv /tmp/driver/chromedriver-linux64/chromedriver /usr/local/bin/chromedriver \
    && chmod +x /usr/local/bin/chromedriver /opt/chrome-linux64/chrome \
    && rm -rf /tmp/chrome.zip /tmp/driver.zip /tmp/driver \
    && google-chrome --version \
    && chromedriver --version

RUN mkdir -p /usr/share/fonts/noto \
    && curl -fsSL -o /usr/share/fonts/noto/NotoSansCJKjp-Regular.otf \
      https://github.com/notofonts/noto-cjk/raw/main/Sans/OTF/Japanese/NotoSansCJKjp-Regular.otf \
    && fc-cache -f || true

ENV CHROME_BIN=/usr/bin/google-chrome
ENV CHROMEDRIVER_PATH=/usr/local/bin/chromedriver
ENV SELENIUM_LOG=/tmp/selenium.log
ENV SELENIUM_SCREENSHOT_DIR=/tmp/selenium
ENV RAILS_ROOT=/var/task

RUN dnf install -y gcc make \
    && dnf clean all

COPY rpa-lambda/Gemfile rpa-lambda/Gemfile.lock ${LAMBDA_TASK_ROOT}/
RUN bundle install

COPY rpa-lambda/boot.rb rpa-lambda/handler.rb ${LAMBDA_TASK_ROOT}/
COPY app/services/log.rb ${LAMBDA_TASK_ROOT}/app/services/log.rb
COPY app/services/captcha ${LAMBDA_TASK_ROOT}/app/services/captcha
COPY app/services/selenium_services/base.rb ${LAMBDA_TASK_ROOT}/app/services/selenium_services/base.rb
COPY app/services/selenium_services/lexica.rb ${LAMBDA_TASK_ROOT}/app/services/selenium_services/lexica.rb
COPY app/services/selenium_services/lexica ${LAMBDA_TASK_ROOT}/app/services/selenium_services/lexica
COPY app/services/lexica/rpa_queue.rb ${LAMBDA_TASK_ROOT}/app/services/lexica/rpa_queue.rb
COPY app/services/lexica/rpa_dispatch.rb ${LAMBDA_TASK_ROOT}/app/services/lexica/rpa_dispatch.rb

CMD ["handler.Handler.process"]
