package eu.claudius.iacob.desktop.presetmanager.lib {
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	
	import ro.ciacob.utils.Files;
	import ro.ciacob.utils.Patterns;
	import ro.ciacob.utils.Strings;
	import ro.ciacob.utils.constants.CommonStrings;

	/**
	 * Class with static methods for validating user input.
	 */
	public class Assertions {
		
		private static const FILE_IS_NULL_MSG : String = 'Argument `file` cannot be null.';		
		private static const FILE_DOES_NOT_EXIST_MSG : String = 'Given file `%s` does not exist on disk.';
		private static const FILE_NOT_DELETED_MSG : String = 'Given file `%s` could not be deleted from disk.';
		private static const FILE_NOT_RENAMED_MSG : String = 'Given file `%s` could not be renamed as `%s`.';
		private static const FILE_NOT_READABLE_MSG : String = 'Given file `%s` is not readable.';

		private static const NAME_IS_NULL_MSG : String = 'Argument `name` cannot be null.';
		private static const NAME_IS_EMPTY_MSG : String = 'Argument `name` cannot be an empty string.';
		private static const NAME_IS_PADDED_MSG : String = 'Argument `name` cannot have leading or trailing spaces.';
		private static const NAME_HAS_ILLEGAL_DOT_MSG : String = 'Argument `name` must not start or end with a dot.';
		private static const NAME_HAS_ILLEGAL_CHARS_MSG : String = 'Argument `name` must obey file naming conventions. The following pattern was not satisfied: %s';
		private static const NAME_IS_TOO_LONG_MSG : String = 'Argument `name` must be a string of at most %s characters.'

		private static const PAYLOAD_IS_NULL_MSG : String = 'Argument `payload` cannot be null.';
		private static const PAYLOAD_IS_EMPTY_MSG : String = 'Argument `payload` cannot be empty.';
		private static const PAYLOAD_HAS_NO_SETTINGS_MSG : String = 'Argument `payload` must contain a data child at index 0, where user settings must be stored.';

		private static const BAD_METADATA_GIVEN_MSG : String = 'Given metadata contains illegal values: %s.';
		private static const ZERO_BYTES_READ_MSG : String = 'Zero bytes read.';
		private static const ZERO_BYTES_WRITTEN_MSG : String = 'Zero bytes written.';
		
		/**
		 * Throws if provided `name` cannot be used as (part of a) file name under both Windows
		 * and macOs.
		 * 
		 * @return	Boolean output, for the case where assertions/RTEs are disabled. 
		 */
		public static function isValidFileName (name : String) : Boolean {
			if (name === null) {
				throw (new ArgumentError (NAME_IS_NULL_MSG));
				return false;
			}
			var trimmedName : String = Strings.trim (name);
			if (trimmedName != name) {
				throw (new ArgumentError (NAME_IS_PADDED_MSG));
				return false;
			}
			if (!name) {
				throw (new ArgumentError (NAME_IS_EMPTY_MSG));
				return false;
			}
			if (Strings.beginsWith (name, CommonStrings.DOT) || Strings.endsWith (name, CommonStrings.DOT)) {
				throw (new ArgumentError (NAME_HAS_ILLEGAL_DOT_MSG));
				return false;
			}
			if (!Files.isValidRelativePath (name)) {
				throw (new ArgumentError (Strings.sprintf (NAME_HAS_ILLEGAL_CHARS_MSG, Patterns.WINDOWS_VALID_FILE_NAME)));
				return false;
			}
			if (name.length > Constants.CONFIG_NAME_MAX_CHARS) {
				throw (new ArgumentError (Strings.sprintf (NAME_IS_TOO_LONG_MSG, Constants.CONFIG_NAME_MAX_CHARS)));
				return false;
			}
			return true;
		}
		
		/**
		 * Throws if provided `payload` is null or lacks content.
		 * 
		 * @return	Boolean output, for the case where assertions/RTEs are disabled. 
		 */
		public static function isValidPayload (payload : Payload) : Boolean {
			if (payload === null) {
				throw (new ArgumentError (PAYLOAD_IS_NULL_MSG));
				return false;
			}
			if (payload.isEqualTo (new Payload ({}))) {
				throw (new ArgumentError (PAYLOAD_IS_EMPTY_MSG));
				return false;
			}
			if (payload.getDataChildAt(0) === null) {
				throw (new ArgumentError (PAYLOAD_HAS_NO_SETTINGS_MSG));
				return false;
			}
			return true;
		}
		
		/**
		 * Throws if provided `file` is null.
		 * 
		 * @return	Boolean output, for the case where assertions/RTEs are disabled. 
		 */
		public static function fileIsNotNull (file : File) : Boolean {
			if (file === null) {
				throw (new ArgumentError (FILE_IS_NULL_MSG));
				return false;
			}
			return true;
		}
		
		/**
		 * Throws if provided `file` does not exist on disk.
		 * 
		 * @return	Boolean output, for the case where assertions/RTEs are disabled. 
		 */
		public static function fileExists (file : File) : Boolean {
			if (file && file.exists) {
				return true;
			}
			throw (new ArgumentError (Strings.sprintf (FILE_DOES_NOT_EXIST_MSG, file.nativePath)));
			return false;
		}
		
		/**
		 * Throws if provided `file` cannot be read.
		 * 
		 * @return	Boolean output, for the case where assertions/RTEs are disabled. 
		 */
		public static function fileIsReadable (file : File) : Boolean {
			var error : ArgumentError = new ArgumentError (Strings.sprintf (FILE_NOT_READABLE_MSG, file.nativePath));
			if (file && file.exists) {
				var fs : FileStream = new FileStream;
				try {
					fs.open (file, FileMode.READ);
					error = null;
				} catch (e : Error) {
					var message : String = (error.message as String);
					error.message = message.concat (CommonStrings.SPACE, e.message); 
				} finally {
					fs.close();
				}
			}
			if (error) {
				throw (error);
				return false;
			}
			return true;
		}
		
		/**
		 * Throws if provided `bytes` ByteArray is empty.
		 * 
		 * @return	Boolean output, for the case where assertions/RTEs are disabled. 
		 */
		public static function notEmpty (bytes : ByteArray) : Boolean {
			if (bytes.length > 0) {
				return true;
			}
			throw (new ArgumentError (ZERO_BYTES_READ_MSG));
			return false;
		}
		
		/**
		 * Throws if any of the provided `name`, `isReadOnly`, `uid`, or `hash` are null or invalid.
		 * 
		 * @return	Boolean output, for the case where assertions/RTEs are disabled. 
		 */
		public static function isCorrectMetadata (name : String, isReadOnly : Object, uid : String, hash : String) : Boolean {
			var error : Error = new ArgumentError (BAD_METADATA_GIVEN_MSG);
			var validName : Boolean = isValidFileName (name);
			var validFlag : Boolean = (isReadOnly is Boolean);
			var validUid : Boolean = (Strings.trim (uid).length == Strings.UUID_LENGTH);
			var validHash : Boolean = (Strings.trim (hash).length == Constants.SHA256_HASH_LENGTH - Constants.HASH_START_INDEX);
			if (validName && validFlag && validUid && validHash) {
				return true;
			}
			var failedFields : Array = [];
			if (!validName) {
				failedFields.push ('name');
			}
			if (!validFlag) {
				failedFields.push ('isReadOnly');
			}
			if (!validUid) {
				failedFields.push ('uid');
			}
			if (!validHash) {
				failedFields.push ('hash');
			}
			if (failedFields.length > 1) {
				failedFields.splice (failedFields.length - 1, 0, CommonStrings.AND);
			}
			throw (new ArgumentError (Strings.sprintf (BAD_METADATA_GIVEN_MSG, failedFields.join (CommonStrings.COMMA_SPACE))));
			return false;
		}
		
		/**
		 * Throws if provided `extension` cannot be used as part of a file name under both Windows
		 * and macOs.
		 * 
		 * @return	Boolean output, for the case where assertions/RTEs are disabled. 
		 */
		public static function isValidFileExtension (extension : String) : Boolean {
			return isValidFileName (extension);
		}
		
		/**
		 * Throws if provided `name` cannot be used as a directory name under both Windows
		 * and macOs.
		 * 
		 * @return	Boolean output, for the case where assertions/RTEs are disabled. 
		 */
		public static function isValidDirectoryName (name : String) : Boolean {
			return isValidFileName (name);	
		}
		
		/**
		 * Throws if provided `file` does not exist on disk. Additionally, throws if provided
		 * `dirCreationError` was not null.
		 * 
		 * @return	Boolean output, for the case where assertions/RTEs are disabled. 
		 */
		public static function directoryExists (directory : File, dirCreationError : Error) : Boolean {
			if (dirCreationError) {
				throw (dirCreationError);
				return false;
			}
			return fileIsNotNull (directory) && fileExists (directory);
		}

		/**
		 * Throws if provided `file` DOES exist on disk (it is assumed that a deletion attempt was
		 * carried on before this assertion was made). Additionally, throws if provided
		 * `fileDeletionError` was not null.
		 * 
		 * @return	Boolean output, for the case where assertions/RTEs are disabled.
		 */
		public static function fileDeleted (file : File, fileDeletionError : Error) : Boolean {
			if (fileDeletionError) {
				throw (fileDeletionError);
				return false;
			}
			if (fileIsNotNull (file) && !file.exists) {
				return true;
			}
			throw (new ArgumentError (Strings.sprintf (FILE_NOT_DELETED_MSG, file.nativePath)));
			return false;
		}
		
		/**
		 * Throws if given `oldFile` could not be renamed as `newFile`. Additionally, throws if provided
		 * `fileMoveError` was not null.
		 * 
		 * @return	Boolean output, for the case where assertions/RTEs are disabled.
		 */
		public static function fileMoved (oldFile : File, newFile : File, fileMoveError : Error) : Boolean {
			if (fileMoveError) {
				throw (fileMoveError);
				return false;
			}
			if (fileIsNotNull (oldFile) &&
				fileIsNotNull (newFile) &&
				fileExists (oldFile) &&
				fileExists (newFile) &&
				oldFile.nativePath == newFile.nativePath) {
				return true;
			}
			throw (new ArgumentError (Strings.sprintf (FILE_NOT_RENAMED_MSG, oldFile.nativePath, newFile.nativePath)));
			return false;
		}
		
		/**
		 * Throws if given `numWrittenBytes` is `0`.
		 * @return	Boolean output, for the case where assertions/RTEs are disabled.
		 */
		public static function notZero (numWrittenBytes : uint) : Boolean {
			if (numWrittenBytes > 0) {
				return true;
			}
			throw (new ArgumentError (ZERO_BYTES_WRITTEN_MSG));
			return false;
		}
		
	}
}