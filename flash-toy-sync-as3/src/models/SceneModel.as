package models {
	
	import core.CustomEvent;
	import core.TPDisplayObject;
	import core.TPMovieClip;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Scene;
	import states.AnimationInfoStates;
	import states.EditorStates;
	import utils.ArrayUtil;
	import utils.HierarchyUtil;
	import utils.MathUtil;
	import utils.SaveDataUtil;
	
	/**
	 * ...
	 * @author notSafeForDev
	 */
	public class SceneModel {
		
		private static var enteredScene : SceneModel;
		
		/** Status for when nothing unusual happened during update */
		public static var UPDATE_STATUS_NORMAL : String = "UPDATE_STATUS_NORMAL";
		/** Status for when the scene was exited on it's own, such as when the user clicks a button and the animation changes frames */
		public static var UPDATE_STATUS_EXIT : String = "UPDATE_STATUS_EXIT";
		/** Status for when the scene looped from it's first frame */
		public static var UPDATE_STATUS_LOOP_START : String = "UPDATE_STATUS_LOOP_START";
		/** Status for when the scene looped from a frame after the first */
		public static var UPDATE_STATUS_LOOP_MIDDLE : String = "UPDATE_STATUS_LOOP_MIDDLE";
		/** Status for when all the children that are part of the scene is stopped without being force stopped */
		public static var UPDATE_STATUS_COMPLETELY_STOPPED : String = "UPDATE_STATUS_COMPLETELY_STOPPED";
		
		// The following events are mainly intended to be utilized by plugins
		
		/** Emitted when the frame have updated, along with the update status */
		public var frameUpdateEvent : CustomEvent;
		/** Emitted when the scene splits, along with the first half */
		public var splitEvent : CustomEvent;
		/** Emitted when the scene have been merged with another scene, along with the other scene it was merged with */
		public var mergeEvent : CustomEvent;
		
		/** Can be set to allow the scene to be merged, or remove when it otherwise would be kept */
		public var isTemporary : Boolean = false;
		
		private var plugins : ScenePluginsModel;
		
		protected var path : Vector.<String> = null;
		
		protected var startFrames : Vector.<Number> = null;
		protected var endFrames : Vector.<Number> = null;
		/** The total number of frames inside each child movieClip, not necessarily the total frames in the scene */
		protected var totalTimelineFrames : Vector.<Number> = null;
		protected var firstStopFrames : Vector.<Number> = null;
		protected var haveDeterminedEndFrames : Vector.<Boolean> = null;
		protected var endsAtLastFrame : Boolean = false;
		
		/** The last frames for each child that the animation was on, while not force stopped */
		private var lastPlayingFrames : Vector.<Number> = null;
		/**
		 * History for the last played frames, it starts updating from when we enter the scene,
		 * and keeps updating as long as no frames are repeated
		 */
		private var playingFramesHistory : Vector.<Vector.<Number>> = null;
		
		private var forceStoppedAtFrames : Vector.<Number> = null;
		private var _isForceStopped : Boolean = false;
		
		private var lastChildIndex : Number = -1;
		
		private var haveDoneInitialUpdate : Boolean = false;
		
		public function SceneModel(_path : Vector.<String>) {
			path = _path;
			lastChildIndex = _path.length;
			
			frameUpdateEvent = new CustomEvent();
			splitEvent = new CustomEvent();
			mergeEvent = new CustomEvent();
			
			plugins = new ScenePluginsModel(this, true);
		}
		
		/**
		 * Create a new scene from save data
		 * @param	_saveData	The save data to use, generated by the toSaveData method
		 * @return 	The scene
		 */
		public static function fromSaveData(_saveData : Object) : SceneModel {
			var path : Vector.<String> = ArrayUtil.addValuesFromArrayToVector(new Vector.<String>(), _saveData.path);
			var scene : SceneModel = new SceneModel(path);
			
			scene.startFrames = ArrayUtil.addValuesFromArrayToVector(new Vector.<Number>(), _saveData.startFrames);
			scene.endFrames = ArrayUtil.addValuesFromArrayToVector(new Vector.<Number>(), _saveData.endFrames);
			scene.totalTimelineFrames = ArrayUtil.addValuesFromArrayToVector(new Vector.<Number>, _saveData.totalTimelineFrames);
			scene.firstStopFrames = ArrayUtil.addValuesFromArrayToVector(new Vector.<Number>(), _saveData.firstStopFrames);
			scene.haveDeterminedEndFrames = ArrayUtil.addValuesFromArrayToVector(new Vector.<Boolean>(), _saveData.haveDeterminedEndFrames);
			scene.endsAtLastFrame = _saveData.endsAtLastFrame;
			
			scene.plugins = ScenePluginsModel.fromSaveData(_saveData.plugins, scene);
			
			return scene;
		}
		
		/**
		 * Get information about the scene as save data
		 * @return	The save data
		 */
		public function toSaveData() : Object {
			var saveData : Object = {};
			
			saveData.path = ArrayUtil.vectorToArray(path);
			saveData.startFrames = ArrayUtil.vectorToArray(startFrames);
			saveData.endFrames = ArrayUtil.vectorToArray(endFrames);
			saveData.totalTimelineFrames = ArrayUtil.vectorToArray(totalTimelineFrames);
			saveData.firstStopFrames = ArrayUtil.vectorToArray(firstStopFrames);
			saveData.haveDeterminedEndFrames = ArrayUtil.vectorToArray(haveDeterminedEndFrames);
			saveData.endsAtLastFrame = endsAtLastFrame;
			
			saveData.plugins = plugins.toSaveData();
			
			return saveData;
		}
		
		/**
		 * Makes a copy of the scene
		 * @return The copy
		 */
		public function clone() : SceneModel {
			var clonedScene : SceneModel = new SceneModel(path);
			
			clonedScene.startFrames = startFrames.slice();
			clonedScene.endFrames = endFrames.slice();
			clonedScene.totalTimelineFrames = totalTimelineFrames.slice();
			clonedScene.firstStopFrames = firstStopFrames.slice();
			clonedScene.haveDeterminedEndFrames = haveDeterminedEndFrames.slice();
			clonedScene.endsAtLastFrame = endsAtLastFrame;
			
			clonedScene.plugins = plugins.clone(clonedScene);
			
			return clonedScene;
		}
		
		/**
		 * Splits the current scene into two different scenes, at the current frame
		 * The first half will end on the last frames that were playing before the current ones
		 * Can only be called while the scene is active
		 * @return	A new scene, which is the first half of the scene
		 */
		public function split() : SceneModel {
			var currentFrames : Vector.<Number> = getCurrentFramesWhileActive();
			var currentInnerFrame : Number = currentFrames[lastChildIndex];
			var firstHalfEndFrames : Vector.<Number> = null;
			var firstHalf : SceneModel = clone();
			var i : Number;
			
			// Keep going back in history until we reach an inner frame that is 1 less than the current inner frame,
			// we want to use those frames as the end frames for the first half
			for (i = playingFramesHistory.length - 1; i >= 0; i--) {
				var innerHistoryFrame : Number = playingFramesHistory[i][lastChildIndex];
				if (innerHistoryFrame == currentInnerFrame - 1) {
					firstHalfEndFrames = playingFramesHistory[i];
					break;
				}
			}
			
			if (firstHalfEndFrames == null) {
				throw new Error("Unable to split scene, no valid history frames found");
			}
			
			for (i = 0; i < currentFrames.length; i++) {
				firstHalf.endFrames[i] = firstHalfEndFrames[i];
				firstHalf.firstStopFrames[i] = firstStopFrames[i] <= firstHalfEndFrames[i] ? firstStopFrames[i] : -1;
				firstHalf.haveDeterminedEndFrames[i] = true;
				
				startFrames[i] = currentFrames[i];
			}
			
			splitEvent.emit(firstHalf);
			
			return firstHalf;
		}
		
		/**
		 * Combine the scene with another scene, so that frames from the other scene is added to this one
		 * @param	_otherScene		The other scene to merge with
		 */
		public function merge(_otherScene : SceneModel) : void {
			if (path.join(",") != _otherScene.path.join(",")) {
				throw new Error("Unable to merge scenes, their paths are not the same");
			}
			
			for (var i : Number = 0; i < startFrames.length; i++) {
				startFrames[i] = Math.min(startFrames[i], _otherScene.startFrames[i]);
				endFrames[i] = Math.max(endFrames[i], _otherScene.endFrames[i]);
				firstStopFrames[i] = Math.max(firstStopFrames[i], _otherScene.firstStopFrames[i]);
				haveDeterminedEndFrames[i] = haveDeterminedEndFrames[i] || _otherScene.haveDeterminedEndFrames[i];
			}
			
			mergeEvent.emit(_otherScene);
		}
		
		/**
		 * Get the plugins for the scenes, which is a collection of additional functionality to the scene
		 * @return The plugins model
		 */
		public function getPlugins() : ScenePluginsModel {
			return plugins;
		}
		
		/**
		 * Get the start frames for each child that is part of the scene, starting from the top most, ending with the inner child
		 * @return	An array of frames
		 */
		public function getStartFrames() : Vector.<Number> {
			return startFrames.slice();
		}
		
		/**
		 * Get the end frames for each child that is part of the scene, starting from the top most, ending with the inner child
		 * @return	An array of frames
		 */
		public function getEndFrames() : Vector.<Number> {
			return endFrames.slice();
		}
		
		/**
		 * Get the current frame for each child that is part of the scene, starting from the top most, ending with the inner child
		 * Can only be called while the scene is active
		 * @return An array of frames
		 */
		public function getCurrentFrames() : Vector.<Number> {
			return getCurrentFramesWhileActive();
		}
		
		/**
		 * Get the start frame for the deepest nested child
		 * @return
		 */
		public function getInnerStartFrame() : Number {
			return startFrames[lastChildIndex];
		}
		
		/**
		 * Get the end frame for the deepest nested child
		 * @return
		 */
		public function getInnerEndFrame() : Number {
			return endFrames[lastChildIndex];
		}
		
		/**
		 * Get the total number of frames for the inner child only
		 * @return	The total number of frames
		 */
		public function getTotalInnerFrames() : Number {
			return endFrames[endFrames.length - 1] - startFrames[startFrames.length - 1] + 1;
		}
		
		/**
		 * Check wether the scene ends at the last timeline frame of the inner child
		 * @return 
		 */
		public function doesEndAtLastTimelineFrame() : Boolean {
			return endsAtLastFrame;
		}
		
		/**
		 * Get the path to the children that are part of the scene
		 * @return
		 */
		public function getPath() : Vector.<String> {
			return path.slice();
		}
		
		/**
		 * Has to be called before calling the update method
		 */
		public function enter() : void {
			if (enteredScene != null) {
				throw new Error("Unable to enter scene, there is already a scene that have been entered");
			}
			
			enteredScene = this;
			
			var currentFrames : Vector.<Number> = getCurrentFramesWhileActive();
			var children : Vector.<TPMovieClip> = getChildrenWhileActive();
			var i : Number;
			
			haveDoneInitialUpdate = false;
			updateLastPlayingFrames(currentFrames.slice());
			
			// For compatibility with save data format version 1
			if (totalTimelineFrames != null && ArrayUtil.includes(totalTimelineFrames, -1) == true) {
				for (i = 0; i < children.length; i++) {
					totalTimelineFrames[i] = children[i].totalFrames;
				}
			}
			
			if (startFrames != null) {
				return;
			}
			
			startFrames = currentFrames.slice();
			endFrames = currentFrames.slice();
			
			totalTimelineFrames = new Vector.<Number>();
			firstStopFrames = new Vector.<Number>();
			haveDeterminedEndFrames = new Vector.<Boolean>();
			
			for (i = 0; i < startFrames.length; i++) {
				totalTimelineFrames.push(children[i].totalFrames);
				firstStopFrames.push(-1);
				haveDeterminedEndFrames.push(false);
			}
		}
		
		/**
		 * Has to be called when the scene is no longer selected
		 */
		public function exit() : void {
			if (_isForceStopped == true && isActive() == true) {
				play();
			}
			
			_isForceStopped = false;
			lastPlayingFrames = null;
			forceStoppedAtFrames = null;
			
			enteredScene = null;
		}
		
		/**
		 * Updates information about the scene. Must be called on every frame while the scene is selected to ensure that it's information is accurate
		 * @return A status code for what happened during the update
		 */
		public function update() : String {
			if (enteredScene != this) {
				throw new Error("Unable to update scene, the scene have not been entered correctly");
			}
			
			// If it's force stopped, but the scene somehow isn't active anymore, exit it
			if (_isForceStopped == true && isActive() == false) {
				exit();
				frameUpdateEvent.emit(SceneModel.UPDATE_STATUS_EXIT);
				return SceneModel.UPDATE_STATUS_EXIT;
			}
			
			// If it's force stopped, but something caused the frames to change, resume playing
			if (_isForceStopped == true && isAtFramesWhileActive(forceStoppedAtFrames) == false) {
				play();
			}
			
			// If the scene wasn't resumed above, stop here
			if (_isForceStopped == true) {
				frameUpdateEvent.emit(SceneModel.UPDATE_STATUS_NORMAL);
				return SceneModel.UPDATE_STATUS_NORMAL;
			}
			
			var i : Number;
			var currentFrame : Number;
			var children : Vector.<TPMovieClip> = getChildrenWhileActive();
			var currentFrames : Vector.<Number> = getCurrentFramesWhileActive();
			var didExitScene : Boolean = false;
			var isActionsScript3 : Boolean = VersionConfig.actionScriptVersion == 3;
			
			// Check if it's currently on a frame within the scene, if not, we want to exit it
			for (i = 0; i < children.length; i++) {
				currentFrame = children[i].currentFrame;
				
				var isStopped : Boolean = currentFrame == firstStopFrames[i];
				var expectedMinFrame : Number = startFrames[i];
				var expectedMaxFrame : Number = isStopped ? endFrames[i] : endFrames[i] + 1;
				
				if (currentFrame < expectedMinFrame || currentFrame > expectedMaxFrame) {
					didExitScene = true;
					break;
				}
			}
			
			// If it did exit it, we don't want to update anything about the scene and exit it
			if (didExitScene == true) {
				exit();
				frameUpdateEvent.emit(SceneModel.UPDATE_STATUS_EXIT);
				return SceneModel.UPDATE_STATUS_EXIT;
			}
			
			var totalStoppedChildren : Number = 0;
			
			// If we're in the editor, update first stop frames and end frames
			if (EditorStates.isEditor.value == true) {
				for (i = 0; i < children.length; i++) {
					currentFrame = children[i].currentFrame;
					var totalFrames : Number = children[i].totalFrames;
					
					if (i == lastChildIndex && currentFrame == totalFrames) {
						endsAtLastFrame = true;
					}
					
					if (haveDoneInitialUpdate == true && currentFrame == lastPlayingFrames[i] && firstStopFrames[i] < 0) {
						firstStopFrames[i] = currentFrame;
						haveDeterminedEndFrames[i] = true;
					}
					
					if (currentFrame < lastPlayingFrames[i]) {
						if (endFrames[i] != totalFrames && isActionsScript3 == true) {
							endFrames[i] = lastPlayingFrames[i] - 1;
						}
						haveDeterminedEndFrames[i] = true;
					}
					
					if (haveDeterminedEndFrames[i] == false) {
						endFrames[i] = Math.max(endFrames[i], currentFrame);
					}
					
					if (currentFrame == firstStopFrames[i]) {
						totalStoppedChildren++;
					}
				}
			}
			
			// If all the children are stopped, stop here
			if (totalStoppedChildren == children.length) {
				updateLastPlayingFrames(currentFrames);
				return SceneModel.UPDATE_STATUS_COMPLETELY_STOPPED;
			}
			
			var innerChildCurrentFrame : Number = children[lastChildIndex].currentFrame;
			var innerChildLastFrame : Number = lastPlayingFrames[lastChildIndex];
			var innerChildStartFrame : Number = startFrames[lastChildIndex];
			
			var updateStatus : String = SceneModel.UPDATE_STATUS_NORMAL;
			
			// Check if the scene looped, and wether it did it from the start or not
			if (innerChildCurrentFrame < innerChildLastFrame) {
				if (innerChildCurrentFrame == innerChildStartFrame) {
					updateStatus = SceneModel.UPDATE_STATUS_LOOP_START;
				} else {
					updateStatus = SceneModel.UPDATE_STATUS_LOOP_MIDDLE;
				}
			}
			
			updateLastPlayingFrames(currentFrames);
			
			haveDoneInitialUpdate = true;
			
			frameUpdateEvent.emit(updateStatus);
			return updateStatus;
		}
		
		/**
		 * Check wether the animation is at the scene currently
		 * @return Wether it is at the scene
		 */
		public function isActive() : Boolean {
			var root : TPMovieClip = AnimationInfoStates.animationRoot.value;
			
			var children : Vector.<TPMovieClip> = HierarchyUtil.getMovieClipsFromPath(root, path);
			if (children == null) {
				return false;
			}
			
			for (var i : Number = 0; i < children.length; i++) {
				var currentFrame : Number = children[i].currentFrame;
				var startFrame : Number = startFrames[i];
				var endFrame : Number = endFrames[i];
				// We also check if it's -1, for compatibility with save data format version 1
				var hasValidTotalFrames : Boolean = children[i].totalFrames == totalTimelineFrames[i] || totalTimelineFrames[i] == -1;
				if (hasValidTotalFrames == false || currentFrame < startFrame || currentFrame > endFrame) {
					return false;
				}
			}
			
			return true;
		}
		
		/**
		 * Check wether the scene have been stopped through the editor
		 * @return Wether it have been stopped through the editor
		 */
		public function isForceStopped() : Boolean {
			return _isForceStopped;
		}
		
		/**
		 * Play all the nested children that are part of the scene, except if a child is at a frame where it was naturally stopped as part of the animation
		 * Can only be called while the scene is active
		 */
		public function play() : void {
			var children : Vector.<TPMovieClip> = getChildrenWhileActive();
			
			for (var i : Number = 0; i < children.length; i++) {
				var child : TPMovieClip = children[i];
				var firstStopFrame : Number = firstStopFrames[i];
				
				if (firstStopFrame < 0 || child.currentFrame < firstStopFrame) {
					child.play();
				}
			}
			
			_isForceStopped = false;
		}
		
		/**
		 * Stop all nested children that are part of the scene
		 * Can only be called while the scene is active
		 */
		public function stop() : void {
			var children : Vector.<TPMovieClip> = getChildrenWhileActive();
			
			for (var i : Number = 0; i < children.length; i++) {
				var child : TPMovieClip = children[i];
				child.stop();
			}
			
			setAsForceStopped();
		}
		
		/**
		 * Play from a specific frame within the scene
		 * @param _frames	The frame to use for each child that is apart of the scene, ending with the frame for the inner child
		 */
		public function gotoAndPlay(_frames : Vector.<Number>) : void {
			gotoFrame(_frames, true);
		}
		
		/**
		 * Stop at a specific frame within the scene
		 * @param _frames	The frame to use for each child that is apart of the scene, ending with the frame for the inner child
		 */
		public function gotoAndStop(_frames : Vector.<Number>) : void {
			gotoFrame(_frames, false);
		}
		
		/**
		 * Stops and steps frames for the inner child only
		 * Can only be called while the scene is active
		 * @param	_frames		The number of frames to step. If a negative value is used, it will step backwards
		 */
		public function stepFrames(_frames : Number) : void {
			stop();
			
			var children : Vector.<TPMovieClip> = getChildrenWhileActive();
			
			var currentFrame : Number = children[lastChildIndex].currentFrame;
			var startFrame : Number = startFrames[lastChildIndex];
			var endFrame : Number = endFrames[lastChildIndex];
			var targetFrame : Number = MathUtil.clamp(currentFrame + _frames, startFrame, endFrame);
			
			for (var i : Number = 0; i < children.length; i++) {
				var child : TPMovieClip = children[i];
				
				if (i < children.length - 1) {
					child.stop();
				} else {
					child.gotoAndStop(targetFrame);
				}
			}
			
			setAsForceStopped();
		}
		
		private function gotoFrame(_frames : Vector.<Number>, _shouldPlay : Boolean) : void {
			var root : TPMovieClip = AnimationInfoStates.animationRoot.value;
			
			for (var i : Number = 0; i < _frames.length; i++) {
				var currentPath : Vector.<String> = path.slice(0, i);
				
				var children : Vector.<TPMovieClip> = HierarchyUtil.getMovieClipsFromPath(root, currentPath);
				var child : TPMovieClip = children[children.length - 1];
				var firstStopFrame : Number = firstStopFrames[i];
				var isStoppedAtFrame : Boolean = firstStopFrame >= 0 && _frames[i] >= firstStopFrame;
				
				if (_shouldPlay == true && isStoppedAtFrame == false) {
					child.gotoAndPlay(_frames[i]);
				} else {
					child.gotoAndStop(_frames[i]);
				}
			}
			
			if (_shouldPlay == false) {
				setAsForceStopped();
			} else {
				_isForceStopped = false;
			}
		}
		
		private function setAsForceStopped() : void {
			_isForceStopped = true;
			forceStoppedAtFrames = getCurrentFramesWhileActive();
			updateLastPlayingFrames(forceStoppedAtFrames.slice());
		}
		
		/**
		 * Updates the last playing frames and the playing frames history
		 * The playing frames history does only update as long as we aren't repeating frames
		 * @param	_frames
		 */
		private function updateLastPlayingFrames(_frames : Vector.<Number>) : void {
			lastPlayingFrames = _frames.slice();
			if (playingFramesHistory == null) {
				playingFramesHistory = new Vector.<Vector.<Number>>();
				playingFramesHistory.push(lastPlayingFrames);
			}
			
			var lastHistoryIndex : Number = playingFramesHistory.length - 1;
			var innerChildFrame : Number = _frames[lastChildIndex];
			var innerChildFrameFromHistory : Number = playingFramesHistory[lastHistoryIndex][lastChildIndex];
			
			if (innerChildFrame > innerChildFrameFromHistory) {
				playingFramesHistory.push(lastPlayingFrames);
			}
		}
		
		private function getChildrenWhileActive() : Vector.<TPMovieClip> {
			var root : TPMovieClip = AnimationInfoStates.animationRoot.value;
			
			var children : Vector.<TPMovieClip> = HierarchyUtil.getMovieClipsFromPath(root, path);
			if (children == null) {
				throw new Error("Unable to get children, the scene is not active");
			}
			
			return children;
		}
		
		private function getCurrentFramesWhileActive() : Vector.<Number> {
			var children : Vector.<TPMovieClip> = getChildrenWhileActive();
			var frames : Vector.<Number> = new Vector.<Number>();
			
			for (var i : Number = 0; i < children.length; i++) {
				var child : TPMovieClip = children[i];
				frames.push(child.currentFrame);
			}
			
			return frames;
		}
		
		private function isAtFramesWhileActive(_frames : Vector.<Number>) : Boolean {
			var currentFrames : Vector.<Number> = getCurrentFramesWhileActive();
			
			for (var i : Number = 0; i < _frames.length; i++) {
				if (currentFrames[i] != currentFrames[i]) {
					return false;
				}
			}
			
			return true;
		}
	}
}