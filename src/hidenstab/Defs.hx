package hidenstab;

typedef Guid = UInt;

class Defs
{
    public static inline var MAX_INT=67108864;

    public static var HOST="localhost";
    public static var PORT=27278;
    
    public static inline var SCALE:Int=2;
    public static inline var CHAR_SCALE:Int=3;
    public static inline var WIDTH:Int=Std.int(640/SCALE);
    public static inline var HEIGHT:Int=Std.int(480/SCALE);
    
    public static inline var WORLD_WIDTH=640*4;
    public static inline var WORLD_HEIGHT=480*4;
    
    public static inline var FLASH_TIME:Float=0.2;
    
    public static inline var BGCOLOR:Int=0x000000;
    
    public static inline var REVEAL_TIME:Float=3;
    
    
    public static function init()
    {
    }
}
