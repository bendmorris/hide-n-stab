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
    
    public var newChars:Array<Stabber>;
    public var chars:Map<Int, Stabber>;
    public var id:Int=-1;
    var buf:ByteArray;
    
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
    
    var waitForBytes:Int = 0;
    
    public function update()
    {
        if (Std.int(socket.bytesAvailable) >= Math.max(waitForBytes, 1))
        {
            if (waitForBytes == 0)
            {
                // get the coming message size
                waitForBytes = socket.readByte();
            }
            else
            {
                // read the complete message
                socket.readBytes(buf, 0, waitForBytes);
                //buf.uncompress();
                readMessage(buf);
                buf.clear();
                waitForBytes = 0;
            }
        }
        
        var ba = Data.getByteArray();
        ba.writeByte(Defs.MSG_SEND_CHARS);
        Data.write(socket);
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
                    
                    var x = buf.readUnsignedInt();
                    var y = buf.readUnsignedInt();
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
                    if (guid != id)
                    {
                        char.moving.x = mx;
                        char.moving.y = my;
                        char.facingRight = dir;
                    }
                    var newState:Int = buf.readByte();
                    if (newState == 6)
                    {
                        char.pc = true;
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
            default: {}
        }
    }
}
