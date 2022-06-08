# syntax=docker/dockerfile:1

FROM golang:1.18-alpine AS build

WORKDIR /app

COPY go.mod ./
COPY go.sum ./
RUN go mod download

COPY *.go ./
RUN CGO_ENABLED=0 go build  -a -installsuffix cgo -ldflags "-s" -o /labkube *.go

FROM busybox

WORKDIR /
RUN ["touch", "/ready"]

COPY --from=build /labkube /labkube
COPY LICENSE /LICENSE

EXPOSE 8080
ENTRYPOINT ["/labkube"]