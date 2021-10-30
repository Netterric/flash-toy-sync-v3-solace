import core.TPDisplayObject;
import flash.geom.ColorTransform;
import flash.geom.Point;

/**
 * ...
 * @author notSafeForDev
 */
class core.TPDisplayObject {
	
	public var sourceDisplayObject : MovieClip;
	
	// Doesn't use any type, as the object could be a TextField
	public function TPDisplayObject(_object) {
		sourceDisplayObject = _object;
	}
	
	public function get x() : Number {
		return sourceDisplayObject._x;
	}
	
	public function set x(_value : Number) : Void {
		sourceDisplayObject._x = _value;
	}
	
	public function get y() : Number {
		return sourceDisplayObject._y;
	}
	
	public function set y(_value : Number) : Void {
		sourceDisplayObject._y = _value;
	}
	
	public function get width() : Number {
		return sourceDisplayObject._width;
	}
	
	public function set width(_value : Number) : Void {
		sourceDisplayObject._width = _value;
	}
	
	public function get height() : Number {
		return sourceDisplayObject._height;
	}
	
	public function set height(_value : Number) : Void {
		sourceDisplayObject._height = _value;
	}
	
	public function get scaleX() : Number {
		return sourceDisplayObject._xscale / 100;
	}
	
	public function set scaleX(_value : Number) : Void {
		sourceDisplayObject._xscale = _value * 100;
	}
	
	public function get scaleY() : Number {
		return sourceDisplayObject._yscale / 100;
	}
	
	public function set scaleY(_value : Number) : Void {
		sourceDisplayObject._yscale = _value * 100;
	}
	
	public function get alpha() : Number {
		return sourceDisplayObject._alpha / 100;
	}
	
	public function set alpha(_value : Number) : Void {
		sourceDisplayObject._alpha = _value * 100;
	}
	
	public function get visible() : Boolean {
		return sourceDisplayObject._visible;
	}
	
	public function set visible(_value : Boolean) : Void {
		sourceDisplayObject._visible = _value;
	}
	
	public function get name() : String {
		return sourceDisplayObject._name;
	}
	
	public function set name(_value : String) : Void {
		sourceDisplayObject._name = _value;
	}
	
	public function get parent() : MovieClip {
		return sourceDisplayObject._parent;
	}
	
	public function get filters() : Array {
		return sourceDisplayObject.filters;
	}
	
	public function set filters(_value : Array) : Void {
		sourceDisplayObject.filters = _value;
	}
	
	public function get colorTransform() : ColorTransform {
		return sourceDisplayObject.transform.colorTransform;
	}
	
	public function set colorTransform(_value : ColorTransform) : Void {
		sourceDisplayObject.transform.colorTransform = _value;
	}
	
	public function setMask(_mask : TPDisplayObject) : Void {
		sourceDisplayObject.setMask(_mask.sourceDisplayObject);
	}
	
	public function addOnEnterFrameListener(_scope, _handler : Function) {
		var originalFunction = sourceDisplayObject.onEnterFrame;
		
		sourceDisplayObject.onEnterFrame = function() {
			if (originalFunction != undefined) {
				originalFunction();
			}
			_handler.apply(_scope);
		}
	}
	
	public function localToGlobal(_point : Point) : Point {
		var modifiedPoint : Point = _point.clone();
		sourceDisplayObject.localToGlobal(modifiedPoint);
		return modifiedPoint;
	}
	
	public function globalToLocal(_point : Point) : Point {
		var modifiedPoint : Point = _point.clone();
		sourceDisplayObject.globalToLocal(modifiedPoint);
		return modifiedPoint;
	}
	
	public static function getParent(_object : MovieClip) : MovieClip {
		return _object._parent;
	}
	
	public static function getParents(_object : MovieClip) : Array {
		var parents : Array = [];
		
		var parent : MovieClip = _object._parent;
		while (parent != null) {
			parents.push(parent);
			parent = parent._parent;
		}
		
		return parents;
	}
	
	public static function getNestedChildren(_topParent : MovieClip) : Array {
		var children : Array = [];

		for (var childName : String in _topParent) {
			if (isDisplayObject(_topParent[childName]) == true) {
				children.push(_topParent[childName]);
				children = children.concat(getNestedChildren(_topParent[childName]));
			}
		}

		// We reverse the children as in AS2, they are ordered from highest to lowest depth, where as in AS3, it's the other way around
		children.reverse();
		
		return children;
	}
	
	public static function getChildIndex(_child : MovieClip) : Number {
		var i : Number = 0;
		
		for (var childName in _child._parent) {
			if (typeof _child._parent[childName] == "movieclip") {
				if (childName == _child._name) {
					return i;
				}
				i++;
			}
		}
	}
	
	public static function getChildAtIndex(_movieClip : MovieClip, _index : Number) : MovieClip {
		var i : Number = 0;
		
		for (var childName in _movieClip) {
			if (typeof _movieClip[childName] == "movieclip") {
				if (i == _index) {
					return _movieClip[childName];
				}
				i++;
			}
		}
	}
	
	public static function isDisplayObject(_object) : Boolean {
		return typeof _object == "movieclip" || _object["_visible"] != undefined;
	}
	
	public static function isDisplayObjectContainer(_object) : Boolean {
		return typeof _object == "movieclip";
	}
	
	public static function asDisplayObjectContainer(_object) : MovieClip {
		return _object;
	}
}