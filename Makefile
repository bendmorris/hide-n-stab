assets: images

images: scripts/inkscape_split.py $(wildcard assets/spine/*.spine) $(wildcard assets/spine/*.svg)
	for i in $(wildcard assets/spine/*.svg); \
    do \
        python2 $< $$i; \
    done
	rm -f assets/spine/*_all*
	touch assets
