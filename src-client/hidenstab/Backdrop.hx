package hidenstab;

import com.haxepunk.graphics.Tilemap;


class Backdrop extends Tilemap
{
    public function new()
    {
        super("graphics/tiles.png", 
            Std.int(Defs.WORLD_WIDTH*Defs.SCALE*2), 
            Std.int(Defs.WORLD_HEIGHT*Defs.SCALE*2), 
            Defs.TILE_SIZE, Defs.TILE_SIZE);
        
        for (x in 0 ... columns)
        {
            for (y in 0 ... rows)
            {
                setTile(x, y, Std.random(4));
            }
        }
        
        scale = 1 / Defs.CHAR_SCALE;
    }
}
