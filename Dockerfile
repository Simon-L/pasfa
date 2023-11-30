FROM openresty/openresty:jammy

ARG SQLITE_YEAR="2023"
ARG SQLITE_VERSION="3440200"

WORKDIR /root/work
COPY . .

RUN wget https://www.sqlite.org/${SQLITE_YEAR}/sqlite-autoconf-${SQLITE_VERSION}.tar.gz \
    && tar -xzf sqlite-autoconf-${SQLITE_VERSION}.tar.gz \
    && cd sqlite-autoconf-${SQLITE_VERSION} \
    && ./configure \
    && make -j$(nproc) \
    && make install

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        libssl-dev \
        build-essential \
        git
    
RUN rm -f /root/work/skipcache \
    && rm -f /root/work/sqlite-autoconf-${SQLITE_VERSION}.tar.gz \
    && rm -rf /root/work/sqlite-autoconf-${SQLITE_VERSION}

RUN luarocks build --only-deps ./pasfa-dev-1.rockspec
RUN git clone https://github.com/grame-cncm/faust /root/work/faust
RUN cd /root/work/faust && git submodule update --init libraries

RUN resty scripts/init.lua /root/work/faust
 
RUN lapis exec "print('Ready!')"
