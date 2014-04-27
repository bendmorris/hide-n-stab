package hidenstab;

import flash.net.Socket;
import flash.utils.ByteArray;
import flash.events.Event;
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
    
    public function new()
    {
        chars = new Map();
        lastSeen = new Map();
        thisSeen = new Map();
        newChars = new Array();
    }
    
    public function connect()
    {
        socket = new Socket();
        socket.addEventListener(Event.CONNECT, onConnect);
        var host = Defs.HOST;
        var port = Defs.PORT;
        socket.connect(host, port);
    }
    
    public function update()
    {
        while (socket.bytesAvailable > 0)
        {
            var buf = new ByteArray();
            socket.readBytes(buf);
            readMessage(buf);
        }
    }
    
    var lastSeen:Map<Int, Bool>;
    var thisSeen:Map<Int, Bool>;
    
    function onConnect(d:Dynamic)
    {
    }
    
    function readMessage(buf:ByteArray)
    {
        var msgType = buf.readByte();
        
        switch(msgType)
        {
            case Defs.MSG_SEND_GUID: {
                // receive this character's ID
                id = buf.readUnsignedInt();
            }
            case Defs.MSG_SEND_CHARS: {
                // character updates
                var n = buf.readByte();
                
                for (i in 0 ... n)
                {
                    var guid = buf.readInt();
                    var char:Stabber = chars.get(guid);
                    
                    if (char == null)
                    {
                        char = StabberPool.get(guid);
                        chars[guid] = char;
                        newChars.push(char);
                    }
                    
                    char.x = buf.readInt();
                    char.y = buf.readInt();
                    if (guid != id)
                    {
                        char.moving.x = buf.readByte();
                        char.moving.y = buf.readByte();
                    }
                    var stateChanged = buf.readBoolean();
                    if (stateChanged)
                    {
                        var newState:UInt = buf.readByte();
                        char.state = Stabber.intToState.get(newState);
                    }
                    
                    thisSeen.set(guid, true);
                }
                
                for (id in lastSeen.keys())
                {
                    if (!thisSeen.exists(id))
                    {
                        var thisChar = chars.get(id);
                        thisChar.scene.remove(thisChar);
                        chars.remove(id);
                    }
                    
                    lastSeen.remove(id);
                }
                
                var emptyMap = lastSeen;
                lastSeen = thisSeen;
                thisSeen = emptyMap;
            }
        }
    }
}