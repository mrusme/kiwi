SD_CARD ?= /dev/null
HOSTNAME := $(shell hostname)

dependencies:
	export MIX_TARGET=rpi0 \
	&& mix deps.get

develop:
	export MNESIA_DUMP_DIRECTORY=Mnesia.kiwi@$(HOSTNAME) \
	&& export NERVES_NETWORK_OBS_SOCKET='ws://127.0.0.1:4444' \
	&& export MIX_ENV=dev \
	&& iex -S mix

firmware:
	export MIX_TARGET=rpi0 \
	&& mix firmware

sdcard:
	export MIX_TARGET=rpi0 \
	&& mix deps.clean --all \
	&& mix deps.get \
	&& mix deps.compile --all \
	&& mix firmware.burn -d ${SD_CARD}

release:
	export MIX_TARGET=rpi0 \
	&& mix firmware.burn -d kiwi.fw
