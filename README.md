# mojo-session

Pure Mojo HTTP session management.

## Features

- **Session Management** - Create, read, update, delete sessions
- **Memory Store** - In-memory session storage
- **Secure IDs** - Cryptographically random session IDs
- **Key-Value Data** - Flexible session data storage

## Installation

```bash
pixi add mojo-session
```

## Quick Start

### Basic Usage

```mojo
from mojo_session import Session, SessionManager, MemorySessionStore

# Create manager with memory store
var manager = SessionManager()

# Get or create session
var session = manager.get_or_create("")

# Store data
session.set("user_id", "123")
session.set("username", "alice")

# Save session
manager.save(session)

# Retrieve session later
var session_id = session.id()
var existing = manager.get_or_create(session_id)
print(existing.get("user_id"))  # "123"
```

### HTTP Integration

```mojo
from mojo_session import SessionManager, generate_session_id

fn handle_request(headers: Dict[String, String]) -> Response:
    var manager = SessionManager()
    
    # Get session ID from cookie
    var session_id = headers.get("Cookie", "")
    var session = manager.get_or_create(session_id)
    
    # Check if logged in
    if session.get("user_id") != "":
        return Response(200, "Welcome back!")
    
    return Response(401, "Please log in")
```

## API Reference

| Class | Description |
|-------|-------------|
| `Session` | Session data container |
| `SessionManager` | Session lifecycle management |
| `MemorySessionStore` | In-memory session storage |

| Method | Description |
|--------|-------------|
| `get_or_create(id)` | Get existing or create new session |
| `save(session)` | Persist session data |
| `delete(id)` | Remove session |
| `generate_session_id()` | Create secure random ID |

## Testing

```bash
mojo run tests/test_session.mojo
```

## License

Apache 2.0

## Part of mojo-contrib

This library is part of [mojo-contrib](https://github.com/atsentia/mojo-contrib), a collection of pure Mojo libraries.
