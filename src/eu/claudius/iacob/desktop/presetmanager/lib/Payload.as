package eu.claudius.iacob.desktop.presetmanager.lib {
	
	import flash.utils.ByteArray;
	
	import mx.utils.SHA256;
	
	import ro.ciacob.desktop.data.DataElement;
import ro.ciacob.utils.Objects;

/**
	 * An ordered collection of name-value pairs, implemented as a sub-class of
	 * ro.ciacob.desktop.data.DataElement.
	 * 
	 * @see ro.ciacob.desktop.data.DataElement
	 */
	public class Payload extends DataElement {
		
		public static const FORMAT_JSON : String = 'formatJson'
			
		/**
		 * Constructor for class Payload.
		 * 
		 * @param	rawContent
		 * 			Optional. Name-value pairs to set as "content" in the resulting Payload 
		 * 			instance.
		 * 
		 * 			NOTES:
		 * 			- The `rawContent` Object, once provided as a parameter cannot be retrieved
		 * 			  again; instead, one can use the DataElement methods to access the content
		 * 			  stored inside the Payload instance, e.g., `getContent(key:String)`,
		 * 			  `getContentKeys():Array`, etc.
		 * 
		 * 			- By design, Configurations are meant to be immutable entities. One does
		 * 			  not alter/update a Configuration, one replaces it with another Configuration,
		 * 			  which has been rebuilt from scratch with different content.
		 * 
		 * 			  To cope with that design, one CANNOT alter a Payload retrieved from a
		 * 			  Configuration (despite the fact that DataElement, the super-class of Payload,
		 * 			  has methods that would allow this). That is because the Payload instances
		 * 			  accessible via `Configuration.payload` are DETACHED COPIES, and NOT the actual
		 * 			  Payload stored inside the Configuration. Thus, calling methods such as:
		 * 
		 * 			  `setContent (key:String, content : *)`
		 * 
		 * 			  on the retrieved Payload instance has no practical effect.
		 */
		public function Payload (rawContent : Object = null) {
			super (null, rawContent);
		}
		
		/**
		 * Returns the last 32 chars of a SHA-256 hash that uniquely represents this Payload, more
		 * specifically, its node that stores the user settings as name-value pairs.
		 * 
		 * NOTE: the hash, once digested, is cached; to minimize the CPU hit, on subsequent calls
		 * this function will return the digested hash, if available, rather than running a digest
		 * cycle again.
		 */
		public function getHash () : String {
			var settingsBranch : Payload = getDataChildAt(0) as Payload;
			var userSettings : Object = settingsBranch.getContentMap();
			var tmpStorage : ByteArray = new ByteArray;
			var storageKeys : Array = Objects.getKeys(userSettings, true);
			var i : int;
			var j : int;
			var key : String;
			var value : Object;
			var arrayVal : Array;
			for (i = 0; i < storageKeys.length; i++) {
				key = (storageKeys[i] as String);
				value = userSettings[key];
				tmpStorage.writeUTFBytes (key);
				if (value is int) {
					tmpStorage.writeByte (value as int);
				} else if (value is Array) {
					arrayVal = (value as Array);
					for (j = 0; j < arrayVal.length; j++) {
						tmpStorage.writeByte (arrayVal[j] as int);
					}
				}
			}
			var fullDigest : String = SHA256.computeDigest (tmpStorage);
			return fullDigest.substr (Constants.HASH_START_INDEX);
		}
	}
}