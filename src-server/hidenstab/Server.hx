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
    static inline var UPDATE_FREQ:Float=Defs.SERVER_UPDATE_FREQ;
    
    var clients:Map<Guid, ClientData>;
    var clientCount:Int = 0;
    var chars:Map<Guid, Stabber>;
    var charCount:Int = 0;
    
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
        var bytesConsumed = 0;
        
        while (len > 0)
        {
            var ba:ByteArray;
            var waitFor = buf.get(pos);
            
            if (len > waitFor)
            {
                var sub = buf.sub(pos+1, waitFor);
                ba = ByteArray.fromBytes(sub);
                //trace("msg length: " + waitFor);
                
                c.ready = true;
                
                readMessage(c, ba);
                
                bytesConsumed += waitFor + 1;
                
                pos += waitFor + 1;
                len -= waitFor + 1;
            }
            else
            {
                c.ready = false;
            }
        }
        
        return { msg : null, bytes : bytesConsumed };
    }
    
    function readMessage(c:ClientData, msg:ByteArray)
    {
        var id = c.guid;
        var char = chars.get(id);
        
        while (msg.bytesAvailable > 0)
        {
            var msgType = msg.readByte();
            
            trace(msgType);
            
            switch(msgType)
            {
                /*case Defs.MSG_SEND_CHARS:
                {
                    // send update
                    c.update(chars);
                }*/
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
                if (char.attackFinished)
                {
                    var tx = char.x + char.width * (char.facingRight ? 1 : -1);
                    for (target in chars.iterator())
                    {
                        if (target != char && target.facingRight == char.facingRight)
                        {
                            if (Math.max(Math.abs(target.x - tx), Math.abs(target.y - char.y)) < char.width)
                            {
                                // hit
                                char.kill(target);
                            }
                        }
                    }
                }
            }
            
            for (client in clients.iterator())
            {
                if (client.ready) client.update(chars);
            }
            
            for (id in chars.keys())
            {
                var char = chars.get(id);
                if (char.dead)
                {
                    // this character is dead
                    chars.remove(id);
                    charCount -= 1;
                    
                    if (char.pc)
                    {
                        respawn(id);
                    }
                    
                    StabberPool.recycle(char);
                }
            }
        }
        
        lastUpdate = curTime;
        
        while (charCount < clientCount * 3)
        {
            spawnRandom();
        }
    }
    
    function respawn(guid:Guid)
    {
        var client = clients.get(guid);
        clients.remove(guid);
        var newGuid = getGuid();
        trace(guid + " respawn as " + newGuid);
        client.guid = newGuid;
        clients.set(client.guid, client);
        spawn(client);
    }
    
    override function clientConnected(s:Socket):ClientData
    {
        var c = new ClientData(s);
        clients.set(c.guid, c);
        clientCount += 1;
        
        spawn(c);
        
        return c;
    }
    
    function spawn(c:ClientData)
    {
        trace("Client connected: " + c.guid);
        
        var char:Stabber = StabberPool.get(c.guid, true);
        char.x = Std.random(Defs.WORLD_WIDTH);
        char.y = Std.random(Defs.WORLD_HEIGHT);
        chars.set(c.guid, char);
        charCount += 1;
        c.stabber = char;
        
        // add random non-pc characters
        for (i in 0 ... (3 + Std.random(3)))
        {
            spawnRandom();
        }
        
        var byteArray = Data.getByteArray();
        
        byteArray.writeByte(Defs.MSG_SEND_GUID);
        byteArray.writeInt(c.guid);
        
        Data.write(c.socket);
    }
    
    override public function clientDisconnected(clientData:ClientData)
    {
        trace("Client disconnected");
        clientData.leave();
        
        var id = clientData.guid;
        if (chars.exists(id))
        {
            chars.remove(id);
            charCount -= 1;
        }
        
        if (clients.exists(id))
        {
            clients.remove(id);
            clientCount -= 1;
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
    
    function getGuid()
    {
        var newGuid:Guid;
        do
        {
            newGuid = Defs.newGuid();
        } while (chars.exists(newGuid) || clients.exists(newGuid));
        return newGuid;
    }
    
    function spawnRandom()
    {
        
        var newGuid = getGuid();
        var char:Stabber = StabberPool.get(newGuid, false);
        char.x = Std.random(Defs.WORLD_WIDTH);
        char.y = Std.random(Defs.WORLD_HEIGHT);
        char.facingRight = Std.random(2) == 0;
        chars.set(newGuid, char);
        charCount += 1;
    }
}
