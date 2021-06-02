let prelude = (./packages.dhall).prelude

let NonEmpty = λ(a : Type) → { head : a, tail : List a }

let nonEmptyHead = λ(a : Type) → λ(list : NonEmpty a) → list.head

let nonEmptyCreate =
        λ(a : Type)
      → λ(head : a)
      → λ(tail : List a)
      → { head = head, tail = tail } : NonEmpty a

let nonEmptyToList =
      λ(a : Type) → λ(input : NonEmpty a) → [ input.head ] # input.tail

let nonEmptyMap =
        λ(a : Type)
      → λ(b : Type)
      → λ(f : a → b)
      → λ(input : NonEmpty a)
      → { head = f input.head, tail = prelude.List.map a b f input.tail }

let listIndexedMap =
        λ(a : Type)
      → λ(b : Type)
      → λ(f : Natural → a → b)
      → λ(list : List a)
      → let Indexed = { index : Natural, value : a }

        in  prelude.List.map
              Indexed
              b
              (λ(x : Indexed) → f x.index x.value)
              (prelude.List.indexed a list)

let listIntegerElementOf =
        λ(x : Integer)
      → prelude.List.any Integer (λ(y : Integer) → prelude.Integer.equal x y)

let textPrepend = λ(a : Text) → λ(b : Text) → a ++ b

in  { NonEmpty =
        { head = nonEmptyHead
        , create = nonEmptyCreate
        , map = nonEmptyMap
        , toList = nonEmptyToList
        , Type = NonEmpty
        }
    , List =
        { indexedMap = listIndexedMap, integerElementOf = listIntegerElementOf }
    , Text.prepend = textPrepend
    }
