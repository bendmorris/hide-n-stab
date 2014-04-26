import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.display.Sprite;
import flash.events.Event;
import flash.geom.Point;
import flash.geom.Rectangle;
import com.haxepunk.HXP;
import com.haxepunk.graphics.Image;
import haxe.Timer;
import hidenstab.Defs;


@:bitmap("assets/graphics/monsterface.png")
class Logo extends BitmapData {}

class Preloader extends NMEPreloader
{
    public var img:Bitmap;
    public var timer:Timer;
    public var fadeout_time:Float=0;
    public static inline var FADEOUT_TIME:Float=0.25;
    static inline var w = Defs.WIDTH*Defs.SCALE;
    static inline var h = Defs.HEIGHT*Defs.SCALE;

    public function new()
    {
        img = new Bitmap(new Logo(0,0));
        
        super();
        
        outline.x = (w - (img.width))/2;
        outline.y = (h - (img.height))/2;
        
        progress.y = outline.y + outline.height + 60 * Defs.SCALE;
        
        outline.graphics.clear();
        outline.addChild(img);
    }
    
    public override function onLoaded()
    {
        timer = new Timer(Math.floor(1000/20));
        timer.run = fadeout;
    }
    
    function fadeout()
    {
        fadeout_time += 1/(FADEOUT_TIME*20);
        if (fadeout_time >= 1) {
            img.alpha = progress.alpha = Math.max(0, img.alpha - 1/(FADEOUT_TIME*20));
            if (img.alpha <= 0) {
                timer.stop();
                done();
            }
        }
    }
    
    function done()
    {
        dispatchEvent (new Event (Event.COMPLETE));
    }
    
    public override function getWidth():Float
    {
        return w;
    }
}
