package eu.claudius.iacob.desktop.presetmanager.lib {
	
	public class Constants {
		public function Constants() {}
		
		public static const META_NAME : String = 'name';
		public static const META_READONLY : String = 'isReadOnly';
		public static const META_UID : String = 'uid';
		public static const META_HASH : String = 'hash';
		
		public static const CONFIG_NAME_MAX_CHARS : uint = 48;
		public static const SHA256_HASH_LENGTH : uint = 64;
		public static const HASH_START_INDEX : uint = 32;
	}
}