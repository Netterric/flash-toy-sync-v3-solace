/**
 * This file have been transpiled from Actionscript 3.0 to 2.0, any changes made to this file will be overwritten once it is transpiled again
 */

import stateTypes.*
import core.JSON

/**
 * ...
 * @author notSafeForDev
 */
class stateTypes.BooleanState extends State {
	
	public function BooleanState(_defaultValue : Boolean) {
		super(_defaultValue, BooleanStateReference);
	}
	
	public function getValue() : Boolean {
		return value;
	}
	
	public function setValue(_value : Boolean) : Void {
		value = _value;
	}
}