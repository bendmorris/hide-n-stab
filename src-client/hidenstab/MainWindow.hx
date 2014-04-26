package hidenstab;

import flash.geom.Point;
import com.haxepunk.HXP;
import com.haxepunk.Scene;
import com.haxepunk.Entity;
import com.haxepunk.utils.Input;
import com.haxepunk.utils.Key;
import hidenstab.Backdrop;


class MainWindow extends Scene
{
    var s:Stabber;
    
    var moving:Point;
    
    override public function begin()
    {
        var b = new Backdrop();
        var e = new Entity(0, 0, b);
        e.layer = Defs.WORLD_WIDTH;
        add(e);
        
        moving = new Point();
        
        Input.define("up", [Key.UP, Key.W]);
        Input.define("down", [Key.DOWN, Key.S]);
        Input.define("left", [Key.LEFT, Key.A]);
        Input.define("right", [Key.RIGHT, Key.D]);
        Input.define("attack", [Key.SPACE, Key.X]);
        Input.define("talk", [Key.Z]);
        
        Client.init();
        
        s = new Stabber(1);
        add(s);
        
        s.x = Defs.WIDTH/2;
        s.y = Defs.HEIGHT/2;
    }
    
    override public function update()
    {
        //Client.current.update();
        
        if (Input.pressed("left")) moving.x = -1;
        if (Input.pressed("right")) moving.x = 1;
        if (Input.pressed("up")) moving.y = -1;
        if (Input.pressed("down")) moving.y = 1;
        if (Input.released("left")) moving.x = Input.check("right") ? 1 : 0;
        if (Input.released("right")) moving.x = Input.check("left") ? -1 : 0;
        if (Input.released("up")) moving.y = Input.check("down") ? 1 : 0;
        if (Input.released("down")) moving.y = Input.check("up") ? -1 : 0;
        
        s.moving.x = moving.x;
        s.moving.y = moving.y;
        
        if (Input.pressed("attack")) s.attack();
        if (Input.pressed("talk")) s.talk();
        
        HXP.camera.x = Std.int(HXP.clamp(HXP.camera.x, Math.max(0, s.x + s.width*3 - Defs.WIDTH), Math.min(Defs.WORLD_WIDTH - Defs.WIDTH, s.x - s.width*3)));
        HXP.camera.y = Std.int(HXP.clamp(HXP.camera.y, Math.max(0, s.y + s.height*3 - Defs.HEIGHT), Math.min(Defs.WORLD_HEIGHT - Defs.HEIGHT, s.y - s.height*3)));
        
        super.update();
    }
}
