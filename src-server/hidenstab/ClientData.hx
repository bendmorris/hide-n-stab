package hidenstab;

import sys.net.Socket;
import hidenstab.ClientApi;
import hidenstab.Defs;


class ClientData implements ServerApi {
    public var socket:Socket;
    public var player:Player;
    public var guid:Guid;
    
    public function new(s:Socket)
    {
        socket = s;
        (cast s).__private = this;
        guid = Std.random(Defs.MAX_INT);
    }
    
    // called when the player's client has been disconnected
    public function leave()
    {
        
    }

    public static function ofSocket(s:Socket):ClientData
    {
        return (cast s).__private;
    }
}
