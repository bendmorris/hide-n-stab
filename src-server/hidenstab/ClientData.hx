package hidenstab;

import sys.net.Socket;
import hidenstab.Defs;
import hidenstab.Stabber;


class ClientData {
    public var socket:Socket;
    public var stabber:Stabber;
    public var guid:Guid;
    
    public function new(s:Socket)
    {
        socket = s;
        (cast s).__private = this;
        guid = Std.random(Defs.MAX_INT);
        stabber = StabberPool.get(guid, true);
        nearby = new Array();
    }
    
    // called when the player's client has been disconnected
    public function leave()
    {
        
    }
    
    public static function ofSocket(s:Socket):ClientData
    {
        return (cast s).__private;
    }
    
    var nearby:Array<Stabber>;
    var nearbyCount:Int=0;
    
    public function update(chars:Map<Guid, Stabber>)
    {
        for (guid in chars.keys())
        {
            var char = chars.get(guid);
            if (Math.abs(stabber.x - char.x) < Defs.WIDTH * 1.2 && Math.abs(stabber.y - char.y) < Defs.HEIGHT * 1.2)
            {
                nearby[nearbyCount++] = char;
            }
        }
        
        for (n in 0 ... nearbyCount)
        {
            var char = nearby[n];
            var guid = char.guid;
            
            socket.output.writeUInt16(guid);
            socket.output.writeByte(Std.int(char.x));
            socket.output.writeByte(Std.int(char.y));
            socket.output.writeByte(char.changedState ? 1 : 0);
            if (char.changedState)
            {
                socket.output.writeByte(Stabber.stateToInt.get(char.state));
            }
        }
    }
}
