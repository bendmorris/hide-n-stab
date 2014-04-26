package hidenstab;

import com.haxepunk.Scene;


class MainWindow extends Scene
{
    override public function begin()
    {
        var s = new Stabber(1);
        add(s);
        
        s.x = Defs.WIDTH/2;
        s.y = Defs.HEIGHT/2;
        
        s.state = Walk;
    }
}
