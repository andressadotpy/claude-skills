---
name: openstack-swift-engineer
description: OpenStack Swift-specific development guidelines and best practices. Inherits all OpenStack/OpenInfra policies from openstack-engineer and adds Swift coding standards, testing requirements, and architectural patterns.
version: 1.0.0
user-invocable: false
inherits: openstack-engineer
---

# OpenStack Swift Engineer Guidelines

Swift-specific development guidelines for contributing to OpenStack Swift. This skill inherits all requirements from openstack-engineer and adds Swift-specific standards.

**IMPORTANT**: All bash commands (.unittests, .probetests, swift-init, etc.) are executed by the user inside the SAIO machine, not by Claude. Claude provides guidance and analysis, while the user runs the commands and reports results back.

## Swift Coding Standards

### PEP 8 Compliance
- **REQUIRED**: Follow PEP 8 guidelines (python.org/dev/peps/pep-0008/)
- Enforced using flake8 with OpenStack hacking module
- Integrate flake8+hacking with your editor for automated checking
- Avoid getting caught by Jenkins - run locally first

### Running Style Checks

```bash
# Run flake8 before submitting
tox -e pep8

# Or run directly
flake8 swift test doc setup.py
```

## Swift Testing Requirements

### Comprehensive Test Suite
Swift maintains comprehensive tests that MUST be kept up-to-date:
- **Unit tests**: Test individual functions and classes in isolation
- **Functional tests**: Black-box API tests
- **Probe tests**: White-box cluster validation tests

### Running Tests

```bash
# Run all tests
./.alltests

# Run only unit tests
./.unittests

# Run only functional tests
./.functests

# Run only probe tests
./.probetests

# Run specific test file
cd test/unit/obj && pytest test_diskfile.py
```

### Test Prerequisites
- Upgrade pip and virtualenv to meet OpenStack requirements
- Install tox: `pip install tox`
- Install distribution packages: `tox -e bindep`

### Test Environment Variables

**Storage Policy Testing:**
```bash
SWIFT_TEST_POLICY=gold  # Test with specific policy
```

**In-Process Functional Testing:**
```bash
SWIFT_TEST_IN_PROCESS=1  # Run against in-process Swift
SWIFT_TEST_IN_MEMORY_OBJ=1  # Use in-memory object server
SWIFT_TEST_IN_PROCESS_CONF_LOADER=ec  # Load EC or encryption config
SWIFT_TEST_DEBUG_LOGS=1  # Enable debug logging to stdout
```

**Note**: Variables matching `SWIFT_*` and `*_proxy` are passed to test environments (requires tox >=2.0.0)

### Test Coverage Expectations
- **New features**: Must include unit tests and probe/functional tests
- **Bug fixes**: Must include test that would have caught the bug
- **Refactoring**: Existing tests must continue to pass
- **Edge cases**: Test error paths and boundary conditions

## Documentation Standards

### Docstring Format (PEP 257)

**Requirements:**
1. Triple quotes for all docstrings
2. Single-line docstrings on one line only
3. Multi-line docstrings need newline after opening and before closing quotes
4. Use reStructuredText markup for Sphinx

**Examples:**

```python
def simple_function():
    """This is a simple one-line docstring."""
    pass

def complex_function(param1, param2):
    """
    Brief summary of what this function does.

    More detailed explanation if necessary. Can span multiple
    paragraphs.

    :param param1: Description of param1
    :param param2: Description of param2
    :returns: Description of return value
    :raises ExceptionType: When this exception is raised
    """
    pass
```

### Building Documentation

```bash
# Install requirements
pip install -r requirements.txt
pip install -r doc/requirements.txt

# Build docs
sphinx-build -W -b html doc/source doc/build/html

# View docs
firefox doc/build/html/index.html
```

## Swift Architecture Knowledge

### Core Components

**Storage Servers:**
- **Proxy Server**: Entry point, routes requests (swift/proxy/server.py)
- **Object Server**: Stores object data (swift/obj/server.py)
- **Container Server**: Manages container metadata (swift/container/server.py)
- **Account Server**: Manages account metadata (swift/account/server.py)

**Background Services:**
- Replicators: Data consistency across cluster
- Auditors: Verify data integrity, quarantine corrupted data
- Updaters: Async metadata updates
- Reconcilers: Handle object overwrites in erasure coding

### Key Concepts

**The Ring:**
- Consistent hashing ring determines data placement
- Partition power, replicas, and zones
- Located in swift/common/ring/

**Quarantine Operations:**
- `quarantine_renamer()`: Quarantines file's parent directory
- `quarantine_dir_renamer()`: Quarantines directory directly
- Used when data corruption detected
- Located in swift/obj/diskfile.py

**Database Operations:**
- SQLite for account/container metadata
- Must use proper locking (lock_path, with statements)
- Located in swift/common/db.py

**WSGI/Swob:**
- Request/Response objects in swift/common/swob.py
- Middleware in swift/common/middleware/
- WSGI server utilities in swift/common/wsgi.py

**Eventlet:**
- Non-blocking I/O for concurrency
- Green threads, not OS threads
- Must avoid blocking operations

## Swift-Specific Patterns

### Error Handling

**Use appropriate exception types:**
```python
from swift.common.exceptions import DiskFileError, DiskFileNotExist
from swift.obj.diskfile import DiskFileDeleted, DiskFileQuarantined

# Filesystem errors
except (OSError, IOError) as e:
    if e.errno == errno.ENOENT:
        # Handle missing file
    elif e.errno == errno.EACCES:
        # Handle permission denied

# Swift-specific errors
except DiskFileNotExist:
    # Object doesn't exist
except DiskFileQuarantined:
    # Object was quarantined
```

**Don't catch too broadly:**
```python
# BAD - catches everything
try:
    do_something()
except Exception:
    pass

# GOOD - specific exceptions
try:
    do_something()
except (OSError, IOError) as e:
    if e.errno not in (errno.ENOENT, errno.ENODATA):
        raise
```

### Ring Operations

```python
from swift.common.ring import Ring

# Load the ring
ring = Ring('/etc/swift/object.ring.gz')

# Get partition for account/container/object
partition = ring.get_part(account, container, obj)

# Get nodes for partition
nodes = ring.get_part_nodes(partition)

# Calculate hash
from swift.common.utils import hash_path
obj_hash = hash_path(account, container, obj, 
                     raw_digest=True).hexdigest()
```

### Database Locking

```python
from swift.common.db import lock_path

# Always lock before modifying hashes
partition_dir = '/srv/node/sdb1/objects/123'
with lock_path(partition_dir):
    hashes = read_hashes(partition_dir)
    hashes['abc'] = None  # Invalidate suffix
    write_hashes(partition_dir, hashes)
```

### Quarantine Operations

```python
from swift.obj.diskfile import quarantine_renamer, quarantine_dir_renamer

# Quarantine a corrupted file (quarantines parent directory)
quarantine_path = quarantine_renamer(device_path, corrupted_file_path)

# Quarantine a directory directly
quarantine_path = quarantine_dir_renamer(device_path, hash_directory)
```

## S3 Compatibility Testing

### Test Location
Cross-compatibility tests in test/s3api/ verify Swift S3 API matches AWS S3.

### Configuration

**Option 1**: /etc/swift/test.conf
```ini
[s3api_test]
endpoint = http://127.0.0.1:8080
region = us-east-1
access_key1 = test:tester
secret_key1 = testing
```

**Option 2**: AWS credentials file
```bash
export SWIFT_TEST_AWS_CONFIG_FILE=~/.aws/credentials
```

### Running S3 Tests

```bash
# Run all S3 tests
cd test/s3api && pytest

# Run specific S3 test
pytest test/s3api/test_bucket.py::TestS3ApiBucket::test_put_bucket
```

## Swift Development Workflow

### Local Development with SAIO

```bash
# Start SAIO
vagrant up
vagrant ssh
cd ~/swift

# Make changes to code

# Run tests
./.unittests
./.probetests  # If behavioral changes

# Check style
tox -e pep8

# Restart Swift services to load changes
sudo swift-init main restart

# Monitor logs
sudo tail -f /var/log/syslog | grep swift

# Or check specific service
sudo tail -f /var/log/swift/object-server.log
```

### Submitting Changes

```bash
# Create feature branch
git checkout -b fix-quarantine-issue

# Make changes and test

# Commit with proper message
git add .
git commit

# Submit to Gerrit
git review
```

### Addressing Review Feedback

```bash
# Make requested changes

# Amend the same commit
git add .
git commit --amend

# Update Gerrit
git review
```

## Common Swift Review Points

When reviewing or submitting Swift patches, verify:

**Correctness:**
- [ ] Does it solve the stated problem?
- [ ] Are edge cases handled (None, empty, ENOENT)?
- [ ] Is error handling appropriate and specific?
- [ ] Are filesystem operations safe (race conditions, cleanup)?

**Testing:**
- [ ] Unit tests for new/changed code
- [ ] Probe tests for behavioral changes
- [ ] Edge cases and error paths tested
- [ ] Tests actually test the change (not just coverage)

**Swift Conventions:**
- [ ] Follows PEP 8 (passes flake8)
- [ ] Uses appropriate Swift exception types
- [ ] Proper use of quarantine functions
- [ ] Database operations use locking
- [ ] Eventlet-friendly (no blocking operations)
- [ ] WSGI/swob patterns followed

**Performance:**
- [ ] No obvious performance regressions
- [ ] Efficient filesystem operations
- [ ] Appropriate caching where needed
- [ ] No N+1 patterns

**Documentation:**
- [ ] Docstrings follow PEP 257
- [ ] Config samples updated if needed
- [ ] Commit message explains why, not just what

## Swift-Specific Resources

**Documentation:**
- Swift Developer Documentation: docs.openstack.org/swift/latest/
- Swift API Reference: docs.openstack.org/api-ref/object-store/
- SAIO Guide: docs.openstack.org/swift/latest/development_saio.html

**Code Locations:**
- Gerrit: review.opendev.org/q/project:openstack/swift
- Git: opendev.org/openstack/swift
- Bug Tracking: bugs.launchpad.net/swift

**Community:**
- IRC: #openstack-swift on OFTC
- Mailing List: openstack-discuss@lists.openstack.org (tag [swift])
- Meetings: Weekly on IRC (check wiki for schedule)

## Testing Commands Reference

```bash
# Unit tests
./.unittests                          # All unit tests
cd test/unit/obj && pytest test_*.py  # Specific module

# Functional tests  
./.functests                          # All functional tests
SWIFT_TEST_IN_PROCESS=1 ./.functests  # In-process mode

# Probe tests
./.probetests                         # All probe tests
cd test/probe && pytest test_*.py     # Specific test

# All tests
./.alltests                           # Everything

# Style checks
tox -e pep8                           # flake8 + hacking
flake8 swift test doc setup.py       # Just flake8

# Documentation
tox -e docs                           # Build docs
```

## Key Takeaways

1. **Follow Swift patterns**: Use existing Swift patterns for error handling, quarantine, ring operations
2. **Test comprehensively**: Unit tests + probe/functional tests for changes
3. **Keep tests updated**: Tests are part of the patch, not an afterthought
4. **Use SAIO**: Test changes in realistic environment before submitting
5. **Follow conventions**: PEP 8, proper docstrings, appropriate exception types
6. **Inherit OpenStack standards**: All openstack-engineer requirements apply
