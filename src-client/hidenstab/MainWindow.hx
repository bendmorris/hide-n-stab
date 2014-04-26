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
    
    var lastMovingSent:Point;
    
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
    }
    
    override public function update()
    {
        var client = Client.current;
        
        client.update();
        
        while (client.newChars.length > 0)
        {
            var newChar = client.newChars.pop();
            trace('a new char: ' + newChar.guid);
            add(newChar);
        }
        
        trace('before');
        if (client.id != -1)
        {
            s = client.chars.get(client.id);
            
            if (s != null)
            {
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
                
                if (moving.x != lastMovingSent.x || moving.y != lastMovingSent.y)
                {
                    var ba = Data.getByteArray();
                    ba.writeInt(moving.x);
                    ba.writeInt(moving.y);
                    Data.send(client.socket);
                }
                
                if (Input.pressed("attack")) {
                    s.attack();
                    var ba = Data.getByteArray();
                    ba.writeByte(Defs.MSG_SEND_ATTACK);
                    Data.send(client.socket);
                }
                if (Input.pressed("talk")) {
                    s.talk();
                    var ba = Data.getByteArray();
                    ba.writeByte(Defs.MSG_SEND_TALK);
                    Data.send(client.socket);
                }
                
                HXP.camera.x = Std.int(HXP.clamp(HXP.camera.x, 
                    Math.max(0, s.x + s.width*3 - Defs.WIDTH), 
                    Math.min(Defs.WORLD_WIDTH - Defs.WIDTH, s.x - s.width*3)));
                HXP.camera.y = Std.int(HXP.clamp(HXP.camera.y, 
                    Math.max(0, s.y + s.height*3 - Defs.HEIGHT), 
                    Math.min(Defs.WORLD_HEIGHT - Defs.HEIGHT, s.y - s.height*3)));
            }
        }
        
        trace('after');
        super.update();
    }
}
