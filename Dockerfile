FROM alpine:latest

WORKDIR /root/

COPY . .

RUN apk add --no-cache tzdata \
    && chmod +x x-ui \
    && chmod +x bin/xray-linux-* \
    && chmod +x x-ui.sh

ENV TZ=Asia/Shanghai

EXPOSE 54321

ENTRYPOINT ["./x-ui"]
