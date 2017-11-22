DC = dmd

all: test

GADGET_SRC := source/package.d source/collision.d source/types.d source/world.d

#.PHONY: libgadget.a
#libgadget.a:
	#dub build

test: test.d $(GADGET_SRC)
	$(DC) -of=$@.x $^ -L-lsfml-graphics -L-lsfml-window -L-lsfml-system
