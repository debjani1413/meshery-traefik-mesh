FROM golang:1.13 as builder

ARG ENVIRONMENT="development"
ARG CONFIG_PROVIDER="viper"
WORKDIR /build
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download
# Copy the go source
COPY main.go main.go
COPY internal/ internal/
COPY traefik/ traefik/
# Build
RUN CGO_ENABLED=1 GOOS=linux GOARCH=amd64 GO111MODULE=on go build -ldflags="-w -s -X main.environment=$ENVIRONMENT -X main.provider=$CONFIG_PROVIDER" -a -o meshery-traefik-mesh main.go

# Use distroless as minimal base image to package the manager binary
# Refer to https://github.com/GoogleContainerTools/distroless for more details
FROM gcr.io/distroless/base
ENV DISTRO="debian"
ENV GOARCH="amd64"
WORKDIR /
COPY --from=builder /build/meshery-traefik-mesh .
ENTRYPOINT ["/meshery-traefik-mesh"]