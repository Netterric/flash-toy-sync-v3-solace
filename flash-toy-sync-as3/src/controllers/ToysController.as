package controllers {
	import components.ToyPanel;
	import flash.display.MovieClip;
	import global.GlobalState;
	/**
	 * ...
	 * @author notSafeForDev
	 */
	public class ToysController {
		
		public function ToysController(_globalState : GlobalState, _panelContainer : MovieClip) {
			var toyPanel : ToyPanel = new ToyPanel(_panelContainer);
			toyPanel.setPosition(0, 400);
		}
	}
}