LIBRARY=voc

$(LIBRARY).js: voc.md
	./voc.njs $^ > $@2
	mkdir -p old/
	cp $@ old/$@
	mv $@2 $@

.PHONY: lint
lint:
	@eslint --ext .js,.njs,.json voc.js voc.njs package.json
	@jshint --show-non-errors voc.js voc.njs package.json
