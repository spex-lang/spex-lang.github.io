---
title: Tutorial - Spex
---

# Tutorial

*Work in progress, coming soon.*

This tutorial is intended to get you started with writing your own Spex
specifications. We'll cover all basic features of the specification language
and explain how they interact with the toolkit via the `spex` command-line
utility (which can be obtained following the installation
[instructions](install.html)).

Before we start, let's discuss in what situations you might want to use *Spex*
in the first place.

## In what situations is Spex useful?

Having a specification is useful for different reasons in different situations,
here are a few:

* New system
  - mock for frontend
  - test new system once done (frontend should then also work)
* Existing (legacy) system
  - document exisiting system (for onbording / docs generation)
  - increase test coverage
* External system dependency
  - mock api for integration testing

XXX: In this tutorial we shall focus on specifying existing (legacy) or external
systems.

## An example system

Spex isn't a programming language in the traditional sense. In particular the
system we want write a specification for will need to be written in another
language. 

Why? Well, *Spex* simply doesn't have the language features necessary to do
normal programming.

So let's start by writing a simple HTTP API server in Python using Flask.

```python
from flask import Flask
from flask import jsonify
from flask import request

app = Flask(__name__)

# NOTE: Not thread-safe and won't work if clients connect concurrently.
petstore = {}

@app.route("/pet/<pet_id>", methods=["GET"])
def get_pet(pet_id):
    if pet_id in petstore:
        pet_name = petstore[pet_id]
        return jsonify(petId=pet_id, petName=pet_name)
    else:
        return jsonify(error="Pet not found"), 404

@app.route("/pet", methods=["POST"])
def add_pet():
    pet_id = request.json.get("petId", None)
    pet_name = request.json.get("petName", None)
    if pet_id in petstore:
        return jsonify(error="Pet already exists"), 409
    petstore[pet_id] = pet_name
    return "[]", 201

@app.route("/health", methods=["GET"])
def health():
    return "[]", 200

@app.route("/_reset", methods=["DELETE"])
def _reset():
    petstore.clear()
    return "[]", 200

if __name__ == "__main__":
    app.run()
```

If we save the above into a file called `petstore.py`, then we can launch the
server using `flask --app petstore run`. Once running we can add new pets as follows:

```bash
$ http POST :5000/pet petId=2 petName="bepa"
HTTP/1.1 201 CREATED

[]
```

And look up pets by their id as follows:

```bash
$ http GET :5000/pet/2
HTTP/1.1 200 OK

{
    "petId": "2",
    "petName": "bepa"
}
```

## First basic specification

One way to specify

```spex
component PetStore where

addPet : POST /pet Pet
getPet : GET /pet/{petId : Int} -> Pet

type Pet =
  { petId   : Int
  , petName : String
  }
```

```
spex verify --port 5000 example/petstore-basic.spex

i Verifying the deployment:    http://localhost:5000
  against the specification:   example/petstore-basic.spex

i Checking the specification.

i Waiting for health check to pass...

✓ Health check passed!

i Starting to run tests...

✓ Done testing!

  Found 0 intereresting test case.

  Coverage:
    2xx:
      49% addPet (49 ops)
    404:
      51% getPet (51 ops)

    Not covered (no non-404 responses):
      getPet

  Total operations (ops): 100

  Use --seed -7124542298296952417 to reproduce this run.
```

XXX: reuse should be 50% if @/# are not specified?

- Keep track of previously generated values and sometimes try to use them
  during generation of new tests. For example, without this ability the
  `getPet` requests would all most certainly return 404.

-  Try running with `--no-shrinking` flag to see the original test case that
  failed.

## Introducing modal types

* Add @ to ensure reuse
* Add # to avoid reuse

- [x] Ability to annotate input types with abstract and unique modalities (@ and
  !). Where an abstract type isn't generated, i.e. gets reused, and a unique type
  is always generated and never reused. Without any annotation a coin is
  flipped and the value either gets reused or generated.
  <details>

  <summary>Example</summary>

  ```diff
  $ diff -u example/petstore-basic.spex example/petstore-modal.spex
  - addPet : POST /pet Pet
  - getPet : GET /pet/{petId : Int} -> Pet
  + addPet : POST /pet !Pet
  + getPet : GET /pet/{petId : @Int} -> Pet
  $ spex verify example/petstore-modal.spex

  i Verifying the deployment:    http://localhost:8080
    against the specification:   example/petstore-modal.spex
  
  i Parsing the specification.
  
  i Waiting for health check to pass.
  
  i Starting to run tests.
  
  i All tests passed, here are the results:
  
    failing tests: []
    client errors: 3
    coverage:      fromList [(OpId "addPet",51),(OpId "getPet",49)]
  ```

  Notice how many fewer 404 errors we get for `getPet` now, because of the
  abstract (`@`) annotation on `petId`.

- [x] Keep track of previous responses and try to use them during generation 

  <details>

  <summary>Example</summary>

  Imagine we got:
  ```
  addPet : POST /pet Pet
  getPet : GET /pet/{petId : Int} -> Pet

  type Pet =
    { petId   : Int
    , petName : String 
    }
  ```
  and `addPet` is implemented such that it throws an error if we try to add the
  exact same pet twice. Finding this error without reusing responses during
  generation is difficult, because we'd need to randomly generate the same
  `petId : Int` and petname : String` twice. 

  If we reuse inputs and reponses on the other hand, then it's easy to find it.
  Here's one scenario which would find the error:

    1. We generate a random `Pet` for `addPet`;
    2. A `getPet` operation gets generated that reuses the `petId` from step 1;
    3. The response `Pet` from step 2 gets reused in a subsequent `addPet`,
       casuing the error.

  </details>


## Mocking APIs

We've seen how to check that an existing system adhears to a specification.

In order to show how a specification can be useful before the system is
implemented, let's have a look at mocking.

Whether the server or specification is written first doesn't really matter, but
longer term we hope that writing the specification first will be helpful in
developing the server (because it gives you tooling that could be useful in the
development).


## Conclusion

* Alpha...

Next you might want to follow the [installation](install.html) instructions in
order to start running Spex on your own.
