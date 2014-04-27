import flash.geom.Point;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.display.BitmapData;
import com.haxepunk.HXP;
import com.haxepunk.Engine;
import com.haxepunk.RenderMode;
import hidenstab.Defs;
import hidenstab.MainWindow;


class Main extends Engine {
#if flash
    static var rArray:Array<Int> = [];
    static var gArray:Array<Int> = [];
    static var bArray:Array<Int> = [];
    public static inline var COLOR_LEVELS:Int=16;
#end
    
    public override function new(width:Int=0, height:Int=0, frameRate:Float=60, fixed:Bool=false, ?renderMode:RenderMode) {
        super(Defs.WIDTH, Defs.HEIGHT, frameRate, fixed, RenderMode.BUFFER);
    }
    
    override public function init() {
#if !final
        HXP.console.enable();
#end
    
#if flash
        var clevel = Math.floor(256/COLOR_LEVELS);
        for (n in 0...COLOR_LEVELS) {
            var val = n==(COLOR_LEVELS-1) ? 255 : Math.floor(247/(COLOR_LEVELS)*n);
            rArray = rArray.concat([for (i in clevel*n ... clevel*(n+1)) val<<16]);
            gArray = gArray.concat([for (i in clevel*n ... clevel*(n+1)) val<<8]);
            bArray = bArray.concat([for (i in clevel*n ... clevel*(n+1)) val]);
        }
#end
        
        
        Defs.init();
        HXP.screen.color = Defs.BGCOLOR;
        HXP.scene = new MainWindow();
    }
    
    public static function main() { new Main(); }
    
    public override function onStage(e:Event = null) {
        super.onStage();
    }
    
    override public function update()
    {
        super.update();
    }
    
#if flash
    override public function render()
    {
        super.render();
        
        paletteMap(HXP.buffer);
    }
    
    static var p:Point = new Point(0,0);
    static inline function paletteMap(buffer:BitmapData)
    {
        buffer.paletteMap(buffer, buffer.rect, p,
                          rArray, gArray, bArray);
    }
#end
}
