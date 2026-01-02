"""
Session Tests
"""

from mojo_session import Session, SessionManager, MemorySessionStore, generate_session_id


fn test_session_id_generation() raises:
    """Test session ID generation."""
    var id1 = generate_session_id()
    var id2 = generate_session_id()

    if len(id1) != 32:
        raise Error("Session ID should be 32 chars, got " + str(len(id1)))

    if id1 == id2:
        raise Error("Session IDs should be unique")

    print("✓ Session ID generation works")


fn test_session_basic() raises:
    """Test basic session operations."""
    var session = Session()

    session.set("user_id", "123")
    session.set("username", "alice")

    var user_id = session.get("user_id")
    if not user_id or user_id.value() != "123":
        raise Error("Session get failed")

    if session.size() != 2:
        raise Error("Session should have 2 keys")

    print("✓ Session basic operations work")


fn test_session_update() raises:
    """Test updating session value."""
    var session = Session()

    session.set("key", "value1")
    session.set("key", "value2")

    var value = session.get("key")
    if not value or value.value() != "value2":
        raise Error("Session update failed")

    if session.size() != 1:
        raise Error("Session should have 1 key after update")

    print("✓ Session update works")


fn test_session_remove() raises:
    """Test removing session key."""
    var session = Session()

    session.set("key", "value")
    if not session.remove("key"):
        raise Error("Session remove should return True")

    if session.contains("key"):
        raise Error("Key should be removed")

    if session.remove("key"):
        raise Error("Session remove should return False for non-existing key")

    print("✓ Session remove works")


fn test_session_clear() raises:
    """Test clearing session."""
    var session = Session()

    session.set("a", "1")
    session.set("b", "2")
    session.clear()

    if session.size() != 0:
        raise Error("Session should be empty after clear")

    print("✓ Session clear works")


fn test_session_regenerate() raises:
    """Test session ID regeneration."""
    var session = Session()
    var old_id = session.id

    session.regenerate_id()

    if session.id == old_id:
        raise Error("Session ID should change after regenerate")

    print("✓ Session regenerate works")


fn test_memory_store_basic() raises:
    """Test memory session store."""
    var store = MemorySessionStore()
    store.set_time(0)

    var session = Session()
    session.set("key", "value")

    store.save(session)

    var loaded = store.load(session.id)
    if not loaded:
        raise Error("Session should be loaded from store")

    var value = loaded.value().get("key")
    if not value or value.value() != "value":
        raise Error("Session data should be preserved")

    print("✓ Memory store basic operations work")


fn test_memory_store_expiry() raises:
    """Test session expiry in store."""
    var store = MemorySessionStore(default_ttl_ms=1000)
    store.set_time(0)

    var session = Session()
    store.save(session)

    # Advance past TTL
    store.advance_time(1500)

    var loaded = store.load(session.id)
    if loaded:
        raise Error("Expired session should not be loaded")

    print("✓ Memory store expiry works")


fn test_memory_store_delete() raises:
    """Test deleting session from store."""
    var store = MemorySessionStore()
    store.set_time(0)

    var session = Session()
    store.save(session)

    if not store.delete(session.id):
        raise Error("Delete should return True for existing session")

    if store.exists(session.id):
        raise Error("Session should not exist after delete")

    print("✓ Memory store delete works")


fn test_memory_store_cleanup() raises:
    """Test cleanup of expired sessions."""
    var store = MemorySessionStore(default_ttl_ms=1000)
    store.set_time(0)

    for i in range(5):
        var session = Session()
        store.save(session)

    if store.count() != 5:
        raise Error("Store should have 5 sessions")

    store.advance_time(1500)
    store.cleanup()

    if store.count() != 0:
        raise Error("Store should be empty after cleanup")

    print("✓ Memory store cleanup works")


fn test_session_manager() raises:
    """Test session manager."""
    var manager = SessionManager()

    var session1 = manager.get_or_create("")
    session1.set("user", "alice")
    manager.save(session1)

    var session2 = manager.get_or_create(session1.id)
    var user = session2.get("user")
    if not user or user.value() != "alice":
        raise Error("Session manager should load existing session")

    print("✓ Session manager works")


fn test_cookie_header() raises:
    """Test cookie header generation."""
    var manager = SessionManager(cookie_name="my_session")
    var session = Session()

    var header = manager.set_cookie_header(session)

    if not header.startswith("my_session="):
        raise Error("Cookie header should start with cookie name")

    if "HttpOnly" not in header:
        raise Error("Cookie header should contain HttpOnly")

    if "Secure" not in header:
        raise Error("Cookie header should contain Secure")

    print("✓ Cookie header generation works")


fn test_cookie_parsing() raises:
    """Test cookie parsing."""
    var manager = SessionManager(cookie_name="session_id")

    var session_id = manager.parse_cookie("session_id=abc123; other=value")
    if session_id != "abc123":
        raise Error("Should parse session_id from cookie: got '" + session_id + "'")

    var empty = manager.parse_cookie("other=value")
    if empty != "":
        raise Error("Should return empty string when cookie not found")

    print("✓ Cookie parsing works")


fn main() raises:
    print("Running Session tests...\n")

    test_session_id_generation()
    test_session_basic()
    test_session_update()
    test_session_remove()
    test_session_clear()
    test_session_regenerate()
    test_memory_store_basic()
    test_memory_store_expiry()
    test_memory_store_delete()
    test_memory_store_cleanup()
    test_session_manager()
    test_cookie_header()
    test_cookie_parsing()

    print("\n✅ All Session tests passed!")
