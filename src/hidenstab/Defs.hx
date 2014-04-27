package hidenstab;

typedef Guid = Int;

class Defs
{
    public static inline var MAX_INT=536870912;
    public static inline var MSG_LEN=256;

//    public static var HOST="localhost";
    public static var HOST="54.244.244.60";
    public static var PORT=27278;
    
    public static inline var SCALE:Int=2;
    public static inline var CHAR_SCALE:Int=3;
    public static inline var WIDTH:Int=Std.int(640/SCALE);
    public static inline var HEIGHT:Int=Std.int(480/SCALE);
    public static inline var TILE_SIZE=64;
    
    public static inline var WORLD_WIDTH=Std.int(640*2.5/SCALE);
    public static inline var WORLD_HEIGHT=Std.int(480*2.5/SCALE);
    
    public static inline var FLASH_TIME:Float=0.2;
    
    public static inline var BGCOLOR:Int=0x000000;
    
    public static inline var MOVE_PER_SEC:Float=96/SCALE;
    public static inline var RUN_MULT:Float=2.5;
    public static inline var REVEAL_TIME:Float=3;
    public static inline var Y_SPEED:Float=0.67;
    public static inline var SERVER_UPDATE_FREQ:Float=1/20;
    public static inline var GRADUAL_MOVE_TIME:Float=SERVER_UPDATE_FREQ;
    
    public static inline var MSG_SEND_GUID=0;
    public static inline var MSG_SEND_CHARS=1;
    public static inline var MSG_SEND_MOVING=2;
    public static inline var MSG_SEND_ATTACK=3;
    public static inline var MSG_SEND_TALK=4;
    public static inline var MSG_TERMINATOR=127;
    
    public static function init()
    {
    }
    
    public static function newGuid():Guid
    {
        var g = MSG_TERMINATOR;
        
        while (g == MSG_TERMINATOR)
        {
            g = Std.random(MAX_INT);
        }
        
        return g;
    }
}
