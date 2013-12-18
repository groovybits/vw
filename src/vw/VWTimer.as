package vw
{
        import flash.utils.Timer;

	public class VWTimer extends Timer
	{		
                public var id:int = -1;

	    	public function VWTimer(myid:int, delay:Number, repeatCount:int):void {
                        id = myid;
                        super(delay, repeatCount);
	    	}
	}
}
