SD_CARD ?= /dev/null

dependencies:
	export MIX_TARGET=rpi0 \
	&& mix deps.get

firmware:
	export MIX_TARGET=rpi0 \
	&& mix firmware

sdcard:
	export MIX_TARGET=rpi0 \
	&& mix firmware.burn -d ${SD_CARD}
