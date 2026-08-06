packages // this looks like stdlibs but better to be packages
Comprehensive Standard Library for Programming Language - 200+ Modules
CORE FOUNDATION (1-20)
core/prelude - Essential functions, basic types, and core utilities

core/io - Standard input/output operations

core/memory - Memory management, allocation, deallocation

core/error - Error handling, exceptions, panic recovery

core/assert - Assertion utilities and testing helpers

core/debug - Debugging tools, stack traces, logging

core/time - Time operations, durations, timestamps

core/system - System information, hostname, OS detection

core/process - Process management, spawning, signals

core/thread - Threading, synchronization primitives

core/atomic - Atomic operations, memory barriers

core/sync - Synchronization, mutexes, semaphores

core/rand - Random number generation, PRNG

core/hash - Hashing functions (CRC, FNV, etc.)

core/string - String manipulation, Unicode handling

core/array - Array operations, sorting, searching

core/vector - Dynamic arrays, slices

core/map - Hash maps, dictionaries, key-value stores

core/set - Set operations, unique collections

core/tuple - Tuple operations and utilities

MATHEMATICS (21-60)
math/basic - Basic arithmetic, constants (π, e, etc.)

math/integer - Integer operations, bit manipulation

math/float - Floating-point operations, precision

math/complex - Complex number operations

math/rational - Rational number operations

math/bigint - Arbitrary precision integers

math/bigfloat - Arbitrary precision floats

math/statistics - Statistical functions (mean, median, etc.)

math/probability - Probability distributions, random variables

math/linear - Linear algebra, vectors, matrices

math/matrix - Matrix operations, determinants, eigenvalues

math/vector3 - 3D vector operations

math/vector4 - 4D vector operations

math/quaternion - Quaternion mathematics

math/geometry - Geometric shapes and calculations

math/trigonometry - Trigonometric functions

math/logarithm - Logarithmic functions

math/exponential - Exponential functions

math/power - Power and root operations

math/special - Special functions (gamma, beta, etc.)

math/calculus - Calculus operations, derivatives, integrals

math/differential - Differential equations

math/numerical - Numerical methods, approximations

math/optimization - Optimization algorithms

math/signal - Signal processing, FFT

math/fourier - Fourier transforms

math/wavelet - Wavelet transforms

math/random - Random number distributions

math/graph - Graph theory algorithms

math/combinatorics - Combinatorial functions

math/prime - Prime number operations

math/modular - Modular arithmetic

math/cryptography - Mathematical cryptography

math/financial - Financial calculations, interest, etc.

math/interpolation - Interpolation methods

math/regression - Regression analysis

math/statistical - Advanced statistics

math/machine - Machine learning math primitives

math/neural - Neural network math

math/geometry3d - 3D geometry operations

CRYPTOGRAPHY (61-80)
crypto/hash - Cryptographic hashing (SHA, MD5, etc.)

crypto/aes - AES encryption

crypto/des - DES and 3DES encryption

crypto/rsa - RSA asymmetric encryption

crypto/ecc - Elliptic curve cryptography

crypto/dsa - Digital Signature Algorithm

crypto/diffie - Diffie-Hellman key exchange

crypto/random - Cryptographically secure random

crypto/cipher - Block cipher modes (CBC, CTR, etc.)

crypto/stream - Stream ciphers

crypto/pbkdf - Password-based key derivation

crypto/hmac - HMAC authentication

crypto/cert - Certificates, X.509

crypto/tls - TLS/SSL implementation

crypto/ssh - SSH protocol

crypto/pgp - PGP/GPG compatibility

crypto/jwt - JWT tokens

crypto/oauth - OAuth implementation

crypto/otp - One-time passwords, TOTP

crypto/zero - Zero-knowledge proofs

NETWORKING (81-110)
net/socket - Socket programming

net/tcp - TCP client/server

net/udp - UDP client/server

net/http - HTTP client/server

net/https - HTTPS implementation

net/websocket - WebSocket protocol

net/ftp - FTP client/server

net/smtp - SMTP email

net/pop3 - POP3 email

net/imap - IMAP email

net/dns - DNS resolution

net/dhcp - DHCP client

net/telnet - Telnet protocol

net/ssh - SSH client/server

net/irc - IRC protocol

net/mqtt - MQTT IoT protocol

net/amqp - AMQP (RabbitMQ)

net/zmq - ZeroMQ implementation

net/grpc - gRPC implementation

net/rpc - RPC implementation

net/proxy - Proxy servers

net/ntp - NTP time synchronization

net/snmp - SNMP protocol

net/tftp - TFTP implementation

net/upnp - UPnP protocol

net/bonjour - Bonjour/Zeroconf

net/multicast - Multicast networking

net/icmp - ICMP ping

net/ip - IP operations

net/mac - MAC address operations

DATA FORMATS (111-130)
data/json - JSON parsing and serialization

data/xml - XML parsing and serialization

data/yaml - YAML parsing and serialization

data/toml - TOML parsing

data/csv - CSV reading/writing

data/tsv - TSV reading/writing

data/binary - Binary encoding/decoding

data/msgpack - MessagePack serialization

data/protobuf - Protocol Buffers

data/thrift - Thrift serialization

data/bson - BSON (MongoDB format)

data/avro - Apache Avro

data/parquet - Parquet format

data/arrow - Apache Arrow

data/orc - ORC format

data/xls - Excel XLS reading

data/xlsx - Excel XLSX reading

data/pdf - PDF generation

data/docx - Word DOCX

data/pptx - PowerPoint PPTX

TEXT PROCESSING (131-150)
text/regex - Regular expressions

text/parsing - Parsing utilities

text/lexing - Lexical analysis

text/format - Text formatting

text/template - Template engines

text/markdown - Markdown parsing

text/html - HTML parsing

text/csv - CSV parsing

text/diff - Text differencing

text/patch - Patching algorithms

text/stemming - Word stemming

text/lemmatization - Word lemmatization

text/nlp - Natural language processing

text/tokenizer - Tokenization

text/ngram - N-gram analysis

text/sentiment - Sentiment analysis

text/summary - Text summarization

text/translation - Translation utilities

text/spell - Spell checking

text/unicode - Unicode utilities

DATABASES (151-170)
db/sql - SQL interface

db/postgres - PostgreSQL driver

db/mysql - MySQL driver

db/sqlite - SQLite driver

db/mongo - MongoDB driver

db/redis - Redis client

db/cassandra - Cassandra driver

db/elastic - Elasticsearch client

db/oracle - Oracle DB driver

db/mssql - Microsoft SQL Server

db/db2 - IBM DB2

db/firebird - Firebird SQL

db/leveldb - LevelDB implementation

db/rocksdb - RocksDB implementation

db/badger - Badger key-value

db/bolt - BoltDB embedded

db/etcd - Etcd client

db/consul - Consul client

db/zookeeper - ZooKeeper client

db/dynamo - DynamoDB client

FILESYSTEM (171-190)
fs/file - File operations

fs/directory - Directory operations

fs/path - Path manipulation

fs/glob - Glob pattern matching

fs/watch - Filesystem watching

fs/temp - Temporary files

fs/lock - File locking

fs/pipe - Named pipes

fs/mmap - Memory-mapped files

fs/archive - Archive handling

fs/zip - ZIP compression

fs/gzip - GZIP compression

fs/tar - TAR archives

fs/bzip2 - BZIP2 compression

fs/xz - XZ compression

fs/7z - 7-Zip compression

fs/rar - RAR decompression

fs/iso - ISO filesystem

fs/disk - Disk operations

fs/fuse - FUSE filesystem

SYSTEM & HARDWARE (191-210)
sys/env - Environment variables

sys/args - Command-line arguments

sys/signal - Signal handling

sys/user - User information

sys/group - Group information

sys/perm - Permissions management

sys/uid - UID/GID operations

sys/exec - Process execution

sys/proc - Process information

sys/mem - Memory information

sys/cpu - CPU information

sys/gpu - GPU information

sys/disk - Disk information

sys/network - Network information

sys/hardware - Hardware detection

sys/uart - UART serial communication

sys/gpio - GPIO control

sys/i2c - I2C bus communication

sys/spi - SPI bus communication

sys/thermal - Temperature sensors

MULTIMEDIA (211-230)
media/image - Image operations

media/png - PNG encoding/decoding

media/jpeg - JPEG encoding/decoding

media/gif - GIF encoding/decoding

media/bmp - BMP encoding/decoding

media/webp - WebP encoding/decoding

media/svg - SVG handling

media/audio - Audio operations

media/mp3 - MP3 decoding

media/wav - WAV handling

media/ogg - OGG handling

media/flac - FLAC decoding

media/aac - AAC decoding

media/video - Video operations

media/mp4 - MP4 handling

media/avi - AVI handling

media/mkv - Matroska handling

media/codec - Codec utilities

media/stream - Media streaming

media/subtitle - Subtitle handling

GRAPHICS & UI (231-250)
ui/terminal - Terminal UI

ui/console - Console UI

ui/window - Window management

ui/gui - GUI framework

ui/widget - Widget library

ui/event - Event handling

ui/canvas - 2D canvas

ui/3d - 3D rendering

ui/opengl - OpenGL binding

ui/vulkan - Vulkan binding

ui/directx - DirectX binding

ui/shader - Shader utilities

ui/texture - Texture handling

ui/font - Font rendering

ui/color - Color operations

ui/animation - Animation framework

ui/dialog - Dialog boxes

ui/menu - Menu systems

ui/toolbar - Toolbar components

ui/theme - Theming engine

SCIENCE & ENGINEERING (251-275)
sci/physics - Physics calculations

sci/chemistry - Chemistry utilities

sci/biology - Biology utilities

sci/astronomy - Astronomy calculations

sci/geology - Geology utilities

sci/weather - Weather calculations

sci/climate - Climate modeling

sci/environment - Environmental science

sci/materials - Materials science

sci/mechanics - Mechanics calculations

sci/thermo - Thermodynamics

sci/quantum - Quantum mechanics

sci/nuclear - Nuclear physics

sci/particle - Particle physics

sci/relativity - Relativity calculations

sci/electronics - Electronics utilities

sci/robotics - Robotics algorithms

sci/control - Control systems

sci/signal - Signal processing

sci/imaging - Scientific imaging

sci/spectroscopy - Spectroscopy

sci/chromatography - Chromatography

sci/microscopy - Microscopy

sci/geography - Geography utilities

sci/meteorology - Meteorology

GAME DEVELOPMENT (276-295)
game/engine - Game engine core

game/math - Game mathematics

game/physics - Physics engine

game/collision - Collision detection

game/particle - Particle systems

game/scene - Scene management

game/entity - Entity component system

game/ai - AI algorithms

game/pathfinding - Pathfinding algorithms

game/steering - Steering behaviors

game/state - State management

game/save - Save/load system

game/achievement - Achievement system

game/leaderboard - Leaderboard system

game/multiplayer - Multiplayer networking

game/input - Input handling

game/audio - Game audio

game/ui - Game UI

game/level - Level management

game/event - Event system

WEB DEVELOPMENT (296-315)
web/server - Web server framework

web/router - Routing system

web/middleware - Middleware components

web/auth - Authentication system

web/session - Session management

web/cookie - Cookie handling

web/cache - Web caching

web/static - Static file serving

web/template - Web templates

web/form - Form handling

web/validation - Input validation

web/csrf - CSRF protection

web/xss - XSS protection

web/rate - Rate limiting

web/cors - CORS handling

web/websocket - WebSocket server

web/sse - Server-sent events

web/rest - REST API framework

web/graphql - GraphQL implementation

web/documentation - API documentation

CLOUD & DEVOPS (316-335)
cloud/aws - AWS SDK integration

cloud/azure - Azure SDK integration

cloud/gcp - Google Cloud integration

cloud/docker - Docker integration

cloud/k8s - Kubernetes API

cloud/terraform - Terraform integration

cloud/ansible - Ansible integration

cloud/puppet - Puppet integration

cloud/chef - Chef integration

cloud/salt - SaltStack integration

cloud/helm - Helm charts

cloud/serverless - Serverless framework

cloud/cfn - CloudFormation

cloud/terraform - Infrastructure as code

cloud/monitoring - Monitoring utilities

cloud/logging - Cloud logging

cloud/tracing - Distributed tracing

cloud/metrics - Metrics collection

cloud/alerting - Alerting system

cloud/scaling - Auto-scaling

MACHINE LEARNING (336-355)
ml/tensor - Tensor operations

ml/neural - Neural networks

ml/deep - Deep learning

ml/training - Model training

ml/inference - Model inference

ml/optimizer - Optimizers (SGD, Adam, etc.)

ml/layers - Neural network layers

ml/activation - Activation functions

ml/loss - Loss functions

ml/metrics - Metrics evaluation

ml/data - Dataset handling

ml/preprocess - Preprocessing utilities

ml/feature - Feature engineering

ml/selection - Feature selection

ml/ensemble - Ensemble methods

ml/boosting - Boosting algorithms

ml/randomforest - Random Forest

ml/svm - Support Vector Machines

ml/clustering - Clustering algorithms

ml/dimensionality - Dimensionality reduction

UTILITIES & HELPERS (356-375)
util/logger - Logging utilities

util/config - Configuration management

util/flag - Command-line flags

util/option - Options pattern

util/retry - Retry mechanisms

util/cache - Caching system

util/pool - Object pooling

util/worker - Worker pools

util/queue - Queue implementations

util/stack - Stack operations

util/lru - LRU cache

util/ttl - TTL cache

util/semaphore - Semaphore utilities

util/backoff - Backoff strategies

util/timeout - Timeout handling

util/context - Context management

util/cancel - Cancellation support

util/benchmark - Benchmarking utilities

util/profiling - Profiling tools

util/tracing - Tracing utilities

TESTING & QUALITY (376-390)
test/unit - Unit testing framework

test/integration - Integration testing

test/benchmark - Benchmark testing

test/fuzzing - Fuzzing utilities

test/mock - Mocking framework

test/stub - Stub generation

test/assert - Assertion helpers

test/coverage - Code coverage

test/property - Property-based testing

test/golden - Golden file testing

test/snapshot - Snapshot testing

test/performance - Performance testing

test/security - Security testing

test/compliance - Compliance testing

test/report - Test reporting

COMPILER & LANGUAGE TOOLS (391-405)
compiler/parser - Parser framework

compiler/lexer - Lexer framework

compiler/ast - AST manipulation

compiler/codegen - Code generation

compiler/optimizer - Optimization passes

compiler/linter - Linting system

compiler/formatter - Code formatter

compiler/analyzer - Static analysis

compiler/refactor - Refactoring tools

compiler/plugin - Plugin system

compiler/macro - Macro system

compiler/inline - Inline assembly

compiler/jit - JIT compilation

compiler/wasm - WebAssembly target

compiler/llvm - LLVM binding

MISCELLANEOUS (406-420)
misc/geo - Geocoding and maps

misc/units - Unit conversion

misc/currency - Currency operations

misc/calendar - Calendar utilities

misc/holiday - Holiday calculations

misc/timezone - Timezone operations

misc/phone - Phone number validation

misc/email - Email validation

misc/url - URL parsing and manipulation

misc/ip - IP address operations

misc/mac - MAC address operations

misc/uuid - UUID generation

misc/slug - Slug generation

misc/emoji - Emoji handling

misc/qrcode - QR code generation

SECURITY & AUTHENTICATION (421-435)
security/auth - Authentication framework

security/authorization - Authorization system (RBAC, ABAC)

security/password - Password hashing (bcrypt, argon2)

security/sanitize - Input sanitization

security/escape - Output escaping

security/audit - Audit logging

security/encrypt - Encryption utilities

security/decrypt - Decryption utilities

security/key - Key management

security/cert - Certificate management

security/secret - Secret management

security/vault - Vault integration

security/oauth - OAuth providers

security/saml - SAML implementation

security/ldap - LDAP integration

INTERNATIONALIZATION (436-450)
i18n/locale - Locale handling

i18n/translate - Translation management

i18n/plural - Pluralization rules

i18n/date - Date localization

i18n/time - Time localization

i18n/number - Number formatting

i18n/currency - Currency formatting

i18n/name - Name formatting

i18n/address - Address formatting

i18n/phonenumber - Phone number formatting

i18n/unit - Unit formatting

i18n/collation - String collation

i18n/unicode - Unicode normalization

i18n/transliteration - Transliteration

i18n/icu - ICU integration

PARALLEL & CONCURRENT (451-465)
concurrent/future - Future/promise system

concurrent/async - Async/await system

concurrent/channel - Channel-based communication

concurrent/stream - Stream processing

concurrent/parallel - Parallel processing

concurrent/forkjoin - Fork-join framework

concurrent/actor - Actor model implementation

concurrent/stm - Software transactional memory

concurrent/lockfree - Lock-free data structures

concurrent/barrier - Barrier synchronization

concurrent/countdown - Countdown latches

concurrent/exchanger - Exchanger utilities

concurrent/phaser - Phaser synchronization

concurrent/executor - Executor framework

concurrent/scheduler - Task scheduler

EMBEDDED & IOT (466-480)
embedded/gpio - GPIO control

embedded/i2c - I2C communication

embedded/spi - SPI communication

embedded/uart - UART serial

embedded/adc - ADC reading

embedded/dac - DAC writing

embedded/pwm - PWM generation

embedded/interrupt - Interrupt handling

embedded/timer - Timer operations

embedded/rtc - Real-time clock

embedded/eeprom - EEPROM access

embedded/flash - Flash memory

embedded/sd - SD card access

embedded/ble - Bluetooth Low Energy

embedded/zigbee - Zigbee protocol

BLOCKCHAIN & WEB3 (481-495)
blockchain/core - Blockchain core

blockchain/ethereum - Ethereum integration

blockchain/bitcoin - Bitcoin integration

blockchain/smartcontract - Smart contracts

blockchain/wallet - Wallet management

blockchain/transaction - Transaction handling

blockchain/consensus - Consensus algorithms

blockchain/crypto - Blockchain cryptography

blockchain/merkle - Merkle trees

blockchain/hashchain - Hash chains

blockchain/nft - NFT support

blockchain/defi - DeFi utilities

blockchain/web3 - Web3 integration

blockchain/oracle - Oracle integration

blockchain/bridge - Bridge protocols

FINAL MISC (496-500)
misc/version - Version handling

misc/semver - Semantic versioning

misc/license - License management

misc/notice - Copyright notices

misc/legal - Legal utilities

This comprehensive list provides 500 standard library modules organized into logical categories. Each module focuses on a specific domain, making the standard library well-organized and easy to navigate. The naming convention (category/subcategory) helps developers find what they need quickly, and the modular structure allows for selective importing to keep binary sizes small.






stdlib modules

I think most of them should be packages and not stdlib. Can we categorize to stdlib and packages cause I think the packages are build on top of stdlib.

most of them are dependencies requires 3rd party. though stdlib should be able to not have dependecies not talking about the nasm and LLVM which the language is build.

can you compile a stdlib ONLY the building blocks as much as we need
You're absolutely right! I was mixing stdlib with external packages. Let me restructure this properly.

Standard Library = Core building blocks, NO external dependencies, written in the language itself (or minimal FFI to OS)

Packages = Built on top of stdlib, may have external dependencies

STANDARD LIBRARY - Core Building Blocks
SYSTEM FOUNDATION
sys/io - Basic I/O operations (stdin, stdout, stderr)

sys/file - File operations (open, read, write, close, seek)

sys/dir - Directory operations (list, create, remove)

sys/path - Path manipulation (join, split, ext, normalize)

sys/env - Environment variables (get, set, unset)

sys/args - Command-line argument parsing

sys/time - Time primitives (now, sleep, duration)

sys/process - Process spawning and management

sys/signal - Signal handling

sys/memory - Memory allocation (malloc, free, resize)

sys/alloc - Custom allocator interface

sys/exit - Process termination

sys/host - Host information (hostname, OS, arch)

sys/thread - Thread creation and joining

sys/mutex - Mutual exclusion primitives

sys/atomic - Atomic operations (CAS, load, store)

sys/semaphore - Semaphore implementation

sys/condvar - Condition variables

sys/once - One-time initialization

sys/rwlock - Read-write locks

CORE LANGUAGE
core/panic - Panic and recover

core/assert - Assertion macros/functions

core/defer - Defer mechanism

core/error - Error types and handling

core/option - Option/Maybe type

core/result - Result type

core/string - String primitives (length, concat, slice)

core/utf8 - UTF-8 validation and decoding

core/utf16 - UTF-16 conversion

core/char - Character operations

core/array - Fixed-size array operations

core/slice - Dynamic slice operations

core/range - Range iteration

core/iter - Iterator interface

core/typeid - Type identification (reflection basics)

core/align - Memory alignment utilities

core/offset - Field offset calculations

core/unsafe - Unsafe operations (pointer casting)

core/builtin - Built-in compiler intrinsics

core/callconv - Calling convention utilities

PRIMITIVE OPERATIONS
math/int - Integer operations (add, sub, mul, div, mod)

math/uint - Unsigned integer operations

math/float - Floating-point operations

math/const - Mathematical constants (pi, e, etc.)

math/abs - Absolute value

math/minmax - Min/max operations

math/clamp - Clamping values

math/sqrt - Square root

math/pow - Power operations (integer exponent)

math/log - Logarithm operations (ln, log2, log10)

math/exp - Exponential operations

math/trig - Trigonometric (sin, cos, tan)

math/atrig - Inverse trig (asin, acos, atan)

math/hyper - Hyperbolic functions

math/floor - Floor, ceil, round, trunc

math/modf - Split integer/fractional parts

math/ldexp - Frexp, ldexp operations

math/bit - Bit operations (popcnt, clz, ctz)

math/rotate - Bit rotation

math/endian - Endianness conversion

BIT & BYTE OPERATIONS
bits/read - Reading bits from bytes

bits/write - Writing bits to bytes

bits/swap - Byte swapping

bits/bytes - Byte operations (to/from ints)

bits/binary - Binary encoding primitives

bits/hex - Hex encoding/decoding

bits/base64 - Base64 encoding/decoding

bits/base32 - Base32 encoding/decoding

bits/base16 - Base16 encoding/decoding

bits/crc - CRC algorithms (CRC32, CRC64)

bits/adler - Adler-32 checksum

bits/checksum - Simple checksum operations

bits/bitarray - Bit array operations

HASHING (Basic)
hash/fnv - FNV-1a hash

hash/murmur - MurmurHash3

hash/city - CityHash

hash/xxhash - xxHash

hash/siphash - SipHash

hash/highway - HighwayHash

hash/composite - Composite hashing utilities

COLLECTIONS
collect/list - Singly/doubly linked list

collect/vector - Dynamic array

collect/stack - Stack implementation

collect/queue - Queue implementation

collect/ring - Ring buffer

collect/map - Hash map (open addressing)

collect/mapch - Hash map (chaining)

collect/tree - Binary tree

collect/avl - AVL tree

collect/rbtree - Red-black tree

collect/bheap - Binary heap

collect/fheap - Fibonacci heap

collect/filter - Filter/functional operations (map, filter, reduce)

collect/deque - Double-ended queue

collect/priority - Priority queue

STRING OPERATIONS
str/compare - String comparison

str/search - Search operations (contains, index)

str/replace - Replace operations

str/trim - Trim whitespace

str/split - Split operations

str/join - Join operations

str/case - Case conversion (upper, lower, title)

str/strip - Strip prefixes/suffixes

str/repeat - Repeat strings

str/pad - Padding operations

str/slice - Safe string slicing

str/escape - Escape sequences

str/printf - Printf-style formatting

str/scanf - Scanf-style parsing

str/format - Basic formatting utilities

CONVERSION
conv/int - String to int conversion

conv/float - String to float conversion

conv/toint - To integer (various bases)

conv/tofloat - To float

conv/tostring - To string (basic types)

conv/parse - Parsing utilities

conv/itos - Integer to string

conv/ftos - Float to string (formatting)

conv/atoi - ASCII to integer

conv/itoa - Integer to ASCII

NETWORKING (Basic)
net/socket - Socket operations (create, bind, connect)

net/address - Address parsing (IPv4, IPv6)

net/tcp - TCP socket utilities

net/udp - UDP socket utilities

net/dns - DNS resolution (system calls)

net/host - Host/port utilities

net/ip - IP address operations

net/port - Port utilities

net/protocol - Protocol utilities

net/url - Basic URL parsing (scheme, host, path)

FILE FORMATS (Basic)
format/hex - Hex dump utilities

format/bytes - Byte formatting

format/dump - Memory dump utilities

format/pretty - Pretty printing

format/table - Table formatting

format/indent - Indentation utilities

format/wrap - Text wrapping

format/column - Column formatting

OS INTERACTION
os/pipe - Pipe creation

os/fd - File descriptor utilities

os/dup - Duplicate descriptors

os/select - Select/poll operations

os/event - Event polling (epoll/kqueue)

os/ioctl - IOCTL operations

os/mmap - Memory mapping

os/stat - File status (size, perms, timestamps)

os/perm - Permission operations (chmod)

os/owner - Owner operations (chown)

os/link - Hard/soft links

os/rename - Rename operations

os/remove - Delete operations

os/symlink - Symbolic link operations

os/readlink - Read symbolic links

os/realpath - Resolve path

os/temp - Temporary directory/file creation

os/cwd - Current working directory

os/chdir - Change directory

os/mkdir - Make directory (with parents)

os/rmdir - Remove directory

os/walk - Directory walking

RANDOM
rand/mt - Mersenne Twister

rand/pcg - PCG random generator

rand/xorshift - Xorshift family

rand/chacha - ChaCha20-based randomness

rand/dist - Distribution utilities (uniform, normal)

rand/seed - Seeding utilities

rand/source - Random source interface

CRYPTOGRAPHY (Basic - No Dependencies)
crypto/sha256 - SHA-256 implementation

crypto/sha512 - SHA-512 implementation

crypto/sha1 - SHA-1 implementation

crypto/md5 - MD5 implementation

crypto/blake2 - BLAKE2 implementation

crypto/keccak - Keccak/SHA-3 implementation

crypto/aes - AES block cipher (pure implementation)

crypto/des - DES block cipher

crypto/chacha - ChaCha20 stream cipher

crypto/poly1305 - Poly1305 authenticator

crypto/curve25519 - Curve25519 implementation

crypto/ed25519 - Ed25519 signatures (pure)

crypto/rsa - RSA basic operations (pure)

crypto/dh - Diffie-Hellman (pure)

crypto/otp - One-time pad

crypto/entropy - Entropy collection

crypto/kdf - Key derivation functions (PBKDF2)

crypto/hmac - HMAC implementation

crypto/padding - Padding utilities (PKCS7)

crypto/mode - Block cipher modes (CBC, CTR)

crypto/rand - Cryptographic random (system)

COMPRESSION (Basic)
compress/deflate - Deflate algorithm

compress/inflate - Inflate algorithm

compress/zlib - ZLIB format

compress/gzip - GZIP format (basic)

compress/lz4 - LZ4 compression (pure)

compress/snappy - Snappy compression (pure)

compress/huffman - Huffman coding

compress/lz - LZ77/LZ78 algorithms

compress/rle - Run-length encoding

SERIALIZATION (Binary)
serial/binary - Binary serialization (read/write)

serial/varint - Variable-length integer encoding

serial/fixed - Fixed-size encoding

serial/zero - Zero-copy serialization

serial/buffer - Buffer serialization

serial/stream - Stream serialization

SORTING
sort/quick - Quicksort implementation

sort/merge - Mergesort implementation

sort/heap - Heapsort implementation

sort/insert - Insertion sort

sort/bubble - Bubble sort

sort/select - Selection sort

sort/radix - Radix sort

sort/count - Counting sort

sort/tim - Timsort implementation

sort/stable - Stable sort utilities

SEARCHING
search/binary - Binary search

search/linear - Linear search

search/interp - Interpolation search

search/exponential - Exponential search

search/jump - Jump search

search/ternary - Ternary search

CONCURRENCY (Core)
concurrent/channel - Channel implementation

concurrent/select - Select statement utilities

concurrent/spawn - Spawn primitives

concurrent/join - Join primitives

concurrent/future - Future primitive

concurrent/promise - Promise primitive

concurrent/yield - Yield/schedule

TIME
time/duration - Duration operations

time/tick - Tick/timer primitives

time/date - Date operations (year, month, day)

time/iso - ISO 8601 formatting

time/parse - Time parsing

time/format - Time formatting

MATHEMATICS (Advanced but Pure)
math/modular - Modular arithmetic

math/prime - Prime operations (isPrime, nextPrime)

math/gcd - GCD/LCM operations

math/factor - Integer factorization (trial division)

math/combin - Combinations, permutations

math/factorial - Factorial operations

math/bigint - Big integer operations (pure)

math/bigrat - Big rational operations (pure)

math/bigfloat - Big float operations (pure)

math/matrix - Matrix operations (basic)

math/vector - Vector operations (2D, 3D)

math/quaternion - Quaternion operations

math/complex - Complex number operations

PLATFORM ABSTRACTION
platform/linux - Linux-specific utilities

platform/windows - Windows-specific utilities

platform/darwin - macOS-specific utilities

platform/bsd - BSD-specific utilities

platform/unix - Unix common utilities

platform/posix - POSIX compliance utilities

FFI
ffi/cdecl - C calling convention

ffi/stdcall - STDCALL calling convention

ffi/fastcall - FASTCALL convention

ffi/pointer - Pointer utilities for FFI

ffi/export - Exporting to C

ffi/import - Importing from C

ffi/struct - Struct layout utilities

ffi/string - C string conversion

DEBUGGING
debug/trace - Stack trace

debug/symbol - Symbol resolution

debug/break - Breakpoint insertion

debug/print - Debug printing

debug/assert - Debug assertions

debug/source - Source location utilities

PERFORMANCE
perf/counter - Performance counters

perf/cycle - Cycle counting

perf/bench - Benchmark utilities

perf/prof - Profiling utilities

perf/alloc - Allocation tracking

MISCELLANEOUS (Core)
misc/uuid - UUID generation (pure)

misc/guid - GUID generation

misc/version - Version parsing/comparison

misc/semver - Semantic versioning (pure)

misc/glob - Glob pattern matching (pure)

misc/diff - Diff utilities (Myers algorithm)

misc/patch - Patch utilities

misc/sort - Natural sort

misc/levenshtein - Levenshtein distance

misc/soundex - Soundex algorithm

Summary
Standard Library: 280 modules, zero external dependencies

All written in the language itself

Only uses OS syscalls via FFI when necessary

Provides building blocks for everything else

Everything else (the 220+ from the previous list) would be packages that:

Build on top of these stdlib modules

Can have external dependencies

Are in a separate package registry

This stdlib is:

Self-contained

Portable (abstracts OS differences)

Minimal but complete enough to build anything on top

The foundation the language's package ecosystem is built upon

migrations plan   // just recomendations you can change it