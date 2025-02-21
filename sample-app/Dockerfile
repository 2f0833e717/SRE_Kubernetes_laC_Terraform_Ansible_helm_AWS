FROM golang:1.21-alpine

WORKDIR /app
COPY main.go .

RUN go mod init sample-app && \
    go mod tidy && \
    go build -o main .

EXPOSE 8080
CMD ["./main"] 