package hidenstab;

import flash.geom.Point;
import com.haxepunk.HXP;
import com.haxepunk.Scene;
import com.haxepunk.Entity;
import com.haxepunk.graphics.BitmapText;
import com.haxepunk.utils.Input;
import com.haxepunk.utils.Key;
import hidenstab.Backdrop;
import hidenstab.Stabber;


class MainWindow extends Scene
{
    public static inline var FONT_NAME='font/perfect_dos.fnt';
    public static inline var FONT_SIZE:Int=24;
    public static inline var FONT_COLOR:Int=0xFFFFFF;
    public static var FONT_OPTIONS={font:FONT_NAME, size:FONT_SIZE, color:FONT_COLOR};
    
    static inline var TEXT_FADE_RATE:Float=1;
    
    var moving:Point;
    
    var lastMovingSent:Point;
    var lastMovingSentTime:Float=0;
    
    var seenDead:Map<Int, Bool>;
    
    public var killLabel:BitmapText;
    public var failLabel:BitmapText;
    public var scoreLabel:BitmapText;
    
    override public function begin()
    {
        seenDead = new Map();
        
        var b = new Backdrop();
        var e = new Entity(0, 0, b);
        e.layer = Defs.WORLD_HEIGHT + 1;
        add(e);
        
        moving = new Point();
        lastMovingSent = new Point();
        
        Input.define("up", [Key.UP, Key.W]);
        Input.define("down", [Key.DOWN, Key.S]);
        Input.define("left", [Key.LEFT, Key.A]);
        Input.define("right", [Key.RIGHT, Key.D]);
        Input.define("attack", [Key.SPACE, Key.X, Key.K]);
        Input.define("talk", [Key.Z, Key.L]);
        
        Client.init();
        Client.current.window = this;
        
        failLabel = new BitmapText("That wasn't a real person...",
                                   Std.int(Defs.WIDTH/2), Std.int(Defs.HEIGHT/2),
                                   0, 0, FONT_OPTIONS);
        killLabel = new BitmapText("You killed a real person!",
                                   Std.int(Defs.WIDTH/2), Std.int(Defs.HEIGHT/2),
                                   0, 0, FONT_OPTIONS);
        killLabel.color = 0xFF0000;
        scoreLabel = new BitmapText("Score: 0",
                                   4, -1,
                                   0, 0, FONT_OPTIONS);
        scoreLabel.color = 0xFF0000;
        
        for (g in [killLabel, failLabel])
        {
            g.alpha = 0;
            g.visible = false;
            g.computeTextSize();
            g.x -= g.textWidth/2;
        }
        
        for (g in [killLabel, failLabel, scoreLabel])
        {
            g.scrollX = g.scrollY = 0;
            var e = new Entity(0, 0, g);
            e.layer = -1;
            add(e);
        }
    }
    
    override public function update()
    {
        var client = Client.current;
        
        if (killLabel.alpha > 0)
        {
            killLabel.visible = true;
            killLabel.alpha -= HXP.elapsed/TEXT_FADE_RATE/2;
            if (killLabel.alpha <= 0)
            {
                killLabel.visible = false;
            }
        }
        if (failLabel.alpha > 0)
        {
            failLabel.visible = true;
            failLabel.alpha -= HXP.elapsed/TEXT_FADE_RATE/2;
            if (failLabel.alpha <= 0)
            {
                failLabel.visible = false;
            }
        }
        
        if (scoreLabel.scale > 1)
        {
            scoreLabel.scale = Math.max(1, scoreLabel.scale - HXP.elapsed/TEXT_FADE_RATE);
        }
        
        client.update();
        
        while (client.newChars.length > 0)
        {
            var newChar = client.newChars.pop();
            if (!seenDead.exists(newChar.guid))
            {
                add(newChar);
            }
        }
        
        if (client.id != -1)
        {
            var s:Stabber = client.chars.get(client.id);
            
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
                
                var curTime = Date.now().getTime();
                
                if (moving.x != lastMovingSent.x || moving.y != lastMovingSent.y || curTime - lastMovingSentTime > Defs.MOVE_SEND_FREQ)
                {
                    var ba = Data.getByteArray();
                    ba.writeByte(Defs.MSG_SEND_MOVING);
                    ba.writeInt(client.id);
                    ba.writeByte(Std.int(moving.x));
                    ba.writeByte(Std.int(moving.y));
                    Data.write(client.socket);
                    
                    lastMovingSent.x = moving.x;
                    lastMovingSent.y = moving.y;
                    lastMovingSentTime = curTime;
                }
                
                if (Input.pressed("attack")) {
                    s.attack();
                    
                    var ba = Data.getByteArray();
                    ba.writeByte(Defs.MSG_SEND_ATTACK);
                    ba.writeInt(client.id);
                    Data.write(client.socket);
                }
                if (Input.pressed("talk")) {
                    s.talk();
                    
                    var ba = Data.getByteArray();
                    ba.writeByte(Defs.MSG_SEND_TALK);
                    ba.writeInt(client.id);
                    Data.write(client.socket);
                }
                
                HXP.camera.x = Std.int(HXP.clamp(HXP.camera.x, 
                    Math.max(0, s.x + s.width*4 - Defs.WIDTH), 
                    Math.min(Defs.WORLD_WIDTH - Defs.WIDTH, s.x - s.width*4)));
                HXP.camera.y = Std.int(HXP.clamp(HXP.camera.y, 
                    Math.max(0, s.y + s.height*4 - Defs.HEIGHT), 
                    Math.min(Defs.WORLD_HEIGHT - Defs.HEIGHT, s.y - s.height*4)));
            }
            else
            {
                centerCamera();
            }
        }
        else
        {
            centerCamera();
        }
        
        for (key in client.chars.keys())
        {
            var char = client.chars.get(key);
            if (char.dead)
            {
                client.chars.remove(key);
                remove(char);
                StabberPool.recycle(char);
                seenDead.set(char.guid, true);
            }
        }
        
        super.update();
    }
    
    function centerCamera()
    {
        HXP.camera.x = Defs.WORLD_WIDTH/2 - Defs.WIDTH/2;
        HXP.camera.y = Defs.WORLD_HEIGHT/2 - Defs.HEIGHT/2;
    }
}
