let prelude = ./prelude.dhall

let NonEmpty = λ(a : Type) → { head : a, tail : List a }

let nonEmptyHead = λ(a : Type) → λ(list : NonEmpty a) → list.head

let nonEmptyCreate =
        λ(a : Type)
      → λ(head : a)
      → λ(tail : List a)
      → { head = head, tail = tail } : NonEmpty a

let nonEmptyToList =
      λ(a : Type) → λ(input : NonEmpty a) → [ input.head ] # input.tail

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

let textPrepend = λ(a : Text) → λ(b : Text) → a ++ b

in  { NonEmpty =
        { head = nonEmptyHead
        , create = nonEmptyCreate
        , toList = nonEmptyToList
        }
    , List = { indexedMap = listIndexedMap }
    , Text = { prepend = textPrepend }
    }
