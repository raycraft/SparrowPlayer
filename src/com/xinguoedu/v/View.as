package com.xinguoedu.v
{
	import com.xinguoedu.evt.view.ViewEvt;
	import com.xinguoedu.m.Model;
	import com.xinguoedu.utils.StageReference;
	import com.xinguoedu.v.base.BaseComponent;
	import com.xinguoedu.v.component.AdComponent;
	import com.xinguoedu.v.component.BottomHintComponent;
	import com.xinguoedu.v.component.ControlBarComponent;
	import com.xinguoedu.v.component.DisplayComponent;
	import com.xinguoedu.v.component.ErrorComponent;
	import com.xinguoedu.v.component.LogoComponent;
	import com.xinguoedu.v.component.QrcodeComponent;
	import com.xinguoedu.v.component.StateHintComponent;
	import com.xinguoedu.v.component.SubtitleComponent;
	import com.xinguoedu.v.component.VideoAdsComponent;
	import com.xinguoedu.v.component.VideoComponent;
	import com.xinguoedu.v.component.logger.LoggerComponent;
	import com.xinguoedu.v.component.settings.SettingsComponent;
	
	import flash.display.Sprite;
	import flash.events.EventDispatcher;
	
	public class View extends EventDispatcher
	{
		private var _m:Model;
		
		/** 界面显示组件的父容器 **/
		private var _root:Sprite; 
		
		private var _videoComp:BaseComponent;
		
		private var _displayComp:BaseComponent;
		
		private var _controlbarComp:BaseComponent;
		
		private var _subtitleComp:BaseComponent;
		
		private var _logoComp:BaseComponent;	
		
		private var _adComp:BaseComponent;
		
		private var _qrcodeComp:BaseComponent;
		
		private var _stateHintComp:BaseComponent;
		
		private var _errorHintComp:BaseComponent;
		
		private var _videoadsComp:VideoAdsComponent;
		
		private var _bottomHintComp:BaseComponent;
		
		private var _settingsComp:BaseComponent;
		
		private var _loggerComp:BaseComponent;
		
		public function View(m:Model)
		{
			super();
			
			this._m = m;		
		}		
		
		public function setup():void
		{
			_root = new Sprite();
			//_root.mouseEnabled = false; 设置为false会导致自定义右键菜单无法显示
			StageReference.stage.addChildAt(_root, 0);
			
			
			_videoComp = new VideoComponent(_m);
			_root.addChild(_videoComp);
			
			_displayComp = new DisplayComponent(_m);
			_root.addChild(_displayComp);
			
			if(_m.subtitleVO.url)
			{
				_subtitleComp = new SubtitleComponent(_m);
				_root.addChild(_subtitleComp);
			}
			
			_bottomHintComp = new BottomHintComponent(_m);
			_root.addChild(_bottomHintComp);
			
			_controlbarComp = new ControlBarComponent(_m);
			_root.addChild(_controlbarComp);		
			
			_logoComp = new LogoComponent(_m);
			_root.addChild(_logoComp);
			
			_adComp = new AdComponent(_m);
			_root.addChild(_adComp);
			
			_qrcodeComp = new QrcodeComponent(_m);
			_root.addChild(_qrcodeComp);
			
			_stateHintComp = new StateHintComponent(_m);
			_root.addChild(_stateHintComp);
			
			_errorHintComp = new ErrorComponent(_m);
			_root.addChild(_errorHintComp);
			
			if(_m.videoadVO.enabled)
			{
				_videoadsComp = new VideoAdsComponent(_m);			
				_root.addChild(_videoadsComp);
			}					
			
			_settingsComp = new SettingsComponent(_m);
			_root.addChild(_settingsComp);
			
			_loggerComp = new LoggerComponent(_m);
			_root.addChild(_loggerComp);	
			
			var rightclickmenu:RightClickMenu = new RightClickMenu(_m, _root);
			rightclickmenu.initializeMenu();
		
			addListeners();
		}
		
		/**
		 * 播放视频广告 
		 * 
		 */		
		public function playVideoAds():void
		{
			_videoadsComp.play();
		}
		
		private function addListeners():void
		{
			_controlbarComp.addEventListener(ViewEvt.PAUSE, function(evt:ViewEvt):void{ dispatchEvent(evt); });
			_controlbarComp.addEventListener(ViewEvt.PLAY, function(evt:ViewEvt):void{ dispatchEvent(evt); });
			_controlbarComp.addEventListener(ViewEvt.MOUSEDOWN_TO_SEEK, function(evt:ViewEvt):void{ dispatchEvent(evt); });
			_controlbarComp.addEventListener(ViewEvt.SEEK, function(evt:ViewEvt):void{ dispatchEvent(evt); });
			_controlbarComp.addEventListener(ViewEvt.FULLSCREEN, function(evt:ViewEvt):void{ dispatchEvent(evt); });
			_controlbarComp.addEventListener(ViewEvt.NORMAL, function(evt:ViewEvt):void{ dispatchEvent(evt); });
			_controlbarComp.addEventListener(ViewEvt.VOLUME, function(evt:ViewEvt):void{ dispatchEvent(evt); });
			_controlbarComp.addEventListener(ViewEvt.MUTE, function(evt:ViewEvt):void{ dispatchEvent(evt); });
			_controlbarComp.addEventListener(ViewEvt.KEYDOWN_SPACE, function(evt:ViewEvt):void{ dispatchEvent(evt); });
			_controlbarComp.addEventListener(ViewEvt.PLAY_NEXT, function(evt:ViewEvt):void{ dispatchEvent(evt); });
			_controlbarComp.addEventListener(ViewEvt.DRAG_TIMESLIDER_MOVING, function(evt:ViewEvt):void{ dispatchEvent(evt); });
			
			_videoComp.addEventListener(ViewEvt.PAUSE, function(evt:ViewEvt):void{ dispatchEvent(evt); });
			_videoComp.addEventListener(ViewEvt.PLAY, function(evt:ViewEvt):void{ dispatchEvent(evt); });
			_videoComp.addEventListener(ViewEvt.NORMAL, function(evt:ViewEvt):void{ dispatchEvent(evt); });
			_videoComp.addEventListener(ViewEvt.FULLSCREEN, function(evt:ViewEvt):void{ dispatchEvent(evt); });
			
			if(_m.videoadVO.enabled)
			{
				_videoadsComp.addEventListener(ViewEvt.VIDEOADS_COMPLETE, videoadsCompleteHandler);
			}		
		}
		
		private function videoadsCompleteHandler(evt:ViewEvt):void
		{
			_videoadsComp.removeEventListener(ViewEvt.VIDEOADS_COMPLETE, videoadsCompleteHandler);
			_root.removeChild(_videoadsComp);
			_videoadsComp = null;
			
			dispatchEvent(evt);
		}
	}
}