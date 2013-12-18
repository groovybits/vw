package vw
{
	import flash.display.Sprite;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Rectangle;

	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetStreamPlayOptions;
        import flash.net.NetStreamPlayTransitions;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
        import flash.filters.BevelFilter;
        import flash.filters.BitmapFilter;
        import flash.filters.BitmapFilterQuality;
        import flash.filters.BitmapFilterType;
	import flash.text.TextField;
        import flash.text.TextFieldAutoSize;
        import flash.text.TextFieldType;
        import flash.text.TextFormat;
	import flash.utils.Timer;

	import vw.CustomClient;

	public class VWPlayer extends Sprite
	{
                public var full_screen_started:Boolean = false;
	        public var full_screen_lock:Boolean = false;
	        public var full_screen_on:Boolean = false;
		public var nextPlay:Boolean = false;

	        private var full_screen_seek:Boolean = false;
                private var full_screen_seek_count:Number = 0;
	        private var fs_pause:Boolean = false;
	 	private var fsc_on:Boolean = false;

	 	// FS Video Controls	 	
                private var playerBar:Sprite = new Sprite();
	 	private var stopButton:Sprite = new Sprite();
	 	private var playButton:Sprite = new Sprite();	 
	 	private var seekForwardButton:Sprite = new Sprite();
	 	private var seekBackwardButton:Sprite = new Sprite();
	 	private var fsButton:Sprite = new Sprite();
	 	
	 	// Button Images
	 	private var playBtn:Loader = new Loader();
	 	private var pauseBtn:Loader = new Loader();
	 	private var stopBtn:Loader = new Loader();
	 	private var ffwdBtn:Loader = new Loader();
	 	private var rwdBtn:Loader = new Loader();
	 	private var FSffwdBtn:Loader = new Loader();
	 	private var FSrwdBtn:Loader = new Loader();
	 	private var fsBtn:Loader = new Loader();
	 		  		 	
	 	// Full Screen
	 	private var fullVideoTime:TextField = new TextField();
	 	private var fullVideoTimeFont:TextFormat = new TextFormat();
	 	private var fullVideoName:TextField = new TextField();
	 	private var fullVideoNameFont:TextFormat = new TextFormat();
	 	private var fnc:NetConnection;
		public var fns:NetStream;
		private var fsv:Video;
		private var fsnd:SoundTransform = new SoundTransform(1, 0);
                private var nspo:NetStreamPlayOptions = new NetStreamPlayOptions();
                private var screenRectangle:Rectangle = new Rectangle(0, 0, 0, 0);
		private var timer:Timer = new Timer(250, 0);
		
		// Scrub Bar
		private var scrubber:Sprite = new Sprite();
		private var track:Sprite = new Sprite();
		private var mScrub:Sprite = new Sprite();
		private var scrubbingOn:Boolean = false;
		private var scrubberBounds:Rectangle =  new Rectangle(0, 0, 0, 0);

		// Volume Bar
		private var volume:Sprite = new Sprite();
		private var vtrack:Sprite = new Sprite();
		private var mVolume:Sprite = new Sprite();
		private var volumeOn:Boolean = false;
		private var volumeBounds:Rectangle =  new Rectangle(0, 0, 0, 0);

                // Filters
                private var bFilter:BitmapFilter = 
			new BevelFilter(1, 90, 0xd0d0d0, .8, 0x555555, .8, 
                        1, 1, 10, BitmapFilterQuality.HIGH, BitmapFilterType.INNER, false);
                private var bFilterKnob:BitmapFilter = 
			new BevelFilter(2, 80, 0x999999, .8, 0x222222, .8, 
                        3, 3, 10, BitmapFilterQuality.HIGH, BitmapFilterType.INNER, false);

		// Adjust Screen size automatically
		private var autoAdjust:Boolean = false;

		// What we are playing
		private var oldVideoURL:String = "";
		public var videoURL:String = "";
		private var videoAnnotation:String = "";

		// Status Information
   		public var pctLoaded:int = 0;

		// User changable variables
		public var id:int = -1;
		public var totalwidth:int;
		public var totalheight:int;
		public var debug:int = 0;
		public var fswidth:int = 0;
		public var fsheight:int = 0;
		public var bufferTime:Number = 5;
		// Color
		public var backgroundColor:uint = 0x000000;
		public var backgroundFontColor:uint = 0xFFFFFF;
		public var backgroundAlpha:Number = 1;
		// Position/Layout
		public var showTitle:Boolean = true;

		public function VWPlayer(mywidth:int, myheight:int, mydebug:int)
		{
			super();			

			debug = mydebug;
			totalwidth = mywidth;
			totalheight = myheight;
		}

		/**
                * Load Images.
                */
        	private function loadImages():void {       		
	 		var urlReq:URLRequest = new URLRequest();
	 		
	 		// Play Button	 		
	 		urlReq.url = "play.png";	 		
	 		playBtn.load(urlReq);	
	 		
	 		// Pause Button	 		
	 		urlReq.url = "pause.png";
	 		pauseBtn.load(urlReq);
	 		
	 		// Stop Button
	 		urlReq.url = "stop.png";
	 		stopBtn.load(urlReq);
	 		
	 		// Rewind Button
	 		urlReq.url = "rewind.png";
	 		FSrwdBtn.load(urlReq);
	 		
	 		// Forward Button
	 		urlReq.url = "forward.png";
	 		FSffwdBtn.load(urlReq);
	 		
	 		// Full Screen Button
	 		urlReq.url = "fullscreen.png";
	 		fsBtn.load(urlReq);
	 		
                        vwTrace("Images Loading...");
	 		return;
        	}

		public function fsInit():void {
			// Calculate full playback height/width to fit
                        if (fswidth == 0 || fsheight == 0) {
				autoAdjust = true;
                                fswidth = (totalwidth);
                                fsheight = fswidth * (3/4);

                                if (fsheight > totalheight)
                                        fsheight = totalheight;
                        }

			loadImages();

			timer.addEventListener(flash.events.TimerEvent.TIMER, fsTimer);
			addChild(fullVideoName);

		        fsv = new Video(fswidth, fsheight);
                        fsv.visible = false;
                        fullVideoName.visible = false;
			addChild(fsv);

			startVideo();

			fsctl(fsheight, false, false);
		}

		private function fsctl(myheight:int, show:Boolean, playmode:Boolean):void {

                        // Full Screen Controls Creation
                        fullScreenControls(myheight);

                        // Add full screen controls to Display
                        showFullScreenControls(show, playmode);

                        // Hide Full Screen Control Bar at first
                       	playerBarMode(show, myheight);

                        // Add Control Bar to Main Frame
                        addFullScreenControls();
		}

                /** 
                * Stop Full Playback Video.
                */
                public function stopVideo():void {
                        vwTrace("Stop Full Stream Called");
                        if (!full_screen_lock) {
                                vwTrace("Stop Full Stream Locked, returning!!!")
                                return;
                        }

			timer.stop();

		       	// Full Screen Mode, revert back to NORMAL
                        if (stage.displayState != StageDisplayState.NORMAL) {
		       	        stage.displayState = StageDisplayState.NORMAL;

				fsv.height = fsheight;
				fsv.width = fswidth;
				fsv.smoothing = true;

		       	        removeEventListener(flash.events.MouseEvent.MOUSE_DOWN, showFSC);
                                removeEventListener(FullScreenEvent.FULL_SCREEN, fsEvent); 
			}
		        
		        // Hide Video/Controls, show Frames/Floor/Browser
			visible = false;
                        playerBar.visible = false;
		        fsv.visible = false;		        

		        // Stop and Clear Video
                        if (full_screen_on) {
                                vwTrace("Clearing All Full Screen Streams");

                                nspo.oldStreamName = videoURL;
                                nspo.streamName = '';
                                nspo.transition = NetStreamPlayTransitions.STOP;
                                fns.play2(nspo);
                        }

                        // Hide Full Screen Control Bar
			fsctl(fsheight, false, false);

	                // Remove Display of Video Name
	                outputVideoText(false, false, 0, fullVideoName, 
	                	fullVideoNameFont, 0, 0, 0, 0, 0, 0, '', 0);					                   
	               	// Remove Timing Display
	               	outputVideoText(false, false, 0, fullVideoTime, 
	                	fullVideoTimeFont, 0, 0, 0, 0, 0, 0, '', 0);

                        // Remove Scrubber
			mScrub.removeEventListener(MouseEvent.MOUSE_DOWN, onThumbDown);
			mScrub.removeEventListener(MouseEvent.MOUSE_UP, onThumbUp);
			removeEventListener(MouseEvent.MOUSE_UP, onThumbUp);
			playerBar.removeEventListener(MouseEvent.MOUSE_UP, onThumbUp);      
                        playerBar.removeEventListener(flash.events.MouseEvent.ROLL_OUT, onThumbUp);

                        // Remove Volume
			mVolume.removeEventListener(MouseEvent.MOUSE_DOWN, onVThumbDown);
			mVolume.removeEventListener(MouseEvent.MOUSE_UP, onThumbUp);

	       	        fsc_on = false;

                        // Set Full Playback to OFF
                        // Unlock Full Screen Mode
		        full_screen_lock = false;
		        full_screen_on = false;
                        full_screen_seek = false;
                        full_screen_seek_count = 0;
			nextPlay = false;
			id = -1;

			return;       				  
                    }

                    /** 
                    * Start Full Video Playback.
                    */
                    public function playVideo(myid:int, vURL:String, vAno:String):void {
		            if (vURL == "" || !full_screen_started) 
				return;

			    id = myid;
			    oldVideoURL = videoURL;
			    videoURL = vURL;
			    videoAnnotation = vAno;

                            // Full Playback Mode
                            full_screen_lock = true;

                            // Display Video Timing
                            outputVideoText(false, false, 0x000000, fullVideoTime,
                                fullVideoTimeFont, 1, 9, 185, 7, 120, 14,  
				"00:00:00 / 00:00:00 0%", 1);

                            // Display Video Name
                            outputVideoText(true, true, backgroundFontColor, fullVideoName,
                                    fullVideoNameFont, 1, 10, 0, 0, totalwidth, totalheight,
                                    ' ' + videoAnnotation, backgroundAlpha);

                            // Hide Full Screen Control Bar
			    pctLoaded = 0;
                            mScrub.x = 0;
                            mVolume.x = (fsnd.volume / 1.0 * vtrack.width);
                            pauseBtn.visible = true;
                            playBtn.visible = false;

			    visible = true;
			    fsv.visible = false;

			    timer.start();

                            // Scrub Bar Events
                            mScrub.addEventListener(MouseEvent.MOUSE_DOWN, onThumbDown);
                            mScrub.addEventListener(MouseEvent.MOUSE_UP, onThumbUp);
                            addEventListener(MouseEvent.MOUSE_UP, onThumbUp);
                            playerBar.addEventListener(MouseEvent.MOUSE_UP, onThumbUp);
                            playerBar.addEventListener(flash.events.MouseEvent.ROLL_OUT, onThumbUp);

                            // Volume Bar
                            mVolume.addEventListener(MouseEvent.MOUSE_DOWN, onVThumbDown);
                            mVolume.addEventListener(MouseEvent.MOUSE_UP, onThumbUp);

                            // Pause Off
                            fs_pause = false;

                            // Play Video Full Screen
                            nspo.streamName = videoURL;
                            nspo.transition = NetStreamPlayTransitions.RESET;
                            fns.play2(nspo);

                            vwTrace("(" + id + "). Full Stream Play: " + videoURL);
                    }

		    /**
                    * Event Handler for Video Meta Data Resutls
                    */
                    private function videoMetaDataHandler(event:Event):void {
				var wasFull:Boolean = false;

                        	// Full Screen Mode, revert back to NORMAL
                        	if (autoAdjust && stage.displayState == StageDisplayState.FULL_SCREEN) {
					if (screenRectangle.width != fns.client.width || 
							screenRectangle.height != fns.client.height) 
					{
                                		stage.displayState = StageDisplayState.NORMAL;

					} else
						wasFull = true;
                        	}

				// Adjust screen size if set to auto adjust
				if (autoAdjust && fns.client.height > 0) {
					fswidth = totalwidth;
					fsheight = fswidth * (fns.client.height/fns.client.width);
				}

		                fsv.x = (totalwidth-fswidth)/2;
				if (showTitle)
		                	fsv.y = 14;
				else
					fsv.y = 0;

				if (fsheight > (totalheight-(fsv.y+4))) {
					fsheight = (totalheight-(fsv.y+4));
				}
				fsv.y = (totalheight-fsheight);

		                fsv.width = fswidth;
			        fsv.height = fsheight;
				fsv.smoothing = true;

				fullVideoTime.x = 185;
				fsctl(fsheight, true, fs_pause);

				vwTrace("Video is " + fns.client.width + "x" + fns.client.height +
					" scaled to " + fswidth + "x" + fsheight + 
					" at " + fsv.x + ":" + fsv.y + " position");

				// Make full screen visible
                                if (!fsv.visible || !visible) {
					visible = true;
				        fsv.visible=true;
		                        full_screen_on = true;
                                }

				if (wasFull) {
                                	fsv.width = fns.client.width;
					fsv.height = fns.client.height;
                                	fsv.smoothing = false;

                                	screenRectangle.x = fsv.x;
                                	screenRectangle.y = fsv.y;
                                	screenRectangle.width = fsv.width;
                                	screenRectangle.height = fsv.height;

                                	// Apply Full Screen Rectangle
                                	stage.fullScreenSourceRect = screenRectangle;

                                	//if (stage.displayState != StageDisplayState.FULL_SCREEN)
                                	//	stage.displayState = StageDisplayState.FULL_SCREEN;

					fsctl(fsv.height-(playerBar.height-2), false, fs_pause);
				}
		    }

                    /** 
                    * Full Playback NetStatus Handler.
                    */
                    private function netFullStatusHandler(event:NetStatusEvent):void {
                            switch (event.info.code) {
                                case "NetConnection.Connect.Success":
					fns = new NetStream(fnc);
					fns.client = new CustomClient(debug);
					fns.client.addEventListener(CustomClient.METADATA, videoMetaDataHandler);
		                        	
		                        fns.bufferTime = bufferTime;
		                        fns.soundTransform = fsnd;

		                        fns.addEventListener(NetStatusEvent.NET_STATUS, netFullStatusHandler);
		                        fns.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncFullErrorHandler);
		                        		                        
		                        fsv.attachNetStream(fns);

		                        // Video Settings
		                        fsv.smoothing = true;		                        
		                        fsv.x = (totalwidth-fswidth)/2;
					if (showTitle)
		                        	fsv.y = 14;
					else 
						fsv.y = 0;
		                        fsv.width = fswidth;
			        	fsv.height = fsheight;

                                        // Full Stream Playback initialized
                                        full_screen_started = true;

					vwTrace("VWFrame full screen initialized");

					break;
				case "NetConnection.Connect.Closed":
					vwTrace("Full Net Connect Close");
                                        full_screen_seek = false;
                                        full_screen_on = false;
					nextPlay = false;
					id = -1;
					break;
				case "NetStream.Play.StreamNotFound":
			                vwTrace("Full Stream not found: " + videoURL);
              				stopVideo();	                    
			                break;
                                case "NetStream.Play.FileStructureInvalid":
			                vwTrace("Full Screen File Structure Invalid/Stop");
                                      	stopVideo();
                                        break;
                                case "NetStream.Play.Stop":
                                        vwTrace("Full Stream Stop: " + videoURL);                                      
					vwTrace("bufferLength=" + fns.bufferLength + " bufferTime=" + fns.bufferTime);
                                        if (!full_screen_on)
                                                break;

                                        // Next Video Playback
                                        if (nextPlay && videoURL != '') {
                                                appendVideo();
						full_screen_seek = false;
						full_screen_seek_count = 0;
						nextPlay = false;
						id++;
                                        } else
                                       	        stopVideo();
                                        break;
                                case "NetStream.Buffer.Flush" :
					vwTrace("Full Stream Buffer Flush");
					vwTrace("bufferLength=" + fns.bufferLength + " bufferTime=" + fns.bufferTime);
					break;
				case "NetStream.Buffer.Full" :
					vwTrace("Full Stream Buffer Full");
					vwTrace("bufferLength=" + fns.bufferLength + " bufferTime=" + fns.bufferTime);
                                        full_screen_seek = false;
					break;
				case "NetStream.Buffer.Empty" :
					vwTrace("Full Stream Buffer Empty");
                                        if (nextPlay &&  videoURL != '') {
						vwTrace("Buffer Empty, nextPlay TRUE.");
						vwTrace("bufferLength=" + fns.bufferLength + " bufferTime=" + fns.bufferTime);
						if (fns.bufferLength < .25) {
							appendVideo();
							nextPlay = false;
							id++;
						}
                                        } else if (full_screen_on && fns != null && fns.bufferTime < 30) {
		                                fns.bufferTime += 5;
						bufferTime = fns.bufferTime;
						vwTrace("Full Playback: Increased bufferTime to " + bufferTime + " seconds.");
					}
					break;
                                case "NetStream.Play.Start":
                                	vwTrace("Full Stream Play Start");
		                        break;
                                case "NetStream.Seek.Notify":
                                        // Seek is Done
                                        if (full_screen_on && full_screen_seek && fns != null && fnc != null) {
                                	        vwTrace("Full Stream Notify at: " + fns.time);
                                                if (fns.time == 0 || fns.time == fns.client.duration && 
                                                        (full_screen_seek_count > (fns.time-2) && 
                                                                full_screen_seek_count < (fns.time+2))) 
                                                {
                                                        full_screen_seek = false;
                                                }
                                        } else
                                	        vwTrace("Full Stream Notify");
                                        break;
                                case "NetStream.Seek.InvalidTime":
                                	vwTrace("Full Stream Invalid Time: " + fns.time);
                                        break;
                                default:     
                                	vwTrace("Full Stream Unknown NetStream Message: " + event.info.code);
					break;
                       	}
                }

		/** 
		* Setup Append Video
		*/
		public function setupAppend(nxtId:int, nxtVideo:String, nxtAnnot:String):void {
			if ((id+1 != nxtId) || nextPlay || !full_screen_on || !full_screen_lock)
				return;

			nextPlay = true;
                        oldVideoURL = videoURL;
                        videoURL = nxtVideo;
                        videoAnnotation = nxtAnnot;
		}

                /** 
                * Append a new full playback video.
                */
                private function appendVideo():void {
			if (!nextPlay || !full_screen_on || !full_screen_lock)
				return;

                        vwTrace("Appending (" + id + "): " + videoURL);
                        vwTrace("bufferLength=" + fns.bufferLength + " bufferTime=" + fns.bufferTime);

                        // Old Video
                        nspo.oldStreamName =  oldVideoURL;

                        // Advance to Next Video
                        nspo.streamName = videoURL;

                        // Append to Playlist
                        nspo.transition = NetStreamPlayTransitions.APPEND;

                        // Set Video Name Display Text
                        fullVideoName.text = ' ' + videoAnnotation;
                        fullVideoName.setTextFormat(fullVideoNameFont);

                        // Play Full Video
		        fns.play2(nspo);
                }
                
                /**
                * Make full screen control bar visible or invisible.
                * 
                * @param mode visibility of components of bar.
                * @param playmode playing or paused, if false pause button is shown.
                */
                private function showFullScreenControls(mode:Boolean, playmode:Boolean):void {
                        playerBar.visible = mode;        
                        pauseBtn.visible = !playmode;        
                        playBtn.visible = playmode;        

                        return;
                }

                /**
                * Mouse down on Scrubber Bar.
                */
		private function onThumbDown(event:MouseEvent):void {							
    			scrubbingOn=true;   				

			scrubberBounds.width = track.width;
   			mScrub.startDrag(false, scrubberBounds);
		}
		
                /**
                * Mouse up on Scrubber Bar and Volume Bar.
                */
		private function onThumbUp(event:MouseEvent):void {
			scrubbingOn=false;
			mScrub.stopDrag();   
                        volumeOn=false;
                        mVolume.stopDrag();  
		}					

                /**
                * Mouse down on Volume Bar.
                */
                private function onVThumbDown(event:MouseEvent):void {
                        volumeOn=true;      

                        volumeBounds.width = vtrack.width;
                        mVolume.startDrag(false, volumeBounds);
                }

		/** 
                * Hide/Show Full Screen Controls
                */
                private function showFSC(event:MouseEvent):void
		{
                        if (event.stageY >= fsv.height-(playerBar.height+1))
                                return;

                        // Show Player Bar
                        if (fsc_on) {
                                // Off
                                vwTrace("showFSC: Turning off bar");
			        fsc_on = false;

				fsctl(fsv.height, false, fs_pause);
                        } else {
                                // On
                                vwTrace("showFSC: Turning on bar");
			        fsc_on = true;		

				fsctl(fsv.height-(playerBar.height-2), true, fs_pause);
                        }
                        return;
		}
                
                /** 
                * Full Screen Mode Handler.
                */
                private function fsHandler(event:MouseEvent):void
		{
			if (stage.displayState == StageDisplayState.NORMAL) {
				fsv.height = fns.client.height;
				fsv.width = fns.client.width;
				fsv.smoothing = false;

                        	screenRectangle.x = fsv.x;
                        	screenRectangle.y = fsv.y;
                        	screenRectangle.width = fsv.width;
                        	screenRectangle.height = fsv.height;

                        	// Apply Full Screen Rectangle
				stage.fullScreenSourceRect = screenRectangle;

				stage.displayState = StageDisplayState.FULL_SCREEN;

				fsc_on = false;

				fsctl(fsv.height-(playerBar.height-2), false, fs_pause);

				stage.addEventListener(flash.events.MouseEvent.MOUSE_DOWN, showFSC);
                                stage.addEventListener(FullScreenEvent.FULL_SCREEN, fsEvent); 
			} else {
				fsv.height = fsheight;
				fsv.width = fswidth;
				fsv.smoothing = true;

				stage.displayState = StageDisplayState.NORMAL;

				fsc_on = false;
				fsctl(fsv.height, true, fs_pause);

				stage.removeEventListener(flash.events.MouseEvent.MOUSE_DOWN, showFSC);
                                stage.removeEventListener(FullScreenEvent.FULL_SCREEN, fsEvent); 
			}
		}

                /**
                * Detect ESC Key on exit of Full Screen Mode.
                */
                private function fsEvent(event:FullScreenEvent):void {    
                        vwTrace("fullscreen event activated=" + event.fullScreen.toString()); 
                        if (!event.fullScreen) {
				fsv.height = fsheight;
				fsv.width = fswidth;
				fsv.smoothing = true;

				fsc_on = false;
				fsctl(fsv.height, true, fs_pause);

				stage.removeEventListener(flash.events.MouseEvent.MOUSE_DOWN, showFSC);
                                stage.removeEventListener(FullScreenEvent.FULL_SCREEN, fsEvent); 
                        }
                }
                
                /**
                * Make Player Bar visible/invisible.
                * 
                * @param mode make player bar visible or not.
                * @param height vertical position to place player bar on screen.
                */
                private function playerBarMode(mode:Boolean, myheight:int):void {
                        playerBar.y = myheight + fsv.y;
                        playerBar.visible = mode;
                }

                /**
                * Fast Forward Button Callback.
                */
                private function fsSeekForward(event:MouseEvent):void {
                        if (!full_screen_on)
                                return;

                	fns.pause();

			vwTrace("Seeking from " + fns.time + " to " + (fns.time+5));
                	fns.seek((fns.time+5));
                	
                	fns.resume();
	               	pauseBtn.visible = true;
	               	playBtn.visible = false;
	               	fs_pause = false;
                };

                /**
                * Rewind Button Callback.
                */
                private function fsSeekBackward(event:MouseEvent):void {
                        if (!full_screen_on)
                                return;
                	fns.pause();
                	if (fns.time >= 5) {
				vwTrace("Seeking from " + fns.time + " to " + (fns.time+5));
                		fns.seek((fns.time-5));
                	} else {
                		fns.seek(0);              	
			}

                	fns.resume();
	               	pauseBtn.visible = true;
	               	playBtn.visible = false;
                	fs_pause = false;               	
                };

                /**
                * Pause/Play Button Callback.
                */
                private function fsPausePlay(event:MouseEvent):void {
                        if (!full_screen_on)
                                return;
                	if (fs_pause) {
                		// pause Button
		               	pauseBtn.visible = true;
		               	playBtn.visible = false;
		               	fs_pause = false;
		        } else {
		        	// Play Button
		               	playBtn.visible = true;
		               	pauseBtn.visible = false;
		               	fs_pause = true;
		        }
                	fns.togglePause();
                };

                /**
                * Stop Button Callback.
                */
                private function fsStopPlay(event:MouseEvent):void {              	
                	stopVideo();
                };

		/** 
		* Error callbacks that shouldn't happen.
		*/
	        private function securityFullErrorHandler(event:SecurityErrorEvent):void {
			vwTrace("securityErrorHandler: \n" + event + "\n playing: \n" + videoURL);
		}

                private function asyncFullErrorHandler(event:AsyncErrorEvent):void {
                        vwTrace("aysncFullErrorHandler: " + videoURL);                      
                }
                
		/**
		* Full Video Playback
		*/	
		private function startVideo():void {
			fnc = new NetConnection();

			// Connect RTSP NULL
			fnc.addEventListener(NetStatusEvent.NET_STATUS, netFullStatusHandler);
			fnc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityFullErrorHandler);
	                fnc.connect(null);
		        		        
		        return;
	 	}

                private function fullScreenControls(myheight:int):void {
                        var hoff:int = myheight+fsv.y;
                        var woff:int = ((totalwidth-fswidth)/2)+5;
                	
                        // Main Player Bar Background
                	playerBar.graphics.clear();
			playerBar.graphics.lineStyle(1, 0xffffff, 1, true, "normal", "round", "round", 0);        
    			playerBar.graphics.beginFill(0xd0d0d0, 1);
 			playerBar.graphics.drawRect(0, 0, fsv.width, 18);
 			playerBar.graphics.endFill();
 			playerBar.x = woff-5;
 			playerBar.y = hoff;

                	// Play/Pause Button
                	playButton.graphics.clear();
			playButton.graphics.lineStyle(1, 0xffffff, 0, true, "normal", "square", "miter", 1);        
    			playButton.graphics.beginFill(0x00ff00, 0);
 			playButton.graphics.drawRect(0, 2, 15, 15);
 			playButton.graphics.endFill();
                        playButton.addEventListener(flash.events.MouseEvent.CLICK, fsPausePlay);
                        playButton.buttonMode = true;
                        playButton.useHandCursor = true;
                        try {
	                        pauseBtn.x = 0;
	                        pauseBtn.y = 2;
	                        pauseBtn.visible = true;
	                        playBtn.x = 0;
	                        playBtn.y = 2;
	                        playBtn.visible = false;
                        } catch (error:Error) {
				// Ignore
			}
                        
                        // Stop Button
                        stopButton.graphics.clear();
			stopButton.graphics.lineStyle(1, 0xffffff, 0, true, "normal", "square", "miter", 1);        
    			stopButton.graphics.beginFill(0xff0000, 0);
 			stopButton.graphics.drawRect(18, 2, 15, 15);
 			stopButton.graphics.endFill();
                        stopButton.addEventListener(flash.events.MouseEvent.CLICK, fsStopPlay);
                        stopButton.buttonMode = true;
                        stopButton.useHandCursor = true;
                        try {
                        	stopBtn.x = 18;
                        	stopBtn.y = 2;
                        } catch (error:Error) {
				// Ignore
			}
                        // Seek Forward Button
                        seekForwardButton.graphics.clear();
			seekForwardButton.graphics.lineStyle(1, 0xffffff, 0, true, "normal", "square", "miter", 1);        
    			seekForwardButton.graphics.beginFill(0x0000ff, 0);
 			seekForwardButton.graphics.drawRect(70, 2, 15, 15);
 			seekForwardButton.graphics.endFill();
                        seekForwardButton.addEventListener(flash.events.MouseEvent.CLICK, fsSeekForward);
                        seekForwardButton.buttonMode = true;
                        seekForwardButton.useHandCursor = true;
                        try {
                        	FSffwdBtn.x = 70;
                        	FSffwdBtn.y = 2;
                        } catch (error:Error) {
				// Ignore
			}
                        // Seek Backward Button
                        seekBackwardButton.graphics.clear();
			seekBackwardButton.graphics.lineStyle(1, 0xffffff, 0, true, "normal", "square", "miter", 1);        
    			seekBackwardButton.graphics.beginFill(0x0000ff, 0);
 			seekBackwardButton.graphics.drawRect(50, 2, 15, 15);
 			seekBackwardButton.graphics.endFill();
                        seekBackwardButton.addEventListener(flash.events.MouseEvent.CLICK, fsSeekBackward);
                        seekBackwardButton.buttonMode = true;
                        seekBackwardButton.useHandCursor = true;
                        try {
                        	FSrwdBtn.x = 50;
                        	FSrwdBtn.y = 2;	
                        } catch (error:Error) {
				// Ignore
			}
                        // Full Screen Mode Button
                        fsButton.graphics.clear();
			fsButton.graphics.lineStyle(1, 0xffffff, 0, true, "normal", "square", "miter", 1);        
    			fsButton.graphics.beginFill(0x0000ff, 0);
 			fsButton.graphics.drawRect(fsv.width-18, 2, 15, 15);
 			fsButton.graphics.endFill();
                        fsButton.addEventListener(flash.events.MouseEvent.CLICK, fsHandler);
                        fsButton.buttonMode = true;
                        fsButton.useHandCursor = true;
                        try {
                        	fsBtn.x = fsv.width-18;
                        	fsBtn.y = 2;
                        } catch (error:Error) {
				// Ignore
			}
			
			// Scrub Bar
		        scrubBar(90, 7);

			// Volume Bar
		        volumeBar(90, 16);

                        playerBar.filters = [bFilter];

                        return;
                }
			
                private function addFullScreenControls():void {
                        // Main Player Bar Background
                        addChild(playerBar);

                	// Play Button
                        playerBar.addChild(pauseBtn);
                        playerBar.addChild(playBtn);
                        playerBar.addChild(playButton);
                        // Stop Button
                        playerBar.addChild(stopBtn);
                        playerBar.addChild(stopButton);
                        // Seek Forward 
                        playerBar.addChild(FSffwdBtn);
                        playerBar.addChild(seekForwardButton);
                        // Seek Backward
                        playerBar.addChild(FSrwdBtn);
                        playerBar.addChild(seekBackwardButton);
                        // Full Screen
                        playerBar.addChild(fsBtn);
                        playerBar.addChild(fsButton);
                        
                        // Timing Information
		        playerBar.addChild(fullVideoTime);		                        

                        // View Scrubber
			playerBar.addChild(scrubber);
			scrubber.addChild(track);
			scrubber.addChild(mScrub);

                        // View Scrubber
			playerBar.addChild(volume);
			volume.addChild(vtrack);
			volume.addChild(mVolume);

                        return;	
                }

                // Scrub Bar
		private function scrubBar(my_x:int, my_y:int):void {  									
			scrubber.x = my_x;
			scrubber.y = my_y;
			
			track.graphics.clear();
			track.graphics.lineStyle(1, 0x000000, 1, true, "normal", "round", "round", 0);        
			track.graphics.beginFill(0x333333);
			track.graphics.drawRect(0, -2.5, fsv.width-130, 2);
			track.graphics.endFill();

			mScrub.graphics.clear();			
			mScrub.graphics.lineStyle(1, 0x000000, 1, true, "normal", "round", "round", 0);        
			mScrub.graphics.beginFill(0xaaaaaa);
			mScrub.graphics.drawRoundRect(-3, -7, 10, 10, 6);
			mScrub.graphics.endFill();			

                        mScrub.filters = [bFilterKnob];
			
			return;
		}

                // Volume Bar
                private function volumeBar(my_x:int, my_y:int):void {
                        volume.x = my_x;
                        volume.y = my_y;

                        vtrack.graphics.clear();
                        vtrack.graphics.lineStyle(1, 0x000000, 1, true, "normal", "round", "round", 0);
                        vtrack.graphics.beginFill(0x333333);
                        vtrack.graphics.drawRect(0, -2.5, 80, 2);
                        vtrack.graphics.endFill();

                        mVolume.graphics.clear();
                        mVolume.graphics.lineStyle(1, 0x000000, 1, true, "normal", "round", "round", 0);
                        mVolume.graphics.beginFill(0xaaaaaa);
                        mVolume.graphics.drawRoundRect(-3, -4, 7, 7, 3);
                        mVolume.graphics.endFill();

                        mVolume.filters = [bFilterKnob];

                        return;
                }

	        // Show Text on Screen
	        private function outputVideoText(bg:Boolean, bld:Boolean, color:Number, Obj:TextField, fmtver:TextFormat,
	        	create:int, sz:int, in_x:int, in_y:int, in_w:int, in_h:int, msg:String, transparent:Number):void 
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
	               
	                Obj.alpha = transparent;
	                Obj.x = in_x;
	                Obj.y = in_y;
	                Obj.width = in_w;
	                Obj.height = in_h;                
	                Obj.background = bg;
	                Obj.backgroundColor = backgroundColor;
	                Obj.borderColor = backgroundColor;
	                Obj.textColor = color;
	                Obj.border = bg;
	                Obj.wordWrap = true;
                        Obj.gridFitType = flash.text.GridFitType.PIXEL;
                        Obj.antiAliasType = flash.text.AntiAliasType.ADVANCED;

	                Obj.text=msg;
	                Obj.setTextFormat(fmtver);
	                
	                return;
	        }

		private function detailedStatus():String {
			var detailedString:String;

   			var kbLoaded:int = Math.round(fns.bytesLoaded/1000);
   			var kbTotal:int = Math.round(fns.bytesTotal/1000);
   			pctLoaded = Math.round(kbLoaded/kbTotal*100);
   
			// Loaded
   			//detailedString = pctLoaded + "% (" + kbLoaded + "kb/" + kbTotal + "kb)";

   			//var pct:Number = Math.min(Math.round(fns.bufferLength/fns.bufferTime*100), 100);
  
			// Buffer Status
   			//detailedString += " " + pct + "%";

			//trackstat.width = (pctLoaded*(track.width/100));

			detailedString = pctLoaded + "%";

			return detailedString;
		}

                private function convertTime(ts:Number, do_ms:Boolean):String {
                	var min:int;
                	var sec:int;
                	var hour:int;
                	var smin:String = new String();
                	var ssec:String = new String();
                	var shour:String = new String();
                	var msec:String = new String();
                	
                	hour = (ts/60)/60;
                	if (ts > (60*60))
                		min = (ts%60)/60
                	else
                		min = ts/60;
                	sec = (ts%60);
                	
                	if (sec < 10)
                		ssec = "0" + sec.toString();
                	else
                		ssec = sec.toString();
                	if (min < 10)
                		smin = "0" + min.toString();
                	else
                		smin = min.toString();
                	if (hour < 10)
                		shour = "0" + hour.toString();
                	else
                		shour = hour.toString();
                		
                	msec = ts.toString();
                	msec = msec.replace(/^.*\./, "");
                	               	
                	if (msec.length == 1)
                		msec = "00" + msec;
                	else if (msec.length == 2)
                		msec = "0" + msec;
                		
                	if (!do_ms)
                		msec = '';
                	else
                		msec = "." + msec;
                		
                	var retstr:String = shour + ":" + smin + ":" + ssec + 
	                	msec;
	                
	                return retstr;
                }

		private function fsTimer(e:TimerEvent):void {
                        // In Full Screen Mode
                        if (full_screen_lock && full_screen_on) {
                                var totalDur:String = convertTime(fns.client.duration, false);
                                var curTS:String = convertTime(fns.time, false);
                                var dur:Number = fns.client.duration;

                                // Duration
                                if (dur == 0)
                                        dur = (60*30); // Guess

                                // Scrub Bar update
                                if(dur > 0) {
                                        var ns:Number = (dur * mScrub.x / track.width);
                                        if(scrubbingOn && full_screen_on) {
                                                if ((ns <= dur) && (ns >= 0))
                                                {
                                                        vwTrace("Seek to: " + ns);
                                                        full_screen_seek = true;
                                                        full_screen_seek_count = ns;
                                                        fns.seek(ns);
                                                }
                                        } else {
                                                if (full_screen_seek &&
                                                        (full_screen_seek_count > fns.time || full_screen_seek_count < (fns.time-1)))
                                                {
                                                        fns.seek(full_screen_seek_count);
                                                        mScrub.x = (full_screen_seek_count / dur * track.width);
                                                } else {
                                                        full_screen_seek = false;
                                                        full_screen_seek_count = 0;
                                                        mScrub.x = (fns.time / dur * track.width);
                                                }
                                        }
                                }

				// Volume Bar update
                                if(volumeOn && full_screen_on) {
                                        var nv:Number = (1.0 * mVolume.x / vtrack.width);
                                        if (nv < .01)
                                                nv = 0;
                                        if (nv > .99)
                                                nv = 1.00;
                                        if (nv <= 1.0 && nv >= 0)
                                        {
                                                vwTrace("Volume set to: " + nv);
                                                fsnd.volume = nv;
                                                fns.soundTransform = fsnd;
                                        }
                                } else {
                                        var np:Number = (fns.soundTransform.volume / 1.0 * vtrack.width);
                                        if (np < .01)
                                                np = 0;
                                        mVolume.x = np;
                                }

                                // Timing Display
                                fullVideoTime.text = curTS + ' / ' + totalDur + " " + detailedStatus();
                                fullVideoTime.setTextFormat(fullVideoTimeFont);
			}
		}

 		private function vwTrace(msg:String):void {
                        if (debug > 0)
                                trace(msg);
                }
	}
}
