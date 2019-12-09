let kube = ../kubernetes.dhall
let union = ../union.dhall

in    λ(name : Text)
    → [ union.Namespace kube.Namespace::{ metadata = kube.ObjectMeta::{ name = name } } ]
