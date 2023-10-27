# ``NTKQueryKit``

A comprehensive server-state management framework for SwiftUI applications, that enables to manage efficiently data-fetching with automatic caching.

## Overview

`NTKQueryKit` is built on top of the idea from the [TanStackQuery](https://tanstack.com/query/latest) library, which is a beloved library in the React ecosystem. This framework aims to ease the process of managing server data in modern mobile applications built in SwiftUI. It's done via simplifying data management by providing a set of intuitive interfaces to work with in order to work with server data. It abstracts a lot of functionalities related to fetching, updating, sharing, and subscribing to data that is coming from remote resources such as APIs or databases. 

One of the core features of `NTKQueryKit` is support for queries and mutations, which lets you manage your server-state efficiently in SwiftUI application:

- **Query** is just a representation of an operation that fetches and retrieves data from a specified data source. Query can be defined with convinient ``NTKQuery`` property wrapper that allows you to work with all query's functionalities. These instances are highly customizable, they can cache the results of fetched data, that will help to reduce unnecessary network requests and enhance the performance of the application. 

- **Mutation** is a representation of an operation that will modify server-side data and then potentially update the client's cache based on the result. Using `NTKQueryKit` you define mutations by the dedicated ``NTKMutation`` property wrapper, which opens access to the mutation related functionality. Mutations support different configuration options on top of success/error handlers, that let you react and perform side effects based on the result of performed mutation.

Both queries and mutations can be configured with global configuration initialized at the stage of app initialization, letting you use constructs exported from the library with already configured and ready-to-use. This includes error handling - `NTKQueryKit` lets you globally set error handlers (for both queries and mutations), send additional meta data that will be available when error is encountered. This provides you with the option to create consistent and unified error handling system for your project.

## Topics

### Essentials

TODO

### Query

- ``NTKQuery``
- ``Query``
- ``QueryConfig``
- ``NTKQueryValue``
- ``QueryValue``
- ``QueryStatus``
- ``QueryFunction``
- ``DefaultQueryFunction``

### Mutation

- ``NTKMutation``
- ``Mutation``
- ``MutationConfig``
- ``MutationStatus``
- ``MutationFunction``
- ``DefaultMutationFunction``
- ``MutationSuccessHandler``
- ``MutationErrorHandler``

### Global configuration

- ``NTKQueryGlobalConfig``
- ``GlobalErrorParameters``
- ``GlobalOnErrorFunction``
- ``MetaDictionary``
- ``QueriesConfigDictionary``
- ``MutationsConfigDictionary``

### Interacting with cache manually

- ``QueryClient``
- ``QueryCacheEntry``
