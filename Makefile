DC = dmd

all: test

GADGET_SRC := source/physics/package.d source/physics/collision.d \
	source/physics/types.d source/physics/world.d

#.PHONY: libgadget.a
#libgadget.a:
	#dub build

test: test.d $(GADGET_SRC)
	$(DC) -of=$@.x $^ -L-lsfml-graphics -L-lsfml-window -L-lsfml-system
