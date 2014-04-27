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
    static var outByteArray:ByteArray = new ByteArray();
    
    public static function getByteArray()
    {
        byteArray.clear();
        return byteArray;
    }
    
    public static function write(socket:Socket)
    {
#if server
        //byteArray.compress();
#end
        var l = Std.int(byteArray.length);
#if flash
        socket.writeBytes(byteArray);
        socket.flush();
#else
    outByteArray.clear();
    #if server
        outByteArray.writeByte(l & 0xFF);
        //outByteArray.writeByte((l & 0xFF00) >> 8);
        //outByteArray.writeByte(l & 0xFF);
    #end
        outByteArray.writeBytes(byteArray);
        socket.output.prepare(Std.int(outByteArray.length));
        socket.output.write(byteArray);
        socket.output.flush();
#end
    }
}
