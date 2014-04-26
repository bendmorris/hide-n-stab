package hidenstab;

import haxe.io.Bytes;
import flash.utils.ByteArray;
import neko.net.ThreadServer;
import sys.net.Socket;
import com.haxepunk.HXP;
import hidenstab.ClientApi;
import hidenstab.Defs;
import flash.utils.ByteArray;



class Server extends ThreadServer<ClientData, ByteArray>
{
    static inline var UPDATE_FREQ:Float=1/10;
    
    static var chars:Map<Guid, Stabber>;
    
    var lastUpdate:Float = 0;
    
    function new()
    {
        super();
        updateTime = UPDATE_FREQ;
        clients = new Map();
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
            case 0:
            {
                // set moving
                char.moving.x = msg.readUnsignedShort();
                char.moving.y = msg.readUnsignedShort();
            }
            case 1:
            {
                // attack
                char.attack();
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
            for (client in clients.iterator())
            {
                client.update();
            }
        }
        
        lastUpdate = curTime;
    }
    
    override function clientConnected(s:Socket):ClientData
    {
        trace("Client connected");
        var c = new ClientData(s);
        clients.set(c.guid, c);
        s.writeByte(0);
        s.writeUnsignedInt(c.guid);
        s.flush();
        return c;
    }
    
    override public function clientDisconnected(clientData:ClientData)
    {
        trace("Client disconnected");
        clientData.leave();
        
        var id = clientData.guid;
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
