LIBRARY=voc

$(LIBRARY).js: voc.md
	./voc.njs $^ > $@2
	mkdir -p old/
	cp $@ old/$@
	mv $@2 $@
