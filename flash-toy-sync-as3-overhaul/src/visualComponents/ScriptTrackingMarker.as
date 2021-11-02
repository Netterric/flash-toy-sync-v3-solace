package visualComponents {
	import core.TPMovieClip;
	import ui.TextElement;
	import ui.TextStyles;
	
	/**
	 * ...
	 * @author notSafeForDev
	 */
	public class ScriptTrackingMarker extends ScriptMarker {
		
		public function ScriptTrackingMarker(_parent : TPMovieClip, _color : Number, _text : String) {
			super(_parent, _text);
			
			element.graphics.beginFill(_color, 0.5);
			element.graphics.drawCircle(0, 0, getRadius());
		}
		
		public function getRadius() : Number {
			return 12;
		}
	}
}