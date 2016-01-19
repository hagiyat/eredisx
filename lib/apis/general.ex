defmodule Eredisx.Api.General do
  import Eredisx.ApiBuilder

  defmacro __using__(opts \\ []) do
    generate_apis Keyword.get(opts, :repo), """
    DEL key [key ...]
    summary: Delete a key
    since: 1.0.0

    DUMP key
    summary: Return a serialized version of the value stored at the specified key.
    since: 2.6.0

    EXISTS key
    summary: Determine if a key exists
    since: 1.0.0

    EXPIRE key seconds
    summary: Set a key's time to live in seconds
    since: 1.0.0

    EXPIREAT key timestamp
    summary: Set the expiration for a key as a UNIX timestamp
    since: 1.2.0

    KEYS pattern
    summary: Find all keys matching the given pattern
    since: 1.0.0

    MIGRATE host port key destination-db timeout [COPY] [REPLACE]
    summary: Atomically transfer a key from a Redis instance to another one.
    since: 2.6.0

    MOVE key db
    summary: Move a key to another database
    since: 1.0.0

    OBJECT subcommand [arguments [arguments ...]]
    summary: Inspect the internals of Redis objects
    since: 2.2.3

    PERSIST key
    summary: Remove the expiration from a key
    since: 2.2.0

    PEXPIRE key milliseconds
    summary: Set a key's time to live in milliseconds
    since: 2.6.0

    PEXPIREAT key milliseconds-timestamp
    summary: Set the expiration for a key as a UNIX timestamp specified in milliseconds
    since: 2.6.0

    PTTL key
    summary: Get the time to live for a key in milliseconds
    since: 2.6.0

    RANDOMKEY -
    summary: Return a random key from the keyspace
    since: 1.0.0

    RENAME key newkey
    summary: Rename a key
    since: 1.0.0

    RENAMENX key newkey
    summary: Rename a key, only if the new key does not exist
    since: 1.0.0

    RESTORE key ttl serialized-value
    summary: Create a key using the provided serialized value, previously obtained using DUMP.
    since: 2.6.0

    SCAN cursor [MATCH pattern] [COUNT count]
    summary: Incrementally iterate the keys space
    since: 2.8.0

    SORT key [BY pattern] [LIMIT offset count] [GET pattern [GET pattern ...]] [ASC|DESC] [ALPHA] [STORE destination]
    summary: Sort the elements in a list, set or sorted set
    since: 1.0.0

    TTL key
    summary: Get the time to live for a key
    since: 1.0.0

    TYPE key
    summary: Determine the type stored at key
    since: 1.0.0
    """
  end

  defapis """
  DEL key [key ...]
  summary: Delete a key
  since: 1.0.0

  DUMP key
  summary: Return a serialized version of the value stored at the specified key.
  since: 2.6.0

  EXISTS key
  summary: Determine if a key exists
  since: 1.0.0

  EXPIRE key seconds
  summary: Set a key's time to live in seconds
  since: 1.0.0

  EXPIREAT key timestamp
  summary: Set the expiration for a key as a UNIX timestamp
  since: 1.2.0

  KEYS pattern
  summary: Find all keys matching the given pattern
  since: 1.0.0

  MIGRATE host port key destination-db timeout [COPY] [REPLACE]
  summary: Atomically transfer a key from a Redis instance to another one.
  since: 2.6.0

  MOVE key db
  summary: Move a key to another database
  since: 1.0.0

  OBJECT subcommand [arguments [arguments ...]]
  summary: Inspect the internals of Redis objects
  since: 2.2.3

  PERSIST key
  summary: Remove the expiration from a key
  since: 2.2.0

  PEXPIRE key milliseconds
  summary: Set a key's time to live in milliseconds
  since: 2.6.0

  PEXPIREAT key milliseconds-timestamp
  summary: Set the expiration for a key as a UNIX timestamp specified in milliseconds
  since: 2.6.0

  PTTL key
  summary: Get the time to live for a key in milliseconds
  since: 2.6.0

  RANDOMKEY -
  summary: Return a random key from the keyspace
  since: 1.0.0

  RENAME key newkey
  summary: Rename a key
  since: 1.0.0

  RENAMENX key newkey
  summary: Rename a key, only if the new key does not exist
  since: 1.0.0

  RESTORE key ttl serialized-value
  summary: Create a key using the provided serialized value, previously obtained using DUMP.
  since: 2.6.0

  SCAN cursor [MATCH pattern] [COUNT count]
  summary: Incrementally iterate the keys space
  since: 2.8.0

  SORT key [BY pattern] [LIMIT offset count] [GET pattern [GET pattern ...]] [ASC|DESC] [ALPHA] [STORE destination]
  summary: Sort the elements in a list, set or sorted set
  since: 1.0.0

  TTL key
  summary: Get the time to live for a key
  since: 1.0.0

  TYPE key
  summary: Determine the type stored at key
  since: 1.0.0
  """
end
