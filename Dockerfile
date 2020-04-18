FROM alpine:edge
MAINTAINER Sylvain Desbureaux <sylvain@desbureaux.fr> #Original creator of this Dockerfile
MAINTAINER Cedric Gatay <c.gatay@code-troopers.com>

# install packages &
## OpenZwave installation &
# grep git version of openzwave &
# untar the files &
# compile &
# "install" in order to be found by domoticz &
## Domoticz installation &
# clone git source in src &
# Domoticz needs the full history to be able to calculate the version string &
# prepare makefile &
# compile &
# remove git and tmp dirs

ARG APP_HASH
ARG VCS_REF
ARG BUILD_DATE

LABEL org.label-schema.vcs-ref=$APP_HASH \
      org.label-schema.vcs-url="https://github.com/domoticz/domoticz" \
      org.label-schema.url="https://domoticz.com/" \
      org.label-schema.name="Domoticz" \
      org.label-schema.docker.dockerfile="/Dockerfile" \
      org.label-schema.license="GPLv3" \
      org.label-schema.build-date=$BUILD_DATE

RUN apk add --no-cache \
		git \
		build-base cmake \
		ninja \
		python3 python3-dev \
		boost-dev \
		boost-thread \
		boost-system \
		boost-date_time \
		sqlite sqlite-dev \
		curl libcurl curl-dev \
		libressl libressl-dev \
		libusb libusb-dev \
		libusb-compat libusb-compat-dev \
		lua5.3-libs lua5.3-dev \
		openzwave openzwave-dev \
		minizip-dev \
		mosquitto-dev \
		coreutils \
		tzdata \
		zlib zlib-dev \
		udev eudev-dev \
		linux-headers && \
        # Link lua for domoticz build
        ln -s /usr/lib/liblua-5.3.so.0 /usr/lib/liblua-5.3.so && \
        # Cereal
        git clone https://github.com/USCiLab/cereal.git /src/cereal && \
        cd /src/cereal && \
        mkdir build && \
        cd build && cmake -G "Ninja" .. \
          -DCMAKE_INSTALL_PREFIX=/usr \
          -DSKIP_PORTABILITY_TEST=ON \
          -DTHREAD_SAFE=ON \
          -DWITH_WERROR=OFF && \
        ninja && ninja install && \
        cd / && \
        rm -rf /src/cereal && \
	# Build Domoticz
	git clone https://github.com/muellni/domoticz.git /src/domoticz && \
	cd /src/domoticz && \
	git reset --hard ${APP_HASH} && \
	cmake -G "Ninja" \
	 	-DBUILD_SHARED_LIBS=True \
	 	-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=/opt/domoticz \
		-DUSE_LUA_STATIC=OFF \
		-DUSE_BUILTIN_MINIZIP=OFF \
		-DUSE_STATIC_BOOST=False \
		-DUSE_BUILTIN_MQTT=OFF \
		-DUSE_BUILTIN_SQLITE=OFF \
		-DUSE_STATIC_OPENZWAVE=OFF \
		-Wno-dev && \
	ninja && \
	ninja install && \
	rm -rf /src/domoticz/ && \
	# Cleanup
	apk del \ 
		git \
		ninja \
		build-base cmake \
		python3-dev \
		boost-dev \
		sqlite-dev \
		curl-dev \
		libressl-dev \
		libusb-dev \
		libusb-compat-dev \
		lua5.3-dev \
		openzwave-dev \
		coreutils \
		zlib-dev \
		eudev-dev \
		linux-headers

VOLUME /config

EXPOSE 8080

ENTRYPOINT ["/opt/domoticz/domoticz", "-dbase", "/config/domoticz.db", "-log", "/config/domoticz.log"]
CMD ["-www", "8080"]
