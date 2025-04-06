FROM golang:1.18-alpine AS builder

WORKDIR /app

COPY . .

RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -o x-ui -ldflags "-s -w" .

FROM alpine:latest

WORKDIR /usr/local/x-ui

COPY --from=builder /app/x-ui /usr/local/x-ui/
COPY bin/ /usr/local/x-ui/bin/
COPY web/ /usr/local/x-ui/web/

RUN mkdir -p /etc/x-ui
RUN chmod +x /usr/local/x-ui/x-ui

VOLUME ["/etc/x-ui"]

ENTRYPOINT ["/usr/local/x-ui/x-ui"]
