FROM php:7.3-fpm

RUN apt-get update && apt-get install -y \
  socat \
  && rm -rf /var/lib/apt/lists/*

ENV NR_AGENT_VERSION 8.6.0.238

RUN curl -L https://download.newrelic.com/php_agent/release/newrelic-php5-${NR_AGENT_VERSION}-linux.tar.gz | tar -C /tmp -zx && \
  export NR_INSTALL_USE_CP_NOT_LN=1 && \
  export NR_INSTALL_SILENT=1 && \
  /tmp/newrelic-php5-*/newrelic-install install && \
  rm -rf /tmp/newrelic-php5-* /tmp/nrinstall*

# Copy example app to doc root
COPY index.php /var/www/html/

EXPOSE 33143
