# Cache

## Overview

Implements a Least Recently Used cache.

State is stored in an Agent, which ensures serialized access. This
doesn't allow for concurrent access, which was a decision made
to simplify implementation, since both structures need to be
updated together.

Primary implementation is in `lib/cache/cache_agent.ex`

External routes are

* PUT to `/put`  
  Payload `{"key": key, "value": value}`

* POST to `/get`  
Payload `{"key": key}`

Any PUT or GET resets that key's "freshness identifier", so it's considered
the "most recently used" key.

The max cache size is hardcoded to 3 for dev/testing purposes. It would be
put in config for actual use.

When a key/value is PUT when the cache is at maximum size, the 
least recently used pair is evicted.

The Agent's state is a Map `%{map: state_map, tree: state_tree}`.

`state_map`: Map of `key => {val, id}`, where id is a
monotonically-increasing unique identifier

`state_tree`: A `:gb_trees` instance of `id => key_from_state_map`

At put-time, if not a max-size, an entry is made to `state_tree` 
`id => key`, where `id` is the next unique identifier. The value itself is added to `state_map`,
with the value being `{val, id}`

If the cache *is* at max size, the least recently used entry is deleted. 
First, the oldest entry in `state_tree` (an ordered `:gb_trees`) is 
deleted, and its value (which is a key in `state_map`) is noted. 
The corresponding entry in `state_map` is then deleted, and new entries
are added to it, with the key being `{val, id}`, where id is the next
unique id; and to `state_tree` with `id => key`.

At get-time, in a similar fashion, the entries for the given key are 
refreshed in both state structures.

## Tests

Tests are in

* `test/cache/cache_agent_test.exs`
* `test/cache_web/controllers/cache_web/cache_controller_test.exs`

