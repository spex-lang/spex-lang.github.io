---
title: Tutorial - Spex
date: 2024-12-17T00:00:00Z
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

* A new system is being developed, a specification is written and:
  - A mock of the backend API is derived from the specification for frontend,
    so that the UI development can start without waiting for the functionality
    to be available;
  - The same specification is used to test the API once done, if the tests pass
    it's likely that the two components will be compatible.
* An existing system is being maintained, a specification is written to:
  - Document the system, perhaps for onboarding or documentation generation;
  - Generate tests and potentially increase the test coverage;
  - Since both the documentation and the tests are derived from the
    specification, we get some guarantees that the documentation isn't stale.

* A legacy system is being rewritten, a specification is used to:
  - Document and test the old system;
  - Develop and test the new system;
  - Since both are tested against the same specification, we get some
    confidence that they will behave the same.
* An external system dependency, where the specification can be used to mock
  the dependency's API, so that it can be made part of the integration test
  suite.

In this tutorial we'll try to give you an idea of how any of these scenarios
can be done.

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
$ http POST :5000/pet petId=1 petName="apa"
HTTP/1.1 201 CREATED

[]
```

And look up pets by their id as follows:

```bash
$ http GET :5000/pet/1
HTTP/1.1 200 OK

{
    "petId": "1",
    "petName": "apa"
}
```

## First basic specification

One way to specify the above example is as follows:

```spex
component PetStore where

addPet : POST /pet Pet
getPet : GET /pet/{petId : Int} -> Pet

type Pet =
  { petId   : Int
  , petName : String
  }
```

We can then verify that the implementation matches the specification as
follows:

```shell
$ spex verify --port 5000 example/petstore-basic.spex

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

Let's go throught the output line by line. 

  1. First we are told which server is getting checked and against which
     specification. One thing to note here is that the default host is
     `localhost`, but it can be changed with the `--host` flag;
  2. That the specification is being checked is referring to it being parsed,
     scope- and type-checked;
  3. Before the tests start we make sure that the system under test is up and
     running by checking if a helathpoint endpoint is returning a 200 response
     code. The health endpoint is assumed to be `/health` by default, but can
     be changed with the `--health` flag;
  4. The tests start, in this case we didn't find anything interesting. We can
     see that the test generated 49 `addPet` operations, which all succeded, and
     51 `getPet` which all returned 404 not found;
  5. We do see that `getPet` didn't get proper coverage properly, i.e. it
     always returned 404;
  6. Finally we are shown the seed used as basis for generating random
     operations. Note that we don't need to restart the server between test
     runs, it knows about the `_reset` endpoint and does the resets itself.

So while we didn't get any interesting test failures, didn't properly cover
`getPet`. Why is that? In order to explain this we need to understand how the
testing works.

## How the generative testing works

The way testing an implementaion against a specification works is by generative
testing. If you've seen property-based testing or fuzzing before, then you'll
hopefully find this familiar.

The way the tests work is as follows:

  1. Pick an operation from the specification, e.g. `getPet` or `addPet`;
  2. Generate random parameters for the operations, e.g. in the case of
     `getPet` the parameter is `petId` of type interger;
  3. Execute the operation against the implementation, i.e. make the HTTP
     request;
  4. Check if the response code is 2xx, if so go to 2, otherwise save the
     operation together with all preceding operations (these will minimised, or
     shrunk, and then presented as an interesting test case);
  5. Stop once we reached some amount of test cases, by default 100.

Now we are in a position to answer why `getPet` wasn't covered. If we look at the
specification for `getPet` we see that it takes a `petId` of type integer, and
as we just said this `petId` parameter gets randomly generated. So, assuming
that we are using 64 bit integers, we got $2^64$ values to pick from when
generating an integer. That means that the chance of generating a random
`petId` that has previously been generated during a `addPet` operation is
small, and therefore we 404 all the time! Let's have a look at how we can fix
this next.

## Introducing modal types

* Add @ to ensure reuse
* Add # to avoid reuse

- Keep track of previously generated values and sometimes try to use them
  during generation of new tests. For example, without this ability the
  `getPet` requests would all most certainly return 404.

-  Try running with `--no-shrinking` flag to see the original test case that
  failed.


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

* We've seen how writing a specification for an existing system gives us testing 

* Mocking for new systems or third-party dependencies

Next you might want to follow the [installation](install.html) instructions in
order to start running Spex on your own.

* Alpha...

