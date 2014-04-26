package hidenstab;

import com.haxepunk.Scene;


class MainWindow extends Scene
{
    var s:Stabber;
    
    override public function begin()
    {
        s = new Stabber(1);
        add(s);
        
        s.x = Defs.WIDTH/2;
        s.y = Defs.HEIGHT/2;
        
        s.state = Walk;
        
        //Client.current.init();
    }
    
    override public function update()
    {
        //Client.current.update();
        
        if (com.haxepunk.utils.Input.mousePressed)
        {
            switch(s.state)
            {
                case Walk: {
                    s.revealTime = 1;
                    s.state = Attack(Std.random(2) == 0 ? Stab : Swing);
                }
                default: {
                    s.state = Walk;
                }
            }
        }
        
        super.update();
    }
}
