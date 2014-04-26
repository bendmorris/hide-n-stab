package hidenstab;

import flash.utils.ByteArray;
import sys.net.Socket;
import hidenstab.Defs;
import hidenstab.Stabber;


class ClientData {
    public var socket:Socket;
    public var stabber:Stabber;
    public var guid:Guid;
    
    static var byteArray:ByteArray = new ByteArray();
    
    public function new(s:Socket)
    {
        socket = s;
        guid = Defs.newGuid();
        stabber = StabberPool.get(guid, true);
        nearby = new Array();
    }
    
    function clearByteArray()
    {
        byteArray.clear();
    }
    
    // called when the player's client has been disconnected
    public function leave()
    {
        
    }
    
    var nearby:Array<Stabber>;
    var nearbyCount:Int=0;
    
    public function update(chars:Map<Guid, Stabber>)
    {
        for (guid in chars.keys())
        {
            var char = chars.get(guid);
            if (Math.abs(stabber.x - char.x) < Defs.WIDTH * 1.5 && Math.abs(stabber.y - char.y) < Defs.HEIGHT * 1.5)
            {
                nearby[nearbyCount++] = char;
            }
        }
        
        clearByteArray();
        
        byteArray.writeByte(nearbyCount);
        
        for (n in 0 ... nearbyCount)
        {
            var char = nearby[n];
            var guid = char.guid;
            
            byteArray.writeUnsignedInt(guid);
            byteArray.writeByte(Std.int(char.x));
            byteArray.writeByte(Std.int(char.y));
            byteArray.writeBoolean(char.changedState);
            if (char.changedState)
            {
                byteArray.writeByte(Stabber.stateToInt.get(char.state));
            }
        }
        
        nearbyCount = 0;
        
        socket.output.write(byteArray);
        socket.output.flush();
    }
}
