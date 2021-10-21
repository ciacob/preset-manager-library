package eu.claudius.iacob.desktop.presetmanager.lib {
	
	/**
	 * Dedicated data structure returned after Configuration related operations, such as storing,
	 * deleting or setting (i.e., recalling and making "current") a Configuration.
	 */
	public class OperationResult {
		
		public static const OPERATION_SAVE : String = 'save';
		public static const OPERATION_DELETE : String = 'delete';
		public static const OPERATION_CHANGE : String = 'change';
		public static const OPERATION_RENAME : String = 'rename';
		public static const REASON_DELETION : String = 'reasonDeletion';
		public static const REASON_OVERWRITING : String = 'reasonOverwriting';
		public static const REASON_OVERWRITING_BUILTIN_FILE : String = 'reasonOverwritingBuiltinFile';
		public static const REASON_UNSAVED_CHANGES : String = 'reasonUnsavedChanges';
		public static const REASON_NOTHING_TO_STORE : String = 'reasonNothingToStore';
		public static const REASON_NO_FILE : String = 'reasonNoFile';
		public static const REASON_ERROR : String = 'reasonError';
		public static const REASON_PARSE_ERROR : String = 'reasonParseError';
		
		private var _operation : String;
		private var _success : Boolean;
		private var _reason : String;
		private var _configuration : Configuration;
		
		/**
		 * Constructor for class OperationResult.
		 * 
		 * @param	operation
		 * 			The operation this result was produced in response of. Expected values shall be
		 * 			one of OperationResult.OPERATION_SAVE, OperationResult.OPERATION_DELETE or 
		 * 			OperationResult.OPERATION_CHANGE.
		 * 
		 * @param	success
		 * 			Whether the operation succeeded.
		 * 
		 * @param	reason
		 * 			If `success` is false, this shall contain the reason for failure. Expected values
		 * 			should be one of OperationResult.REASON_DELETION, OperationResult.REASON_OVERWRITING,
		 * 			OperationResult.REASON_UNSAVED_CHANGES and OperationResult.REASON_NOTHING_TO_STORE.
		 * 
		 * @param	configuration
		 * 			The Configuration instance this operation was executed against.
		 * 			
		 */
		public function OperationResult (operation : String, success : Boolean, reason : String, configuration : Configuration) {
			_operation = operation;
			_success = success;
			_reason = reason;
			_configuration = configuration;
		}
		
		/**
		 * See description for the "operation" parameter in the constructor documentation.
		 */
		public function get operation () : String {
			return _operation;
		}
		
		/**
		 * See description for the "success" parameter in the constructor documentation.
		 */
		public function get success () : Boolean {
			return _success;
		}
		
		/**
		 * See description for the "reason" parameter in the constructor documentation.
		 */
		public function get reason () : String {
			return _reason;
		}
		
		/**
		 * See description for the "configuration" parameter in the constructor documentation.
		 */
		public function get configuration () : Configuration {
			return _configuration;
		}
	}
}