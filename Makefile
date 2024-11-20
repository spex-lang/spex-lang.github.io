SRC_FILES := $(wildcard src/*.md)

all: src/install.md $(patsubst src/%.md, dist/%.html, $(SRC_FILES)) dist/asset dist/style.css

src/install.md:
	curl \
		--silent \
		--show-error \
		--fail \
		--location \
		--output src/install.md \
		https://raw.githubusercontent.com/spex-lang/spex/refs/heads/main/INSTALL.md

dist/%.html: src/%.md 
	title="$(shell awk -F ': ' '/title:/ { print $$2 }' $<)" \
	      ./src/header.sh > $@
	pandoc --from gfm --to html5 \
		--syntax-definition highlight/spex.xml \
		--syntax-definition highlight/shell.xml \
		$< >> $@
	cat src/footer.html >> $@

dist/asset:
	cp -R asset dist/asset

dist/style.css: src/style.css
	cp src/style.css dist

publish:
	git subtree push --prefix dist origin gh-pages

clean:
	rm -f dist/*.html
	rm -rf dist/asset

distclean: clean
	rm -f src/install.md

.PHONY: all publish clean distclean
