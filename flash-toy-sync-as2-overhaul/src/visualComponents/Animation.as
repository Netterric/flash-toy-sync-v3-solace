/**
 * This file have been transpiled from Actionscript 3.0 to 2.0, any changes made to this file will be overwritten once it is transpiled again
 */

import visualComponents.*
import core.JSON

import core.CustomEvent;
import core.TranspiledMovieClipFunctions;
import core.TranspiledStage;
import core.TranspiledMovieClip;
import core.TranspiledSWFLoaderFunctions;
import states.AnimationSizeStates;

/**
 * ...
 * @author notSafeForDev
 */
class visualComponents.Animation {
	
	public var loadedEvent : CustomEvent;
	public var loadErrorEvent : CustomEvent;
	
	private var container : TranspiledMovieClip;
	
	public function Animation(_container : MovieClip) {
		container = TranspiledMovieClip.create(_container, "animationContainer");
		
		loadedEvent = new CustomEvent();
		loadErrorEvent = new CustomEvent();
		
		AnimationSizeStates.listen(this, onAnimationSizeStatesChange, [AnimationSizeStates.width, AnimationSizeStates.height]);
	}
	
	public function browse(_scope , _onSelectHandler : Function) : Void {
		TranspiledSWFLoaderFunctions.browse(_scope, _onSelectHandler, "swf (in animations folder)");
	}
	
	/**
	 * Load an animation found in the animations folder
	 * @param	_name	The name of the swf file, including the .swf extension
	 */
	public function load(_name : String) : Void {
		var path : String = "animations/" + _name;
		
		TranspiledSWFLoaderFunctions.load(path, container.sourceMovieClip, this, onLoaded, onLoadError);
	}
	
	/**
	 * Load a standalone animation found in the same folder as the application
	 * @param	_name	The name of the swf file, including the .swf extension
	 */
	public function loadStandalone(_name : String) : Void {
		var path : String = _name;
		
		TranspiledSWFLoaderFunctions.load(path, container.sourceMovieClip, this, onLoaded, onLoadError);
	}
	
	private function onLoaded(_swf : MovieClip, _stageWidth : Number, _stageHeight : Number, _frameRate : Number) : Void {
		loadedEvent.emit(_swf, _stageWidth, _stageHeight, _frameRate);
	}
	
	private function onLoadError(_error : String) : Void {
		loadErrorEvent.emit(_error);
	}
	
	private function onAnimationSizeStatesChange() : Void {
		var width : Number = AnimationSizeStates.width.value;
		var height : Number = AnimationSizeStates.height.value;
		var scale : Number = getTargetScale();
		
		container.x = (TranspiledStage.stageWidth - (width * scale)) / 2;
		container.y = (TranspiledStage.stageHeight - (height * scale)) / 2;
		container.scaleX = scale;
		container.scaleY = scale;
	}
	
	private function getTargetScale() : Number {
		var scaleX : Number = TranspiledStage.stageWidth / AnimationSizeStates.width.value;
		var scaleY : Number = TranspiledStage.stageHeight / AnimationSizeStates.height.value;
		
		return Math.min(scaleX, scaleY);
	}
}