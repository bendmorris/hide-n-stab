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
#if server
        byteArray.compress();
#end
        var l = Std.int(byteArray.length);
#if flash
        socket.writeByte(l);
        socket.writeBytes(byteArray);
        socket.flush();
#else
        socket.output.prepare(Std.int(byteArray.length) + 1);
        socket.output.writeByte(l);
        
        socket.output.write(byteArray);
        socket.output.flush();
#end
    }
}
