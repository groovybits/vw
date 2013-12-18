package vw
{
	import flash.events.*;

	public class CustomClient extends EventDispatcher
	{		
		// Events
		public static var METADATA:String = "metadata";

                public var duration:Number;
                public var width:Number;
                public var height:Number;
                public var fps:Number;
                public var debug:int;
                
                public function CustomClient (dbg:int) {
                        duration = new Number();
                        width = new Number();
                        height = new Number();
                        fps = new Number();
                        debug = dbg;
                }
                
                public function onMetaData(info:Object):void {
                        if (debug > 0)
                                trace("metadata: duration=" + info.duration + 
                                        " width=" + info.width + " height=" + info.height + " framerate=" + info.framerate);
                        // Stream Information
                        duration = info.duration;
                        width = info.width;
                        height = info.height;
                        fps = info.framerate;
                        
                        if (debug > 0) {
                                var key:String;
                                for (key in info)
                                {
                                        trace(key + ": " + info[key]);
                                }
                        }
			dispatchEvent(new Event(CustomClient.METADATA));
                }
                public function onCuePoint(info:Object):void {
                        // Nothing
			if (debug > 0)
				trace("onCuePoint");
                }
                public function onLastSecond(info:Object):void {
                        // Nothing
			if (debug > 0)
				trace("onLastSecond");
                }

	}
}
