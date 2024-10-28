#cmakedefine CONFIG_EBML_WRITING
#cmakedefine CONFIG_EBML_UNICODE
#cmakedefine CONFIG_DEBUGCHECKS
#cmakedefine CONFIG_STDIO
#cmakedefine CONFIG_DEBUG_LEAKS


#cmakedefine CONFIG_64BITS_SYSTEM

#if (defined(_FILE_OFFSET_BITS) && _FILE_OFFSET_BITS == 64) || defined(CONFIG_64BITS_SYSTEM)
/* Use CONFIG_FILEPOS_64 only on 64 bits systems or 32 bits systems that have _FILE_OFFSET_BITS set to 64. */
#define CONFIG_FILEPOS_64 1
#endif
