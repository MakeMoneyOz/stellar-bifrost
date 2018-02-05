FROM golang:alpine as builder

ADD apk-build /apk-build
RUN chmod +x /apk-build
RUN /apk-build

#install unzip 
#RUN apk add unzip

# Deploy Ellaism Geth Binary
#RUN mkdir -p /go/src/github.com/ellaism/ \
#	&& cd /go/src/github.com/ellaism \
#	&& wget https://github.com/ellaism/go-ellaism/releases/download/v4.2.1/geth-ellaism-linux.zip \
#	&& unzip /go/src/github.com/ellaism/geth-ellaism-linux.zip
#
# deploy bifrost binary
RUN mkdir -p /go/src/github.com/stellar/ \
    && git clone --depth 1 --branch master https://github.com/MakeMoneyOz/go.git /go/src/github.com/stellar/go \
    && cd /go/src/github.com/stellar/go \
    && curl https://glide.sh/get | sh \
    && glide install \
    && go install github.com/stellar/go/services/bifrost


    # deploy db init script
    ADD initbifrost /go/src/github.com/stellar/initbifrost
    RUN go get github.com/lib/pq \
        && go install github.com/stellar/initbifrost

# -----------------------
FROM alpine:latest
#COPY --from=builder /go/src/github.com/ellaism/geth /go/bin/geth
COPY --from=builder /go/bin/bifrost /go/bin/bifrost
COPY --from=builder /go/bin/initbifrost /go/bin/initbifrost
COPY --from=builder /go/src/github.com/stellar/go/services/bifrost/database/migrations/01_init.sql /go/src/github.com/stellar/go/services/bifrost/database/migrations/01_init.sql

ADD build-config /usr/bin/build-config
RUN chmod +x /usr/bin/build-config

RUN ["mkdir", "-p", "/opt/bifrost"]

ADD entry.sh /entry.sh
RUN chmod +x /entry.sh

ADD apk-server /apk-server
RUN chmod +x /apk-server
RUN /apk-server

ADD configs /configs

ENTRYPOINT ["/entry.sh"]

EXPOSE 8800
