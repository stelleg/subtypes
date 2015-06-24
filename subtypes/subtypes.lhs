% Subtypes for Free!
% George Stelle and Stephanie Forrest

Motivation
==========
It would be nice if a type system could be as precise as possible to restrict
what a value will be. In Haskell, for example, the type `Bool` ensures a value
will either be `True` or `False`. What we want is the type system to be precise
when possible, so instead of always inferring `Bool`, it could infer `True`,
`False`, or `Bool`, where `True` and `False` are *subtypes* of `Bool`, i.e.
every value of type `True` is also of type `Bool`. This preciseness can ensure
the prevention of run-time errors by removing partial functions, like `head` and
`tail`.

Existing Approaches
===================
There is a significant literature on subtyping, mostly in the context of
object-oriented (OO) languages. Indeed, subtyping in languages that combine
OO features with functional features implement subtypes using objects
\cite{odersky2004overview, leroy2014ocaml}. 

Generalized algebraic data types (GADTs) enable a limited form of subtyping as
well \cite{fluet2006phantom}. For example, in the canonical example of a simple
language with booleans and integers, `Expr Int` are distinct from `Expr Bool`,
while both are subtypes of `Expr a`.

For both the OO and the GADT approaches, we are not aware of any
capable of inferring:

```haskell
   null nil :: True
```

where `null` checks if a list is empty and `nil` is the empty list.

Our Approach
============
We use Scott encoding of algebraic data types, along with the Glasgow Haskell
Compiler's (GHC's) type inference, to achieve a very general form of subtype
polymorphism. We show how GHC can take advantage of this approach without
modification by ~~abusing~~ taking full advantage of rank-n types. 

Scott encodings are implementations of algebraic data types that encode their
own `case` destruction using lambda expressions. Our primary insight is that by
wrapping the Scott encodings in a `newtype`, and then carefully constraining the
types, we can define types that represent arbitrary subsets of the constructors.

This allows us to type the following examples, among others:

```haskell
   true :: True
   and true false :: False
   head :: Cons a -> a
   fromJust :: Just a -> a
   null nil :: True
```

An Example
==========
One application of subtyping is to runtime failures. Here we show how to use our
approach to define a total version of `fromJust` from the Haskell standard
library.

To achieve this, we define a `Maybe` type as a replacement for Haskell's `data
Maybe a = Just a | Nothing`. The Scott encoding for `Maybe` takes two *case*
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

Our `Maybe` type is analogous to the standard `Data.Maybe` type in Haskell. In
this case, similar to the `maybe` function from `Data.Maybe`, we don't know
whether we have a value of type `Just` or a value of type `Nothing`, so we must
ensure that the two cases return the same type. But if the compiler can infer
that the value is of type `Just`, we don't care what the `n` cases type is, and
only constrain the return type to be the same as the `Just` case `j`.

With that in mind, we can write our total `fromJust`, using a `Bottom` type with
no values to convince ourselves that our function will never typecheck
`fromJust` applied to a type that includes `Nothing`.

>   fromJust :: Just a -> a
>   fromJust (Maybe j) = j bottom $ \a->a
>
>   data Bottom
>   bottom = error "impossible" :: Bottom

We can still define the partial version of `fromJust`, which like the one from
the Haskell standard library, allows runtime failure.

>   partialFromJust :: Maybe a -> a
>   partialFromJust (Maybe m) = m (error "partialFromJust Nothing") $ \a->a 

We have implemented more sophisticated examples, including recursive types,
GADTs, and total versions of `head` and `tail`, available at
[http://cs.unm.edu/~stelleg/scott/](http://cs.unm.edu/~stelleg/scott/).

Conclusion
===========
We have shown how to attain powerful form of subtyping in Haskell using basic
extensions. The resulting subtypes allow us to define total versions of existing
partial functions, preventing runtime errors. We are currently working on
formalizing and verifying this approach using parametricity
\cite{wadler1989theorems}. 

\bibliographystyle{abbrvnat}
\bibliography{subtypes}

