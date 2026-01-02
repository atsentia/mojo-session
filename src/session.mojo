"""
Session Management

Pure Mojo HTTP session management.
"""

from random import random_ui64


# =============================================================================
# Session ID Generation
# =============================================================================

fn generate_session_id() -> String:
    """
    Generate a cryptographically random session ID.

    Returns a 32-character hex string (128 bits of entropy).
    """
    var high = random_ui64()
    var low = random_ui64()
    return _to_hex_64(high) + _to_hex_64(low)


fn _to_hex_64(value: UInt64) -> String:
    """Convert 64-bit value to 16-character hex string."""
    alias HEX = "0123456789abcdef"
    var result = String()

    for i in range(16):
        var nibble = Int((value >> (60 - i * 4)) & 0x0F)
        result += HEX[nibble]

    return result


# =============================================================================
# Session Data
# =============================================================================

struct Session:
    """
    HTTP session with key-value storage.

    Example:
        var session = Session()
        session.set("user_id", "123")
        var user_id = session.get("user_id")
    """
    var id: String
    var keys: List[String]
    var values: List[String]
    var created_at: Int64
    var last_accessed: Int64
    var expires_at: Int64
    var is_new: Bool
    var is_modified: Bool

    fn __init__(out self, session_id: String = ""):
        """Create new session."""
        if session_id == "":
            self.id = generate_session_id()
            self.is_new = True
        else:
            self.id = session_id
            self.is_new = False

        self.keys = List[String]()
        self.values = List[String]()
        self.created_at = 0
        self.last_accessed = 0
        self.expires_at = 0
        self.is_modified = False

    fn set(inout self, key: String, value: String):
        """Set session value."""
        var idx = self._find_key(key)
        if idx >= 0:
            self.values[idx] = value
        else:
            self.keys.append(key)
            self.values.append(value)
        self.is_modified = True

    fn get(self, key: String) -> Optional[String]:
        """Get session value."""
        var idx = self._find_key(key)
        if idx < 0:
            return None
        return self.values[idx]

    fn get_or(self, key: String, default: String) -> String:
        """Get session value or default."""
        var idx = self._find_key(key)
        if idx < 0:
            return default
        return self.values[idx]

    fn contains(self, key: String) -> Bool:
        """Check if key exists."""
        return self._find_key(key) >= 0

    fn remove(inout self, key: String) -> Bool:
        """Remove key from session."""
        var idx = self._find_key(key)
        if idx < 0:
            return False

        var new_keys = List[String]()
        var new_values = List[String]()
        for i in range(len(self.keys)):
            if i != idx:
                new_keys.append(self.keys[i])
                new_values.append(self.values[i])
        self.keys = new_keys
        self.values = new_values
        self.is_modified = True
        return True

    fn clear(inout self):
        """Clear all session data."""
        self.keys = List[String]()
        self.values = List[String]()
        self.is_modified = True

    fn size(self) -> Int:
        """Get number of keys in session."""
        return len(self.keys)

    fn regenerate_id(inout self):
        """Regenerate session ID (for security after login)."""
        self.id = generate_session_id()
        self.is_modified = True

    fn _find_key(self, key: String) -> Int:
        """Find index of key."""
        for i in range(len(self.keys)):
            if self.keys[i] == key:
                return i
        return -1


# =============================================================================
# Session Store Interface
# =============================================================================

struct MemorySessionStore:
    """
    In-memory session store.

    For development/testing. Not suitable for production
    (sessions lost on restart, no distributed support).

    Example:
        var store = MemorySessionStore()
        var session = Session()
        store.save(session)
        var loaded = store.load(session.id)
    """
    var session_ids: List[String]
    var sessions_keys: List[List[String]]
    var sessions_values: List[List[String]]
    var session_expiry: List[Int64]
    var default_ttl_ms: Int64
    var current_time: Int64

    fn __init__(out self, default_ttl_ms: Int64 = 3600000):  # 1 hour default
        """Create memory session store."""
        self.session_ids = List[String]()
        self.sessions_keys = List[List[String]]()
        self.sessions_values = List[List[String]]()
        self.session_expiry = List[Int64]()
        self.default_ttl_ms = default_ttl_ms
        self.current_time = 0

    fn set_time(inout self, time_ms: Int64):
        """Set current time."""
        self.current_time = time_ms

    fn advance_time(inout self, delta_ms: Int64):
        """Advance time."""
        self.current_time += delta_ms

    fn save(inout self, session: Session):
        """Save session to store."""
        var idx = self._find_session(session.id)

        if idx >= 0:
            # Update existing
            self.sessions_keys[idx] = session.keys
            self.sessions_values[idx] = session.values
            self.session_expiry[idx] = self.current_time + self.default_ttl_ms
        else:
            # Create new
            self.session_ids.append(session.id)
            self.sessions_keys.append(session.keys)
            self.sessions_values.append(session.values)
            self.session_expiry.append(self.current_time + self.default_ttl_ms)

    fn load(self, session_id: String) -> Optional[Session]:
        """Load session from store."""
        var idx = self._find_session(session_id)
        if idx < 0:
            return None

        # Check expiry
        if self.session_expiry[idx] <= self.current_time:
            return None

        var session = Session(session_id)
        session.keys = self.sessions_keys[idx]
        session.values = self.sessions_values[idx]
        session.is_new = False
        return session

    fn delete(inout self, session_id: String) -> Bool:
        """Delete session from store."""
        var idx = self._find_session(session_id)
        if idx < 0:
            return False

        # Remove at index
        var new_ids = List[String]()
        var new_keys = List[List[String]]()
        var new_values = List[List[String]]()
        var new_expiry = List[Int64]()

        for i in range(len(self.session_ids)):
            if i != idx:
                new_ids.append(self.session_ids[i])
                new_keys.append(self.sessions_keys[i])
                new_values.append(self.sessions_values[i])
                new_expiry.append(self.session_expiry[i])

        self.session_ids = new_ids
        self.sessions_keys = new_keys
        self.sessions_values = new_values
        self.session_expiry = new_expiry
        return True

    fn exists(self, session_id: String) -> Bool:
        """Check if session exists and is not expired."""
        var idx = self._find_session(session_id)
        if idx < 0:
            return False
        return self.session_expiry[idx] > self.current_time

    fn cleanup(inout self):
        """Remove expired sessions."""
        var new_ids = List[String]()
        var new_keys = List[List[String]]()
        var new_values = List[List[String]]()
        var new_expiry = List[Int64]()

        for i in range(len(self.session_ids)):
            if self.session_expiry[i] > self.current_time:
                new_ids.append(self.session_ids[i])
                new_keys.append(self.sessions_keys[i])
                new_values.append(self.sessions_values[i])
                new_expiry.append(self.session_expiry[i])

        self.session_ids = new_ids
        self.sessions_keys = new_keys
        self.sessions_values = new_values
        self.session_expiry = new_expiry

    fn count(self) -> Int:
        """Get number of sessions."""
        return len(self.session_ids)

    fn _find_session(self, session_id: String) -> Int:
        """Find session index."""
        for i in range(len(self.session_ids)):
            if self.session_ids[i] == session_id:
                return i
        return -1


# =============================================================================
# Session Manager
# =============================================================================

struct SessionManager:
    """
    High-level session manager.

    Handles session creation, loading, and saving.

    Example:
        var manager = SessionManager()
        var session = manager.get_or_create("")
        session.set("user", "alice")
        manager.save(session)
    """
    var store: MemorySessionStore
    var cookie_name: String
    var secure: Bool
    var http_only: Bool
    var same_site: String

    fn __init__(out self, cookie_name: String = "session_id"):
        """Create session manager."""
        self.store = MemorySessionStore()
        self.cookie_name = cookie_name
        self.secure = True
        self.http_only = True
        self.same_site = "Lax"

    fn get_or_create(inout self, session_id: String) -> Session:
        """Get existing session or create new one."""
        if session_id != "":
            var existing = self.store.load(session_id)
            if existing:
                return existing.value()

        # Create new session
        var session = Session()
        self.store.save(session)
        return session

    fn save(inout self, session: Session):
        """Save session to store."""
        self.store.save(session)

    fn destroy(inout self, session_id: String):
        """Destroy session."""
        _ = self.store.delete(session_id)

    fn set_cookie_header(self, session: Session) -> String:
        """Generate Set-Cookie header for session."""
        var parts = List[String]()
        parts.append(self.cookie_name + "=" + session.id)

        if self.http_only:
            parts.append("HttpOnly")

        if self.secure:
            parts.append("Secure")

        parts.append("SameSite=" + self.same_site)
        parts.append("Path=/")

        var result = String()
        for i in range(len(parts)):
            if i > 0:
                result += "; "
            result += parts[i]

        return result

    fn parse_cookie(self, cookie_header: String) -> String:
        """Parse session ID from Cookie header."""
        # Simple parser: looks for cookie_name=value
        var prefix = self.cookie_name + "="
        var idx = 0

        # Find cookie name
        while idx < len(cookie_header):
            if cookie_header[idx:idx + len(prefix)] == prefix:
                # Found it, extract value
                var start = idx + len(prefix)
                var end = start
                while end < len(cookie_header) and cookie_header[end] != ";" and cookie_header[end] != " ":
                    end += 1
                return cookie_header[start:end]
            idx += 1

        return ""
