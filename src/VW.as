/**
* VW Video Wall
* Chris Kennedy (C) 2009
*
*
* Shows a Wall of Videos
*/

package {
	import vw.VWFrame;
	import vw.VWPlayer;
	import vw.Data;
	import vw.VWTimer;
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Point;
	import flash.geom.Rectangle;
        import flash.geom.Matrix;
        import flash.geom.Matrix3D;
        import flash.geom.Vector3D;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.system.Capabilities;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
        import flash.filters.BevelFilter;
        import flash.filters.BitmapFilter;
        import flash.filters.BitmapFilterQuality;
        import flash.filters.BitmapFilterType;

        /**
        * VW Class
        */
	public class VW extends Sprite
	{
		public static const VIDEO_WALL_VERSION:String = '0.5.2';

                // Settings
                private var doCache:Boolean = true;
		
		// Main Array of data structures
		private var frames:Vector.<VWFrame> = new Vector.<VWFrame>();
                private var startupOrder:Vector.<int> = new Vector.<int>();
		
		//  Locking 
	        private var done_starting:Boolean = false;
	 	private var browse_lock:Boolean = true;	
                private var global_reload:Boolean = false;
	        private var do_search:Boolean = false;
	        private var fullScreen:Boolean = false;

                private var current_mouse_x:int = 0;
                private var current_mouse_y:int = 0;
                private var current_zoom:int = -1;
                private var reset_frames:Boolean = false;
                private var video_database_loaded:Boolean = false;
                private var video_timers_loaded:Boolean = false;

		// Layout Layers				
		private var mainframe:Sprite = new Sprite();
	 	private var bground:Shape = new Shape();
	 	private var floor:Sprite = new Sprite();

                // Browser Bar Base
	 	private var cbar:Sprite= new Sprite();

                // Filters
                private var bFilter:BitmapFilter = 
			new BevelFilter(1, 90, 0xd0d0d0, .8, 0x555555, .8, 
                        1, 1, 10, BitmapFilterQuality.HIGH, BitmapFilterType.INNER, false);

	 	// Wall Browser Controls
	 	private var nextButton:Sprite = new Sprite();
	 	private var prevButton:Sprite = new Sprite();
	 	private var browserText:TextField = new TextField();
	 	private var browserTextFont:TextFormat = new TextFormat();
	 	private var browserInputText:TextField = new TextField();
	 	private var browserInputTextFont:TextFormat = new TextFormat();
	 	private var searchText:TextField = new TextField();
	 	private var searchTextFont:TextFormat = new TextFormat();
	 	
	 	// Version
	 	private var verText:TextField = new TextField();
	 	private var verFont:TextFormat = new TextFormat();
	 	
	 	// Main Logo Image	 	
	 	private var wwwLogoBig:Loader = new Loader();
	 	
	 	// Button Images
	 	private var ffwdBtn:Loader = new Loader();
	 	private var rwdBtn:Loader = new Loader();
	 		  		 	
		// VW Data Class
		private var videoData:Data;

		// VWPlayer Class
		private var fsPlayer:VWPlayer;
		
		// Update Timer
		private var frameTimer:VWTimer;
		
		// Count of Frames, Videos, and Playlist Entries Active
		private var playlist_size:int = 0;
		private var playlist_total_size:int = 0;
				
		// AMF 
                private var amf_with_xml:Boolean = false;

		/**
		* Public Flash Vars 
		*/
	        public var debug:int = 0;
                public var browserOn:Boolean = true;
                public var playAll:int = 1;
	        public var hideversion:int = 0;
	        public var playsecs:Number = 4;
	        public var scale:Number = 2.00;
	        public var totalheight:Number = 0;
	        public var totalwidth:Number = 0;
	        public var fsheight:Number = 0;
	        public var fswidth:Number = 0;
	        public var imgwidth:Number = 88;
	        public var imgheight:Number = 66;
	        public var hoffset:Number = 4;
	        public var woffset:Number = 4;
	        public var menuon:int = 1;
	        public var menuColor:uint = 0x598bab;
	        public var menuTextColor:uint = 0xffffff;
	        public var menuheight:Number = 10;
                public var otw:Boolean = false;
                public var qLevel:String = '';
	        public var mFps:Number = 16;
	        public var zInc:Number = .10;

		/**
		* Colors and Look
		*/
                public var focusFrameColor:uint = 0xFFFFFF;
                public var mainFrameColor:uint = 0x000000;
                public var insideFrameColor:uint = 0xFFFFFF;
                public var backgroundColor:uint = 0x000000;
                public var backgroundFontColor:uint = 0xFFFFFF;
                public var backgroundAlpha:Number = 1;
		// Position/Layout
		public var showTitle:Boolean = true;
		public var showFSV:Boolean = false;
	        
		/**
		* Input Settings to Configure from HTML
		*/
                public var showHelp:int = 0;
	        public var pl:String = 'thumbs.xml';
	        public var start_track:int = 0;
	        public var end_track:int = 0;
	        public var wnum:Number = 5;
	        public var hnum:Number = 5;
	        public var search_filter:String = ".*";

		/** 
		* AMF Settings
		*/
                public var useAmf:Boolean = false;
                public var amfGateway:String = "/amfphp/gateway.php";
                public var amfService:String = "vw.getResults";
                public var amfClass:String = "vw";

		/**
		* 3D Mode
		*/
		public var do3d:Boolean = false;

		/**
		* Video to Play
		*/
		public var videoURL:String = "";
        	
                /**
                * Main VW Class Function
                */
		public function VW()
		{		
			super();				

			for (var fv:Object in root.loaderInfo.parameters) {
				vwTrace("flashvar name = "+fv);
				vwTrace("flashvar value = "+root.loaderInfo.parameters[fv]);
				switch(fv) {
					case 'debug':
						debug = root.loaderInfo.parameters[fv];
						break;
					case 'videoURL':
						videoURL = root.loaderInfo.parameters[fv];
						break;
					case 'hideversion':
						hideversion = root.loaderInfo.parameters[fv];
						break;
					case 'menuon':
						menuon = root.loaderInfo.parameters[fv];
						break;
					case 'menuheight':
						menuheight = root.loaderInfo.parameters[fv];
						break;
					case 'playsecs':
						playsecs = root.loaderInfo.parameters[fv];
						break;
					case 'imgheight':
						imgheight = root.loaderInfo.parameters[fv];
						break;
					case 'imgwidth':
						imgwidth = root.loaderInfo.parameters[fv];
						break;
					case 'wnum':
						wnum = root.loaderInfo.parameters[fv];
						break;
					case 'hnum':
						hnum = root.loaderInfo.parameters[fv];
						break;
					case 'end_track':
						end_track = root.loaderInfo.parameters[fv];
						break;
					case 'start_track':
						start_track = root.loaderInfo.parameters[fv];
						break;
					case 'scale':
						scale = root.loaderInfo.parameters[fv];
						break;
					case 'hoffset':
						hoffset = root.loaderInfo.parameters[fv];
						break;
					case 'woffset':
						woffset = root.loaderInfo.parameters[fv];
						break;
					case 'pl':
						pl = root.loaderInfo.parameters[fv];
						break;
					case 'search_filter':
						search_filter = root.loaderInfo.parameters[fv];
						break;
					case 'fsheight':
						fsheight = root.loaderInfo.parameters[fv];
						break;
					case 'fswidth':
						fswidth = root.loaderInfo.parameters[fv];
						break;
					case 'fps':
						mFps = root.loaderInfo.parameters[fv];
						break;
					case 'smooth':
						zInc = root.loaderInfo.parameters[fv];
						break;
					case 'menucolor':
						menuColor = root.loaderInfo.parameters[fv];
						break;
					case 'menutextcolor':
						menuTextColor = root.loaderInfo.parameters[fv];
						break;
					case 'otw':
						otw = root.loaderInfo.parameters[fv];
						break;
					case 'qLevel':
						qLevel = root.loaderInfo.parameters[fv];
						break;
					case 'browserOn':
						browserOn = root.loaderInfo.parameters[fv];
						break;
					case 'showHelp':
						showHelp = root.loaderInfo.parameters[fv];
						break;
					case 'playAll':
						playAll = root.loaderInfo.parameters[fv];
						break;
					case 'useAmf':
						useAmf = root.loaderInfo.parameters[fv];
						break;
					case 'amfGateway':
						amfGateway = root.loaderInfo.parameters[fv];
						break;
					case 'amfClass':
						amfClass = root.loaderInfo.parameters[fv];
						break;
					case 'amfService':
						amfService = root.loaderInfo.parameters[fv];
						break;
					case 'do3d':
						do3d = root.loaderInfo.parameters[fv];
						break;
					case 'ifc':
						insideFrameColor = root.loaderInfo.parameters[fv];
						break;
					case 'mfc':
						mainFrameColor = root.loaderInfo.parameters[fv];
						break;
					case 'ffc':
						focusFrameColor = root.loaderInfo.parameters[fv];
						break;
					case 'bc':
						backgroundColor = root.loaderInfo.parameters[fv];
						break;
					case 'bfc':
						backgroundFontColor = root.loaderInfo.parameters[fv];
						break;
					case 'ba':
						backgroundAlpha = root.loaderInfo.parameters[fv];
						break;
					case 'st':
						showTitle = root.loaderInfo.parameters[fv];
						break;
					case 'showFSV':
						showFSV = root.loaderInfo.parameters[fv];
						break;
				}
				
			}
        		// Start/Stop track sanity
		        if (end_track == 0 && start_track == 0) {
		        	end_track = ((hnum*wnum)-1);
		        } else {
		        	// User Input
		        	if (end_track <= start_track)
		        		end_track = start_track + ((hnum*wnum)-1);
		        }
	
		        //
			// STAGE SETUP
			//
			super.stage.align = StageAlign.TOP_LEFT;
			super.stage.scaleMode = StageScaleMode.NO_SCALE;
			super.stage.stageFocusRect = false;
			super.stage.frameRate = mFps;
			if (qLevel != '')
				super.stage.quality = qLevel;
			
			// Total Height and Width of Videos
			totalheight = (hoffset +  (hnum * (hoffset+imgheight)));
	        	totalwidth = (woffset + (wnum * (woffset+imgwidth)));

			//
			// STAGE RESIZE LISTENER
			//
			super.stage.addEventListener( Event.RESIZE, resizeHandler );						
	        		        	
	        	//
			// STAGE RESIZE HANDLER
			//
			function resizeHandler( e:Event=null ):void
			{
			    	var w:Number = stage.stageWidth;
			    	var h:Number = stage.stageHeight;
	        	
			        vwTrace("Resize to " + stage.stageWidth + "x" +
			    		        stage.stageHeight);			    
			}
			//
			// INITIALIZE
			//	
			resizeHandler()

                        if (showHelp == 1) {
                                debug = 1;
	    			showError("Help Options for VW:\n\n");
                                return;
                        }

			// Play full Video
			if (videoURL != "") {
				// VWPlayer Class
				fsPlayer = new VWPlayer(totalwidth, totalheight, debug);

				// Color
				fsPlayer.backgroundColor = backgroundColor;
				fsPlayer.backgroundFontColor = backgroundFontColor;
				fsPlayer.backgroundAlpha = backgroundAlpha;
				fsPlayer.showTitle = showTitle;

				// Choose video window size
				if (fsheight != 0 && fswidth != 0) {
					fsPlayer.fsheight = fsheight;
					fsPlayer.fswidth = fswidth;
				}
				// Initialize Full Screen Player
				fsPlayer.fsInit();
				addChild(fsPlayer);

				fsPlayer.playVideo(0, videoURL, videoURL);

				return;
			}

                        // Load Images
                        try {
                                loadImages();
                        } catch (error:Error) {
                                showError(error.name);
                        }
		}

        	/** 
                * Load Images.
                */
        	private function loadImages():void {       		
	 		var urlReq:URLRequest = new URLRequest();
	 		var ss:int = 10;
	 		
	 		// Rewind Button
	 		urlReq.url = "rewind.png";
	 		rwdBtn.load(urlReq);	
	 		
	 		// Forward Button
	 		urlReq.url = "forward.png";
	 		ffwdBtn.load(urlReq);
	 		
	 		// Wait till main image loads
			wwwLogoBig.contentLoaderInfo.addEventListener(Event.COMPLETE, onLogoLoadOK);
			wwwLogoBig.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLogoLoadOK);
	 				 		
	 		// Logo
	 		urlReq.url = "logoBig.gif";
	 		wwwLogoBig.load(urlReq);	 			 		
	                	                	               	 			 		
                        vwTrace("Images Loading...");
	 		return;
        	}
        	
	        /**
                * Images Loaded OK, now load Wall, frames and then XML Video Database File.
                */
		private function onLogoLoadOK(evt:Event):void {
                        vwTrace("Logo and Images Loaded OK.");
                        wwwLogoBig.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLogoLoadOK);
                        wwwLogoBig.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onLogoLoadOK);

                        // Main Wall Background
		        wallLoad();		        			

                        // Frames to put videos into
			frameLoad();

			// Startup Main Frame Timer
			startFrameTimer();
            		
			// Get Video Data
			videoData = new Data(debug, useAmf);

			videoData.url = this.loaderInfo.url;
			videoData.parameters = this.loaderInfo.parameters;
			videoData.useAmf = useAmf;
			videoData.amfGateway = amfGateway;
			videoData.amfService = amfService;
			videoData.amfClass = amfClass;
			videoData.pl = pl;

			videoData.addEventListener(Data.GOTRESULTS, videoDataHandler);

			// Perform Search
			videoData.doSearch(search_filter);

                        return;
		}

		/**
		* Event Handler for Data Resutls
		*/
		private function videoDataHandler(event:Event):void {
			useAmf = videoData.useAmf;
			amf_with_xml = videoData.amf_with_xml;

			if (videoData.failed) 
				showError("Failed at searching XML File");
			else {
				if (!done_starting)
					video_database_loaded = true;
				else {
					if (useAmf && !amf_with_xml) {
						vwTrace("New AMF Video Database with " + search_filter + " as filter");
						copyAmf(0, (frames.length-1));
					} else {
						vwTrace("New XML Video Database " + pl + " with " + search_filter + " as filter");
						searchXML(search_filter, 0, (frames.length-1));
					}

					loadNewDB();
				}
			} 
		}

		/** 
		* Startup Timer for Frame Events
		*/
		internal function startFrameTimer():void {
			//frameTimer = new VWTimer(0, (1000/mFps), 0);
                        //frameTimer.addEventListener(flash.events.TimerEvent.TIMER, onEnterFrame);
                        addEventListener(flash.events.Event.ENTER_FRAME, onEnterFrame);
                        //frameTimer.start();
		}

		/**
                * Main Wall background.
                */
		internal function wallLoad():void {	 			  	
                        var cbar_height:int = 18;

			// Main Window Frame
			if (do3d)
				mainframe.z = 0;
	        	mainframe.graphics.lineStyle(0, mainFrameColor, 0, true, 
	        		LineScaleMode.NONE, "square", "miter", 0);        
			if (browserOn)
	       	 		mainframe.graphics.beginFill(mainFrameColor, 1);
			else
	       	 		mainframe.graphics.beginFill(mainFrameColor, 0);
	 		mainframe.graphics.drawRect(0, 0, totalwidth, (totalheight+cbar_height));
	 		mainframe.graphics.endFill();
	 		
			// Background White Wall
			if (do3d)
				bground.z = 0;
	        	bground.graphics.lineStyle(0, insideFrameColor, 0, true, LineScaleMode.NONE, "round", "round", 0);        
	       	 	bground.graphics.beginFill(insideFrameColor, 1);
	 		bground.graphics.drawRoundRect(0, 0, totalwidth, totalheight, 20);
	 		bground.graphics.endFill();	 		
	 		
	 		// Floor Transparent for Frames to sit on
			if (do3d)
				floor.z = 0;
	        	floor.graphics.lineStyle(woffset, mainFrameColor, 1, true, LineScaleMode.NONE, "round", "miter", 0);        
	       	 	floor.graphics.beginFill(mainFrameColor, 0);
	 		floor.graphics.drawRect(0, 0, totalwidth, totalheight);
	 		floor.graphics.endFill();
	 			 			 		
	 		// Bottom Control Bar
	        	cbar.graphics.lineStyle(1, 0xe0e0e0, 1, true, LineScaleMode.NONE, "square", "miter", 0);        
	       	 	cbar.graphics.beginFill(0xe0e0e0, 1);
	 		cbar.graphics.drawRect(0, 0, totalwidth, cbar_height);
	 		cbar.graphics.endFill();	 		
                        cbar.x = 0;
                        cbar.y = totalheight;
	 		
 			// Next Videos Button
			nextButton.graphics.lineStyle(0, 0x000000, 0, true, LineScaleMode.NONE, "square", "miter", 0);        
    			nextButton.graphics.beginFill(0xffffff, 0);
 			nextButton.graphics.drawRect(totalwidth-20, 1, 20, cbar_height-2);
 			nextButton.graphics.endFill();				
                        nextButton.addEventListener(flash.events.MouseEvent.CLICK, nextVideos);
                        nextButton.buttonMode = true;
                        nextButton.useHandCursor = true;
                        nextButton.mouseEnabled = false;
                        ffwdBtn.x = totalwidth-19;
                        ffwdBtn.y = 1;
                        
                        // Previous Videos Button
			prevButton.graphics.lineStyle(0, 0x000000, 0, true, LineScaleMode.NONE, "square", "miter", 0);        
    			prevButton.graphics.beginFill(0xffffff, 0);
 			prevButton.graphics.drawRect(1, 1, 20, cbar_height-2);
 			prevButton.graphics.endFill();				
                        prevButton.addEventListener(flash.events.MouseEvent.CLICK, prevVideos);
                        prevButton.buttonMode = true;
                        prevButton.useHandCursor = true;
                        prevButton.mouseEnabled = false;
                        rwdBtn.x = 3;
                        rwdBtn.y = 1;                                             
                                               
                        // Big Logo
			if (do3d)
				wwwLogoBig.z = 0;
			wwwLogoBig.x = (totalwidth-wwwLogoBig.width)/2;
			wwwLogoBig.y = (totalheight-wwwLogoBig.height)/2;
                        
                        // Input Search
                        inputSearch();
                        browserInputText.type = TextFieldType.INPUT;                                             
                                                  	                       
                        // background/Floor and Browser Bar
                        backGround();

	            	// Version Output
	            	if (hideversion != 1) {
	                    outputVersion();
	            	}
                        browserBar('Starting up VW...');
                       
			// VWPlayer Class
			fsPlayer = new VWPlayer(totalwidth, totalheight, debug);

			// Color
			fsPlayer.backgroundColor = backgroundColor;
			fsPlayer.backgroundFontColor = backgroundFontColor;
			fsPlayer.backgroundAlpha = backgroundAlpha;
			fsPlayer.showTitle = showTitle;

			// Choose video window size
			if (fsheight != 0 && fswidth != 0) {
				fsPlayer.fsheight = fsheight;
				fsPlayer.fswidth = fswidth;
			}
			// Initialize Full Screen Player
			fsPlayer.fsInit();
			mainframe.addChild(fsPlayer);

                        vwTrace("Main Wall Loaded.");
                        return;
  		}
  		
  		/** 
                * Frames Setup.
                */
  		internal function frameLoad():void {
	        	var myid:int = 0;
			var my_y:Number = new Number(0);
			var my_x:Number = new Number(0);
	        	var i:int;
			var j:int;
			
			for(j = 0, my_y = hoffset;j < hnum; j++, my_y+=(imgheight+hoffset)) {
	                    // Row X, Column Y
	                    for(i = 0, my_x = woffset; i < wnum; i++, my_x+=(imgwidth+woffset)) {
		        	// Make TV Shape on base floor to fit Frame into
		        	floor.graphics.lineStyle(3, mainFrameColor, 1, true, LineScaleMode.NONE, CapsStyle.SQUARE, JointStyle.MITER, 0);
		        	floor.graphics.drawRect(my_x-(woffset/2), my_y-(hoffset/2), 
		        		imgwidth+(woffset), imgheight+(hoffset));
		        	floor.graphics.lineStyle(5, mainFrameColor, 1, true, LineScaleMode.NONE, CapsStyle.ROUND, JointStyle.ROUND, 0);
		        	floor.graphics.drawRoundRect(my_x-(woffset/2), my_y-(hoffset/2), 
		        		imgwidth+(woffset), imgheight+(hoffset), 20);
	                        	                       							
	                    	// Main Frame Data Structure
	                    	var myframe:VWFrame = new VWFrame(myid, do3d, debug);

				// VWFrame basic setup
				myframe.menuFontSize = 5;
				myframe.menuHeight = menuheight;
				myframe.menuColor = menuColor;
				myframe.menuTextColor = menuTextColor;
				myframe.focusFrameColor = focusFrameColor;
				myframe.mainFrameColor = mainFrameColor;
				myframe.visible = false;

	 			// VWFrame 3D Mode
				if (do3d)
					myframe.z = 0;

				// VWFrame Graphics Layout/Draw width/height parameters
	 			myframe.graphics.lineStyle(0, 0x000000, 
		                        	0, true, LineScaleMode.NONE, "round", "round", 0);
	 			myframe.graphics.beginFill(0x000000, 0);
		 		myframe.graphics.drawRect(0, 0, imgwidth, imgheight);
		        	myframe.graphics.endFill();

				// Set X/Y Position of Frame
		        	myframe.x = my_x;
	 			myframe.y = my_y;

				// Setup/Initialize Layers for VWFrame Class
				myframe.setupLayers();

				// Frame Mouse Events
                                myframe.layers.frame.addEventListener(flash.events.MouseEvent.ROLL_OUT, onFrameRollOut);
                                myframe.layers.frame.addEventListener(flash.events.MouseEvent.ROLL_OVER, onFrameRollOver);
                                myframe.layers.frame.addEventListener(flash.events.MouseEvent.CLICK, onPress);

				// Add VWFrame to floor Display
				floor.addChild(myframe);

	                        // Save Frame into Array
	                    	frames.push(myframe);

	                        // Increment Box ID
	 			myid++;						
	                    }
	           	}
	 			 			  		
                        vwTrace(myid + " Frames Loaded.");

	            	return;
        	}
        	
        	/**
        	* Load Videos in Frames.
        	*/
        	internal function videoLoad ():void {	        	
			var i:int;
			
            		// Get Videos from DB
                        if (useAmf && !amf_with_xml)
                                copyAmf(0, (frames.length-1));
                        else
            		        searchXML(search_filter, start_track, end_track);
 			
                        // Mouse Over for Floor
                        floor.addEventListener(flash.events.MouseEvent.MOUSE_MOVE, onFloorMouseMoveCB);
	            		            			        			            	
	            	// When roll out of main floor, make sure all frames are normal zoom
		        floor.addEventListener(flash.events.MouseEvent.ROLL_OUT, onBigRollOutCB);	

	        	// Setup Video Boxes
	                for(i = 0; i < frames.length; i++) {
			        // Start Video Playback, Randomly start them, not all at once
			        var rand_num:Number = Math.floor(Math.random() * ((wnum*1000) - 1 + 1)) + 1;

                                // New Timer for Video Startup and Menu Slideout
                                frames[i].timer = new VWTimer(i, rand_num, 1);
                                frames[i].timer.addEventListener(flash.events.TimerEvent.TIMER, startVideoTimer);
                                frames[i].timer.start();
	                }
	
	            	vwTrace(i + " Videos Loading...");
	            	return;
	        } 
	        
		/**
        	* Process XMLDocument Config.
                *
                * @param term String/Filter to search with through XML File.
                * @param a start index of results to show.
                * @param b end index of results to show.
        	*/
        	internal function searchXML(term:String, a:int, b:int):void {                  	
			// XML Stuff
			var tracks:XML;   
			var video:XML;  

			var result:Array = new Array();
			var pat:RegExp; 
                    
                	var n:int = 0;
                	var i:int = 0;
                	var x:int = 0;                 	 
                	var got_it:Boolean;
                	
                	pat = new RegExp(term, "i");	
      
                	vwTrace("Searching for '" + term + "'" + " for tracks " + a + " to " + b);           	               	
	                for each (tracks in videoData.trackList.children()) {
	                	got_it = false;	                   		                    	
	                        for each (video in tracks.children()) {	  	                        	  	                        	                    	
	                                if (video.name() == "http://xspf.org/ns/0/::location") {
	                                	result[0] = video.text();	                                	
	                                	if (useAmf || video.text().toString().search(pat) >= 0) {
	                                        		                                    		
							if (video.text().toString().length > 0)
	                                 			got_it = true;
	                                 	}
	                                } else if (video.name() == "http://xspf.org/ns/0/::image") {
	                                	result[1] = video.text();
	                                	if (useAmf || video.text().toString().search(pat) >= 0) {
	                                        		                                    		
							if (video.text().toString().length > 0)
	                                    			got_it = true;
	                                 	}
	                                } else if (video.name() == "http://xspf.org/ns/0/::annotation") {	                                        
	                                    	result[2] = video.text();
	                                    	if (useAmf || video.text().toString().search(pat) >= 0) {
	                                        		                                    		
							if (video.text().toString().length > 0)
	                                    			got_it = true;
	                                 	}
	                                } else
	                                        vwTrace("(" + n + "). Unknown: " + video.text());
	                                video = null;	                             
	                        }
	                 		
	                 	// Matching Tracks in Range and fit into Frames Array	                 	
	                        if ((x >= a && x <= b) && got_it && n < frames.length) {
					frames[n++].setPlist(result[0], result[1], result[2]);
	                        }     
	                        // Total Entries that Match Counter
	                 	if (got_it)
	                 		x++;    

	                        // Total Entries Counter
	                        i++; 
	                        
	                        tracks = null;             	

				result[0] = "";
				result[1] = "";
				result[2] = "";
	                }
	                vwTrace("Found " + n + " Video Tracks out of " + x + " Total.");
	                playlist_size = n;	 
	                playlist_total_size = x;	                

	                tracks = null;
	                video = null;
	                pat = null;
	                	                                       
	                return;
        	}

		/**
        	* Process Amf Associative Array.
                *
                * @param a start index of results to show.
                * @param b end index of results to show.
        	*/
        	internal function copyAmf(a:int, b:int):void {                  	
                	var n:int = 0;
                	var i:int = 0;
                	
                	vwTrace("Getting results for '" + search_filter + "'" + " tracks " + a + " to " + b);           	               	
	                for (i=0; i < videoData.amfResults.length; i++) {
	                 	// Matching Tracks in Range and fit into Frames Array	                 	
	                        if ((i >= a && i <= b) && n < frames.length) {
					frames[n].setPlist(videoData.amfResults[i].location,
						videoData.amfResults[i].image, videoData.amfResults[i].annotation);
	                        	n++; 
	                        }     
	                }
	                vwTrace("Found " + n + " Video Tracks out of " + i + " Total.");
	                playlist_size = n;	 
	                playlist_total_size = i;	                

	                return;
        	}

        	/**
                * Show Main Screen Background/Frame.
                */
	        internal function backGround():void {
	        	// background/Floor and Browser Bar
                        addChild(mainframe);
                        mainframe.addChild(bground);
                        try {
                        	mainframe.addChild(wwwLogoBig);
                        } catch (error:Error) {
	    			// Ignore Errors
	    		}
	 		mainframe.addChild(floor);
	 			
                        mainframe.cacheAsBitmap = doCache;

		        return;
	        }
	        
	        /** 
                * Show Main Bottom Browser Bar, setup if current text isn't set yet.
                * 
                * @param msg Message to output to browser bar, calls outputTracksText.
                */
	        internal function browserBar(msg:String):void {		        	        	
                        if (!browserOn)
                                return;

                        if (browserText.text != '') {
                                outputTracksText(msg, false);
                                return;
                        }

	        	mainframe.addChild(cbar);
	        	try {
	                	cbar.addChild(ffwdBtn);
	                } catch (error:Error) {
	    			// Ignore
	    		}
	                cbar.addChild(nextButton);
	                try {
	                	cbar.addChild(rwdBtn);
	                } catch (error:Error) {
	    			// Ignore
	    		}
		        cbar.addChild(prevButton); 
		        cbar.addChild(searchText);

                        // Calculate Output Tracks
                        outputTracksText(msg, true);

		        cbar.addChild(browserText);
		        cbar.addChild(browserInputText);
		        if (hideversion != 1)
		        	cbar.addChild(verText);    

                        cbar.filters = [bFilter];
                        cbar.cacheAsBitmap = doCache;
                        
		        return;  
	        }
	        
                /**
                * Output browser bars tracks information setup.
                * 
                * @param msg Message to output, if empty then prints tracks out.
                * @param initialize If true then setup text output, else just changes text.
                */
        	internal function outputTracksText(msg:String, initialize:Boolean):void {
        		var st:int = start_track;
        		var et:int = end_track;
                        var statMsg:String;

                        // If XML file doesn't contain as many videos as Wall has Frames
                        if (playlist_total_size < end_track && playlist_total_size < ((wnum*hnum)-1))
                                et = playlist_total_size;
        		
        		if (st == 0 && et != (hnum*wnum) && et < playlist_size)
        			et+=1;
        		st += 1;       		      		   			
                        if (msg == '' && playlist_total_size > 0)
                                statMsg =  st + "-" + et + " of " + playlist_total_size;
                        else  if (msg == '' && playlist_total_size <= 0)
                                statMsg = "No Video Results";
                        else if (msg == '')
                                statMsg = '';
                        else
                                statMsg = msg;
        			
                        if (initialize) {
        		        outputVideoText(false, true, 0x000000, browserText, 
	                	        browserTextFont, 1, 10, 30, 1, 100, 16, statMsg);
                        } else {
                                browserText.text = statMsg;
                                browserText.setTextFormat(browserTextFont);
                        }
	        }
        	
                /**
                * Lock browser bar while loading frames.
                *
                * @param mode Locks or Unlocks browser bar.
                */
                internal function browseLock(mode:Boolean):void {
                	browse_lock = mode;
		        nextButton.mouseEnabled = !mode;
		        prevButton.mouseEnabled = !mode;	
                }

                /** 
                * Lock Screen while loading frames.
                *
                * @param mode Locks or Unlocks Screen.
                */
                internal function screenLock(mode:Boolean):void {
                	// Screen Lock
                	var z:int = 0;
                	
                	if (mode) { // Lock Screen
                		vwTrace("Locking Screen.");
                		browseLock(true);
                                for each (z in startupOrder) {
 					// Hide Frames
                                        frameVisible(z, false);
 					
 					// Reset Zoom to 1.0
 					zoomVideo(z, 1.0);					
                                        boxMenuOff(z);
                		}
                	} else { // Unlock Screen
                		vwTrace("Unlocking Screen.");
			        browseLock(false);
                	}                	
                }
                
                /** 
                * Page to previous page of videos.
                */
        	internal function prevVideos(event:MouseEvent):void {
                        if (browse_lock || global_reload)
                                return;
        		       		
        		if ((start_track-(hnum*wnum)) >= 0) {
        			start_track -= ((hnum*wnum));
        			end_track = start_track + (hnum*wnum);
        		} else if (start_track != 0) {
        			start_track = 0;
        			end_track = start_track + (hnum*wnum);
        		} else
        			return;		
 					
 			screenLock(true);
                        if (useAmf && !amf_with_xml)
                                copyAmf(start_track, end_track);
                        else
		                searchXML(search_filter, start_track, end_track);
		        
			resetFrames();

                        browserBar('Loading...');
                        global_reload = true;
            		vwTrace(" Previous Video Paging: " + playlist_size + " Videos in Database.");
                };
                
                /** 
                * Page to next page of videos.
                */
                internal function nextVideos(event:MouseEvent):void {	
                        if (browse_lock || global_reload)
                                return;
        		       		
                	if ((start_track+((hnum*wnum))) <= playlist_total_size-((hnum*wnum))) {
        			start_track += ((hnum*wnum));
        			end_track = start_track + ((hnum*wnum));
        		} else if ((start_track+(hnum*wnum)) < (playlist_total_size)) {
        			start_track += ((hnum*wnum));
        			end_track = (playlist_total_size);
        		} else
        			return; 	           		              		
 			
 			screenLock(true);		        
                        if (useAmf && !amf_with_xml)
                                copyAmf(start_track, end_track);
                        else
 			        searchXML(search_filter, start_track, end_track);

			resetFrames();

                        browserBar('Loading...');
                        global_reload = true;
            		vwTrace(" Next Video Paging: " + playlist_size + " Videos in Database.");
                };
        	 	        
	        /**
                * Search Text Callback.
                */
	        internal function onSearchInput(event:KeyboardEvent):void {
	        	if (browse_lock || global_reload)
                		return;
 
	        	if (event.target.text.length > 0 && (event.keyCode == 13)) {
	        		vwTrace("keyboard input: " + event.target.text);

	        		search_filter = event.target.text;

                                if (useAmf) {
                                       	videoData.doSearch(search_filter);
                                } else {
	        		        searchXML(search_filter, 0, (frames.length-1));

                                        // Load new DB
                                        loadNewDB();
                                }
	        	} else if (event.keyCode == 13 && event.target.text.length == 0)  {
	        		vwTrace("keyboard enter pressed, default search .* used.");

	        		search_filter = ".*";

                                if (useAmf) {
                                       	videoData.doSearch(search_filter);
                                } else {
	        		        searchXML(search_filter, 0, (frames.length-1));

                                        // Load new DB
                                        loadNewDB();
                                }
                        }
	        };	

                /** 
                * Load New Video Database, first page
                */
                internal function loadNewDB():void {
                        start_track = 0;
                        end_track = playlist_size;

                        if (playlist_size > 0)
                                screenLock(true);

			resetFrames();

                        if (playlist_size > 0) {
                                global_reload = true;
                                browserBar('Searching...');
                        } else {
                                browserBar('0 matches');
                        }
                        return;
                }
	        
		/**
		* Reset state of all frames, stop video, scale to 1.0
		*/
		internal function resetFrames():void {
                        for each (var z:int in startupOrder) {
				zoomVideo(z, 1.0);
                                frames[z].stopVideo();
                                if (z >= playlist_size)
                                        frames[z].clearPlist();
                        }
		}

                // Video/Menu Timer Function
                internal function startVideoTimer(event:TimerEvent):void {
                        // Start Video
                        if (!frames[event.target.id].timer_started) {
				// Signal we started the Video
				frames[event.target.id].timer_started = true;

				// Start the Video (first time)
				frames[event.target.id].playVideo();

				// Save order of video startup into an array
                                startupOrder.push(event.target.id);
                        } else {
				// Box Menu Slideout
                                boxMenu(event.target.id, true);
                        }
                }

	        // Show Menu in ZOOM Mode
	        internal function boxMenu(id:int, turnOn:Boolean):void {
	             if (menuon == 1) {
                          if (id < 0 || id >= frames.length)
                                return;

	                  if (turnOn) {	
	                        // Bottom Row needs to jump up a bit
	                  	if (((id+1) > ((hnum*wnum)-wnum)) && (frames[id].scaleY > 1.0))
	                                frames[id].y -= (frames[id].scaleY*frames[id].menuHeight) + (4-hoffset);

	              	  	// Make Menu Visible
                                menuVisible(id, true);
	              	  } else { 	              	  		              	  	              	  	
	                  	// Menu OFF
                                menuVisible(id, false);
	                  }	                  	                  	                  
	             }
	        }

                // Main Timer for Zoom/Timing updates
	        internal function onEnterFrame(event:Event):void {
                        var z:int;

			// Wait till netstream/video is fully initialized
			if (!done_starting && !video_timers_loaded) {
				// Check that all NetStreams are initialized
				for (z=0; z < frames.length; z++) {
					if (frames[z].state < 0)
						return;
				}
				// Start Video Timers
				if (video_database_loaded) 
					videoLoad();
				else
					return;

				video_timers_loaded = true;
			}

                        // Check if all videos have started up
                        if (!done_starting && (startupOrder.length == frames.length)) {
				done_starting = true;

				if (!fsPlayer.full_screen_lock) {
					vwTrace("Unlocking browser bar after startup.");
                                        browserBar('');
                                        browseLock(false);
				}
				vwTrace("Done loading " + startupOrder.length +
                                      " Frames for Floor with " + playlist_size + " Videos in Database.");
                        }

			if (fsPlayer.full_screen_lock && fsPlayer.full_screen_on) {
				if (!fullScreen && cbar.visible) {
					cbar.visible  = false;
					current_zoom = -1;
				}
				fullScreen = true;

		                // Stop all other videos
                                for each (z in startupOrder) {
					if (frames[z].lock)
						continue;

					zoomVideo(z, 1.0);
	        			zoomME(z, 1.0);
					frames[z].stopVideo(showFSV);

					frames[z].lock = true;
                                }

                                // Move to next Video on Wall
                                if ((playAll == 1) && fsPlayer.fns.client.duration > 0 && 
						(fsPlayer.fns.time >= (fsPlayer.fns.client.duration-1))) 
				{
                                        if ((fsPlayer.id+1) < frames.length && 
						fsPlayer.videoURL != frames[fsPlayer.id+1].plist.image &&
                                                frames[fsPlayer.id+1].running && 
                                                frames[fsPlayer.id+1].plist.image != '' &&
                                                !fsPlayer.nextPlay) 
                                        {
                                                vwTrace("Next Full Stream APPEND for ID: " + (fsPlayer.id+1));
						fsPlayer.setupAppend(fsPlayer.id+1, frames[fsPlayer.id+1].plist.image,
							frames[fsPlayer.id+1].plist.annotation);
                                        }
                                }

                		return;
                	} else if (fsPlayer.full_screen_lock) {
				if (!fullScreen && cbar.visible) {
					cbar.visible  = false;
					current_zoom = -1;
				}
                                return;
			} else if (fullScreen) {
				cbar.visible  = true;

				// Exiting out of Full Screen Mode
				fullScreen = false;

				// Lock for Reload
				screenLock(true);

				// Set all Frames to Reload
				for each (z in startupOrder) {
					frames[z].lock = false;
					if (frames[z].plist.location != '')
						frames[z].reload_stream = true;
				}

				// Allow Frame Videos to Reload
				browserBar('Loading...');

				global_reload = true;
			} else if (!cbar.visible)
				cbar.visible = true;

                	// Check all Streams for Zooming and Reloading
                        var looped:Boolean = false;
                        for each (z in startupOrder) {
				var id:int = z;      	
	        		var fS:Number = new Number(frames[id].scaleX);      		  
	        		var qS:Number = new Number(frames[id].scale);

                                fS = Number(fS.toFixed(2));

                                // Check if this frame is in focus
                                if (current_zoom == id) {
                                        // Frame is in Focus
                                        if (frames[id].layers.bbox.visible && 
							frames[id].state == 1) 
                                        {
						frames[id].showWBox();
                                        }
                                } else {
                                        // Frame Out of focus
                                        if ((frames[id].layers.wbox.visible || frames[id].layers.menuBG.visible) && 
                                                        frames[id].state == 1) 
                                        {
						frames[id].showBBox();
						frames[id].showMenu(false);
                                        }
                                }

	                	// Zoom/Resize Frame if a request is in the queue
				var changed_scale:Boolean = false;
	        		if (fS != qS) { // Queued Scale Different than current
	        		        var nS:Number = new Number(0);

	        			if (fS < qS) { // Increase Zoom
	        				if ((fS+zInc) > qS)
	        					nS = fS+.02;
	        				else
	        					nS = fS+zInc;
	        				if (nS > qS)
	        					nS = qS;
                                                if (nS > scale)
                                                        nS = scale;
                                                else if (nS < 1.0)
                                                        nS = 1.0;
	        					
                                                nS = Number(nS.toFixed(2));
	        				if (nS == 1.0 || nS == scale || (nS >= (fS+.02))) {
	        					zoomME(id, nS);
							changed_scale = true;
	        				}
	        			} else if (fS > qS) { // Decrease Zoom
	        				if ((fS-zInc) < qS)
	        					nS = fS-.02;
	        				else
	        					nS = fS-zInc;
	        				if (nS < qS)
	        					nS = qS;
                                                if (nS > scale)
                                                        nS = scale;
                                                else if (nS < 1.0)
                                                        nS = 1.0;
	        				
                                                nS = Number(nS.toFixed(2));
	        				if (nS == 1.0 || nS == scale || (nS <= (fS-.02))) {
	        					zoomME(id, nS);
							changed_scale = true;
	        				}	
	        			}
					//event.updateAfterEvent();
	        		}    		
	                		
	                	// Check if Reload/Restart Needed
				if (!looped && global_reload && frames[id].reload_stream) {
					var all_done:Boolean = true;
                                        looped = true;

				        // Fully stop old Video	
					zoomVideo(id, 1.0);
					//frames[id].stopVideo();

				        // Play New Video URL	
                                        frames[id].playVideo();
						
					// Check if all streams done reloading
                                        for (var i:int=0; i < frames.length; i++) {
						if (frames[i].reload_stream) {
							all_done = false;
							break;
						}
					}
					// Unlock screen if all are done restarting
					if (all_done) {
						screenLock(false);
                                                global_reload = false;
                                                browserBar('');
					}					

				}
                	}
                }             

                // Toggle Frame Visibility
                internal function frameVisible(id:int, mode:Boolean):void {
                        if (id < 0 || id >= frames.length)
                                return;

                        // White or Black Boxes
                        if (mode) {
                                if (current_zoom == id)
					frames[id].showWBox();
                                else
					frames[id].showBBox();
                        }

			// VWFrame Base
			frames[id].visible = mode;

                        return;
                }
                
                // Toggle Menu Visibility
                internal function menuVisible(id:int, mode:Boolean):void {
                        if (id < 0 || id >= frames.length)
                                return;

			// VWFrame Menu 
			frames[id].showMenu(mode);

                        return;
                }
	        
                // Get Zoom Size
                internal function getZoomSize(dfc:Number, perc:Number, focus:Boolean):Number {
                        var s:Number = scale;
                        if (!focus)
                                s -= .40;
                        var zoomSize:Number = (s - (dfc*perc));
                        if (focus && (zoomSize < (scale-.10)))
                                zoomSize = scale-.10;
                        if (zoomSize < 1.0)
                                zoomSize = 1.0;

                        // Chop off all extra beyond .00
                        zoomSize = Number(zoomSize.toFixed(2));

                        return zoomSize;
                }

	        // Set Video Scale/Zoom (with checking)   
	        internal function zoomVideo(id:int, count:Number):void 
        	{
        		if (id < 0 || id >= frames.length)
                		return;               			               	             	

                        if (frames[id].state == 0 && count > 1.0)
                                return;

                        if (count < 1 || count > scale)
                                return;
                	              	               	                 
                	// Queue Zoom Scale	              	          
                	frames[id].scale = count;              	                  	           	
         	}

	        // Zoom frame ID to Scale Number on all Layers
	        internal function zoomME(id:int, value:Number):void { 
	        	// is this box the current Zoomed Frame		
                	var focus:Boolean = false; 
                	if (current_zoom == id)
                		focus = true;

                        // Balloon Video Position
                        var new_x:Number;
                        var new_y:Number;
                        if (value == 1) {
                        	new_x = frames[id].g.p.x;
                        	new_y = frames[id].g.p.y;
                        } else { 
                        	new_x = ((imgwidth*(value-1))/2);
                        	new_y = ((imgheight*(value-1))/2);
                                
                                // Can have side frames go off the wall if desired
                                if (!otw || focus) {  
		                        // Move X Axis of Box this much when zooming
		                        if (frames[id].g.p.x <= (new_x+woffset))
		                                new_x = 0;
		                        else if (((id+1)%wnum) == 0)
		                                new_x = ((imgwidth*(value-1))/1) + (4-woffset);
		            
		                        // Move Y Axis of Box this much when zooming
		                        if (frames[id].g.p.y <= (new_y+hoffset))
		                                new_y = 0;
		                        else if ((id+wnum+1) > (hnum*wnum))
		                                new_y = ((imgheight*(value-1))/1) + (4-hoffset);
                                }
	                         	                              
	                        new_x = frames[id].g.p.x - new_x;
                        	new_y = frames[id].g.p.y - new_y;
                        }   

                        // Adjust bottom row for Menu
                        if (value > 1.0 && frames[id].layers.menuBG.visible) {
                        	if ((id+1) > ((hnum*wnum)-wnum)) {
	                                new_y -= (value*menuheight) + (4-hoffset);
	                        }	
                        }

			var zAxis:Number = 0;
			if (!do3d) {
				// Use a Matrix to transform Frame into desired Scale and Position
				var newMatrix:Matrix = frames[id].transform.matrix;

				newMatrix.createBox(value, value, 0, new_x, new_y);

				frames[id].transform.matrix = newMatrix;
			} else {
				// Use a 3D Matrix to transform Frame into desired Scale and Position
				var newMatrix3D:Matrix3D = frames[id].transform.matrix3D;
				var comp:Vector.<Vector3D> = new Vector.<Vector3D>();

				var tr:Vector3D = new Vector3D(new_x, new_y, frames[id].z);
				var ro:Vector3D = new Vector3D(frames[id].rotationX, 
					frames[id].rotationY, frames[id].rotationZ);
				var sc:Vector3D = new Vector3D(value, value, value);

				comp.push(tr);
				comp.push(ro);
				comp.push(sc);

				newMatrix3D.recompose(comp);
				frames[id].transform.matrix3D = newMatrix3D;
			}

                        // Geometry Position of this frames Center inside of Floor
                        var midX:Number = (new_x+((imgwidth*value)/2));
                        var midY:Number = (new_y+((imgheight*value)/2));
                        frames[id].g.cp.x = midX;
                        frames[id].g.cp.y = midY;
	        }

	        // On Mouse Over
	        internal function onFrameRollOver(event:MouseEvent):void {
                        var id:int = event.target.id;
                        if (frames[id].state != 1)
                                return;

                        current_zoom = id;
                        reset_frames = false;

                        // Make black/white boxes show properly
                        frameVisible(id, true);
                        onFloorMouseMove(true);

                        // Menu Timer
                        if (frames[id].timer_started && !frames[id].timer.running) {
                                frames[id].timer.delay = 1000;
                                frames[id].timer.repeatCount = 1;
                                frames[id].timer.start();
                        }

                        //event.updateAfterEvent();
                }

	        // On Mouse Out
	        internal function onFrameRollOut(event:MouseEvent):void {
                        var id:int = event.target.id;
                        
			current_zoom = -1;

                        boxMenuOff(id);

                        // Make black/white boxes show properly
                        if (frames[id].state == 1)
                                frameVisible(id, true);

                        //event.updateAfterEvent();
                }

	        // On Mouse Move 
	        internal function onFloorMouseMoveCB(event:MouseEvent):void {
                        onFloorMouseMove(false);
                }
	        internal function onFloorMouseMove(justDoIt:Boolean):void {
                        var z:int;

		        var mX:Number = floor.mouseX;
		        var mY:Number = floor.mouseY;		        

                        // Don't do this if the mouse is not moving
                        if ((mX <= 0 && mY <= 0) || (!justDoIt && 
                                ((mX == current_mouse_x && mY == current_mouse_y) || 
                                        current_zoom == -1))) 
                        {
                                if (current_zoom < 0 || ((mX <= 0 && mY <= 0) || (mX >= totalwidth && mY >= totalheight)))
                                        //onBigRollOut();

                                return;
                        }
                        current_mouse_x = mX;
                        current_mouse_y = mY;

                        // Store current mouse position and distance from center of each frame
                        var frameSizes:Array = new Array();
		        var pt:Point = new Point(mX, mY);
                        for (z = 0; z < frames.length; z++) {
                                // Distance from Mouse Pointer to Center of Frame
                                var dfc:Number = (.01 * Point.distance(pt, frames[z].g.cp));                                

                                frameSizes.push({id:z, size:dfc});
                        }
                        // Nothing to do, no focus, set all frames to 1.0 scale
                        if (current_zoom < 0) {
                                //onBigRollOut();
                                return;
                        }

                        //  Sort Frame Array of distances from Mouse Pointer
                        frameSizes.sortOn(["size"], Array.NUMERIC | Array.DESCENDING);

                        //  Cycle through Frames and Zoom/Focus them according to Mouse Proximity
                        var oldDepth:int;
                        var i:int = 0;
                        var zoomSize:Number;
                        for (z = 0; z < frameSizes.length; z++) {
                                //
                                if (current_zoom != frames[frameSizes[z].id].id) {
                                        // Unfocused Frame
                                        if (z == frameSizes.length-1)
                                                break;

                                        // Focus Frame
                                        oldDepth = baseDepth(frameSizes[z].id, false, 0);
                                        if (oldDepth != i)
                                                floor.swapChildrenAt(oldDepth, i);

                                        // Zoom Frame
                                        zoomSize = getZoomSize(frameSizes[z].size, .25, false);
	        	                zoomVideo(frameSizes[z].id,  zoomSize);       		

                                        i++;
                                } else {
                                        // Main Zoom Focused Frame
                                        oldDepth = baseDepth(frameSizes[z].id, false, 0);
                                        if (oldDepth != (frameSizes.length-1))
                                                floor.swapChildrenAt(oldDepth, (frameSizes.length-1));

                                        // Zoom Frame
                                        zoomSize = getZoomSize(frameSizes[z].size, .15, true);
	        	                zoomVideo(frameSizes[z].id,  zoomSize);       		

                                        if (z != (frameSizes.length-1)) {
                                                // Frame we are closest to from Main Zoom Frame
                                                oldDepth = baseDepth(frameSizes[(frameSizes.length-1)].id, false, 0);
                                                if (oldDepth != (frameSizes.length-2))
                                                        floor.swapChildrenAt(oldDepth, (frameSizes.length-2));

                                                // Closest Frame to Focus Zoom
                                                zoomSize = getZoomSize(frameSizes[frameSizes.length-2].size, .10, false);
	        	                        zoomVideo(frameSizes[(frameSizes.length-1)].id, zoomSize);
                                        }
                                }
                        }

                        return;
                }

                // On Roll Out/Over Floor
	        internal function onBigRollOutCB(event:MouseEvent):void {
                        onBigRollOut();
                }
	        internal function onBigRollOut():void {
	        	// Set every frame back to normal scale	
                        if (reset_frames) 
                                return;

                        reset_frames = true;
                        for each (var id:int in startupOrder) {
                                frames[id].scale = 1.0;
	                }
			current_zoom = -1;
	        }
	       
                // Set Frame Depth to Top if Focus, else right below Focus
                internal function arrangeFocusDepth(id:int):void {
                        var z:int = (floor.numChildren-1);
                        var thisDepth:int = baseDepth(id, false, 0);

                        // Not Current Zoom
                        if (current_zoom != id)
                                z--;

                        // Main Focus
                        if (thisDepth != z)
                                floor.swapChildrenAt(z, thisDepth);

                        return;
                }

                // Set or Get Depth of a Frame
                internal function baseDepth(id:int, set:Boolean, value:int):int {
                        if (id < 0 || id >= frames.length)
                                return 0;
                        if (!set)
                                return floor.getChildIndex(frames[id]);
                        else
                                floor.setChildIndex(frames[id], value);
                        return 0;
                }
	        
                // Turn Off Menu
                internal function boxMenuOff(id:int):void {
                        if (!frames[id].timer_started)
                                return;

			// Stop Menu Timer
                        if (frames[id].timer.running)
                                frames[id].timer.stop();

	                boxMenu(id, false);

                        return;
                }
	        
		// On press, send to Website
	        internal function onPressGoToWWW(event:MouseEvent):void {
                	var request:URLRequest = new URLRequest("http://www.groovy.org");
			
			flash.net.navigateToURL(request, "_blank");
	        };
	        
	         // Callback for On Press for Full Video Playback
	        internal function onPress(event:MouseEvent):void {
			fsPlayer.playVideo(event.target.id,
				frames[event.target.id].plist.image,
				frames[event.target.id].plist.annotation);
	        };	
	        
		//
	        // Search Input Text Form
	        //
	        internal function inputSearch():void {	
	        	// Search Label
	        	searchTextFont.size = 12;
	        	searchTextFont.bold = true;
	        	
	        	searchText.x = 120;
	                searchText.y = 1;
	                searchText.width = 60;
	                searchText.height = 16;	                
	
	                searchText.background = false;
	                searchText.alpha = 1;
	                searchText.backgroundColor = 0xffffff;
	                searchText.borderColor = 0x000000;
	                searchText.textColor = 0x000000;
	                searchText.border = false;
	                searchText.wordWrap = false;
	                searchText.text='Search:';
                        searchText.gridFitType = flash.text.GridFitType.PIXEL;
                        searchText.antiAliasType = flash.text.AntiAliasType.ADVANCED;
                        searchTextFont.font = "Arial";
	                searchText.setTextFormat(searchTextFont);	                
	                
	                searchText.selectable = false;
	        	               
	        	// Form Input Text                	
	                browserInputTextFont.size = 9;
	                browserInputTextFont.bold = false;
                        browserInputTextFont.font = "Arial";
			
	                browserInputText.x = 170;
	                browserInputText.y = 1;
	                browserInputText.width = 125;
	                browserInputText.height = 16;
	                
	
	                browserInputText.background = true;
	                browserInputText.alpha = 1;
	                browserInputText.backgroundColor = 0xffffff;
	                browserInputText.borderColor = 0x666666;
	                browserInputText.textColor = 0x000000;
	                browserInputText.border = true;
	                browserInputText.wordWrap = false;
	                browserInputText.maxChars = 40;
	                browserInputText.text='';
	                browserInputText.setTextFormat(browserInputTextFont);	                
	                
	                browserInputText.addEventListener(flash.events.KeyboardEvent.KEY_DOWN, onSearchInput);
	                browserInputText.selectable = true;
	        }

	        // Show Text on Screen
	        internal function outputVideoText(bg:Boolean, bld:Boolean, color:Number, Obj:TextField, fmtver:TextFormat,
	        	create:int, sz:int, in_x:int, in_y:int, in_w:int, in_h:int, msg:String):void 
	        {
	    		if (Obj != null && create == 0) {
	    			Obj.visible = false;
	    			Obj.text = '';
	    			return;
	    		} else if (Obj != null) {
	    			Obj.text = '';
	    			Obj.visible = true;
	    		} else
	    			return;	                
	
	                fmtver.size = sz;
	                fmtver.bold = bld;
                        fmtver.font = "Arial";
	               
	                Obj.x = in_x;
	                Obj.y = in_y;
	                Obj.width = in_w;
	                Obj.height = in_h;                
	                Obj.background = bg;
	                Obj.backgroundColor = 0x000000;
	                Obj.borderColor = 0x000000;
	                Obj.textColor = color;
	                Obj.border = bg;
	                Obj.wordWrap = true;
                        Obj.gridFitType = flash.text.GridFitType.PIXEL;
                        Obj.antiAliasType = flash.text.AntiAliasType.ADVANCED;

	                Obj.text=msg;
	                Obj.setTextFormat(fmtver);
	                
	                return;
	        }
	        
	        // Show Version on bottom on screen
	        internal function outputVersion():void {	                	
	                verFont.size = 10;
	                verFont.bold = true;
			
	                verText.x = totalwidth-145;
	                verText.y = 1;
	                verText.width = 122;
	                verText.height = 15;
	                
	                verText.background = false;
	                verText.backgroundColor = 0x000000;
	                verText.borderColor = 0x000000;
	                verText.textColor = 0x000000;
	                verText.border = false;
	                verText.wordWrap = false;
                        verText.antiAliasType = flash.text.AntiAliasType.ADVANCED;
                        verText.gridFitType = flash.text.GridFitType.PIXEL;
                        verFont.font = "Arial";
	                verText.selectable = false;

	                verText.text='VW-' + VIDEO_WALL_VERSION + ' (C) 2009';
	                verText.setTextFormat(verFont);
	                
	                verText.addEventListener(flash.events.MouseEvent.CLICK, onPressGoToWWW);
	        }

		// Error with XML Loading
		internal function errorLoad (e:Event):void {
			showError("Failed to load XMLDocument Playlist!!!");
		}
	    
                // Error Output or Help/Usage
		internal function showError(msg:String):void {
		        var output:TextField = new TextField();
		        var fmterror:TextFormat = new TextFormat();
		        
                        if (showHelp > 0) {
		                output.x = 0;
		                output.y = 0;
		                output.width = totalwidth+50;
		                output.height = totalheight*1.5;
                        } else {
		                output.x = (woffset+5);
		                output.y = (hoffset-1);
		                output.width = (totalwidth-(2*(woffset+5)));
		                output.height = imgheight;
                        }
		        
		        fmterror.size = 12;
		        fmterror.bold = true;
                        fmterror.font = "Arial";
		
		        output.background = true;
		        output.backgroundColor = 0xffffff;
		        output.borderColor = 0xffffff;
		        output.textColor = 0x000000;
		        output.border = true;
		        output.wordWrap = true;
			output.autoSize = TextFieldAutoSize.CENTER;
                        output.antiAliasType = flash.text.AntiAliasType.ADVANCED;
                        output.gridFitType = flash.text.GridFitType.PIXEL;
			
                        var vwVersion:String = 'VW Version ' + VIDEO_WALL_VERSION + ' by Chris Kennedy (C) 2009';
		        if (debug > 0) {
                            var vwOptions:String = '?debug=' + debug + '&pl=' + pl + 
		                    '&scale=' + scale + "&hnum=" + hnum + "&wnum=" + wnum + 
		                    "&woffset=" + woffset + "&hoffset=" + hoffset + 
		                    '\n&hideversion=' + hideversion + 
		                    "&start_track=" + start_track + "&end_track=" + end_track +
		                    "&imgheight=" + imgheight + "&imgwidth=" + imgwidth + "\n&menuon=" +
		                    menuon + "&fsheight=" + fsheight + "&fswidth=" + fswidth +
		                    "&search_filter=" + search_filter + "&menuheight=" + menuheight + '\n' +
		                    "&smooth=" + zInc + "&menucolor=" + menuColor + "&menutextcolor=" + menuTextColor +
                                    "&otw=" + otw.toString() + "\n&playsecs=" + playsecs + "&qLevel=" + qLevel + 
                                    "&browserOn=" + browserOn.toString() + '&fps=' + mFps + '&playAll=' + playAll + '\n' +
                                    '&useAmf=' + useAmf.toString() + '&amfService=' + amfService + '\n' +
                                    '&amfGateway=' + amfGateway + '&amfClass=' + amfClass;

                            var vwSize:String = totalwidth + 'x' + (totalheight + 18);
                            if (showHelp > 0) {
                                var vwHowTo:String = '' +
                                        'pl:(String) XML file location, needs to be on the same server, currently ' + pl + '\n' +
                                        'scale:(Number) scale of fully zoomed frame, currently ' + scale + '\n' +
                                        'wnum:(int) horizontal frames of video, currently ' + wnum + '\n' +
                                        'hnum:(int) vertical frames of video, currently ' + hnum + '\n' +
                                        'woffset:(int) horizontal spacing of frames, currently ' + woffset + '\n' +
                                        'hoffset:(int) vertical spacing of frames, currently ' + hoffset + '\n' +
                                        'fps:(int) frames per second of flash file, currently ' + mFps + '\n' +
                                        'hideversion:(int) if set to 1 will hide version output\n' +
                                        'start_track:(int) first video in XML file to load into frames\n' +
                                        'end_track:(int) last video in XML file to load into frames\n' +
                                        'imgwidth:(int) width of video in frames, scales to this size\n' +
                                        'imgheight:(int) height of video in frames, scales to this size\n' +
                                        'menuon:(int) if set to 1, uses menus below videos, 1 by default\n' +
                                        'fswidth:(int) playback width of videos, defaults to fit into Wall size\n' +
                                        'fsheight:(int) playback height of videos, defaults to fit into Wall size\n' +
                                        'search_filter:(String) default search filter for Wall from XML file, default is .*\n' +
                                        'menuheight:(int) height of menus, currently' + menuheight + '\n' +
                                        'smooth:(Number) scaling smoothness when Zooming, defaults to .10\n' +
                                        'menucolor:(Hex) color of menu background, currently ' + menuColor + '\n' +
                                        'menutextcolor:(Hex) color of text on menus, currently ' + menuTextColor + '\n' +
                                        'otw:(Boolean) if set to true, frames not in focus will move off the wall with zoom' + '\n' +
                                        'playsecs:(int) seconds to play videos before restarting' + '\n' +
                                        'qLevel:(String) normal flash levels of quality, best, high, medium, low' + '\n' +
                                        'browserOn:(Boolean) if set to true, default, shows bottom browser/search bar' + '\n' +
                                        'playAll:(int) if set to 1, default, plays video chosen and rest on wall till done' + '\n' +
                                        'useAmf:(Boolean) If set, will use AMF to get Video Data, need remote gateway setup' + '\n' +
                                        'amfGateway:(String) AMF Gateway URL to use, use AmfPHP or Adobe BlazeDS' + '\n' +
                                        'amfService:(String) AMF Service to use, defaults to vw.getResults' + '\n' +
                                        'amfClass:(String) AMF Class to use, defaults to vw' + '\n' +
                                '\n';
		                output.text= ' ' + msg + vwHowTo + '\n Flash Plugin Version: ' + flash.system.Capabilities.version + 
                                        '\n ' + vwVersion + '\n\n Wall Size: ' + vwSize + '\n\n' + vwOptions;
                            } else
		                output.text= ' ' + msg + '\n Flash Plugin Version: ' + flash.system.Capabilities.version + 
                                        '\n ' + vwVersion + '\n Wall Size: ' + vwSize + '\n\n' + vwOptions;

		    	} else {
		            output.text= ' ' + msg + '\n' +  ' ' + vwVersion;
		    	}
		       	output.setTextFormat(fmterror);
		       	
		       	addChild(output);
		       	return;
		}		

                internal function vwTrace(msg:String):void {
                        if (debug > 0)
                                trace(msg);
                }
	}
}

