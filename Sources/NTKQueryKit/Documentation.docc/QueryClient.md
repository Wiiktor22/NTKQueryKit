# ``NTKQueryKit/QueryClient``

API (accessible globally) to interact with the cache.

## Overview

`QueryClient` class enables you to read the current state of cache entries and overwrite their states based on your needs through the `shared` property.

## Topics

### Using a shared client

- ``shared``

### Read the state of saved cache entries

- ``getQueryData(queryKey:)``
- ``getQueryState(queryKey:)``

### Overwrite the state of cache entries

- ``prefetchQuery(queryKey:queryFunction:)``
- ``removeQuery(queryKey:)``
- ``setQueryData(queryKey:data:)``
