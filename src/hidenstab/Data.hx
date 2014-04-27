package hidenstab;

import flash.utils.ByteArray;
#if flash
import flash.net.Socket;
#else
import sys.net.Socket;
#end


class Data
{
    static var byteArray:ByteArray = new ByteArray();
    
    public static function getByteArray()
    {
        byteArray.clear();
        return byteArray;
    }
    
    public static function write(socket:Socket)
    {
        //byteArray.compress();
        var l = Std.int(byteArray.length);
#if flash
        socket.writeBytes(byteArray);
        socket.flush();
        trace('sent ' + l + ' bytes');
#else
    #if server
        socket.output.writeByte(l);
    #end
        socket.output.write(byteArray);
        socket.output.flush();
#end
    }
}
