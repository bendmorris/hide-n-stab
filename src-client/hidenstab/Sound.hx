package hidenstab;

import com.haxepunk.HXP;
import com.haxepunk.Sfx;


class Sound
{
    public static inline var MAX_SFX_VOLUME:Float=0.25;
    public static inline var MAX_MUSIC_VOLUME:Float=1;
    
    public static var muted(default, set):Bool=false;
    static function set_muted(m:Bool)
    {
        HXP.volume = m ? 0 : 1;
        return muted = m;
    }
    
    public static var audio:Map<String, Sfx>;
#if flash
    public static inline var soundSuffix=".mp3";
#else
    public static inline var soundSuffix=".wav";
#end

    public static function init() {
        audio = new Map<String, Sfx>();
        
        var sounds = ['attack', 'scatter', 'kill'];
        for (file in sounds) {
            loadSound(file);
        }
    }

    static inline function loadSound(file) {
        audio[file] = new Sfx("sound/" + file + soundSuffix);
        audio[file].type = "sound";
    }
    
    public static function playSound(name, loop=false) {
        if (muted) return;
        if (!audio.exists(name)) loadSound(name);
        if (loop) audio[name].loop() else audio[name].play();
    }
}
