/**
 * ...
 * @author notSafeForDev
 */
class core.stateTypes.BooleanState {
	
	private var value : Boolean;
	private var PreviousValue : Boolean;
	private var listeners : Array = [];
	
	public function BooleanState(_default : Boolean) {
		PreviousValue = _default != undefined ? _default : false;
		value = _default != undefined ? _default : false;
	}
	
	public function listen(_scope, _handler : Function) : Object {
		var listener : Object = {handler: _handler, scope : _scope}
		listeners.push(listener);
		return listener;
	}
	
	public function setState(_value : Boolean) : Void {		
		if (_value == value) {
			return;
		}
		
		for (var i : Number = 0; i < listeners.length; i++) {
			this.listeners[i].handler.apply(this.listeners[i].scope, [_value]);
		}
		
		PreviousValue = value;
		value = _value;
	}
	
	public function getState() : Boolean {
		return value;
	}
	
	public function getPreviousValue() : Boolean {
		return PreviousValue;
	}
}