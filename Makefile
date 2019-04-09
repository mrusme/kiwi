BURN_DEVICE ?= /dev/null

mixdeps:
	export MIX_TARGET=rpi0 \
	&& mix deps.get

firmware:
	export MIX_TARGET=rpi0 \
	&& mix firmware

burn:
	export MIX_TARGET=rpi0 \
	&& mix firmware.burn -d ${BURN_DEVICE}
