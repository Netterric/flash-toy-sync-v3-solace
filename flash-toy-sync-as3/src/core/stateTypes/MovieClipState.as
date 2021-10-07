package core.stateTypes {
	
	import flash.display.MovieClip;
	
	/**
	 * ...
	 * @author notSafeForDev
	 */
	public class MovieClipState {
		
		private var value : MovieClip;
		private var previousValue : MovieClip;
		private var listeners : Array = [];
		
		public function MovieClipState(_default : MovieClip = null) {
			previousValue = _default;
			value = _default;
		}
		
		public function listen(_scope : *, _handler : Function) : Object {
			var listener : Object = {handler: _handler, scope : _scope}
			listeners.push(listener);
			return listener;
		}
		
		public function setState(_value : MovieClip) : void {
			if (_value == value) {
				return;
			}
			
			for (var i : Number = 0; i < listeners.length; i++) {
				this.listeners[i].handler(_value);
				if (this.listeners[i].once == true) {
					this.listeners.splice(i, 1);
					i--;
				}
			}
			previousValue = value;
			value = _value;
		}
		
		public function getState() : MovieClip {
			return value;
		}
		
		public function getPreviousState() : MovieClip {
			return previousValue;
		}
	}
}