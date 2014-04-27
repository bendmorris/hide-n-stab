package hidenstab;

import haxe.io.Bytes;
import flash.utils.ByteArray;
import neko.net.ThreadServer;
import sys.net.Socket;
import com.haxepunk.HXP;
import hidenstab.Defs;
import hidenstab.Stabber;



class Server extends ThreadServer<ClientData, ByteArray>
{
    static inline var UPDATE_FREQ:Float=1/60;
    
    static var clients:Map<Guid, ClientData>;
    static var chars:Map<Guid, Stabber>;
    
    var lastUpdate:Float = 0;
    
    function new()
    {
        super();
        updateTime = UPDATE_FREQ;
        clients = new Map();
        chars = new Map();
    }
    
    override function readClientMessage(c:ClientData, buf:Bytes, pos:Int, len:Int)
    {
        var ba:ByteArray;
#if flash
        ba = buf.getData();
#else
        ba = ByteArray.fromBytes(buf);
#end
        return { msg : ba, bytes : len };
    }
    
    override function clientMessage(c:ClientData, msg:ByteArray)
    {
        var id = c.guid;
        var char = chars.get(id);
        
        var msgType = msg.readByte();
        switch(msgType)
        {
            case Defs.MSG_SEND_MOVING:
            {
                // set moving
                char.moving.x = msg.readByte();
                char.moving.y = msg.readByte();
            }
            case Defs.MSG_SEND_ATTACK:
            {
                // attack
                char.attack();
            }
            case Defs.MSG_SEND_TALK:
            {
                // attack
                char.talk();
            }
            default: {}
        }
    }
    
    override function update() {
        var curTime = Sys.time();
        
        if (lastUpdate > 0)
        {
            var elapsedTime = curTime - lastUpdate;
            HXP.elapsed = elapsedTime;
            
            for (char in chars.iterator())
            {
                char.update();
            }
            
            for (client in clients.iterator())
            {
                client.update(chars);
            }
        }
        
        lastUpdate = curTime;
    }
    
    override function clientConnected(s:Socket):ClientData
    {
        var c = new ClientData(s);
        clients.set(c.guid, c);
        
        trace("Client connected: " + c.guid);
        
        var char:Stabber = StabberPool.get(c.guid, true);
        char.x = Std.random(Defs.WORLD_WIDTH);
        char.y = Std.random(Defs.WORLD_HEIGHT);
        char.facingRight = Std.random(2) == 0;
        chars.set(c.guid, char);
        c.stabber = char;
        
        // add random non-pc characters
        for (i in 0 ... (2 + Std.random(3)))
        {
            var rid = Defs.newGuid();
            var char:Stabber = StabberPool.get(rid, false);
            char.x = Std.random(Defs.WORLD_WIDTH);
            char.y = Std.random(Defs.WORLD_HEIGHT);
            char.facingRight = Std.random(2) == 0;
            chars.set(rid, char);
        }
        
        var byteArray = Data.getByteArray();
        
        byteArray.writeByte(Defs.MSG_SEND_GUID);
        byteArray.writeInt(c.guid);
        
        Data.write(s);
        
        return c;
    }
    
    override public function clientDisconnected(clientData:ClientData)
    {
        trace("Client disconnected");
        clientData.leave();
        
        var id = clientData.guid;
        if (chars.exists(id))
        {
            chars.remove(id);
        }
        
        if (clients.exists(id))
        {
            clients.remove(id);
        }
    }
    
    public static function main() {
        var args = Sys.args();
        var host = Defs.HOST;
        if (args.length > 0) Defs.HOST = args[0];
        if (args.length > 1) Defs.PORT = Std.parseInt(args[1]);
        
        var server = new Server();
        trace("Starting server (HOST=" + Defs.HOST + ", PORT=" + Defs.PORT + ")");
        server.run(Defs.HOST, Defs.PORT);
    }
}
