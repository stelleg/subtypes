% Subtypes for Free!

Sometimes it would be nice if a type system could automatically "do it's best"
to restrict what a value will be. For example, the type `Bool` is the compiler
saying the value will either be `True` or `False`, but it doesn't know which.
What we want is the compiler to be able to be precise when possible, so instead
of always saying `Bool` (or "I don't know"), it could say `True`, `False`, or
`Bool`. This post shows how GHC (and really any Hindley-Milner-based type
system) already has this capability that can be exercised by using Church or
Scott encodings of simple data types.

> {-# LANGUAGE RankNTypes #-}
> {-# LANGUAGE GADTs #-}
> import qualified Data.Maybe as M
> import Prelude hiding (and, or, Maybe, Bool, map, not, null, head)
> data Bottom
> bottom :: Bottom
> bottom = undefined

Booleans 
============

Instead of the standard data constructors, we define church booleans. `True` and
`False` are synonyms for the types inferred for `true` and `false`, respectively.

> newtype Bool' t f b = Bool (t -> f -> b)
> type Bool = forall b. Bool' b b b
> type True = forall t f. Bool' t f t
> true :: True
> true = Bool $ \t f -> t
> type False = forall t f. Bool' t f f
> false :: False
> false = Bool $ \ t f -> f

We can define logical `or` and `and`, leaving the types blank intentionally

> if' :: Bool' a b c -> a -> b -> c
> if' (Bool c) a b = c a b
>
> not (Bool c) = c false true
> or (Bool a) b = a true b 
> and (Bool a) b = a b false

Some tests, showing us that GHC infers precise types

> test1 = true `and` false :: False
> test2 = true `and` true  :: True
> test3 = true `or` false  :: True

We can create corresponding type for `Bool`

> showBool :: Bool -> String
> showBool (Bool b) = b "true" "false"

Indeed, GHC will infer this type if we force it to unify `True` and `False`:

> g = [true, false] :: [Bool' a a a]

Maybe 
=====

We can encode combinations of product and sum types, e.g. `Maybe a`, in a data
type, with the general type 

> newtype Maybe' a n j m = Maybe (n -> (a -> j) -> m)
> type Maybe a = forall m. Maybe' a m m m 
> type Just a = forall n j. Maybe' a n j j
> just :: a -> Just a
> just a = Maybe $ \n j -> j a
> type Nothing = forall a n j. Maybe' a n j n
> nothing :: Nothing
> nothing = Maybe $ \n j -> n

We can use the more precise types to construct a version of `fromJust` that is
total

> fromJust :: Just a -> a
> fromJust (Maybe p) = p bottom id 

Now, the following expression would create a type error:

```haskell
  typeError = fromJust (just 1) + fromJust nothing
```

This is in contrast with using the partial function with the algebraic data
types, which will typecheck the `typeError` example without complaint:

> runTimeError = M.fromJust (Just 1) + M.fromJust Nothing

Wizards and Warriors
====================

We now turn to a slightly more complex (and fun) example. We'll try and
implement [Eric Lippert's problem of trying to represent subtypes in game with
wizards and warriors](http://ericlippert.com/2015/04/27/wizards-and-warriors-part-one/). 
To summarize, want to describe the following types for a game:

- A weapon is a sword, a staff, or a dagger.
- A player is a warrior or a wizard.
- Every player has a weapon.
- A warrior can't use a staff.
- A wizard can't use a sword. 

We can translate these rules into our scott encoding as follows:

> newtype Player' wiz war pl = Player ((NotSword -> wiz) -> 
>                                      (NotStaff -> war) ->
>                                      pl)
> type Player = forall pl. Player' pl pl pl


A player is either a wizard, which has a dagger or staff, or a warrior, which
has a dagger or sword.

> type Wizard = forall wiz war . Player' wiz war wiz
> wizard :: NotSword -> Wizard
> wizard wpn = Player $ \wiz war -> wiz wpn
>
> type Warrior = forall wiz war . Player' wiz war war 
> warrior :: NotStaff -> Warrior
> warrior wpn = Player $ \wiz war -> war wpn
>
> showClass :: Player -> String
> showClass (Player p) = p (const "wizard") (const "warrior")
>
> headWizard, thiefWizard :: Wizard
> headWizard = wizard staff 
> thiefWizard = wizard dagger

Now if we try and create a wizard with a sword: `wizard sword`, we'll get a type
error. The weapon is a simple sum type, similar to our `Boolean` type above.

> newtype Weapon' sw d st w = Weapon (sw -> d -> st -> w)
> type Weapon = forall a. Weapon' a a a a 
>
> staff = Weapon $ \st dg sw -> st
> dagger = Weapon $ \st dg sw -> dg
> sword = Weapon $ \st dg sw -> sw
>
> showWeapon :: Weapon -> String
> showWeapon (Weapon w) =  w "staff" "dagger" "sword"

We don't bother creating type synonyms for our constructors, as we're more
interested in the following types:

> type NotSword = forall sw nsw. Weapon' nsw nsw sw nsw
> type NotStaff = forall st nst. Weapon' st nst nst nst

These let us express our subtypes exactly as needed. 

We can also write an accessor function to get the weapon from a player. Note
that we leave the type signature out. If we were to add the naive signature
`weapon :: Player -> Weapon` we would lose some type inference power. For
example, we would lose the fact that `weapon . warrior :: NotStaff`, and instead
get `weapon . warrior :: Weapon`.

> weapon (Player p) = p id id

Letting GHC infer the most general type for `weapon`,  when we check
the type of `weapon . warrior`, we get `NotStaff -> NotStaff`, as desired.  Now we can
write a function that only accepts warriors, which calls a function that depends
on the type of the weapon being `NotStaff`.

> spinToWin :: Warrior -> IO ()
> spinToWin w = putStrLn $ "Warrior perform deadly spin for " ++
>   (show $ spinDamage $ weapon w) ++ " damage"
>
> spinDamage :: NotStaff -> Int
> spinDamage (Weapon w) = w bottom 10 20

Lists
=====

> newtype List' a b c d = List (b->(a->(List a)->c)->d)
> type Nil = forall a n c. List' a n c n
> nil :: Nil
> nil = List $ \n c -> n
> type Cons a = forall n c. List' a n c c
> cons :: a -> List a -> Cons a
> cons h t = List $ \n c -> c h t
> type List a = forall l. List' a l l l
>
> head :: Cons a -> a
> head (List l) = l bottom (\h t->h) 
>
> tail :: Cons a -> List a
> tail (List l) = l bottom (\h t->t) 
>
> null :: List' a (Bool' t f t) (Bool' t f f) l -> l
> null (List l) = l true (\h t->false)
>
> (-:-) :: a -> List a -> Cons a
> (-:-) h t = cons h t
>
> map :: (a -> b) -> List' a (List' b n c n) (List' b n c c) t -> t
> map f (List l) = l nil (\h t -> f h -:- map f t)
>
> index :: Int -> List a -> a
> index 0 (List l) = l (error "index") $ \h t -> h
> index n (List l) = l (error "index") $ \h t -> index (n-1) t

GADT Example
============
A canonical example for GADTs is typesafe evaluation of a language with Ints
and Bools. We show how we can implement it using subtypes

> newtype Term' int add bool not term = Term
>   ((Int -> int) ->
>    (IntTerm -> IntTerm -> add) ->
>    (Bool -> bool) ->
>    (BoolTerm -> not) ->
>    term)
> type IntTerm = forall i ni. Term' i i ni ni i
> type BoolTerm = forall b nb. Term' nb nb b b b
> type Term t i b = Term' i i b b t
> int :: Int -> IntTerm
> int k = Term $ \i a b n -> i k
> add :: IntTerm -> IntTerm -> IntTerm
> add x y = Term $ \i a b n -> a x y
> bool :: Bool -> BoolTerm
> bool b' = Term $ \i a b n -> b b'
> tnot :: BoolTerm -> BoolTerm
> tnot b' = Term $ \i a b n -> n b'
> evalTerm :: Term t Int (Bool' a a a) -> t
> evalTerm (Term t) = t 
>   (\i -> i)
>   (\a b -> evalTerm a + evalTerm b)
>   (\b -> b)
>   (\b -> not (evalTerm b))

Call by Name
===============
Another useful subtype is the value subtype of expressions. Here we use this
subtype to define a big step evaluator.

> newtype Expr' v l a e = Expr ((Int -> v) -> 
>                               (Expr -> l) ->
>                               (Expr -> Expr -> a) ->
>                               e)
> type Expr = forall e. Expr' e e e e 
> var :: Int -> Expr' v l a v
> var i = Expr $ \v l a -> v i
> type Value = forall v l a. Expr' v l a l
> lam :: Expr -> Value
> lam b = Expr $ \v l a -> l b
> app :: Expr -> Expr -> Expr' v l a a
> app m n = Expr $ \v l a -> a m n
>
> showExpr :: Expr -> String
> showExpr (Expr e) = e 
>   (\i -> show i)
>   (\b -> 'λ':showExpr b)
>   (\m n -> "(" ++ showExpr m ++ " " ++ showExpr n ++ ")")
>
> -- Subst i for e in e'
> subst :: Int -> Expr -> Expr -> Expr
> subst i e (Expr e') = e'
>   (\j -> if j == i then e else var j)
>   (\b -> lam $ subst (i+1) e b) 
>   (\m n -> app (subst i e m) (subst i e n))
>
> eval :: Expr -> Value
> eval (Expr exp) = exp
>   (\i -> error "Expression not closed")
>   (\b -> lam b)
>   (\m n -> case eval m of 
>     Expr v -> v
>       (\i -> bottom) 
>       (\b -> eval $ subst 0 n b) 
>       (\m n -> bottom))

We also haven't *proved* that our constructors and types all match up. That is,
the type system has proved some things about them, but really we should be
using parametricity to prove things like `Boolean` = {`true`, `false`}.


[This post is a literate haskell file compiled by pandoc.](./subtypes.lhs)
