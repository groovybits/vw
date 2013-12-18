package vw
{
        import flash.events.*;
        import flash.net.URLLoader;
        import flash.net.URLRequest;

        // Remote Object AMF Channel Method
        import mx.rpc.remoting.RemoteObject;
        import mx.rpc.events.ResultEvent;
        import mx.rpc.events.FaultEvent;
        import mx.messaging.Channel;
        import mx.messaging.channels.AMFChannel;
        import mx.messaging.ChannelSet;
        import mx.collections.*;

        // Adobe internal AMF Actionscript Bug workaround...
        import mx.core.mx_internal;
        import mx.messaging.config.LoaderConfig;
        import mx.logging.targets.TraceTarget;
        import mx.messaging.messages.*;
        import mx.messaging.config.ConfigMap;
        import mx.collections.ArrayList;
        import mx.collections.ArrayCollection;
        import mx.utils.ObjectProxy;
        import flash.net.registerClassAlias;

	public class Data extends EventDispatcher
	{		
		public var debug:int = 0;
		public var url:String = "";
		public var parameters:Object;

		// Events
		public static var GOTRESULTS:String = "gotresults";
		public var failed:Boolean = false;

		// XML File
                public var pl:String = 'thumbs.xml';

                // XML Stuff
                private var xmlLoader:URLLoader = new URLLoader();
                private var xmlRequest:URLRequest;
                private var xmlData:XML;

		// XML Return Results
                public var trackList:XMLList;

                /**
                * AMF Settings
                */
                public var useAmf:Boolean = false;
                public var amfGateway:String = "/amfphp/gateway.php";
                public var amfService:String = "vw.getResults";
                public var amfClass:String = "vw";

                // AMF Remote Object
                private var ro:RemoteObject;
                private var debugSetup:TraceTarget = new TraceTarget();

                public var amf_with_xml:Boolean = false;
		public var search_filter:String = ".*";

		// Return Results
                public var amfResults:Object;

                public function Data(doDebug:int, useAmf:Boolean = false) {
			super();

			debug = doDebug;

			// Data Base Objects
                        // Workaround Adobe bug in AMF in pure ActionScript Code
                        if (useAmf) {
                                // Setup MX Trace Verbose debugging output
                                if (debug > 0)
                                        debugSetup.level = 0;

                                registerClassAlias("flex.messaging.messages.CommandMessage",
                                        CommandMessage);
                                registerClassAlias("flex.messaging.messages.RemotingMessage",
                                        RemotingMessage);
                                registerClassAlias("flex.messaging.messages.AcknowledgeMessage",
                                        AcknowledgeMessage);
                                registerClassAlias("flex.messaging.messages.ErrorMessage",
                                        ErrorMessage);
                                registerClassAlias("DSC",
                                        CommandMessageExt);
                                registerClassAlias("DSK",
                                        AcknowledgeMessageExt);
                                registerClassAlias("flex.messaging.io.ArrayList",
                                        ArrayList);
                                registerClassAlias("flex.messaging.config.ConfigMap",
                                        ConfigMap);
                                registerClassAlias("flex.messaging.io.ArrayCollection",
                                        ArrayCollection);
                                registerClassAlias("flex.messaging.io.ObjectProxy",
                                        ObjectProxy);
                                registerClassAlias("flex.messaging.messages.HTTPMessage",
                                        HTTPRequestMessage);
                                registerClassAlias("flex.messaging.messages.SOAPMessage",
                                        SOAPMessage);
                                registerClassAlias("flex.messaging.messages.AsyncMessage",
                                        AsyncMessage);
                                registerClassAlias("DSA",
                                        AsyncMessageExt);
                                registerClassAlias("flex.messaging.messages.MessagePerformanceInfo",
                                        MessagePerformanceInfo);
                        }
                }

		/** 
		* Do search of database
		*/
		public function doSearch(keyword:String):void {
			search_filter = keyword;

			if (useAmf) {
				searchAmfRemote();
			} else {
				readXML(pl);
			}
		}

                /**
                * Load Data from XML File
                */
                private function readXML(fname:String):void {
                        // Load XML Playlist File
                        try {
                                // XML Events to listen for
                                xmlLoader.addEventListener(Event.COMPLETE, xmlLoaded);
                                xmlLoader.addEventListener(IOErrorEvent.IO_ERROR, errorLoad);

                                // Load XML Playlist
                                xmlRequest = new URLRequest(fname);
                                xmlLoader.load(xmlRequest);
                        } catch (error:Error) {
                                vwTrace(error.name);

				// Signal We failed at getting the Results
				failed = true;
				dispatchEvent(new Event(Data.GOTRESULTS));
                        }
                        vwTrace("XML Config File Loading...");
                        return;
                }

		/** 
		* Failure
		*/
		private function errorLoad(e:Event):void {
			// Signal We failed at getting the Results
			failed = true;
			dispatchEvent(new Event(Data.GOTRESULTS));
		}

                /**
                * XML File Loaded OK
                */
                private function xmlLoaded(e:Event):void {
                        vwTrace("XML File " + pl + " Loaded OK.");

                        xmlLoader.removeEventListener(Event.COMPLETE, xmlLoaded);
                        xmlLoader.removeEventListener(IOErrorEvent.IO_ERROR, errorLoad);

                        // Process XML Data
                        processXML(e.target.data);

			// Signal We Got the Results
			dispatchEvent(new Event(Data.GOTRESULTS));

                        return;
                }

                /**
                * Process String into XML Data
                */
                private function processXML(db:String):void {
                        // XML Data
                        xmlData = new XML(db);

                        // Get tracklist from XML File
                        xmlData.ignoreWhite = true;
                        trackList = xmlData.children();
                }

                /**
                * Amf Remote Object
                */
                private function searchAmfRemote():void {
                        LoaderConfig.mx_internal::_url = url;
                        LoaderConfig.mx_internal::_parameters = parameters;

                        ro = new RemoteObject(amfClass);
                        ro.source = 'vw';
                        ro.channelSet = new ChannelSet();
                        ro.channelSet.addChannel(new AMFChannel("my-amf", amfGateway));

                        ro.addEventListener(ResultEvent.RESULT, amfResultHandler);
                        ro.addEventListener(FaultEvent.FAULT, amfFaultHandler);

                        vwTrace("Running amfService: " +
                                amfService.slice(3) + " with RemoteObject: " + ro.toString());

                        ro.getOperation(amfService.slice(3)).send(search_filter);
                }

                /**
                * Amf Remote Object Fault Handler
                */
                private function amfFaultHandler (event:FaultEvent) : void {
                        //this will fire if the method throws an error
                        trace("amfFaultHandler: " + event.fault.faultString);
                        trace("Fault String: " + event.toString());
                        trace("Fault Code: " + event.fault.faultCode);
                        trace("Fault Message: " + event.fault.message);
                        trace("Fault Detail: " + event.fault.faultDetail);

                        ro.removeEventListener(ResultEvent.RESULT, amfResultHandler);
                        ro.removeEventListener(FaultEvent.FAULT, amfFaultHandler);

                        // Revert to XML
                        useAmf = false;
                        readXML(pl);
                }

                /**
                * Amf Remote Object Result Handler
                */
                private function amfResultHandler (event:ResultEvent):void {
                        //this will fire when a result comes back from the method
                        vwTrace("Got Amf Message: " + event.message.timestamp);

                        ro.removeEventListener(ResultEvent.RESULT, amfResultHandler);
                        ro.removeEventListener(FaultEvent.FAULT, amfFaultHandler);

                        switch(amfService) {
                                case 'vw.getVideoDB':
                                        var rows:ArrayCollection =
                                                event.result as ArrayCollection;
                                        amfResults = rows.source;
                                        break;
                                case 'vw.getMysqlResults':
                                case 'vw.getResults':
                                        amfResults = event.result;
                                        break;
                                case 'vw.getXML':
                                        processXML(String(event.result));
                                        amf_with_xml = true;
                                        break;
                                default:
                                        amfResults = event.result;
                                        break;
                        }

                        // New AMF Database of Videos loaded.
                        vwTrace("New AMF Video Database with " + search_filter + " as filter.");

			// Signal We Got the Results
			dispatchEvent(new Event(Data.GOTRESULTS));
                }

                private function vwTrace(msg:String):void {
                        if (debug > 0)
                                trace(msg);
                }
	}
}
