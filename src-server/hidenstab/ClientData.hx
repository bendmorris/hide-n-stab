package hidenstab;

import sys.net.Socket;
import com.haxepunk.HXP;
import hidenstab.Defs;
import hidenstab.Stabber;


class ClientData {
    public var socket:Socket;
    public var stabber:Stabber;
    public var guid:Guid;
    
    public var fps(default, set):Float = 30;
    function set_fps(f:Float)
    {
        lastFramerates.push(f);
        if (lastFramerates.length > 5) lastFramerates.shift();
        fps = Lambda.fold(lastFramerates, function (a, b) return a+b, 0) / lastFramerates.length;
        return fps;
    }
    var lastFramerates:Array<Float>;
    public var elapsed:Float=0;
    
    public var respawned:Bool=false;
    public var ready:Bool=true;
    
    public var lastGoodWrite:Float = 0;
    public var timeout:Float = 0;
    
    public function new(s:Socket)
    {
        socket = s;
        guid = Defs.newGuid();
        stabber = StabberPool.get(guid, true);
        nearby = new Array();
        lastFramerates = [30];
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
        nearbyCount = 0;
        
        elapsed += HXP.elapsed;
        timeout += HXP.elapsed;
        if (elapsed < 1./fps) return false;
        
        elapsed -= 1./fps;
        
        if (me != null)
        {
            var byteArray = Data.getByteArray();
            
            byteArray.writeByte(Defs.MSG_SEND_CHARS);
            
            if (chars.get(guid) != null)
            {
                nearby[nearbyCount++] = me;
            }
            else
            {
                return false;
            }
            
            for (guid in chars.keys())
            {
                if (guid != this.guid)
                {
                    var char = chars.get(guid);
                    if (Math.abs(me.x - char.x) < Defs.WIDTH*1.05 && 
                        Math.abs(me.y - char.y) < Defs.HEIGHT*1.05)
                    {
                        nearby[nearbyCount++] = char;
                    }
                }
            }
            
            byteArray.writeByte(nearbyCount);
            
            for (n in 0 ... Std.int(Math.min(nearbyCount, 48)))
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
            
            return true;
        }
        
        return false;
    }
}
