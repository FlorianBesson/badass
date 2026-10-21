FROM alpine:3.24.2
RUN apk add --no-cache busybox
CMD ["tail", "-f", "/dev/null"]
