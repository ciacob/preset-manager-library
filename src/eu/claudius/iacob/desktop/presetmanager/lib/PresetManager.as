package eu.claudius.iacob.desktop.presetmanager.lib {
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	
	import avmplus.getQualifiedClassName;
	
	import ro.ciacob.desktop.data.DataElement;
	import ro.ciacob.desktop.io.RawDiskReader;
	import ro.ciacob.desktop.io.RawDiskWritter;
	import ro.ciacob.utils.Files;
	import ro.ciacob.utils.Strings;
	
	/**
	 * 
	 * This library is a generic solution for managing combinations of name-value pairs.
	 * It is meant to be used in user configurable desktop AIR applications. By using this
	 * library, the end-user will be able to store and retrieve his/her preferred 
	 * configurations as "presets", and easily apply them.
	 * 
	 * The library is composed of an ActionScript standalone kernel, and an MXML UI component
	 * that uses the kernel. The kernel is completely independent and agnostic of the MXML
	 * UI component and could be used with other UI, or without any UI at all.
	 * 
	 * All presets will be stored on disk in a sub-folder of the "application storage 
	 * directory". The exact value of this directory is only known at runtime, via the 
	 * `File.applicationStorageDirectory constant.` The sub-folder name will be provided as
	 * a parameter when initializing the library.
	 * 
	 * The preset files will be saved under user-provided names. the file extension will
	 * also be provided as a parameter upon library initialization.
	 * 
	 * The library introduces and makes use of the following concepts, each defined as a
	 * dedicated Actionscript class:
	 * 
	 * - Payload: an ordered collection of name-value pairs;
	 * 
	 * - Configuration: a Payload that has been given a name and stored on disk.
	 * 
	 * - PayloadAnalysisResult: dedicated data structure returned when a new Payload is sent
	 *   in; if that Payload was previously sent and stored as a Configuration, contains
	 *   information regarding that Configuration.
	 * 
	 * - OperationResult: dedicated data structure returned after Configuration related
	 *   operations, such as storing, deleting or setting (i.e., marking as "current")
	 *   a Configuration.
	 * 
	 * @author Claudius Iacob <claudius.iacob@gmail.com>
	 * @version 1.0 2020/03/19
	 * @see documentation of the class constructor method for more information.
	 */
	public class PresetManager {

		public static const ALTERNATE_SYS_HOME_DIR_PATH : String = 'assets/system_presets';

		/**
		 * Stores the parent folder for any user-defined "home directory". The exact
		 * location is given by the `File.applicationStorageDirectory` constant.
		 * 
		 * @see `File.applicationStorageDirectory`
		 */
		public static const ROOT_HOME_DIRECTORY : File = File.applicationStorageDirectory;
		
		/**
		 * Stores the name of a sub-folder of the `PresetManager.ROOT_HOME_DIRECTORY`
		 * that the library will use to store "read-only" (aka, "system") Configuration
		 * files.
		 */
		public static const BUILTIN_CACHE_DIR_NAME : String = 'cache.builtIn';

		/**
		 * Pattern to use when giving file names to Configuration files.
		 */
		private static const CONFIG_FILE_NAME_TEMPLATE : String = '%s-%s.%s';
		
		/**
		 * Returns `true` if all of the following are true:
		 * 	- the folder denoted by the constant `PresetManager.ROOT_HOME_DIRECTORY`
		 * 	  contains a sub-folder by the name of the given `homeDirName` argument;
		 * 
		 * 	- this sub-folder contains a sub-sub-folder by the name of the 
		 * 	  `PresetManager.BUILTIN_CACHE_DIR_NAME` constant;
		 * 
		 * 	- the sub-sub-folder contains at least one file.
		 * 
		 * Returns `false` otherwise.
		 * 
		 * 
		 * @param	homeDirName
		 * 			Name of a folder (relative to the `PresetManager.ROOT_HOME_DIRECTORY`
		 * 			location), where all the Configuration files are to be stored. A
		 * 			sub-folder by the name of the `PresetManager.BUILTIN_CACHE_DIR_NAME`
		 * 			constant is expected to live there, and contain all the "built-in"
		 * 			Configuration files.
		 * 
		 * @see PresetManager.ROOT_HOME_DIRECTORY
		 * @see PresetManager.BUILTIN_CACHE_DIR_NAME
		 */
		public static function hasBuiltInCache (homeDirName : String) : Boolean {
			if (Assertions.isValidDirectoryName (homeDirName)) {
				var homeDir : File = ROOT_HOME_DIRECTORY.resolvePath (homeDirName);
				if (!homeDir.exists) {
					return false;
				}
				var builtInCacheDir : File = homeDir.resolvePath (BUILTIN_CACHE_DIR_NAME);
				if (!builtInCacheDir.exists) {
					return false;
				}
				var builtInFiles : Vector.<File> = Files.getDirContent (builtInCacheDir, false);
				return (builtInFiles.length > 0);
			}
			return false;
		}
		
		private var _initialized : Boolean;
		private var _currentPayload : Payload;
		private var _currentConfiguration : Configuration;
		private var _currentAnalysisResult : PayloadAnalysisResult;
		private var _mustUpdateConfigurations : Boolean;
		private var _configurations : Vector.<Configuration>;
		private var _fileExtension : String;
		private var _homeDir : File;
		private var _alternateSystemHomeDir : File;
		private var _builtinCacheDir : File;
		
		/**
		 * Constructor for class PresetManager.
		 * 
		 * @param	builtinConfigurations
		 * 			List of Configurations that shall be considered as "built-in", and, thus,
		 * 			not deletable.
		 * 
		 * 			The library will cache these on disk on first invocation, and ignore this
		 * 			parameter afterwards. Use the static method:
		 * 
		 * 			`PresetManager.hasBuiltInCache (homeDirName : String) : Boolean`
		 * 
		 * 			to skip processing and packaging the list of built-in Configurations when
		 * 			they are not needed anymore. This way, you will save CPU on subsequent runs
		 * 			of the application.
		 * 
		 * @param	fileExtension
		 * 			The file "Type" or "extension" to use for storing Configurations on disk.
		 * 
		 * @param	homeDirName
		 * 			Name of a folder (relative to the `ROOT_HOME_DIRECTORY` location), where all
		 * 			the Configuration files will be stored. A "cache.builtIn" sub-folder will be
		 * 			created here for "built-in" Configurations.
		 * 
		 * @see ROOT_HOME_DIRECTORY
		 */
		public function PresetManager (
			builtinConfigurations : Vector.<Configuration>,
			fileExtension : String,
			homeDirName : String) : void {

			// Check availability of the "alternate system home directory", another
			// means of providing read-only configuration files. This folder is optional.
			var systemPresetsHome : File = File.applicationDirectory.resolvePath (ALTERNATE_SYS_HOME_DIR_PATH);
			if (systemPresetsHome.exists) {
				var ownPresetsHome : File = systemPresetsHome.resolvePath(homeDirName);
				if (ownPresetsHome.exists) {
					_alternateSystemHomeDir = ownPresetsHome;
				}
			}
			
			// Store the file extension to use for all saved Configurations
			if (Assertions.isValidFileExtension (fileExtension)) {
				_fileExtension = fileExtension;
			}
			
			// Ensure availability of the general "home directory", the folder were
			// all user Configuration files are stored.
			var dirCreationError : Error = null;
			if (Assertions.isValidDirectoryName (homeDirName)) {
				var homeDir : File = ROOT_HOME_DIRECTORY.resolvePath (homeDirName);
				if (!homeDir.exists) {
					try {
						homeDir.createDirectory();
					} catch (err1 : Error) {
						dirCreationError = err1;
					}
				}
				if (Assertions.directoryExists (homeDir, dirCreationError)) {
					_homeDir = homeDir;
				}
			}
			
			// Ensure availability of the "built-in cache directory", a sub-folder
			// of the "home directory" where all read-only Configuration files are
			// stored.
			dirCreationError = null;
			var builtInCacheDir : File = null;
			try {
				builtInCacheDir = _homeDir.resolvePath (BUILTIN_CACHE_DIR_NAME);
			} catch (err2 : Error) {
				dirCreationError = err2;
			}
			if (builtInCacheDir && !builtInCacheDir.exists) {
				try {
					builtInCacheDir.createDirectory();
				} catch (err3 : Error) {
					dirCreationError = err3;
				}
			}
			if (Assertions.directoryExists (builtInCacheDir, dirCreationError)) {
				_builtinCacheDir = builtInCacheDir;
			}
			
			// Ensure all built-in Configurations are cached on disk
			if (_builtinCacheDir && builtinConfigurations && builtinConfigurations.length > 0) {
				if (!PresetManager.hasBuiltInCache (homeDirName)) {
					_cacheBuiltinConfigurations (builtinConfigurations);
				}
			}
			
			// Alternate way to tell whether initialization was successful or not
			// for the case where assertions are disabled)
			_initialized = (_fileExtension && _homeDir && _builtinCacheDir);
		}
		
		/**
		 * Returns the Configuration that was previously marked as "current" via
		 * `setCurrentConfiguration()`. Returns `null` if no Configuration was ever
		 * marked as "current".
		 */
		public function get currentConfiguration () : Configuration {
			return _currentConfiguration;
		}
		
		/**
		 * Contains `true` if this class was correctly initialized. Especially useful for
		 * the case where assertions were disabled.
		 */
		public function get initialized () : Boolean {
			return _initialized;
		}
		
		/**
		 * Analyses given `payload` and decides whether its content is novel or has been sent
		 * for analysis before. If the later, chances are for that content to have been also
		 * stored on disk as a Configuration; if this is the case, the returned PayloadAnalysisResult
		 * instance will contain that Configuration.
		 * 
		 * @param	payload
		 * 			The Payload to be sent-in for evaluation.
		 *
		 * @return	An instance of the PayloadAnalysisResult class with data about the analysis
		 *			payload, and especially whether an equivalent payload has been or not analysed
		 *			and stored to disk before.
		 */
		public function setCurrentPayload (payload : Payload) : PayloadAnalysisResult {
			var availableActions : Vector.<String> = Vector.<String>([]);
			if (Assertions.isValidPayload (payload)) {
				_currentPayload = payload;
				var configurations : Vector.<Configuration> = listConfigurations();
				var hash : String = _currentPayload.getHash();
				var match : Vector.<Configuration> = configurations.filter (function (configuration : Configuration, ...etc) : Boolean {
					return (configuration.hash == hash);
				});
				if (match.length > 0) {
					var matchingConfiguration : Configuration = match[0];
					if (!matchingConfiguration.isReadOnly) {
						availableActions.push (PayloadAnalysisResult.ACTION_DELETE);
					}
					_currentAnalysisResult = new PayloadAnalysisResult (PayloadAnalysisResult.STATUS_MATCH,
						matchingConfiguration.uid, availableActions);
					return _currentAnalysisResult; 
				}
				availableActions.push(PayloadAnalysisResult.ACTION_SAVE);
				_currentAnalysisResult = new PayloadAnalysisResult (PayloadAnalysisResult.STATUS_NO_MATCH, null, availableActions);
				return _currentAnalysisResult;
			}
			_currentAnalysisResult = new PayloadAnalysisResult (PayloadAnalysisResult.STATUS_ERROR, null, availableActions);
			return _currentAnalysisResult;
		}

		/**
		 * Returns a (possibly empty) list with all Configurations currently stored on disk,
		 * both "built-in" and user-defined.
		 */
		public function listConfigurations () : Vector.<Configuration> {
			if (!_configurations || _mustUpdateConfigurations) {
				if (_configurations) {
					_configurations.length = 0;
				} else {
					_configurations = Vector.<Configuration>([]);
				}
				var configFiles : Vector.<File> = Vector.<File>([]);
				if (_alternateSystemHomeDir) {
					configFiles = configFiles.concat(Files.getDirContent (_alternateSystemHomeDir, false));
				}
				configFiles = configFiles.concat (Files.getDirContent (_homeDir, false));
				configFiles.filter (function (file : File, ...etc) : Boolean {
					return (file.extension == _fileExtension);
				});
				for (var i:int = 0; i < configFiles.length; i++) {
					var configFile : File = configFiles[i];
					var configuration : Configuration = _readConfigurationFromFile (configFile);
					if (configuration) {
						_configurations.push (configuration);
					}
				}
				_mustUpdateConfigurations = false;
			}
			return _configurations;
		}
		
		/**
		 * Creates and stores to disk a new Configuration, which encapsulates the last Payload that was sent-in
		 * for analysis via `setCurrentPayload()`.
		 * 
		 * @param	name
		 * 			The name to use for storing the resulting Configuration on disk.
		 * 
		 * @throws	When any of the following situations occur:
		 * 			- TODO: PROVIDE COMPLETE LIST
		 * 
		 * @return Returns an OperationResult instance with information about the outcome.
		 */
		public function storeCurrentPayload (name : String) : OperationResult {
			if (Assertions.isValidFileName(name)) {
				if (_currentPayload && _currentAnalysisResult && 
					_currentAnalysisResult.availableActions.indexOf (PayloadAnalysisResult.ACTION_SAVE) != -1) {
					var configuration : Configuration = new Configuration (name, false, _currentPayload);
					var result : OperationResult = _writeConfigurationToFile (configuration);
					if (result.success) {
						setCurrentPayload (_currentPayload);
					}
					return result;
				}
			}
			return new OperationResult (OperationResult.OPERATION_SAVE, false, OperationResult.REASON_ERROR, null);
		}
		
		/**
		 * Sets one of the stored configurations as "current". The "current configuration"
		 * can be retrieved via the `currentConfiguration` public getter and is subjected by
		 * the `deleteCurrentConfiguration()` and `renameCurrentConfiguration()` methods.
		 * 
		 * Setting a Configuration as "current" also sets its contained Payload as "current",
		 * which is a potentially destructive action (because, if the existing Payload was novel
		 * and unsaved, it will be lost). Normally, setting a Configuration as "current" will be
		 * denied if this leads to loosing an unsaved Payload, but the `force` argument can be
		 * provided and set to `true` to bypass this restriction.
		 * 
		 * @param	configurationUid
		 * 			The unique id of one of the stored Configurations.
		 * 
		 * @param	force
		 * 			Optional, defaults to `true`. Permits the operation even if it would result
		 * 			in loosing a novel and unsaved Payload.
		 * 	
		 * @return	Returns an OperationResult instance with information about the outcome.
		 */
		public function setCurrentConfiguration (configurationUid : String, force : Boolean = true) : OperationResult {
			var configurations : Vector.<Configuration> = listConfigurations();
			var match : Vector.<Configuration> = configurations.filter (function (configuration : Configuration, ...etc) : Boolean {
				return (configuration.uid == configurationUid);
			});
			if (match.length > 0) {
				var matchingConfiguration : Configuration = match[0];
				var isDestructiveOperation : Boolean = (_currentPayload && _currentAnalysisResult && 
					_currentAnalysisResult.status == PayloadAnalysisResult.STATUS_NO_MATCH);
				if (isDestructiveOperation && !force) {
					return (new OperationResult (OperationResult.OPERATION_CHANGE, false, OperationResult.REASON_UNSAVED_CHANGES, 
						matchingConfiguration));
				}
				_currentConfiguration = matchingConfiguration;
				setCurrentPayload (matchingConfiguration.payload);
				return (new OperationResult (OperationResult.OPERATION_CHANGE, true, null, matchingConfiguration));
			}
			return (new OperationResult (OperationResult.OPERATION_CHANGE, false, OperationResult.REASON_NO_FILE, null));
		}
		
		/**
		 * Deletes from disk the Configuration that was previously set as "current". This is a
		 * destructive action and the change is permanent.
		 * 
		 * Deleting a Configuration does not unset the "current payload". Since this is the
		 * Payload that was previously stored inside the deleted Configuration, immediately
		 * calling `storeCurrentPayload()` after `deleteCurrentConfiguration()` will, in effect,
		 * restore the deleted Configuration.
		 * 
		 * Deleting is denied for built-in Configurations. This is a restriction that cannot be
		 * circumvented.
		 * 
		 * @return Returns an OperationResult instance with information about the outcome.
		 */
		public function deleteCurrentConfiguration () : OperationResult {
			if (_currentConfiguration) {
				var fileName : String = Strings.sprintf (CONFIG_FILE_NAME_TEMPLATE, 
					_currentConfiguration.name, _currentConfiguration.hash, _fileExtension);
				var file : File = _homeDir.resolvePath (fileName);
				if (file.exists) {
					var fileDeletionError : Error = null;
					try {
						file.deleteFile();
					} catch (e : Error) {
						fileDeletionError = e;
					}
				}
				if (Assertions.fileDeleted (file, fileDeletionError)) {
					_mustUpdateConfigurations = true;
					return (new OperationResult (OperationResult.OPERATION_DELETE, true, null, _currentConfiguration));
				}
			}
			return (new OperationResult (OperationResult.OPERATION_DELETE, false, OperationResult.REASON_ERROR, null));
		}
		
		/**
		 * "Renames" the Configuration that was previously set as "current", both on disk and in-memory. Renaming
		 * is denied for built-in Configurations. This is a restriction that cannot be circumvented.
		 * 
		 * NOTE: by design, Configurations are immutable entities. Thus, in order to "rename" an existing 
		 * Configuration, a new one is created that copies all the properties of the existing one, except name.
		 * The "old" configuration is then discarded, and the new one takes its place, both on-disk and in-memory.
		 * 
		 * @param	newName
		 * 			The name to use instead of the current one.
		 * 
		 * @param	force
		 * 			Optional, defaults to `false`. If `true`, permits operation even if it would result in another
		 * 			user Configuration being overwritten. The operation is always denied if it would result in a
		 * 			built-in (aka "system") configuration being overwritten.
		 * 
		 * @return Returns an OperationResult instance with information about the outcome.
		 */
		public function renameCurrentConfiguration (newName : String, force : Boolean = false) : OperationResult {
			if (_currentConfiguration) {
				if (_currentConfiguration.isReadOnly) {
					return (new OperationResult (OperationResult.OPERATION_RENAME, false, 
						OperationResult.REASON_OVERWRITING_BUILTIN_FILE, _currentConfiguration));
				}
				if (Assertions.isValidFileName (newName)) {
					var newPayload : Payload = (_currentConfiguration.payload.clone() as Payload);
					newPayload.setContent (Constants.META_NAME, newName);
					var newConfiguration : Configuration = new Configuration (newName, false, newPayload, _currentConfiguration.uid, 
						_currentConfiguration.hash);
					deleteCurrentConfiguration();
					_writeConfigurationToFile (newConfiguration, force);
					_mustUpdateConfigurations = true;
					setCurrentConfiguration (newConfiguration.uid, true);
					return (new OperationResult (OperationResult.OPERATION_RENAME, true, null, newConfiguration));
				}
			}
			return (new OperationResult (OperationResult.OPERATION_RENAME, false, OperationResult.REASON_ERROR, null));
		}
		
		
		/**
		 * Stores given `configurations` as files inside the "built-in cache directory".
		 * 
		 * @see PresetManager.ROOT_HOME_DIRECTORY
		 * @see PresetManager.BUILTIN_CACHE_DIR_NAME
		 * 
		 * @param	configurations
		 * 			List with Configuration objects to serialize and store on disk.
		 */
		private function _cacheBuiltinConfigurations (configurations : Vector.<Configuration>) : void {
			for (var i : int = 0; i < configurations.length; i++) {
				var configuration : Configuration = configurations[i];
				if (configuration && configuration.isReadOnly) {
					_writeConfigurationToFile (configuration);
				}
			}
		}
		
		/**
		 * Attempts to load and parse a Configuration that has been previously serialized to
		 * the given file.
		 * 
		 * @throws	When any of the following situations occur:
		 * 			- if provided `file` argument was `null`;
		 * 
		 * 			- if provided `file` argument points to a File that does not exist on disk;
		 * 
		 * 			- if provided `file` argument points to a File the user running the application
		 * 			  does not have the right to read.
		 * 			
		 * 			- if reading the provided `file` produced an empty ByteArray.
		 * 
		 * 			- if the ByteArray produced by reading the provided `file` cannot be interpreted
		 * 			  as a serialized Payload.
		 * 
		 * 			- if the unserialized Payload obtained by reading the provided `file` contains
re		 *
  		 * @return	Returns the resulting Configuration instance on success, or `null` on failure.
		 */
		private function _readConfigurationFromFile (file : File) : Configuration {
			if (Assertions.fileIsNotNull (file) && Assertions.fileExists (file) && Assertions.fileIsReadable (file)) {
				var reader : RawDiskReader = new RawDiskReader;
				var bytes : ByteArray = (reader.readContent(file) as ByteArray);
				if (Assertions.notEmpty (bytes)) {
					var payload : Payload = (DataElement.fromSerialized (bytes, Payload, getQualifiedClassName(Payload)) as Payload);
					if (Assertions.isValidPayload (payload)) {
						var name : String = payload.getContent (Constants.META_NAME) as String;
						var parentPath : String = file.parent.nativePath;
						var isReadOnly : Boolean = (parentPath == _alternateSystemHomeDir.nativePath) ||
								(parentPath == _builtinCacheDir.nativePath) ||
								(payload.getContent (Constants.META_READONLY) as Boolean);
						var uid : String = payload.getContent (Constants.META_UID) as String;
						var hash : String = payload.getContent (Constants.META_HASH) as String;
						if (Assertions.isCorrectMetadata (name, isReadOnly, uid, hash)) {
							return (new Configuration (name, isReadOnly, payload, uid, hash));
						}
					}
				}
			}
			return null;
		}
		
		/**
		 * Attempts to serialize and write a given Configuration to disk.
		 *
		 * @param	configuration
		 *          A Configuration instance to serialize and save to disk. The exact location
		 *          where the new file will be stored depends on the `isReadOnly` property of the
		 *          Configuration being saved, namely:
		 *
		 *          - user-provided Configurations will be stored in a "home directory" that is
		 *            relative to the `PresetManager.ROOT_HOME_DIRECTORY` location;
		 *
		 *          - built-in (or "read-only") Configurations will be stored in a sub-folder
		 *            of the aforementioned "home directory", by the name of the
		 *           `PresetManager.BUILTIN_CACHE_DIR_NAME` constant.
		 *
		 * @param	force
		 *
		 * @throws  When any of the following situations occur:
		 *          - TODO: PROVIDE COMPLETE LIST
		 *
		 * @return  Returns an OperationResult instance with information about the outcome.
		 *          Writing was successful if the returned OperationResult instance's `success`
		 *          field contains `true`.
		 */
		private function _writeConfigurationToFile (configuration : Configuration, force : Boolean = false) : OperationResult {
			var fileName : String = Strings.sprintf (CONFIG_FILE_NAME_TEMPLATE, configuration.name, configuration.hash, _fileExtension);
			var file : File = (configuration.isReadOnly? _builtinCacheDir : _homeDir).resolvePath (fileName);
			if (file.exists) {
				var fileNotOverridable : Boolean = (file.parent == _builtinCacheDir);
				if (fileNotOverridable) {
					return (new OperationResult (OperationResult.OPERATION_SAVE, false, OperationResult.REASON_OVERWRITING_BUILTIN_FILE, configuration));
				}
				if (!force) {
					return (new OperationResult (OperationResult.OPERATION_SAVE, false, OperationResult.REASON_OVERWRITING, configuration));
				}
			}
			var writer : RawDiskWritter = new RawDiskWritter;
			var bytes : ByteArray = configuration.bytes;
			var numWrittenBytes : uint = writer.write (bytes, file);
			if (Assertions.notZero (numWrittenBytes)) {
				_mustUpdateConfigurations = true;
				return (new OperationResult (OperationResult.OPERATION_SAVE, true, null, configuration));
			}
			return null;
		}		

	}
}