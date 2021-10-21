package eu.claudius.iacob.desktop.presetmanager.lib {
	import flash.utils.ByteArray;
	
	import ro.ciacob.utils.Strings;
	import eu.claudius.iacob.desktop.presetmanager.lib.Assertions;
	import eu.claudius.iacob.desktop.presetmanager.lib.Constants;
	import eu.claudius.iacob.desktop.presetmanager.lib.Payload;
	
	/**
	 * A Configuration is essentially a container for a Payload. Unlike Payloads, which are
	 * (per se) volatile, Configurations are serializable entities that can, and are stored
	 * on disk. So, in a way, a Configuration is a Payload that has been given a name and is
	 * stored on disk.
	 *
	 * By design, Configurations are meant to be immutable entities. One does not update a
	 * Configuration; when the need arises, one replaces it with another Configuration, which
	 * has been rebuilt from scratch with different content.
	 */
	public class Configuration {
		
		private var _name : String;
		private var _uid : String;
		private var _hash : String;
		private var _payload : Payload;
		private var _isReadOnly : Boolean;
		
		/**
		 * Constructor for class Configuration.
		 * 
		 * @param	name
		 * 			A name to associate with this Configuration. The name need not be unique.
		 * 			In order to overwrite an existing Configuration, one creates and saves to
		 * 			disk another Configuration, by the name of an existing one.
		 * 
		 * @param	isReadOnly
		 * 			Whether this Configuration instance should be deemed as read-only (which
		 * 			will deny any request of deleting or overwriting it).
		 * 
		 * @param	payload
		 * 			The Payload instance to be stored inside this Configuration. It will
		 * 			be transparently augmented with Configuration's own data (`name`, `uid`,
		 * 			`hash`, read only status).
		 * 
		 * @param	uid
		 * 			Optional. A unique ID to be associated with this configuration. When reading
		 * 			a Configuration from disk, this should be explicitly set to the value 
		 * 			retrieved. If left unset, it will be populated internally.
		 * 
		 * @param	hash
		 * 			Optional. A unique hash that reflects the Payload stored inside this 
		 * 			Configuration. When reading a Configuration from disk, this should be 
		 * 			explicitly set to the value retrieved. If left unset, it will be populated
		 * 			internally.
		 * 
		 * @throws	Runs several assertions to ensure proper input. Can throw one or more of the
		 * 			following ArgumentErrors:
		 * 			- TODO: PROVIDE COMPLETE LIST
		 * 			
		 */
		public function Configuration (name: String, isReadOnly : Boolean, payload : Payload, uid : String = null, hash : String = null) {
			if (Assertions.isValidFileName (name) && Assertions.isValidPayload (payload)) {
				_name = name;
				_isReadOnly = isReadOnly;
				_uid = uid || Strings.UUID;
				_hash = hash || payload.getHash ();
				_payload = _augmentPayload (payload, _name, _isReadOnly, _uid, _hash);
			}
		}
		
		/**
		 * Returns the name associated with this Configuration instance. Configuration names are
		 * not unique.
		 */
		public function get name () : String {
			return _name;
		}
		
		/**
		 * Returns a globally unique ID associated with this Configuration instance. UIDs are
		 * internally generated at instance creation.
		 */
		public function get uid () : String {
			return _uid;
		}
		
		/**
		 * Returns a SHA-256 hash that uniquely represents the Payload stored inside this
		 * Configuration. Hashes are internally computed at instance creation.
		 */
		public function get hash () : String {
			return _hash;
		}
		
		/**
		 * Returns the read-only setting associated with this Configuration instance. "Read-only"
		 * instances will deny any request of deleting or overwriting them.
		 */
		public function get isReadOnly ()  : Boolean {
			return _isReadOnly;
		}
		
		/**
		 * A detached copy of the Payload instance to stored inside this Configuration.
		 * Modifying this copy has no practical effect. This is in-line with the design
		 * of Configurations as immutable entities.
		 */
		public function get payload () : Payload {
			return _payload.clone() as Payload;
		}
		
		/**
		 * Returns the serialized, disk-ready form of this Configuration.
		 */
		public function get bytes () : ByteArray {
			return _payload.toSerialized();
		}
		
		/**
		 * Stores all information about the Configuration container inside the contained Payload.
		 * We do this in order to benefit from the built-in serialization and deserialization
		 * abilities of the Payload class. This way, in order to store a Configuration to disk, we
		 * simply serialize its Payload and save the resulting ByteArray.
		 */
		private function _augmentPayload (payload : Payload, name : String, isReadOnly : Boolean, uid : String, hash : String) : Payload {
			payload.setContent (Constants.META_NAME, name);
			payload.setContent (Constants.META_READONLY, isReadOnly);
			payload.setContent (Constants.META_UID, uid);
			payload.setContent (Constants.META_HASH, hash);
			return payload;
		}
	}
}