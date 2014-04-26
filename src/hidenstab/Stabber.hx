package hidenstab;

import haxe.ds.Vector;
import openfl.Assets;
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
    public static inline var POOL_SIZE=128;
    static var pool:Vector<Stabber> = new Vector(POOL_SIZE);
    static var n:Int = -1;
    
    public static function get(guid:Guid):Stabber
    {
        if (n >= 0) {
            var newItem = pool[n--];
            newItem.reinit(guid);
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
    
    static var hbSlots = ["torso", "legs",];
    static var loader:BitmapDataTextureLoader;
    static var atlas:TextureAtlas;
    static var skeletonData:SkeletonData;
    static var stateData:AnimationStateData;
    public var sp:SpinePunk;
    
    public var guid:Guid;
    
    public var changedState:Bool = true;
    
    public var facingRight:Bool=true;
    var flash:Float=0;
    
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
                case Dead: setAnimation("dead", false);
            }
            
            changedState = true;
        }
        return state = s;
    }
    
    public function new(guid:Guid)
    {
        super();
        
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
#if server
        sp.state.onEvent.add(doAttack);
#end
        
        reinit(guid);
        
        sp.hitboxSlots = hbSlots;
        
        graphic = sp;
        
        type = "stabber";
    }
    
    public function reinit(guid:Guid)
    {
        state = Idle(Stand);
        
        facingRight = true;
        
        visible = false;
        flash = 0;
        sp.color = 0xFFFFFF;
        
        this.guid = guid;
    }
    
    public var animation:String;
    function setAnimation(animationName:String, loop:Bool=true, force:Bool=false) {
        if (force || animation != animationName) {
            if (animationName != null) {
                sp.state.setAnimationByName(0, animationName, loop);
            }
            animation = animationName;
        }
    }
    
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
    
    public override function update()
    {
        if (flash > 0)
            flash = Math.max(0, flash - HXP.elapsed / (Defs.FLASH_TIME * sp.scale));
        sp.color = flash > 0 ? 0xFF8080 : 0xFFFFFF;
        sp.flipX = !facingRight;
        sp.update();
        setHitboxTo(sp.mainHitbox);
        
        if (width > 0 && height > 0)
        {
            switch(state)
            {
                case Dead:
                {
                    _scene.remove(this);
                    StabberPool.recycle(this);
                }
                default: {}
            }
        }
        
        super.update();
        
        visible = true;
    }
    
#if server
    function doAttack()
    {
    }
#end
}
