---
title: The Spex specification language and verifier
---

# Spex

Spex is a specification language and verifier for HTTP API servers.

Here's an example specification:

```spex
component PetStore where

addPet       : POST /pet Pet
getPet       : GET /pet/{petId : @Int} -> Pet
getBadPet    : GET /pet/badJson/{petId : @Int} -> Pet
neverReached : GET /noThere -> Int

type Pet =
  { petId   : Int
  , petName : String
  }
```

The verifer takes a specification and an URL and checks if the server behind
the URL respects the specification. In particular the verifier looks for:

  * Non-2xx responses; 
  * JSON response decode and type errors;
  * Unreachable endpoints.

Here's an example run that uses the above specification:

```
$ spex verify example/petstore-modal-faults.spex \
    --tests 2000 --host http://localhost --port 8080

i Verifying the deployment:    http://localhost:8080
  against the specification:   example/petstore-modal-faults.spex

i Checking the specification.

i Waiting for health check to pass...

✓ Health check passed!

i Starting to run tests...

✓ Done testing, here are the results: 

Test failure:

1. addPet : POST /pet {petId = -46, petName = qux}
2. addPet : POST /pet {petId = -46, petName = qux}
  ↳ 409 Conflict: Pet already exists
------------------------------------------------------------------------
Test failure (1 shrinks):

1. getBadPet : GET /pet/badJson/99 -> Pet
decode failure: Error in $: endOfInput "petId":99,"petName":"qux"}
------------------------------------------------------------------------

Coverage:
  2xx:
    26% addPet (530 ops)
    8% getBadPet (156 ops)
    8% getPet (160 ops)
  404:
    15% getBadPet (308 ops)
    17% getPet (336 ops)
    25% neverReached (509 ops)
  409:
    0% addPet (1 ops)

Not covered (no non-404 responses):
  neverReached

Total operations (ops): 2000

Use --seed 3967796076964233976 to reproduce
```

Note that the server running on `http://localhost:8080` needs to be written in
another language and be deployed, before the Spex verifer is run.

For an introduction to how the above works in more detail, please see the
[tutorial](tutorial.html).
