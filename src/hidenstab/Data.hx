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
        byteArray.compress();
        
        var l:UInt = byteArray.length;
        var b1:UInt = (l & 0xFF00) >> 8;
        var b2:UInt = l & 0xFF;
#if flash
        socket.writeByte(b1);
        socket.writeByte(b2);
        socket.writeBytes(byteArray);
        socket.flush();
#else
        socket.output.prepare(Std.int(byteArray.length) + 2);
        socket.output.writeByte(b1);
        socket.output.writeByte(b2);
        socket.output.write(byteArray);
        socket.output.flush();
#end
    }
}
