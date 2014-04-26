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
#if flash
        socket.writeBytes(byteArray);
        socket.flush();
#else
        socket.output.write(byteArray);
        socket.output.flush();
#end
    }
}
