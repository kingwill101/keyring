/// An in-memory credential store for web platforms and testing.
///
/// Uses a `HashMap`-backed store that lives only for the duration of the
/// current process. Suitable for web applications where native secure
/// storage APIs are unavailable.
///
/// See [WebKeyringStore] for implementation details.
library;
export 'src/web_store.dart';
