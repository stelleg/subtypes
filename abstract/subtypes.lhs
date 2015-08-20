% Subtypes for Free!

Introduction
==========
Haskell's popularity is in large part due to its powerful type system, which 
prevents a large class of runtime errors. Unfortunately, it doesn't prevent some
runtime errors caused by partial functions which are only defined for a subtype of
their input type. For example, the `head` function will fail at runtime if the
argument is the empty list. Some errors of this sort can be prevented with
appropriate subtype inference. We present an approach to implementing algebraic
data types (ADTs) using Scott encodings and rank-n types that supports subtype
inference to prevent these kinds of failures.

Previous Work
=============
With a few exceptions, work on subtypes has focused on defining a subtype
heirarchy over the entire type space [\cite{mitchell1991type,
liskov1994behavioral}].  Our work is less ambitious in scope: we only define
subtypes within the type of an ADT.  Similar in spirit to Scala's `case class`
constructs [\cite{odersky2004overview}], our approach enables type inference
over arbitrary subsets of the constructors of an ADT.

Like our technique, generalized algebraic data types (GADTs) use parametric
polymorphism to implement subtypes of ADTs [\cite{fluet2006phantom}].  Indeed,
the connection is deeper: for the canonical GADT example of a simple language
with booleans and integers, one can implement a type-safe evaluator using our
approach or GADTs. We suspect that there is significant overlap between the
approaches, and are working on proving that this is the case.

We address the following gap in the literature: we are not aware of any
subtyping scheme that infers

```haskell
   null nil :: True
```

where `null` checks if a list is empty, `nil` is the empty list, and `True` is a
subtype of `Bool` [^caseclass]. 


[^caseclass]: Scala's `case class` construct is capable of something similar,
but only with methods, e.g. `Nil().nil : True`. 

Approach
========
Using parametric polymorphism to define subtypes is at the core of our approach.
Consider the Church/Scott boolean functions `true t f = t` and `false t f = f`.
`true` is of type `a -> b -> a`, and `false` is of type `a -> b -> b`. If we
unify the two types, we get `a -> a -> a`. If we alias the types to `True`,
`False,` and `Bool`, respectively, `True` and `False` are subtypes of `Bool`,
i.e. every value of type `True` is also of type `Bool`.

To implement this approach for any ADT, we use Scott encodings along with the
Glasgow Haskell Compiler's (GHC's) rank-n type inference. Scott encodings
implement ADTs by encoding their own `case` deconstruction using lambda
expressions, like the boolean case above. By wrapping the Scott encodings in a
`newtype`, and then carefully constraining the types, we can define types that
represent arbitrary subsets of an ADT's constructors. This allows us to
typecheck the following examples, among others:

```haskell
   true :: True
   true `and` false :: False
   head :: Cons a -> a
   fromJust :: Just a -> a
   null nil :: True
```

We are currently formalizing and verifying our approach using parametricity
[\cite{wadler1989theorems}]. 

Preventing Runtime Failures with Subtypes
==========
We illustrate our approach by defining a total version of `fromJust` from the
Haskell standard library.

We define a `Maybe` type as a replacement for Haskell's `data Maybe a = Just a |
Nothing`. The Scott encoding for `Maybe` takes two case arguments. The first, of
type `n`, corresponds to `nothing`, so it has no parameters, and the second, of
type `a -> j`, corresponds to `just a`, so it has one parameter of type `a`. 

>   newtype Maybe' a n j m = Maybe (n -> (a -> j) -> m)
>   type Maybe a = forall m. Maybe' a m m m 
>   type Just a = forall n j. Maybe' a n j j
>   just :: a -> Just a
>   just a = Maybe $ \n j -> j a
>   type Nothing = forall a n j. Maybe' a n j n
>   nothing :: Nothing
>   nothing = Maybe $ \n j -> n

For the `Maybe` type above, like standard case deconstruction in Haskell, we
don't know whether we have a value of type `Just a` or a value of type
`Nothing`, so we must ensure that both cases return the same type. But, if the
compiler can infer that the value is of type `Just a`, we don't care what the
`n` type is, and only constrain the return type to be the same as the `Just`
case, `j`.

With that in mind, we now define our total function `fromJust`. As a sanity
check, we define the type `Bottom` which has no values and observe that the
function never typechecks `fromJust` applied to a type that includes
`Nothing`:

>   fromJust :: Just a -> a
>   fromJust (Maybe j) = j bottom $ \a->a
>
>   data Bottom
>   bottom = undefined :: Bottom

By contrast, the partial function `partialFromJust`, identical to that defined
in the Haskell standard library, allows runtime failures.

>   partialFromJust :: Maybe a -> a
>   partialFromJust (Maybe m) = m (error "partialFromJust Nothing") $ \a->a 

More elaborate examples are implemented and available at
[http://cs.unm.edu/~stelleg/scott/](http://cs.unm.edu/~stelleg/scott/).

Conclusion
===========
As Haskell continues to grow in popularity, automatic prevention of runtime
errors becomes even more valuable. The restricted form of subtyping shown here
could help Haskell programs avoid some classes of run-time errors by defining
total versions of existing partial functions.  

\bibliography{subtypes}

