let kube = ../kubernetes.dhall
let prelude = ../prelude.dhall
let Union = ../union.dhall

let Rule = kube.PolicyRule.Type

let f =
        λ(a : Type)
      → λ(xs : List a)
      → λ(x : Union)
      →       if prelude.Natural.isZero (prelude.List.length a xs)
        then  [] : List Union
        else  [ x ]

let Input =
      { serviceAccount : Text
      , createAccount : Bool
      , name : Text
      , namespace : Text
      , clusterRules : List Rule
      , rules : List Rule
      }

in    λ(i : Input)
    → let meta =
            kube.ObjectMeta::{ name = i.name, namespace = Some i.namespace }

      let serviceAccount =
                  if i.createAccount
            then  [ Union.ServiceAccount
                      kube.ServiceAccount::{ metadata = meta }
                  ]
            else  [] : List Union

      let clusterRole =
            f
              Rule
              i.clusterRules
              ( Union.ClusterRole
                  kube.ClusterRole::{ metadata = meta, rules = i.clusterRules }
              )

      let clusterBinding =
            f
              Rule
              i.clusterRules
              ( Union.ClusterRoleBinding
                  kube.ClusterRoleBinding::{
                  , metadata = meta
                  , roleRef =
                      { apiGroup = "rbac.authorization.k8s.io"
                      , kind = "ClusterRole"
                      , name = i.name
                      }
                  , subjects =
                      [ { kind = "ServiceAccount"
                        , name = i.serviceAccount
                        , namespace = Some i.namespace
                        , apiGroup = None Text
                        }
                      ]
                  }
              )

      let role =
            f
              Rule
              i.rules
              (Union.Role kube.Role::{ metadata = meta, rules = i.rules })

      let roleBinding =
            f
              Rule
              i.rules
              ( Union.RoleBinding
                  kube.RoleBinding::{
                  , metadata = meta
                  , roleRef =
                      { apiGroup = "rbac.authorization.k8s.io"
                      , kind = "Role"
                      , name = i.name
                      }
                  , subjects =
                      [ { kind = "ServiceAccount"
                        , name = i.serviceAccount
                        , namespace = Some i.namespace
                        , apiGroup = None Text
                        }
                      ]
                  }
              )

      in    serviceAccount # clusterRole # clusterBinding # role # roleBinding
          : List Union
