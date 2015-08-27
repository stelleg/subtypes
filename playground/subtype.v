(*Booleans*)
Definition Bool : Type := forall b, b -> b -> b.
Definition True : Type := forall t f, t -> f -> t.
Definition False : Type := forall t f, t -> f -> f.

(*Maybe*)
Definition Maybe (a:Type) : Type := forall m, m -> (a -> m) -> m.
Definition Just (a:Type) : Type := forall n j, n -> (a -> j) -> j.
Definition Nothing (a:Type): Type := forall n j, n -> (a -> j) -> n.

(*Eithers*)
Definition Either (a b : Type) : Type := forall e, (a -> e) -> (b -> e) -> e.
Definition Left (a b : Type) : Type := forall l r, (a -> l) -> (b -> r) -> l. 
Definition Right (a b : Type) : Type := forall l r, (a -> l) -> (b -> r) -> r.

Definition coerce {g : forall a b : Type, Type} (f : forall a b, g a b) (a :Type) : 
  g a a := f a a.

Example true_bool : True -> Bool := coerce.
Example false_bool : False -> Bool := coerce.

Example just_maybe (a : Type) : Just a -> Maybe a := coerce.
Example nothing_maybe (a : Type): Nothing a -> Maybe a := coerce.

Example left_either (a b : Type) : Left a b -> Either a b := coerce.
Example right_either (a b : Type) : Right a b -> Either a b := coerce.


