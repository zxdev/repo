# build linux/amd64 on macOS
FROM --platform=linux/amd64 golang:alpine as base

# RUN adduser \
#   --disabled-password \
#   --gecos "" \
#   --home "/nonexistent" \
#   --shell "/sbin/nologin" \
#   --no-create-home \
#   --uid 65532 \
#   scratch-user

WORKDIR /app

COPY . .

RUN go mod download
RUN go mod verify

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
-trimpath \
-ldflags "-s -w -X github.com/zxdev/env/v2.Version=docker -X github.com/zxdev/env/v2.Build=linux/amd64"  \
-o /server app/main.go

FROM scratch
#FROM alpine

COPY --from=base /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
#COPY --from=base /etc/passwd /etc/passwd
#COPY --from=base /etc/group /etc/group

COPY --from=base /server .

#USER  scratch-user:scratch-user

#EXPOSE 1455
#ENV HOST=0.0.0.0

CMD ["./server"]