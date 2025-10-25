# Copyright 2023 LiveKit, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM golang:1.25-alpine AS builder

LABEL stage=gobuilder

ENV CGO_ENABLED 0
ENV GOOS linux
ENV GOPROXY https://goproxy.cn,direct
ENV HTTP_PROXY http://192.168.16.148:7890
ENV HTTPS_PROXY http://192.168.16.148:7890
RUN echo "nameserver 223.6.6.6" > /etc/resolv.conf
RUN apk update --no-cache && apk add --no-cache tzdata

# ARG TARGETPLATFORM
# ARG TARGETARCH
# RUN echo building for "$TARGETPLATFORM"

WORKDIR /workspace

# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

# Copy the go source
COPY cmd/ cmd/
COPY pkg/ pkg/
COPY test/ test/
COPY tools/ tools/
COPY version/ version/

RUN CGO_ENABLED=0 GOOS=linux GO111MODULE=on go build -a -o livekit-server ./cmd/server

FROM alpine

COPY --from=builder /workspace/livekit-server /livekit-server

# Run the binary.
ENTRYPOINT ["/livekit-server"]
