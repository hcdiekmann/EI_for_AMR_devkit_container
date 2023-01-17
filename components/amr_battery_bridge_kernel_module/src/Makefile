obj-m += src/battery_bridge.o

KERN_VER=$(shell uname -r)

all:
	make -C /lib/modules/$(KERN_VER)/build M=$(shell pwd) modules

clean:
	rm -f src/.*.cmd src/*.ko src/*.o src/*.mod Module.symvers modules.order src/*.mod.c
