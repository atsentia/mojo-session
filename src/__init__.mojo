"""
Mojo Session Library

Pure Mojo HTTP session management.

Example:
    from mojo_session import Session, SessionManager, MemorySessionStore

    var manager = SessionManager()
    var session = manager.get_or_create("")
    session.set("user_id", "123")
    manager.save(session)
"""

from .session import (
    Session,
    SessionManager,
    MemorySessionStore,
    generate_session_id,
)
