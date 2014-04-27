package hidenstab;

import sys.net.Socket;
import hidenstab.Defs;
import hidenstab.Stabber;


class ClientData {
    public var socket:Socket;
    public var stabber:Stabber;
    public var guid:Guid;
    
    public var ready:Bool=true;
    
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
        var me = stabber;
        
        if (me != null)
        {
            var byteArray = Data.getByteArray();
            
            byteArray.writeByte(Defs.MSG_SEND_CHARS);
            
            if (chars.get(guid) != null)
            {
                nearby[nearbyCount++] = me;
            }
            
            for (guid in chars.keys())
            {
                if (guid != this.guid)
                {
                    var char = chars.get(guid);
                    if (Math.abs(me.x - char.x) < Defs.WIDTH * 1.25 && 
                        Math.abs(me.y - char.y) < Defs.HEIGHT * 1.25)
                    {
                        nearby[nearbyCount++] = char;
                    }
                }
            }
            
            byteArray.writeByte(nearbyCount);
            
            for (n in 0 ... nearbyCount)
            {
                var char = nearby[n];
                var guid = char.guid;
                
                byteArray.writeInt(guid);
                byteArray.writeFloat(char.x);
                byteArray.writeFloat(char.y);
                byteArray.writeByte(Std.int(char.moving.x));
                byteArray.writeByte(Std.int(char.moving.y));
                byteArray.writeBoolean(char.facingRight);
                var stateCode = Stabber.stateToInt.get(char.state);
                if (char.state == Dead && char.pc) stateCode += 1;
                byteArray.writeByte(stateCode);
            }
            
            nearbyCount = 0;
            
            Data.write(socket);
        }
    }
}
