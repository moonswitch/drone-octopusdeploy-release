FROM alpine:3.9

RUN apk -Uuv add curl ca-certificates bash jq httpie

ADD release.sh /bin/
RUN chmod +x /bin/release.sh

ENTRYPOINT /bin/release.sh
