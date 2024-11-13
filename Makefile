all: index.html install.html community.html

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
	pandoc --from gfm --to html5 $< >> $@
	cat footer.html >> $@

clean:
	rm -f index.html install.md install.html community.html

.PHONY: all clean
