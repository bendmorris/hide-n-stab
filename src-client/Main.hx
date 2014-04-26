import com.haxepunk.HXP;
import com.haxepunk.Engine;
import com.haxepunk.RenderMode;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import hidenstab.Defs;
import hidenstab.Client;
import hidenstab.MainWindow;


class Main extends Engine {
    public override function new(width:Int=0, height:Int=0, frameRate:Float=60, fixed:Bool=false, ?renderMode:RenderMode) {
        super(Defs.WIDTH, Defs.HEIGHT, frameRate, fixed, renderMode);
    }
    
    override public function init() {
#if !final
        HXP.console.enable();
#end
        Defs.init();
        Client.init();
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
}
