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
        guid = Defs.newGuid();
        stabber = StabberPool.get(guid, true);
        nearby = new Array();
    }
    
    // called when the player's client has been disconnected
    public function leave()
    {
        
    }
    
    var nearby:Array<Stabber>;
    var nearbyCount:Int=0;
    
    public function update(chars:Map<Guid, Stabber>)
    {
        var byteArray = Data.getByteArray();
        
        byteArray.writeByte(Defs.MSG_SEND_CHARS);
        
        for (guid in chars.keys())
        {
            var char = chars.get(guid);
            if (true)//if (Math.abs(stabber.x - char.x) < Defs.WIDTH * 1.5 && Math.abs(stabber.y - char.y) < Defs.HEIGHT * 1.5)
            {
                nearby[nearbyCount++] = char;
            }
        }
        
        byteArray.writeByte(nearbyCount);
        
        for (n in 0 ... nearbyCount)
        {
            var char = nearby[n];
            var guid = char.guid;
            
            byteArray.writeInt(guid);
            byteArray.writeInt(Std.int(char.x));
            byteArray.writeInt(Std.int(char.y));
            byteArray.writeByte(Std.int(char.moving.x));
            byteArray.writeByte(Std.int(char.moving.y));
            byteArray.writeByte(Stabber.stateToInt.get(char.state));
        }
        
        nearbyCount = 0;
        
        Data.write(socket);
    }
}
