let kube = ../kubernetes.dhall

let prelude = ../prelude.dhall

let Union = ../union.dhall

let Rule = kube.PolicyRule.Type

let Roles = ./Roles.dhall

let f =
        λ(a : Type)
      → λ(xs : List a)
      → λ(x : Union)
      → if prelude.List.null a xs then [] : List Union else [ x ]

let g =
        λ(xs : List Rule)
      → prelude.Optional.default Bool (prelude.List.null Rule xs == False)

in    λ(i : Roles.Type)
    → let meta =
            kube.ObjectMeta::{ name = i.name, namespace = Some i.namespace }

      let serviceAccount =
                  if i.createAccount

            then  [ Union.ServiceAccount
                      kube.ServiceAccount::{
                      , metadata =
                          kube.ObjectMeta::{
                          , name = i.serviceAccount
                          , namespace = Some i.namespace
                          }
                      }
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
                  if g i.clusterRules i.createClusterBinding

            then  [ Union.ClusterRoleBinding
                      kube.ClusterRoleBinding::{
                      , metadata = meta
                      , roleRef =
                          { apiGroup = "rbac.authorization.k8s.io"
                          , kind = "ClusterRole"
                          , name =
                              prelude.Optional.default
                                Text
                                i.name
                                i.clusterRoleRefName
                          }
                      , subjects =
                          [ { kind = "ServiceAccount"
                            , name = i.serviceAccount
                            , namespace = Some i.namespace
                            , apiGroup = None Text
                            }
                          ]
                      }
                  ]

            else  [] : List Union

      let role =
            f
              Rule
              i.rules
              (Union.Role kube.Role::{ metadata = meta, rules = i.rules })

      let roleBinding =
                  if g i.rules i.createRoleBinding

            then  [ Union.RoleBinding
                      kube.RoleBinding::{
                      , metadata = meta
                      , roleRef =
                          { apiGroup = "rbac.authorization.k8s.io"
                          , kind = "Role"
                          , name =
                              prelude.Optional.default Text i.name i.roleRefName
                          }
                      , subjects =
                          [ { kind = "ServiceAccount"
                            , name = i.serviceAccount
                            , namespace = Some i.namespace
                            , apiGroup = None Text
                            }
                          ]
                      }
                  ]

            else  [] : List Union

      in    serviceAccount # clusterRole # clusterBinding # role # roleBinding
          : List Union
