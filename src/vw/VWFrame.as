package vw
{
	import vw.CustomClient;
	import vw.PlayList;
	import vw.Layers;
	import vw.VWSprite;
        import vw.VWTimer;
	
	import flash.display.*;
	import flash.events.*;
        import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
        import flash.media.Video;
        import flash.net.NetStreamPlayOptions;
        import flash.net.NetStreamPlayTransitions;
	import flash.media.SoundTransform;
	import flash.net.NetStream;
	import flash.net.NetConnection;
	
	/**
	* VWFrame Class
	*/
	public class VWFrame extends Sprite {
		/**
		* Frame ID
		*/
		public var id:int = -1;

		/** 
		* Frame running
		*/
		public var running:Boolean = false;	

		/**
		* Video State, -1=uninit, 0=init/stopped, 1=playing
		*/
		public var state:int = -1;	

		/** 
		* Video needs to reload
		*/
		public var reload_stream:Boolean = false;

		/** 
		* Lock visibility for full playback
		*/
		public var lock:Boolean = false;

		/** 
		* Loop signal
		*/
		private var loop:Boolean = false;

		/**
		* Seek Signal
		*/
		private var seek:int = 0;	

		/** 
		* Current queued scale size
		*/
		public var scale:Number = 1;

		/**
		* Mute Video Sound
		*/
		public var mute:Boolean = true;

		private var debug:int = 0;
		private var do3Dmode:Boolean = false;

		// Video locations/Description
		public var plist:PlayList;

		// Timer for Video startup and Menu slideout
                public var timer:VWTimer;
		public var timer_started:Boolean = false;

		// Frame geometry/layers
                public var g:Object;
		public var layers:Layers;
		private var menu:TextField;
		private var fmtmenu:TextFormat;

		// Video Network
		private var nc:NetConnection;
		private var ns:NetStream;
                private var nspo:flash.net.NetStreamPlayOptions;

		// Base start size
		private var base_width:int;
		private var base_height:int;

		// Menu Settings
		public var menuHeight:int = 10;
		public var menuFontSize:int = 5;
		public var menuColor:uint = 0x598bab;
		public var menuTextColor:uint = 0xffffff;

                /**
		* Frame Color
                */
                public var focusFrameColor:uint = 0xFFFFFF;
                public var mainFrameColor:uint = 0x000000;
		
		// Main VWFrame Class Constructor Function
		public function VWFrame(myid:int, do3D:Boolean, doDebug:int):void {
			super();

			// Set our ID
			id = myid;			
			do3Dmode = do3D;
			debug = doDebug;

			// XML File Frame Settings
			plist = new PlayList();

			// Layers
			layers = new Layers();

                        // Geometry Stuff
                        g = new Object();
                        var centerpoint:Point;
                        var leftcorner:Point;

                        g.cp = centerpoint; // CenterPoint
                        g.p = leftcorner; // OriginPoint

			// Drop Down Frame Menu
			menu = new TextField();

			// Dropdown Frame Menu Font
			fmtmenu = new TextFormat();

			// Configure Menu Settings
			setupMenu();

			vwTrace("VWFrame: " + id + " initialized");
			return;
		}

		/** 
		* Setup Menu
		*/
		private function setupMenu():void {
			fmtmenu.size = menuFontSize;
			fmtmenu.bold = false;
                        fmtmenu.font = "Arial";

			menu.selectable = true;			
			menu.background = false;
			menu.border = false;
			menu.textColor = menuTextColor;
			menu.wordWrap = true;
			menu.autoSize=TextFieldAutoSize.NONE;
			menu.antiAliasType = flash.text.AntiAliasType.ADVANCED;
			menu.gridFitType = flash.text.GridFitType.NONE;

			menu.setTextFormat(fmtmenu);
		}

		/**
		* Setup Frame Layers of Display Objects
		*/
		public function setupLayers():void {
                        layers.menuBG = new Sprite();
                        layers.menu = new Shape();
                        layers.video = new Video(width, height);
                        layers.bbox = new Shape();
                        layers.wbox = new Shape();
                        layers.frame = new VWSprite();

                        layers.frame.id = id;
			base_width = width;
			base_height = height;

			// Turn off Menu Visibility
			layers.menuBG.visible = false;
			menu.visible = false;
			layers.menu.visible = false;

			// Use Black Box frame by default
			layers.wbox.visible = false;

			// Draw Frame Graphics
			drawFrameGraphics();

			// Menu Text Postion
                        menu.height = menuHeight;
                        menu.width = base_width;
                        menu.y = base_height;

                        // Use Hand Cursor
                        layers.frame.useHandCursor = true;
                        layers.frame.buttonMode = true;

                        // Geometry Position/Points
                        var midX:Number = (x+(base_width/2));
                        var midY:Number = (y+(base_height/2));
                        g.cp = new Point(midX, midY);
                        g.p = new Point(x, y);

			// Initialize Video Playback
			startVideo();

                        // Add Menu Backing
                        addChild(layers.menuBG);

                        // Add Menu Frame and Text
                        addChild(menu);
                        addChild(layers.menu);

                        // Add Video Frame
                        addChild(layers.video);

                        // Add White and Black Box Frame
                        addChild(layers.wbox);
                        addChild(layers.bbox);

                        // Add Main Mouse Event Frame Overlay
                        addChild(layers.frame);
		}

		/**
		* Draw Frame Graphics
		*/
		private function drawFrameGraphics():void {
                        // Mouse Overlay Frame
			if (do3Dmode)
				layers.frame.z = 0;
                        layers.frame.graphics.lineStyle(0, 0x000000, 0, 
				true, LineScaleMode.NONE, "round", "round", 0);
                        layers.frame.graphics.beginFill(0x000000, 0);
                        layers.frame.graphics.drawRect(0,0, base_width, base_height);
                        layers.frame.graphics.endFill();

                        // Black Box Frame with round corners
			roundedBox(mainFrameColor, layers.bbox);

                        // White Box Frame with round corners
			roundedBox(focusFrameColor, layers.wbox);

                        // Menu BG Frame
			if (do3Dmode)
				layers.menuBG.z = 0;
                        layers.menuBG.graphics.lineStyle(0, focusFrameColor, 0, 
				true, LineScaleMode.NONE, "round", "round", 0);
                        layers.menuBG.graphics.beginFill(menuColor, 1);
                        layers.menuBG.graphics.drawRoundRect(0, 0, 
				width, base_height+menuHeight+2, 6);
                        layers.menuBG.graphics.endFill();

                        // Menu Border Frame (white)
			if (do3Dmode)
				layers.menu.z = 0;
                        layers.menu.graphics.lineStyle(2, focusFrameColor, 1, 
				true, LineScaleMode.NONE, "round", "round", 0);
                        layers.menu.graphics.beginFill(0x000000, 0);
                        layers.menu.graphics.drawRoundRect(0, 0, base_width, base_height+menuHeight+2, 6);
                        layers.menu.graphics.endFill();
		}

                /**
                * Round Corner Color Box Border around Frames.
                *
                * @param color Color of Box.
                * @param frame Shape Class to draw on.
                */
                private function roundedBox(color:uint, frame:Shape):void {
                        // Box with Rounded Corners
			if (do3Dmode)
				frame.z = 0;
                        frame.graphics.lineStyle(4, color,
                                1, true, LineScaleMode.NONE, "round", "round", 0);
                        frame.graphics.beginFill(0x000000, 0);
                        frame.graphics.drawRoundRect(0, 0, base_width, base_height, 4);
                        frame.graphics.drawRoundRect(0, 0, base_width, base_height, 8);
                        frame.graphics.drawRoundRect(0, 0, base_width, base_height, 12);
                        frame.graphics.endFill();

                        frame.cacheAsBitmap = false;
                }

		/** 
		* Show White Box
		*/
		public function showWBox():void {
			// Use White Box frame by default
			layers.wbox.visible = true;
			layers.bbox.visible = false;
		}

		/** 
		* Show Black Box
		*/
		public function showBBox():void {
			// Use Black Box frame by default
			layers.bbox.visible = true;
			layers.wbox.visible = false;
		}

		/** 
		* Show/Hide Frame Menu.
		*/
		public function showMenu(mode:Boolean):void {
			// Turn off Menu Visibility
			layers.menuBG.visible = mode;
			menu.visible = mode;
			layers.menu.visible = mode;

			if (mode) {
				// Menu ON
				menu.text=plist.annotation;
				menu.setTextFormat(fmtmenu);

				layers.frame.height = base_height + menuHeight;
			} else {
				menu.text='';
				menu.setTextFormat(fmtmenu);

				// Menu OFF
				layers.frame.height = base_height;
			}
		}

                /**
                * Clear Video Playlist for Frame.
                */
                public function clearPlist():void {
                        plist.location = '';
                        plist.image = '';
                        plist.annotation = '';			
                }

                /**
                * Setup Video Playlist for Frame.
                */
                public function setPlist(location:String, image:String, annotation:String):void {
                        plist.location = location;
                        plist.image = image;
                        plist.annotation = annotation;			
			reload_stream = true;
                }

                /**
                * Play Frame Video.
                */
                public function playVideo():void {
			vwTrace("(" + id + ") Video play with running=" + 
				running.toString() + " state=" + state +
				" for: " + plist.location);

			if (ns == null || plist.location == '' || !running /*|| state == 1*/)
				return;

			reload_stream = false;
                        loop = false;
                        state = 0;
                        seek = 0;

                        // Play Video Frame
                        nspo.streamName = plist.location;
                        nspo.start = 0;
                        nspo.transition = NetStreamPlayTransitions.RESET;
                        ns.play2(nspo);
                }

                /**
                * Stop Frame Video.
                */
                public function stopVideo(show:Boolean = false):void {
			if (ns == null)
				return;

			vwTrace("(" + id + ") Video stop with running=" + 
				running.toString() + " state=" + state);

			visible = show;

                        if (running && state == 1) {
                                // Stop Video
                                ns.pause();
                                ns.close();
				if (!show)
                                	layers.video.clear();

				/*nspo.oldStreamName = plist.location;
                                nspo.streamName = '';
                                nspo.transition = NetStreamPlayTransitions.STOP;
                                ns.play2(nspo);*/

                                loop = false;
                                state = 0;
                                seek = 0;
                        }
                }

                /**
		* Initialize Frame Video.
		*/
                private function startVideo():void {
                        // Open Net Connection
                        nc = new NetConnection();

                        nc.addEventListener(NetStatusEvent.NET_STATUS, 
				netStatusHandler);
                        nc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, 
				securityErrorHandler);

                        nc.connect(null);
			vwTrace("(" + id + ") Video starting.");

                        return; 
                }

                /**
                * Frame NetStatus Handler.
                */
                private function netStatusHandler(event:NetStatusEvent):void {
                        switch (event.info.code) {
                            case "NetConnection.Connect.Success":
				var lvl:Number = 0;
			        if (!mute)
					lvl = 1;
                                ns = new NetStream(nc);
                                ns.soundTransform = new SoundTransform(lvl, 0);;
                        	nspo = new NetStreamPlayOptions();

                                ns.addEventListener(NetStatusEvent.NET_STATUS, 
					netStatusHandler);
                                ns.addEventListener(AsyncErrorEvent.ASYNC_ERROR, 
					asyncErrorHandler);

                                ns.client = new CustomClient(0)
                                layers.video.attachNetStream(ns);

                                layers.video.smoothing = true;
                                layers.video.width = base_width;
                                layers.video.height = base_height;

				// State is ready
                                state = 0;

                                // Running is TRUE
                                running = true;

				vwTrace("(" + id + ") Video initialized. '" + plist.location + "'");

                                break;
                            case "NetConnection.Connect.Closed":
                                break;
                            case "NetStream.Play.FileStructureInvalid":
                            case "NetStream.Play.StreamNotFound":
                                // Not Running
				vwTrace("(" + id + ") Video not found. '" + plist.location + "'");
                               	visible = false; 
                                state = 0;
                                loop = false;
                                break;
                            case "NetStream.Play.Stop":
				//vwTrace("(" + id + ") Video Stop. " + plist.location);
                                if (!lock && !loop && running &&
                                        state == 1 &&
                                        plist.location != '' &&
                                        !reload_stream &&
                                        seek == 0)
                                {
                                        // Signal a Loop is needed
					loop = true;
					seek = 1; 
                                	ns.pause();
					ns.seek(0);
                                }
                                break;
                            case "NetStream.Play.Start":
				vwTrace("(" + id + ") Video Start. " + plist.location);
                                seek = 0;
                                loop = false;
                                break;
                            case "NetStream.Buffer.Flush":
                                break;
                            case "NetStream.Buffer.Empty":
                                break;
                            case "NetStream.Buffer.Full":
                                // Make Frame Visible
                                if (!lock && state == 0) {
                                        visible = true;
                                }
                                // Play State ON
                                state = 1;
                                break;
                            case "NetStream.Seek.Notify":
                                // Seek is Done
                                if (seek == 1) {
                                        seek = 0;
					if (!lock) {
						loop = false;
						ns.resume();
					}
                                }
                                break;
                            default:
                                break;
                    }
                }

		/**
		* Video Playback callbacks
		*/
                private function securityErrorHandler(event:SecurityErrorEvent):void {
			// Ignore
                }

                private function asyncErrorHandler(event:AsyncErrorEvent):void {
			// Ignore
                }

		private function vwTrace(msg:String):void {
                        if (debug > 0)
                                trace(msg);
                }
	}
}
