package eu.claudius.iacob.desktop.presetmanager.lib {
	
	/**
	 * Dedicated data structure returned when a new Payload is sent in; if that Payload
	 * was previously sent and stored as a Configruation, contains information regarding
	 * that Configuration.
	 */
	public class PayloadAnalysisResult {
		
		public static const STATUS_MATCH : String = 'statusMatch';
		public static const STATUS_NO_MATCH : String = 'statusNoMatch';
		public static const STATUS_ERROR : String = 'statusError';
		
		public static const ACTION_SAVE : String = 'actionSave';
		public static const ACTION_DELETE : String = 'actionDelete';
		public static const ACTION_RENAME : String = 'actionRename';
		
		private var _status : String;
		private var _matchUid : String;
		private var _availableActions : Vector.<String>;
		
		/**
		 * Constructor for class PayloadAnalysisResult.
		 * 
		 * @param	status
		 * 			The status analysis of the given Payload has yelded. Expected values shall be
		 * 			one of:
		 * 
		 * 			- PayloadAnalysisResult.STATUS_MATCH: an identical Payload (same name-value
		 * 			  pairs) has been received before, and is now stored on disk as a Configuration;
		 * 
		 * 			- PayloadAnalysisResult.STATUS_NO_MATCH: none of the Configurations currently
		 * 			  stored on disk originated from a Payload containing the same name-value
		 * 			  pairs as the current one;
		 * 
		 * 			- PayloadAnalysisResult.STATUS_ERROR: the analysis could not be carried on,
		 * 			  most likely because given Payload was invalid.
		 * 
		 * @param	matchUid
		 * 			If `status` is PayloadAnalysisResult.STATUS_MATCH, then this argument shall
		 * 			contain the unique id of the matching Configuration.
		 * 
		 * @param	availableActions
		 * 			The logical actions one should be entitled to carry upon the given Payload. Expected
		 * 			values shall be one of:
		 * 
		 * 			- PayloadAnalysisResult.ACTION_SAVE: if `status` is PayloadAnalysisResult.STATUS_NO_MATCH;
		 * 
		 * 			- PayloadAnalysisResult.ACTION_DELETE and PayloadAnalysisResult.ACTION_RENAME: if `status`
		 * 			  is PayloadAnalysisResult.STATUS_MATCH and matched Configuration is NOT one of the 
		 * 			  "built-in" configurations (its `isReadOnly` getter returns `false`).
		 */
		public function PayloadAnalysisResult (status : String, matchUid : String, availableActions : Vector.<String>) {
			_status = status;
			_matchUid = matchUid;
			_availableActions = availableActions;
		}
		
		/**
		 * See description for the "status" parameter in the constructor documentation.
		 */
		public function get status () : String {
			return _status;
		}
		
		/**
		 * See description for the "matchUid" parameter in the constructor documentation.
		 */
		public function get matchUid () : String {
			return _matchUid;
		}
		
		/**
		 * See description for the "availableActions" parameter in the constructor documentation.
		 */
		public function get availableActions () : Vector.<String> {
			return _availableActions;
		}
	}
}