// Compatibility shims for compiling on newer BYOND versions.

/// Calls a proc in an external library. 515+ requires call_ext() for non-constant library names.
#if DM_VERSION >= 515
#define LIBCALL call_ext
#else
#define LIBCALL call
#endif
