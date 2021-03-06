package com.xinguoedu.m
{
	import com.adobe.images.PNGEncoder;
	import com.hurlant.util.Base64;
	import com.xinguoedu.consts.ConnectionStatus;
	import com.xinguoedu.consts.DebugConst;
	import com.xinguoedu.consts.PlayerState;
	import com.xinguoedu.consts.StreamStatus;
	import com.xinguoedu.evt.EventBus;
	import com.xinguoedu.evt.PlayerStateEvt;
	import com.xinguoedu.evt.debug.DebugEvt;
	import com.xinguoedu.evt.js.JSEvt;
	import com.xinguoedu.evt.media.MediaEvt;
	import com.xinguoedu.m.js.JSAPI;
	import com.xinguoedu.m.media.BaseMedia;
	import com.xinguoedu.m.media.HLSMedia;
	import com.xinguoedu.m.media.HttpEMedia;
	import com.xinguoedu.m.media.HttpMedia;
	import com.xinguoedu.m.media.RTMPMedia;
	import com.xinguoedu.m.media.httpm.HttpMMedia;
	import com.xinguoedu.m.vo.AdVO;
	import com.xinguoedu.m.vo.ErrorHintVO;
	import com.xinguoedu.m.vo.FeedbackVO;
	import com.xinguoedu.m.vo.LogoVO;
	import com.xinguoedu.m.vo.MediaVO;
	import com.xinguoedu.m.vo.NodeVO;
	import com.xinguoedu.m.vo.QrcodeVO;
	import com.xinguoedu.m.vo.SubtitleVO;
	import com.xinguoedu.m.vo.VideoAdVO;
	import com.xinguoedu.utils.Configger;
	import com.xinguoedu.utils.Logger;
	import com.xinguoedu.utils.MultifunctionalLoader;
	import com.xinguoedu.utils.StageReference;
	import com.xinguoedu.utils.Strings;
	
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.display.StageDisplayState;
	import flash.utils.ByteArray;
	
	public class Model
	{		
		public var playerconfig:Object;		
		public var js:JSAPI = JSAPI.getInstance();
		
		public var media:BaseMedia;		
		private var _mediaMap:Object = {};		
		private var _mediaVO:MediaVO = new MediaVO();
		private var _logoVO:LogoVO = new LogoVO();
		private var _errorHintVO:ErrorHintVO = new ErrorHintVO();
		private var _adVO:AdVO = new AdVO();
		private var _videoadVO:VideoAdVO = new VideoAdVO();
		private var _qrcodeVO:QrcodeVO = new QrcodeVO();
		private var _nodeVO:NodeVO = new NodeVO();
		private var _feedbackVO:FeedbackVO = new FeedbackVO();
		private var _subtitleVO:SubtitleVO = new SubtitleVO();
		/** 播放器皮肤 **/
		private var _skin:MovieClip;
		private var _state:String = PlayerState.IDLE;
		private var _isMute:Boolean = false;
		
		protected var _srtTimeArray:Array;
		protected var _srtTimeArrayLength:int = 0;
		protected var _defaultLangTextArray:Array;
		protected var _secondLangTextArray:Array;
		
		public function Model()
		{
			setMedia();
		}		
		
		private function setMedia():void
		{
			_mediaMap[MediaType.HTTP] = new HttpMedia(MediaType.HTTP);			
			_mediaMap[MediaType.HLS] = new HLSMedia(MediaType.HLS);
			_mediaMap[MediaType.HTTPE] = new HttpEMedia(MediaType.HTTPE);		
			_mediaMap[MediaType.HTTPM] = new HttpMMedia(MediaType.HTTPM);
			_mediaMap[MediaType.RTMP] = new RTMPMedia(MediaType.RTMP);
		}
		
		private function addListeners():void
		{
			media.addEventListener(MediaEvt.MEDIA_INFO, mediaInfoHandler);
			media.addEventListener(MediaEvt.MEDIA_STATE, mediaStateHandler);
			js.addEventListener(JSEvt.SCREENSHOT, screenshotHandler);
			js.addEventListener(JSEvt.QRCODE, qrcodeHandler);
			js.addEventListener(JSEvt.PAUSE, pauseHandler);
			js.addEventListener(JSEvt.PLAY, playHandler);
		}
		
		private function mediaInfoHandler(evt:MediaEvt):void
		{
			developermode && (Logger.info('Model', evt.data));
			switch(evt.data)
			{
				case StreamStatus.START_LOAD_MEDIA:
					EventBus.getInstance().dispatchEvent(new MediaEvt(MediaEvt.LOAD_MEDIA));	
					break;
				case StreamStatus.LOAD_MEDIA_IOERROR:
					sendErrorAndDebugMsg(DebugConst.LOAD_MEDIA_IOERROR + ":" + mediaVO.url);
					break;
				case StreamStatus.STREAM_NOT_FOUND:
					sendErrorAndDebugMsg(DebugConst.STREAM_NOT_FOUND + ":" + mediaVO.url);
					break;
				case StreamStatus.PLAY_START:
				case StreamStatus.BUFFERING:
					state = PlayerState.BUFFERING;
					break;
				/*case StreamStatus.PAUSE_NOTIFY: //视频缓冲中在某些情况下也会触发，所以不再处理这个状态
					state = PlayerState.PAUSED;
					break;*/
				case StreamStatus.UNPAUSE_NOTIFY:	//unpause和bufferfull可认为是一致的			
				case StreamStatus.BUFFER_FULL:
					state = PlayerState.PLAYING;
					EventBus.getInstance().dispatchEvent(new MediaEvt(MediaEvt.MEDIA_BUFFER_FULL));
					break;
				case StreamStatus.PLAY_COMPLETE:
					state = PlayerState.IDLE; 
					EventBus.getInstance().dispatchEvent(new MediaEvt(MediaEvt.MEDIA_COMPLETE));	
					break;
				case StreamStatus.PLAY_NEARLY_COMPLETE:
					EventBus.getInstance().dispatchEvent(new MediaEvt(MediaEvt.MEDIA_NEARLY_COMPLETE));
					break;
				case StreamStatus.NOT_NEARLY_COMPLETE:
					EventBus.getInstance().dispatchEvent(new MediaEvt(MediaEvt.NOT_NEARLY_COMPLETE));
					break;
				case ConnectionStatus.CLOSED:
					sendErrorAndDebugMsg(DebugConst.CONNECTION_CLOSED + ":" + mediaVO.url);
					break;
				case ConnectionStatus.REJECTED:
					sendErrorAndDebugMsg(DebugConst.CONNECTION_REJECTED + ":" + mediaVO.url);
					break;
				case ConnectionStatus.SECURITY_ERROR:
					sendErrorAndDebugMsg(DebugConst.CONNECTION_SECURITY_ERROR + ":" + mediaVO.url);
					break;
				case ConnectionStatus.FAILED:
					sendErrorAndDebugMsg(DebugConst.CONNECTION_FAILED + ":" + mediaVO.url);
				default:
					break;
			}
		}
		
		/** 派发错误事件和调试信息事件 **/
		private function sendErrorAndDebugMsg(debugMsg:String):void
		{
			EventBus.getInstance().dispatchEvent(new MediaEvt(MediaEvt.MEDIA_ERROR));
			EventBus.getInstance().dispatchEvent(new DebugEvt(DebugEvt.DEBUG, debugMsg));
		}
		
		/** 流状态发生变化 **/
		private function mediaStateHandler(evt:MediaEvt):void
		{
			state = evt.data;
		}
		
		/** 截图处理 **/
		private function screenshotHandler(evt:JSEvt):void
		{
			media.pause();
			var bitmapData:BitmapData;
			var screenshotByteArray:ByteArray;
			try
			{
				bitmapData = new BitmapData(evt.data.width, evt.data.height ,true, 0);
				bitmapData.draw(media.display);
				
				screenshotByteArray = PNGEncoder.encode(bitmapData);
				var imgstr:String = "data:image/png;base64," + (Base64.encodeByteArray(screenshotByteArray));
				js.showScreenshot(imgstr);
			}
			catch(err:Error)
			{
				developermode && (Logger.error("Model", "截图出错",  err.toString()));
				
				if(bitmapData != null)
				{
					bitmapData.dispose(); //释放内存
					bitmapData = null;
				}
				
				if(screenshotByteArray != null)
				{
					screenshotByteArray.clear(); //释放内存
					screenshotByteArray = null;
				}
				
				media.play();
			}
		}
		
		private function qrcodeHandler(evt:JSEvt):void
		{
			EventBus.getInstance().dispatchEvent(evt);
		}
		
		private function pauseHandler(evt:JSEvt):void
		{
			media.pause();
		}
		
		private function playHandler(evt:JSEvt):void
		{
			media.play();
		}
										   
		
		/**
		 * 根据媒体类型 激活相应的媒体模块 
		 * @param mediaType 媒体类型
		 * 
		 */		
		public function setActiveMedia():void
		{
			if(!hasMedia(_mediaVO.type))
				_mediaVO.type = MediaType.HTTP;
			
			if(_subtitleVO.url)
			{
				var loader:MultifunctionalLoader = new MultifunctionalLoader(false);
				loader.registerFunctions(loadSrtComplete);
				loader.load(_subtitleVO.url);
			}
			
			media = _mediaMap[_mediaVO.type];	
			media.vol = volume;
			addListeners();			
			media.init(_mediaVO);
		}
		
		protected function loadSrtComplete(data:String):void
		{
			var srtTimeArr:Array = [];
			var srtTextArr:Array = [];
			
			var arr:Array = data.split('\r\n');
			var len:int = arr.length;
			for(var i:int = 0; i < len; i++)
			{
				if(int(arr[i]) || !arr[i]) //过滤掉字幕中的数字序列和空字符串
				{
					continue;
				}
				
				if(arr[i].indexOf('-->') != -1)
				{
					var temp:Array = arr[i].split('-->');
					srtTimeArr.push(Strings.string2Number(temp[0]), Strings.string2Number(temp[1]));
				}
				else
				{
					srtTextArr.push(arr[i]);
				}
			}
			
			if(_subtitleVO.isBilingual)
			{
				_srtTimeArray = [];
				_defaultLangTextArray = [];
				_secondLangTextArray  =[];
				
				var timeArrayLen:int = srtTimeArr.length;
				for(var j:int = 0; j <= timeArrayLen-4; j+=4)
				{
					_srtTimeArray.push(srtTimeArr[j], srtTimeArr[j+1]);
				}
				
				var textArrayLen:int = srtTextArr.length;
				for(var k:int = 0; k < textArrayLen; k++)
				{
					(k % 2 == 0) ? _defaultLangTextArray.push(srtTextArr[k]) : _secondLangTextArray.push(srtTextArr[k]); 
				}
				
				//释放内存
				srtTextArr = [];
				srtTextArr = [];
			}
			else
			{
				_srtTimeArray = srtTimeArr;
				_defaultLangTextArray = srtTextArr;
			}
			
			_srtTimeArrayLength = _srtTimeArray.length;
		}
		
		private function hasMedia(mediaType:String):Boolean
		{
			return (_mediaMap[mediaType] is BaseMedia);
		}
			
		public function get mediaVO():MediaVO
		{
			return _mediaVO;
		}

		public function get logoVO():LogoVO
		{
			return _logoVO;
		}
		
		public function get errorHintVO():ErrorHintVO
		{
			return _errorHintVO;
		}	
		
		public function set skin(mc:MovieClip):void
		{
			_skin = mc;
		}

		public function get skin():MovieClip
		{
			return _skin;
		}

		public function get state():String
		{
			return _state;
		}
		
		public function get adVO():AdVO
		{
			return _adVO;
		}
		
		public function set volume(vol:int):void
		{
			if(playerconfig.volume != vol)
			{
				playerconfig.volume = vol;
				Configger.saveCookie("volume", vol);
			}
		}
		
		public function get volume():int
		{
			return playerconfig.volume;
		}

		public function set state(value:String):void
		{
			if(_state != value)
			{
				_state = value;
				EventBus.getInstance().dispatchEvent(new PlayerStateEvt(PlayerStateEvt.PLAYER_STATE_CHANGE));
			}			
		}		

		public function get videoadVO():VideoAdVO
		{
			return _videoadVO;
		}

		public function set videoadVO(value:VideoAdVO):void
		{
			_videoadVO = value;
		}
		
		/**
		 * 是否开启开发者模式 
		 * @return 
		 * 
		 */		
		public function get developermode():Boolean
		{
			return playerconfig.developermode;
		}
		
		/**
		 * 版本号 
		 * @return 
		 * 
		 */		
		public function get version():String
		{
			return playerconfig.version;
		}
		
		
		/**
		 * 在normal screen的情况下，计时器时间到后是否自动隐藏controlbar 
		 * @return 
		 * 
		 */		
		public function get autohide():Boolean
		{
			if(int(playerconfig.autohide))
				return true;
			else
				return	false;
		}
		
		/**
		 * 是否全屏 
		 * @return 
		 * 
		 */		
		public function get isFullScreen():Boolean
		{
			return StageReference.stage.displayState == StageDisplayState.FULL_SCREEN;
		}
		
		/**
		 * 视频是否播放完 
		 * @return 
		 * 
		 */		
		public function get isMediaComplete():Boolean
		{
			return media.isComplete;
		}

		/**
		 * 视频是否处在静音状态 
		 * @return 
		 * 
		 */		
		public function get isMute():Boolean
		{
			return _isMute;
		}

		public function set isMute(value:Boolean):void
		{
			_isMute = value;
			EventBus.getInstance().dispatchEvent(new MediaEvt(MediaEvt.MEDIA_MUTE));
		}

		public function get qrcodeVO():QrcodeVO
		{
			return _qrcodeVO;
		}

		public function get nodeVO():NodeVO
		{
			return _nodeVO;
		}

		public function get feedbackVO():FeedbackVO
		{
			return _feedbackVO;
		}

		public function get subtitleVO():SubtitleVO
		{
			return _subtitleVO;
		}
		
		/**
		 * srt字幕时间数组 
		 * @return 
		 * 
		 */		
		public function get srtTimeArray():Array
		{
			return _srtTimeArray;
		}
		 
		/**
		 * 将srt字幕时间数组的长度缓存，避免重复遍历数组  
		 * @return 字幕时间数组的长度 
		 * 
		 */		
		public function get srtTimeArrayLength():int
		{
			return _srtTimeArrayLength;
		}
		
		/**
		 * 存储默认字幕文字信息的数组 
		 * @return 
		 * 
		 */		
		public function get defaultLangTextArray():Array
		{
			return _defaultLangTextArray;
		}
		
		/**
		 * 双语字幕时存储第二字幕文字信息的数组 
		 * @return 
		 * 
		 */		
		public function get secondLangTextArray():Array
		{
			return _secondLangTextArray;
		}
	}
}