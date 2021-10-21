package eu.claudius.iacob.desktop.presetmanager.lib {
	import flash.events.Event;
	
	/**
	 * Event dispatched by the `PresetManagerUi` class. Contains information about
	 * one or more of the managed presets, aka "Configurations".
	 */
	public class PresetEvent extends Event {
		
		public static const PRESET_CHANGED : String = 'presetChanged';
		
		private var _data : Object;
		
		/**
		 * Constructor for class PresetEvent.
		 * @param	type
		 * 			The type of this event. Should be one of the public constants
		 * 			defined by class PresetEvent.
		 * 
		 * @param	data
		 * 			Data to be associated with this Event.
		 */
		public function PresetEvent (type : String, data : Object) {
			super (type, false, false);
			_data = data;			
		}
		
		/**
		 * The data associated with this Event.
		 */
		public function get data () : Object {
			return _data;
		}
		
		/**
		 * @see flash.events.Event.clone()
		 */
		override public function clone() : Event {
			return new PresetEvent (type, _data);
		}
	}
}