all: assets


.PHONY: server


debug: flash-debug

flash:
	haxelib run openfl build flash -v
	chromium flash.html
flash-debug:
	haxelib run openfl build flash -debug -v
	chromium flash.html
flash-final:
	haxelib run openfl build flash -Dfinal -v
	chromium flash.html
flash-build:
	haxelib run openfl build flash -debug -v

neko:
	haxelib run openfl build linux -neko -Ddesktop -v
	bin/linux64/neko/bin/hidenstab
neko-final:
	haxelib run openfl build linux -neko -Ddesktop -Dfinal -v
	bin/linux64/neko/bin/hidenstab

linux:
	haxelib run openfl test linux -Ddesktop -v
linux-debug:
	haxelib run openfl test linux -Ddesktop -v -debug
linux-final:
	haxelib run openfl test linux -Ddesktop -Dfinal -v


server:
	haxe -main hidenstab.Server -neko server.n -cp src -cp src-server -lib openfl -lib openfl-native -lib HaxePunk --macro "allowPackage('flash')" -D server
	nekotools boot server.n
server-run: server
	./server


assets: images sounds

images: scripts/inkscape_split.py $(wildcard assets/spine/*.spine) $(wildcard assets/spine/*.svg)
	for i in $(wildcard assets/spine/*.svg); \
    do \
        python2 $< $$i; \
    done
	rm -f assets/spine/*_all*
	touch assets

sounds: $(patsubst assets/sound/%.wav, assets/sound/%.mp3, $(wildcard assets/sound/*.wav))

%.mp3: %.wav
	rm -f $@
	ffmpeg -i $< -acodec libmp3lame -ab 192k -ar 11025 $@
