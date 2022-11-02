FROM alpine:3.16

RUN apk --no-cache add curl jq ncurses

ENV api_key=""
ENV service_url=""
ENV secret_name=""
ENV secret_type="kv"

COPY scanner.sh .

ENTRYPOINT ["./scanner.sh"]
