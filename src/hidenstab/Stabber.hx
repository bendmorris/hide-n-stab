package hidenstab;

import haxe.ds.Vector;
import openfl.Assets;
#if !server
import spinehaxe.Bone;
import spinehaxe.Slot;
import spinehaxe.SkeletonData;
import spinehaxe.SkeletonJson;
import spinehaxe.Event;
import spinehaxe.animation.Animation;
import spinehaxe.animation.AnimationState;
import spinehaxe.animation.AnimationStateData;
import spinehaxe.animation.TrackEntry;
import spinehaxe.atlas.TextureAtlas;
import spinehaxe.platform.nme.BitmapDataTextureLoader;
import spinepunk.SpinePunk;
#end
import com.haxepunk.HXP;
import com.haxepunk.Entity;
import com.haxepunk.graphics.Image;
import flash.display.BitmapData;
import flash.geom.Point;
import hidenstab.Defs;


enum IdleType
{
    Stand;
    Talk;
}

enum AttackType
{
    Stab;
    Swing;
}

enum StabberState
{
    Idle(idleType:IdleType);
    Walk;
    Attack(attackType:AttackType);
    Dead;
}


class StabberPool
{
    public static inline var POOL_SIZE=256;
    static var pool:Vector<Stabber> = new Vector(POOL_SIZE);
    static var n:Int = -1;
    
    public static function get(guid:Guid, pc:Bool=false):Stabber
    {
        if (n >= 0) {
            var newItem = pool[n--];
            newItem.reinit(guid, pc);
            return newItem;
        } else {
            return new Stabber(guid);
        }
    }
    
    public static function recycle(obj:Stabber)
    {
        if (n < POOL_SIZE-1) pool[++n] = obj;
    }
}


class Stabber extends Entity
{
    public static var intToState:Map<Int, StabberState> = [
        0 => Idle(Stand),
        1 => Idle(Talk),
        2 => Walk,
        3 => Attack(Stab),
        4 => Attack(Swing),
        5 => Dead,
    ];
    
    public static var stateToInt:Map<StabberState, Int> = [
        Idle(Stand)     => 0,
        Idle(Talk)      => 1,
        Walk            => 2,
        Attack(Stab)    => 3,
        Attack(Swing)   => 4,
        Dead            => 5,
    ];
    
    public static var animationTime:Map<String, Float> = [
        "stab" => 0.5,
        "swing" => 0.5,
    ];
    
#if !server
    static var loader:BitmapDataTextureLoader;
    static var atlas:TextureAtlas;
    static var skeletonData:SkeletonData;
    static var stateData:AnimationStateData;
    public var sp:SpinePunk;
#end
    
    public var guid:Guid;
    public var pc:Bool=false;
    
    public var changedState:Bool = true;
    public var revealTime:Float = 0;
    
    public var moving:Point;
    public var facingRight:Bool=true;
    var flash:Float=0;
    var loopedAnimation:Bool=false;
    var animationTimer:Float = 0;
    
    public var state(default, set):StabberState;
    function set_state(s:StabberState)
    {
        if (state != s)
        {
            switch(s) {
                case Idle(i): switch(i) {
                    case Stand: setAnimation("stand");
                    case Talk: setAnimation("talk");
                };
                case Walk: setAnimation("walk");
                case Attack(a): switch(a) {
                    case Swing: setAnimation("swing", false);
                    case Stab: setAnimation("stab", false);
                };
                case Dead: {
                    setAnimation("dead", false);
                    flash = 1;
                }
            }
            
            changedState = true;
        }
        return state = s;
    }
    
    public function new(guid:Guid, pc:Bool=false)
    {
        super();
        
        moving = new Point();
        
#if !server
        if (loader == null)
        {
            loader = new BitmapDataTextureLoader();
        }
        if (atlas == null)
        {
            atlas = TextureAtlas.create(Assets.getText("graphics/stabber.atlas"), "graphics/", loader);
        }
        
        if (skeletonData == null)
        {
            var json = SkeletonJson.create(atlas);
            skeletonData = json.readSkeletonData(Assets.getText("graphics/stabber.json"), "stabber");
            stateData = new AnimationStateData(skeletonData);
            stateData.defaultMix = 0.1;
        }
        
        sp = new SpinePunk(skeletonData, false);
        
        sp.state = new AnimationState(stateData);
        sp.state.clearWhenFinished = false;
        
        graphic = sp;
        
        sp.scale = 1/Defs.SCALE / Defs.CHAR_SCALE;
        sp.smooth = false;
#end
        
        var dims:Int = Std.int(128 / Defs.SCALE / Defs.CHAR_SCALE);
        setHitbox(dims, dims, Std.int(dims/2), Std.int(dims/2 + (32 / Defs.SCALE / Defs.CHAR_SCALE)));
        
        reinit(guid, pc);
    }
    
    public function reinit(guid:Guid, pc:Bool)
    {
        state = Idle(Stand);
        
        facingRight = true;
        
#if !server
        visible = false;
        flash = 0;
        sp.color = 0xFFFFFF;
#end
        
        revealTime = 0;
        hide();
        
        animationTimer = 0;
        
        moving.x = moving.y = 0;
        this.pc = pc;
        
        this.guid = guid;
    }
    
    public var animation:String;
    function setAnimation(animationName:String, loop:Bool=true, force:Bool=false) {
        if (force || animation != animationName) {
            if (animationName != null) {
#if server
                animationTimer = 0;
#else
                sp.state.setAnimationByName(0, animationName, loop);
#end
            }
            animation = animationName;
            loopedAnimation = loop;
        }
    }
    
#if !server
    public var track(get, never):TrackEntry;
    function get_track() {
        var track = sp.state.tracks[0];
        if (track != null) return track;
        return null;
    }
    public var time(get, never):Float;
    function get_time():Float {
        var anim = track;
        if (anim == null) return 0;
        return anim.time;
    }
    public var duration(get, never):Float;
    function get_duration():Float {
        var anim = track;
        if (anim == null) return 0;
        return anim.endTime;
    }
    public var remaining(get, never):Float;
    function get_remaining() {
        return duration - time;
    }
#end
    
    public override function update()
    {
        if (flash > 0)
            flash = Math.max(0, flash - HXP.elapsed / Defs.FLASH_TIME);
#if !server
        sp.color = flash > 0 ? 0xFF8080 : 0xFFFFFF;
        sp.flipX = !facingRight;
        sp.update();
#end
        
        if (visible)
        {
            switch(state)
            {
                case Dead:
                {
                    _scene.remove(this);
                    StabberPool.recycle(this);
                }
                case Idle(i):
                {
                    if (moving.x != 0 || moving.y != 0) state = Walk;
                }
                case Walk:
                {
                    var spd:Float = (revealTime > 0) ? Defs.RUN_MULT : 1;
                    if (moving.x == 0 && moving.y == 0)
                    {
                        state = Idle(Stand);
                    }
                    else
                    {
                        // move
                        if (moving.x != 0 && moving.y != 0) spd /= 1.4142;
                        
                        if (moving.x != 0)
                        {
                            x += moving.x * spd * HXP.elapsed * Defs.MOVE_PER_SEC;
                            facingRight = moving.x > 0;
                        }
                        if (moving.y != 0)
                        {
                            y += moving.y * spd * HXP.elapsed * Defs.MOVE_PER_SEC * Defs.Y_SPEED;
                        }
                        
                        x = HXP.clamp(x, width, Defs.WORLD_WIDTH-width);
                        y = HXP.clamp(y, height, Defs.WORLD_HEIGHT-height);
                    }
                }
                
                default: {}
            }
        }
        
        layer = Std.int((Defs.WORLD_HEIGHT - y) / 10);
        
        if (revealTime > 0)
        {
            revealTime = Math.max(0, revealTime - HXP.elapsed/Defs.REVEAL_TIME);
            if (revealTime <= 0)
            {
                hide();
            }
        }
        
        super.update();
        
#if server
        if (!loopedAnimation)
        {
            animationTimer += HXP.elapsed;
        }
        
        if (animationTime.exists(animation) && animationTimer >= animationTime[animation])
#else
        if (!loopedAnimation && remaining <= 0)
#end
        {
            state = Idle(Stand);
        }
        
        visible = true;
    }
    
    function hide()
    {
#if !server
        for(slot in sp.skeleton.slots) {
            if(slot.data.name == "knife" || slot.data.name == "eyes")  {
                slot.attachment = null;
            }
        }
#end
    }
    
    public function attack()
    {
        revealTime = 1;
        state = Attack(Std.random(2) == 0 ? Stab : Swing);
    }
    
    public function talk()
    {
        state = switch(state) {
            case Idle(t): {
                Idle(t == Talk ? Stand : Talk);
            }
            default: {
                Idle(Talk);
            }
        };
    }
    
#if server
    function doAttack()
    {
    }
#end
}