---
title: Motivation - Spex
---

# Motivation

*Work in progress*

## What is a "specification language"?

In a lecture, back in 2010, Joe Armstrong
[said](https://youtu.be/ieEaaofM7uU?list=PL_aCdZH3eJJVki0YqHbJtqZKSmcbXH0jP&t=68):

> "We need languages to describe encodings and protocols not machine
> instructions"

He then went on to elaborate saying that we have plenty (too many) programming
languages (e.g. C, Java, Go, Python, Erlang, etc) which at a high-level allow
us to manipulate machines via machine instructions (and syscalls). However we
only have a few *specification languages* which describe encodings and
protocols, i.e. describe what's going on *between* two, or more, machines!

In a later [talk](https://youtu.be/ed7A7r6DBsM?t=723) (2013) Joe has the
following slide:

![Joe Armstrong's talk "The How and Why of Fitting Things
Together"](asset/joe_protocols.png)

Where the black boxes are written using programming languages while the big red
arrow between is what Joe means with encodings and protocols. It's this big red
arrow which is what we need different languages for, and to distinguish them
from "normal" programming languages, we shall call them specification
languages.

*Spex* tries to be such a specification language.

## The difference between APIs, encoding and protocols 

Before we can start talking about the shortcomings of current specification
languages, it's helpful to first break down Joe's red arrow. It actually has
three components:

  1. The interface of the blackbox (the API), i.e. what messages the component
     accepts;
  2. The encoding of the messages, i.e. what bytes (or bits) are sent over the
     communication channel;
  3. The protocol, i.e. what sequences of messages are allowed.

Hopefully it's clear what encodings are (e.g. UTF-8 encoded JSON or binary
Protobuf messages), but it might be worth pondering the difference between APIs
and protocols.

In the latter of the above mentioned talks, Joe gives an example where merely
knowing the API isn't good enough. The example he gives is the POSIX filesystem
API:

  * `open`: takes a filepath and returns a file descriptor;
  * `write`: takes a file descriptor and string and returns how many bytes it
    successfully wrote;
  * `close`: takes a file descriptor and closes it, thus freeing up resources.

Nothing in the API says, for example, that we can't continue writing to a file
descriptor that has been closed! This is where protocols come in, saying for
example that we can only write to a file descritor that is open, etc.

## What are the problems with past approaches?

Now that we've established the differences between APIs, encodings and
protocols, we can start talking about where the current specification languages
fall short.

Consider for example OpenAPI specifications, they only talk about the API

* Syntax?
* Tooling?
  - Is the spec up to date?

* TypeSpec

* gRPC

* OpenAPI spec, json schema, protobufs, Thrift,
  [Avro](https://en.wikipedia.org/wiki/Apache_Avro),
  [ASN.1](https://en.wikipedia.org/wiki/ASN.1)

* session types, Joe's [UBF](https://erlang.org/workshop/2002/Armstrong.pdf)

* http://www.erlang-factory.com/upload/presentations/180/ErlangUserConference2009-NortonandFritchie.pdf

* Separate types from their encodings?

Few people write specifications for their software these days. The reason for
this clear: there are few benefits from doing so, especially when taking into
account the risk of the specification and the real system drifting out of sync
(i.e. either the system or the specification is changed, but we forget to
update the other).

Spex tries to address this shortcoming of specifications by in addition to
being a specification language, it's also a verifier that checks if some system
respects the specification -- thereby always ensuring that the two are in sync.

In the process of testing the real system against the specification is will
also produce minimal test cases for potential problems it notices along the way:

  - Non-2xx responses;
  - JSON response decoding and type issues;
  - Non-reachable APIs.

(We'll look at examples of how exactly this gets reported in the next section on
features.)

In the future we'd like to derive more useful functionality from
specifications, including:

  - Joe's contract checker;
  - Ability to import and export OpenAPI/Swagger, Protobuf, etc. Think of how
    Pandoc can covert between text formats, perhaps we can do the same between
    specifications;
  - Generate a prototype implementation from a specification, so that you can
    demo your idea or hand of a working server HTTP API to the frontend team
    before the actual backend is done (without risking that there will be a
    mismatch in the end, since the real backend is tested against the same
    specification as the prototype is derived from);
  - A REPL, which allows you to explore a system using a specification. Tab
    completion is provided for the API and random payload data is generated on
    the fly;
  - A time traveling debugger which enables you to step forwards and backwards
    through a sequence of API calls, in order to explore how the system evolves
    over time.
  - Lua templating (again similar to Pandoc) which enables code generation from
    specifications or the minimal test cases that the verifer produces;
  - The ability to refine types, e.g. `{ petId : Int | petId > 0 }` and be able
    to generate validation logic from these;
  - Generate diagrams for a better overview of how components are connected.

With this future functionality we hope to get to the point where there's a
clear benefit to writing specifications!

## Long term

* Machine-to-machine interfaces, might also want to specify human-to-machine
  interfaces (e.g. CLI, GUIs?)

* OpenAPI and Protobuf describe the interface of one machine, but what about
  the topology? I.e. which machine talks to which machine?

* The long term vision for *Spex* is allow for complete system specifications,
  rather than mere HTTP JSON API specifications. HTTP API specifications of
  components in a system captures how the components may be called, but they
  don't say how the components are related to each other. For example, one
  obvious thing that's missing is that there can be async message passing
  between the components. These more complete system specifications open up the
  potential for other kinds of tooling:
    - Linters that ensures global consistancy;
    - More complete documentation with diagrams for visualising how components
      are connected;
    - Generation of deployment related code;
    - Load testing.

* There are many programming languages, but relatively few specification
  languages. Lab for experimentation and research? Similar to how Haskell lab for PLT?

  By coevolving the language and the tooling, we can add features that will be
  hard to replicate in OpenAPI, e.g.:

    - Refinement types -- validation logic;
    - Model definitions -- fakes rather than mocks and better fuzzing.


## Conclusion

* What we mean by specification languages
* How the current approaches are lacking
* How we propose to fix the current problems and go beyond
