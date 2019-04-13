SD_CARD ?= /dev/null
HOSTNAME := $(shell hostname)

dependencies:
	export MIX_TARGET=rpi0 \
	&& mix deps.get

develop:
	export MNESIA_DUMP_DIRECTORY=Mnesia.kiwi@$(HOSTNAME) \
	&& export MIX_ENV=dev \
	&& iex -S mix

firmware:
	export MIX_TARGET=rpi0 \
	&& mix firmware

sdcard:
	export MIX_TARGET=rpi0 \
	&& mix firmware.burn -d ${SD_CARD}

release:
	export MIX_TARGET=rpi0 \
	&& mix firmware.burn -d kiwi.fw
