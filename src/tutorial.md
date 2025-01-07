---
title: Tutorial - Spex
date: 2025-01-07T00:00:00Z
---

# Tutorial

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

## An example system: petstore

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

Let's go thought the output line by line. 

  1. First we are told which server is getting checked and against which
     specification. One thing to note here is that the default host is
     `localhost`, but it can be changed with the `--host` flag;
  2. That the specification is being checked is referring to it being parsed,
     scope- and type-checked;
  3. Before the tests start we make sure that the system under test is up and
     running by checking if a health endpoint is returning a 200 response
     code. The health endpoint is assumed to be `/health` by default, but can
     be changed with the `--health` flag;
  4. The tests start, in this case we didn't find anything interesting. We can
     see that the test generated 49 `addPet` operations, which all succeeded, and
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

The way testing an implementation against a specification works is by generative
testing. If you've seen property-based testing or fuzzing before, then you'll
hopefully find this familiar.

The way the tests work is as follows:

  1. Pick an operation from the specification, e.g. `getPet` or `addPet`;
  2. Generate random parameters for the operations, e.g. in the case of
     `getPet` the parameter is `petId` of type integer;
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

## Abstract type modality 

We've seen how by always generating new `petId`s we'll rarely call `getPet`
with a `petId` that has previously been added via `addPet`. 

If only we could say something like "don't make up random `petId`, but rather
reuse ones that you've seen already in previous operations"...

Well as it so happens, there's a feature to do exactly that. It's called
abstract modality, i.e. the random generation machinery should treat them as
abstract and not try to generate them randomly.

The syntax for saying that a type should be treated as abstract is the following:

  ```diff
  $ diff -u example/petstore-basic.spex example/petstore-modal.spex
    addPet : POST /pet Pet
  - getPet : GET /pet/{petId : Int} -> Pet
  + getPet : GET /pet/{petId : @Int} -> Pet
  ```

The mnemonic being `@` looks like an "A", which is the first letter of
abstract. If we run the tests again with this newly changed specification, we
see the following:

```shell
✓ Done testing!

  Found 0 intereresting test case.

  Coverage:
    2xx:
      15% getPet (15 ops)
      52% addPet (52 ops)
    404:
      33% getPet (33 ops)


  Total operations (ops): 100

  Use --seed 6320047119747240588 to reproduce this run.
```

Notice that we got fewer 404 errors now, because of the abstract (`@`)
annotation on `petId`.

How is this implemented? Basically any time we generate any value, e.g. a
`petId` as part of an `addPet` operation, we store it in a "generation
environment". If a type is annotated with the abstract modality, we'll reuse
old values from the generation environment.

Responses from operation also gets stored in the generation environment, and
maybe be reused when generating subsequent operations.

## Unique type modality

The abstract type modality ensure that values of the underlying type get
reused, but what if we wanted to do the opposite -- enforce that values never
get reused?

This can be achieved with the unique type modality (`#`). The mnemonic being
that "#" character is pronounced "hash" and (cryptographic) hashing functions
uniquely identify its inputs.

We've already seen an example of when this might be useful. If we try to add a
pet with a pet id that already has been added we get a "409 Pet already exists"
error, if we want to tell Spex to avoid generating add pet operations that
result in conflicts, we can change the specification as follows:

```diff
  $ diff -u example/petstore-basic.spex example/petstore-modal.spex
  - addPet : POST /pet Pet
  + addPet : POST /pet #Pet
    getPet : GET /pet/{petId : @Int} -> Pet
```

## Mocking APIs

We've seen how to check that an existing system adheres to a specification.

In order to show how a specification can be useful before the system is
implemented, let's have a look at mocking.

To start a mock server, use the `mock` subcommand:

```shell
$ spex mock example/petstore-basic.spex
i Starting mock server on http://localhost:8080
  Use --seed -684280361768894873 to reproduce this mock.
```

In another terminal, we can interact with the mock. For example we can pretend
we are adding a new pet:

```bash
$ http POST :8080/pet petId=1 petName="apa"
HTTP/1.1 200 OK

[]
```

Or pretend we are retrieving a pet by its `petId` as follows:

```bash
$ http GET :8080/pet/1
HTTP/1.1 200 OK

{"petId":-543,"petName":"foo"}
```

Note however that we don't get back the same pet that we added! The
specification isn't an implementation, and not rich enough to describe that if
we add a pet with some id and then try to get a pet with the same id that we
should get back the same pet[^1]...

The way mocks work is that they accept requests with parameters of the right
type and return randomly generated values of the right return type.

## Conclusion

We've seen how writing a specification for an existing system gives us
generative testing which can increase the coverage and find interesting
sequences of requests that result in non-2xx responses, JSON parsing errors or
unreachable endpoints.

We've also had a look at how we can get a mocking for new systems or
third-party dependencies from a specification, which can be useful in
integration testing.

Whether the server implementation or specification is written first doesn't
really matter, but longer term we hope that writing the specification first
will be helpful in developing the server (because it gives you tooling that
could be useful in the development). For more (future) uses of specifications,
see the [motivation](motivation.html) page.

Next you might want to follow the [installation](install.html) instructions in
order to start running Spex on your own. Although keep in mind that Spex is
still in alpha stage and not suitable for use on anything larger than toy
examples, such as the petstore we've seen above.


[^1]: One could imagine richer specifications that could describe this
    relationship though. Future releases of Spex might add such functionality,
    but for now it's not possible.
