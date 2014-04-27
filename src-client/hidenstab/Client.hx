package hidenstab;

import haxe.io.Bytes;
#if flash
import flash.net.Socket;
#else
import sys.net.Socket;
#end
import flash.utils.ByteArray;
import flash.events.Event;
import com.haxepunk.HXP;
import hidenstab.Defs;
import hidenstab.Stabber;


class Client
{
    static var _current:Client;
    public static var current(get, never):Client;
    static function get_current()
    {
        if (_current == null) _current = new Client();
        return _current;
    }
    
    public static function init()
    {
        current.connect();
    }
    
    public var socket:Socket;
    
    public var score:Int = 0;
    
    public var newChars:Array<Stabber>;
    public var chars:Map<Int, Stabber>;
    public var id:Int=-1;
    var buf:ByteArray;
    
    public var window:MainWindow;
    
    public function new()
    {
        chars = new Map();
        lastSeen = new Map();
        thisSeen = new Map();
        newChars = new Array();
        buf = new ByteArray();
    }
    
    public function connect()
    {
        socket = new Socket();
        socket.endian = flash.utils.Endian.LITTLE_ENDIAN;
        //socket.setBlocking(false);
#if flash
        var host = Defs.HOST;
#else
        var host = new sys.net.Host(Defs.HOST);
#end
        var port = Defs.PORT;
        socket.connect(host, port);
    }
    
    var waitForBytes:UInt = 0;
    
    public function update()
    {
        //trace(Std.int(socket.bytesAvailable) + "/" + waitForBytes);
        while (Std.int(socket.bytesAvailable) >= Math.max(waitForBytes, 4))
        {
            if (waitForBytes == 0)
            {
                // get the coming message size
                var b1:UInt = socket.readByte() & 0xFF;
                var b2:UInt = socket.readByte() & 0xFF;
                waitForBytes = (b1 << 8) + b2;
            }
            else
            {
                // read the complete message
                try
                {
                    socket.readBytes(buf, 0, waitForBytes);
                    buf.uncompress();
                    readMessage(buf);
                }
                catch(e:Dynamic)
                {
                    
                }
                buf.clear();
                waitForBytes = 0;
            }
            
            //trace(Std.int(socket.bytesAvailable) + "/" + waitForBytes);
        }
    }
    
    var lastSeen:Map<Int, Bool>;
    var thisSeen:Map<Int, Bool>;
    
    function readMessage(buf:ByteArray)
    {
        var msgType = buf.readByte();
        
        switch(msgType)
        {
            case Defs.MSG_SEND_GUID: {
                // receive this character's ID
                id = buf.readInt();
                score = 0;
                updateScoreLabel();
                HXP.screen.shake(4, 0.2);
            }
            case Defs.MSG_SEND_CHARS: {
                // character updates
                var n = buf.readByte();
                
                for (i in 0 ... n)
                {
                    var guid = buf.readInt();
                    var char:Stabber = chars.get(guid);
                    
                    var newChar:Bool = false;
                    
                    if (char == null)
                    {
                        char = StabberPool.get(guid);
                        chars[guid] = char;
                        newChars.push(char);
                        if (guid == id)
                        {
                            HXP.camera.x = char.x - Defs.WIDTH/2;
                            HXP.camera.y = char.y - Defs.HEIGHT/2;
                        }
                        
                        newChar = true;
                    }
                    
                    var x = buf.readFloat();
                    var y = buf.readFloat();
                    if (newChar || Math.max(Math.abs(char.x-x), Math.abs(char.y-y)) > char.width)
                    {
                        char.x = x;
                        char.y = y;
                    }
                    else
                    {
                        char.gradualMove(x, y);
                    }
                    
                    var mx = buf.readByte();
                    var my = buf.readByte();
                    var dir = buf.readBoolean();
                    if (true)//(guid != id)
                    {
                        char.moving.x = mx;
                        char.moving.y = my;
                        char.facingRight = dir;
                    }
                    var newState:Int = buf.readByte();
                    if (newState == 6)
                    {
                        char.pc = true;
                        if (guid == id)
                        {
                            HXP.screen.shake(4, 0.2);
                            window.contLabel.alpha = 1;
                            window.contLabel.visible = true;
                            window.needRespawn = true;
                        }
                    }
                    char.state = Stabber.intToState.get(newState);
                    
                    thisSeen.set(guid, true);
                }
                
                for (id in lastSeen.keys())
                {
                    if (!thisSeen.exists(id))
                    {
                        var thisChar = chars.get(id);
                        if (thisChar.state != Dead)
                        {
                            thisChar.scene.remove(thisChar);
                            chars.remove(id);
                            StabberPool.recycle(thisChar);
                        }
                    }
                    
                    lastSeen.remove(id);
                }
                
                var emptyMap = lastSeen;
                lastSeen = thisSeen;
                thisSeen = emptyMap;
            }
            case Defs.MSG_SEND_KILL_SUCCESS, Defs.MSG_SEND_KILL_FAIL:
            {
                var success = msgType == Defs.MSG_SEND_KILL_SUCCESS;
                
                if (success)
                {
                    score += 1;
                    window.killLabel.alpha = 1;
                    updateScoreLabel();
                    Sound.playSound("kill");
                }
                else
                {
                    window.failLabel.alpha = 1;
                    Sound.playSound("scatter");
                }
            }
            default: {}
        }
    }
    
    function updateScoreLabel()
    {
        window.scoreLabel.text = "Score: " + score;
        window.scoreLabel.scale = 2;
    }
}
