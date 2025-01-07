---
title: The Spex specification language and verifier
---

# Spex

Spex is a specification language and toolkit for working with HTTP API servers.

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

The verifier takes a specification and an URL and checks if the server behind
the URL respects the specification. In particular the verifier looks for:

  * Minimal test cases that give rise to non-2xx responses, or; 
  * JSON response decode or type errors, as well as;
  * Unreachable endpoints.

Here's an example run that uses the above specification:

```shell
$ spex verify example/petstore-modal-faults.spex \
    --host http://localhost --port 8080 --tests 2000

i Verifying the deployment:    http://localhost:8080
  against the specification:   example/petstore-modal-faults.spex

i Checking the specification.

i Waiting for health check to pass...

✓ Health check passed!

i Starting to run tests...

✓ Done testing!

  Found 2 intereresting test cases:

    1. addPet : POST /pet {petId = -46, petName = qux} 
       addPet : POST /pet {petId = -46, petName = qux} 
         ↳ 409 Conflict: Pet already exists

    2. getBadPet : GET /pet/badJson/{petId = 99} -> Pet
         ↳ JSON decode failure: Error in $: endOfInput "petId":99,"petName":"qux"}
       (1 shrink)

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

  Use --seed 3967796076964233976 to reproduce this run.
```

Note that the server running on `http://localhost:8080` needs to be written in
another language and be deployed, before the Spex verifier is run.

For an introduction to how the above works in more detail, please see the
[tutorial](tutorial.html).
