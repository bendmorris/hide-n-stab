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
    var waitForRespawn:Map<Guid, ClientData>;
    var clientCount:Int = 0;
    var chars:Map<Guid, Stabber>;
    var charCount:Int = 0;
    
    var lastUpdate:Float = 0;
    
    function new()
    {
        super();
        updateTime = UPDATE_FREQ;
        clients = new Map();
        waitForRespawn = new Map();
        chars = new Map();
    }
    
    static inline var headerLength:Int = 2;
    
    override function readClientMessage(c:ClientData, buf:Bytes, pos:Int, len:Int)
    {
        var bytesConsumed = 0;
        
        while (len > 0)
        {
            var ba:ByteArray;
            //var waitFor = ByteArray.fromBytes(buf.sub(pos, headerLength)).readInt();
            var b1:UInt = buf.get(pos);
            var b2:UInt = buf.get(pos+1);
            var waitFor:UInt = (b1 << 8) + b2;
            
            if (len > waitFor)
            {
                var sub = buf.sub(pos+headerLength, waitFor);
                ba = ByteArray.fromBytes(sub);
                //trace("msg length: " + waitFor);
                
                c.ready = true;
                
                readMessage(c, ba);
                
                bytesConsumed += waitFor + headerLength;
                
                pos += waitFor + headerLength;
                len -= waitFor + headerLength;
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
        
        var msgType = msg.readByte();
        
        switch(msgType)
        {
            case Defs.MSG_SEND_MOVING:
            {
                // set moving
                var mx = msg.readByte();
                var my = msg.readByte();
                
                if (char == null) return;
                
                char.moving.x = mx;
                char.moving.y = my;
            }
            case Defs.MSG_SEND_ATTACK:
            {
                // attack
                if (char == null) return;
                char.attack();
            }
            case Defs.MSG_SEND_TALK:
            {
                // talk
                if (char == null) return;
                char.talk();
            }
            case Defs.MSG_SEND_RESPAWN:
            {
                // respawn
                if (waitForRespawn.exists(id))
                {
                    respawn(id);
                }
            }
            case Defs.MSG_SEND_FPS:
            {
                var fps = msg.readByte();
                c.fps = HXP.clamp(fps, 2, 60);
                if (fps > 10) c.timeout = 0;
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
            
            for (id in chars.keys())
            {
                var char = chars.get(id);
                char.update();
                if (char.attackFinished)
                {
                    var tx = char.x + char.width * (char.facingRight ? 1 : -1);
                    for (target in chars.iterator())
                    {
                        if (target != char && 
                            !target.dead &&
                            target.state != Dead &&
                            target.facingRight == char.facingRight)
                        {
                            if (Math.max(Math.abs(target.x - tx), Math.abs(target.y - char.y)) < char.width)
                            {
                                // hit
                                var success = char.kill(target);
                                var client = clients.get(id);
                                var msgType = success ? Defs.MSG_SEND_KILL_SUCCESS : Defs.MSG_SEND_KILL_FAIL;
                                
                                var byteArray = Data.getByteArray();
                                byteArray.writeByte(msgType);
                                attemptWrite(client);
                            }
                        }
                    }
                }
            }
            
            for (client in clients.iterator())
            {
                if (client.ready)
                {
                    var success = client.update(chars);
                    if (success) attemptWrite(client);
                }
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
                        dead(id);
                    }
                    
                    StabberPool.recycle(char);
                }
            }
        }
        
        lastUpdate = curTime;
        
        while (charCount < Math.max(clientCount * 3, 10))
        {
            spawnRandom();
        }
    }
    
    function dead(guid:Guid)
    {
        var client = clients.get(guid);
        client.ready = false;
        waitForRespawn[guid] = client;
    }
    
    function respawn(guid:Guid)
    {
        var client = waitForRespawn.get(guid);
        waitForRespawn.remove(guid);
        trace(Date.now().toString() + ": " + guid + " respawn");
        spawn(client, false);
        client.ready = true;
    }
    
    override function clientConnected(s:Socket):ClientData
    {
        s.setFastSend(true);
        
        var c = new ClientData(s);
        clients.set(c.guid, c);
        clientCount += 1;
        
        spawn(c);
        
        return c;
    }
    
    function spawn(c:ClientData, newChar:Bool=true)
    {
        if (newChar) trace(Date.now().toString() + ": client connected: " + c.guid);
        
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
        
        attemptWrite(c);
        
        trace(clientCount + " clients connected");
    }
    
    override public function clientDisconnected(clientData:ClientData)
    {
        trace(Date.now().toString() + ": client disconnected: " + clientData.guid);
        
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
        
        trace(clientCount + " clients connected");
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
    
    function attemptWrite(c:ClientData)
    {
        var socket = c.socket;
        
        try
        {
            Data.write(socket);
            c.lastGoodWrite = Sys.time();
        }
        catch (e:Dynamic)
        {
            if (Sys.time() - c.lastGoodWrite > Defs.TIMEOUT)
            {
                trace(c.guid + " timed out");
                c.ready = false;
                stopClient(socket);
            }
        }
    }
}
