% Subtypes for Free!
% George Stelle, Stephanie Forrest

Motivation
==========
It would sometimes be nice if a type system could be as precise as possible to
restrict what a value will be. For example, the type `Bool` says the value will
either be `True` or `False`, but it doesn't know which.  What we want is the
type system to be precise when possible, so instead of always saying `Bool` (or
"I don't know"), it could say `True`, `False`, or `Bool`. In this example,
`True` and `False` are *subtypes* of `Bool`, in the sense that every value of
type `True` is also of type `Bool`. The ability  

Existing Approaches
===================
There is a significant literature on subtyping, mostly in the context of
object-oriented programming. Indeed, subtyping in languages that comnbine
object-oriented features with functional features implement subtypes using the
objects. OCaml, F#

Our Approach
============
Our approach is to use scott encodings of algebraic data types, along with
Hindley Milner type inference, to achieve subtype polymorphism. We show how 
GHC (and really any Hindley-Milner-based type system) can take advantage of this
approach already.

Example
=======
One reason to want subtyping is to prevent partial functions where possible. 
We show how to use our approach to define a total `fromJust` function by
defining a type `Possibly`, analagous to Haskell's `Maybe` type. To describe the
scott encoding in words, it takes two *case* expressions, the first
corresponding to `nothing`, so it has no parameters, and the second
corresponding to `just a`, so it has one parameter of type `a`. 

>   type Possibly a = forall b . b -> (a -> b) -> b
>   type Just a = forall b c . b -> (a -> c) -> c
>   just :: a -> Just a
>   just a n j = j a
>   type Nothing = forall a b . a -> b -> a
>   nothing :: Nothing
>   nothing n j = n

With those defined, we can write our total function, using a `Bottom` type with
no values to convince ourselves that our function will never typecheck
`fromJust` applied to a type that includes `nothing`.

>   data Bottom
>   bottom = error "impossible" :: Bottom
>   fromJust :: Just a -> a
>   fromJust j = j bottom id 

Now if we apply fromJust to anything of type `Maybe a` or `Nothing`, it will
fail, e.g.

```haskell
   typeError = fromJust (just 1) + fromJust nothing
```

We can still define the partial version of `fromJust`, which like the one from
the Haskell standard library, allows runtime failure.

>   partialFromJust :: Possibly a -> a
>   partialFromJust m = m (error "partialFromJust Nothing") id

For a more complex (and fun) example, where we solve [Eric Lippert's problem of
trying to represent subtypes in game with wizards and
warriors](http://ericlippert.com/2015/04/27/wizards-and-warriors-part-one/),
see: [http://cs.unm.edu/~stelleg/scott/](http://cs.unm.edu/~stelleg/scott/).

Limitations
===========
One issue with how we've presented this approach is that it uses only type
synonyms, so This problem is largely solvable by using `newtype`s, as one would to
distinguish synonyms of type `Int`. 

We also can't represent recursive types, like lists, because of the occurrs
check.  

Perhaps most importantly, we are working on proving that our types and
constructors are correct. In particular, we are working on showing that a
transformation from a class of finite generalized algebraic data types are sound  
