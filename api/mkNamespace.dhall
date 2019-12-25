let kube = ../kubernetes.dhall

in    λ(name : Text)
    → [ kube.Resource.Namespace
          kube.Namespace::{ metadata = kube.ObjectMeta::{ name = name } }
      ]
