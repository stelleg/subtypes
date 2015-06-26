% Subtypes for Free!
% George Stelle and Stephanie Forrest

Introduction
==========
Haskell's popularity is in large part thanks to its powerful type system which 
prevents a large class of runtime errors. Still, there are a class of function
that expect only a subtype of their declared argument type, e.g. `head`, that
can fail at runtime. We present an approach to subtyping GADTs using rank-n
types that allows us to define versions of these functions that cannot fail. 

Existing Approaches
===================
There is much too broad a literature on subtyping to cover here, from
inheritance in object oriented languages and Liskov's substitution principle
\cite{liskov1994behavioral} to row and record polymorphism to phantom types and
generalized algebraic data types (GADTs) [\cite{odersky2004overview,
leroy2014ocaml}]. We instead focus on what these techniques *can't* do. Namely,
as far as we are aware, *no existing subtyping scheme can, for a given GADT,
define __and infer__ types for arbitrary subsets of the constructors*. For
example, we are not aware of any subtyping scheme able to infer that:

```haskell
   null nil :: True
```

where `null` checks if a list is empty, `nil` is the empty list, and `True` is
a subtype of `Bool`. We present an approach that enables this kind of inference. 

Our Approach
============
By inferring `Bool` as the type of `True`, we are losing precision in the type
system about what the value can be. What we would like is for the type system to
be precise when possible, so instead of always inferring `Bool`, it could infer
`True`, `False`, or `Bool`, where `True` and `False` are *subtypes* of `Bool`,
i.e. every value of type `True` is also of type `Bool`. We present an approach
that enables this class of inference, and show how it can prevent run-time
errors by replacing partial functions with their total counterparts, e.g. `head`
and `tail`.  

We use Scott encoding of algebraic data types, along with the Glasgow Haskell
Compiler's (GHC's) type inference with rank-n polymorphism to achieve a very
general form of subtype polymorphism. 

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
One application of subtyping is to prevent runtime failures. Here we show how to
use our approach to define a total version of `fromJust` from the Haskell
standard library.

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
that the value is of type `Just`, we don't care what the `n` type is, and only
constrain the return type to be the same as the `Just` case `j`.

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
[\cite{wadler1989theorems}]. 

\bibliography{subtypes}

