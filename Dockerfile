FROM alpine:3.7

LABEL maintainer="David Coppit <david@coppit.org>"

ENV TERM=xterm-256color

RUN \
  echo "http://dl-cdn.alpinelinux.org/alpine/v3.7/community" >> /etc/apk/repositories && \
  apk --update upgrade && \
  # Basics, including runit
  apk add bash curl htop runit && \
  # Needed by our code
  apk add expect libc6-compat && \
  rm -rf /var/cache/apk/* && \
  # RunIt stuff
  adduser -h /home/user-service -s /bin/sh -D user-service -u 2000 && \
  chown user-service:user-service /home/user-service && \
  mkdir -p /etc/run_once /etc/service

# Boilerplate startup code
COPY ./boot.sh /sbin/boot.sh
RUN chmod +x /sbin/boot.sh
CMD [ "/sbin/boot.sh" ]

VOLUME ["/config"]

RUN \
  mkdir /files \
  && chmod a+rwX /files \
  && cd /files \
  && curl https://www.noip.com/client/linux/noip-duc-linux.tar.gz | tar xvz \
  && cd noip-2.1.9-1 \
  && apk add alpine-sdk \
  && make \
  && mv noip2 /files/ \
  && apk del alpine-sdk \
  && cd /files \
  && rm -rf /files/noip-2.1.9-1

COPY ["noip.conf", "create_config.exp", "/files/"]

# run-parts ignores files with "." in them
COPY parse_config_file.sh /etc/run_once/parse_config_file
RUN chmod +x /etc/run_once/parse_config_file

COPY noip.sh /etc/service/noip/run
RUN chmod +x /etc/service/noip/run
