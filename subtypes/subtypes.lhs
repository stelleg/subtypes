% Subtypes for Free!
% George Stelle

Introduction
==========
Haskell's popularity is in large part due to its powerful type system, which 
prevents a large class of runtime errors. Still, there is a class of runtime
errors which the type system does not prevent because some functions assume a
subtype of the declared argument type. For example, the `head` function can fail
at runtime if the argument nil. Partial function errors of this sort can be
prevented with appropriate subtype inference. We present an approach to
implementing generalized algebraic data types (GADTs) using rank-n types that
supports subtype inference to prevent these kinds of failures.

Previous Work
===================
There is a vast literature on subtyping, from inheritance in object-oriented
languages and Liskov's substitution principle [\cite{liskov1994behavioral}] to row
and record polymorphism to phantom types and generalized algebraic data types
(GADTs) [\cite{odersky2004overview, leroy2014ocaml}]. This work has enabled many
powerful type systems, but to our knowledge, none of these subtyping schemes
support inference over arbitrary subsets of the constructors. For example, we are
not aware of any subtyping scheme that infers:

```haskell
   null nil :: True
```

where `null` checks if a list is empty, `nil` is the empty list, and `True` is
a subtype of `Bool`. We present an approach that enables this kind of inference. 

Approach
============
As a simple example of the class of subtyping we investigate, consider a typical
Haskell inference, `True :: Bool`.  Inferring `Bool` as the type of `True` loses
information about the expression's possible values. Ideally, the type system
would be as precise as possible, so instead of always inferring `Bool`, it could
infer `True`, `False`, or `Bool`, where `True` and `False` are *subtypes* of
`Bool`, i.e. every value of type `True` is also of type `Bool`. This level of
precision can prevent certain types of run-time errors by replacing partial
functions with their total counterparts.  

We use Scott encoding of algebraic data types, along with the Glasgow Haskell
Compiler's (GHC's) type inference with rank-n polymorphism to achieve a general
form of subtype polymorphism. TODO: More precise.
Scott encodings implement algebraic data types by encoding their own `case`
deconstruction using lambda expressions. By wrapping the Scott encodings in a
`newtype`, and then carefully constraining the types, we can define types that
represent arbitrary subsets of the constructors. This approach allows us to
typecheck the following examples, among others:

```haskell
   true :: True
   and true false :: False
   head :: Cons a -> a
   fromJust :: Just a -> a
   null nil :: True
```

Preventing Runtime Failures with Subtype Inferencing
==========
We illustrate our approach by defining a total version of `fromJust`
from the Haskell standard library.

Define a `Maybe` type as a replacement for Haskell's `data Maybe a = Just a |
Nothing`. The Scott encoding for `Maybe` takes two case
arguments, the first, of type `n`, corresponding to `nothing`, so it has no
parameters, and the second, of type `a -> j`, corresponding to `just a`, so it
has one parameter of type `a`. 

>   newtype Maybe' a n j m = Maybe (n -> (a -> j) -> m)
>   type Maybe a = forall m. Maybe' a m m m 
>   type Just a = forall n j. Maybe' a n j j
>   just :: a -> Just a
>   just a = Maybe $ \n j -> j a
>   type Nothing = forall a n j. Maybe' a n j n
>   nothing :: Nothing
>   nothing = Maybe $ \n j -> n

For the 'Maybe' type, similar to the `maybe` function from Haskell's
`Data.Maybe`, we don't know whether we have a value of type `Just` or a value of
type `Nothing`, so we must ensure that both cases return the same type. But,
if the compiler can infer that the value is of type `Just`, we don't care what
the `n` type is, and only constrain the return type to be the same as the
`Just` case `j`.

With that in mind, we now write the total function `fromJust`. As a sanity
check, we define the type `Bottom` which has no values and observe that the
function never typechecks `fromJust` applied to a type that includes
`Nothing`:

>   fromJust :: Just a -> a
>   fromJust (Maybe j) = j bottom $ \a->a
>
>   data Bottom
>   bottom = error "impossible" :: Bottom

By contrast, the partial function `partialFromJust`, identical to that defined
in the Haskell standard library, allows runtime failures.

>   partialFromJust :: Maybe a -> a
>   partialFromJust (Maybe m) = m (error "partialFromJust Nothing") $ \a->a 

More elaborate examples, including recursive types, GADTs, and total versions of
`head` and `tail`, are implemented and available at
[http://cs.unm.edu/~stelleg/scott/](http://cs.unm.edu/~stelleg/scott/).

We are currently formalizing and verifying this approach using parametricity.
[\cite{wadler1989theorems}]. 

Conclusion
===========
Powerful forms of subtyping such as we have shown here could help Haskell
programs avoid some classes of run-time errors, by defining total versions of
existing partial functions.
As the Haskell language continues to mature and gain wider acceptance in the
programming community, automatic prevention of runtime errors also becomes more
important.

\bibliography{subtypes}

