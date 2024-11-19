HTML := index.html documentation.html motivation.html tutorial.html install.html community.html

all: $(HTML)

install.md:
	curl \
		--silent \
		--show-error \
		--fail \
		--location \
		--output install.md \
		https://raw.githubusercontent.com/spex-lang/spex/refs/heads/main/INSTALL.md

%.html: %.md 
	title="$(shell awk -F ': ' '/title:/ { print $$2 }' $<)" \
	      ./header.sh > $@
	pandoc --from gfm --to html5 --syntax-definition spex.xml $< >> $@
	cat footer.html >> $@

clean:
	rm -f $(HTML) install.md

.PHONY: all clean
