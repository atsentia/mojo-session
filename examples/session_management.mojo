"""
Example: HTTP Session Management

Demonstrates:
- Creating and managing sessions
- Storing session data
- Session expiration
- Integration with HTTP handlers
"""

from mojo_session import Session, SessionManager, MemorySessionStore, generate_session_id


fn basic_session_example():
    """Basic session creation and usage."""
    print("=== Basic Session Example ===")

    # Create session manager with in-memory store
    var manager = SessionManager()

    # Create a new session
    var session_id = generate_session_id()
    var session = manager.get_or_create(session_id)
    print("Created session: " + session.id[:16] + "...")

    # Store user data
    session.set("user_id", "12345")
    session.set("username", "alice")
    session.set("role", "admin")
    print("Stored user data in session")

    # Retrieve data
    var user_id = session.get("user_id")
    var username = session.get("username")
    print("Retrieved: user_id=" + user_id + ", username=" + username)

    # Save session
    manager.save(session)
    print("")


fn http_integration_example():
    """Session integration with HTTP requests."""
    print("=== HTTP Integration Pattern ===")

    var manager = SessionManager()

    # Simulating incoming HTTP request with session cookie
    fn handle_request(manager: SessionManager, session_cookie: String) -> String:
        # Get or create session
        var session = manager.get_or_create(session_cookie)

        # Check if user is logged in
        var user_id = session.get("user_id")
        if user_id == "":
            return "Please log in"

        var username = session.get("username")
        return "Welcome back, " + username + "!"

    # First request (no session)
    var response1 = handle_request(manager, "")
    print("Request 1 (no session): " + response1)

    # Login - create session with user data
    var session = manager.get_or_create("")
    session.set("user_id", "42")
    session.set("username", "bob")
    manager.save(session)
    var session_cookie = session.id

    # Second request (with session)
    var response2 = handle_request(manager, session_cookie)
    print("Request 2 (with session): " + response2)
    print("")


fn session_expiration_example():
    """Session expiration handling."""
    print("=== Session Expiration ===")

    # Create manager with 30 minute timeout
    var store = MemorySessionStore(timeout_minutes=30)
    var manager = SessionManager(store)

    var session = manager.get_or_create("")
    session.set("data", "important")
    manager.save(session)

    print("Session created with 30 minute timeout")
    print("Session ID: " + session.id[:16] + "...")

    # Check if session is valid
    var is_valid = manager.is_valid(session.id)
    print("Is valid: " + String(is_valid))

    # Destroy session (logout)
    manager.destroy(session.id)
    print("Session destroyed (logout)")

    is_valid = manager.is_valid(session.id)
    print("Is valid after destroy: " + String(is_valid))
    print("")


fn main():
    print("mojo-session: Pure Mojo HTTP Session Management\n")

    basic_session_example()
    http_integration_example()
    session_expiration_example()

    print("=" * 50)
    print("Features:")
    print("  - Secure session ID generation")
    print("  - In-memory session store")
    print("  - Configurable expiration")
    print("  - Thread-safe operations")
