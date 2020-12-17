let kube = (../packages.dhall).kubernetes

let prelude = (../packages.dhall).prelude

let Rule = kube.PolicyRule.Type

let Roles = ./Roles.dhall

let f =
        λ(a : Type)
      → λ(xs : List a)
      → λ(x : kube.Resource)
      → if prelude.List.null a xs then [] : List kube.Resource else [ x ]

let g =
        λ(xs : List Rule)
      → prelude.Optional.default Bool (prelude.List.null Rule xs == False)

in    λ(i : Roles.Type)
    → let meta =
            kube.ObjectMeta::{ name = Some i.name, namespace = Some i.namespace }

      let serviceAccount =
                  if i.createAccount

            then  [ kube.Resource.ServiceAccount
                      kube.ServiceAccount::{
                      , metadata =
                          kube.ObjectMeta::{
                          , name = Some i.serviceAccount
                          , namespace = Some i.namespace
                          }
                      }
                  ]

            else  [] : List kube.Resource

      let clusterRole =
            f
              Rule
              i.clusterRules
              ( kube.Resource.ClusterRole
                  kube.ClusterRole::{ metadata = meta, rules = Some i.clusterRules }
              )

      let clusterBinding =
                  if g i.clusterRules i.createClusterBinding

            then  [ kube.Resource.ClusterRoleBinding
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
                      , subjects = Some
                          [ { kind = "ServiceAccount"
                            , name = i.serviceAccount
                            , namespace = Some i.namespace
                            , apiGroup = None Text
                            }
                          ]
                      }
                  ]

            else  [] : List kube.Resource

      let role =
            f
              Rule
              i.rules
              ( kube.Resource.Role
                  kube.Role::{ metadata = meta, rules = Some i.rules }
              )

      let roleBinding =
                  if g i.rules i.createRoleBinding

            then  [ kube.Resource.RoleBinding
                      kube.RoleBinding::{
                      , metadata = meta
                      , roleRef =
                          { apiGroup = "rbac.authorization.k8s.io"
                          , kind = "Role"
                          , name =
                              prelude.Optional.default Text i.name i.roleRefName
                          }
                      , subjects = Some
                          [ { kind = "ServiceAccount"
                            , name = i.serviceAccount
                            , namespace = Some i.namespace
                            , apiGroup = None Text
                            }
                          ]
                      }
                  ]

            else  [] : List kube.Resource

      in    serviceAccount # clusterRole # clusterBinding # role # roleBinding
          : List kube.Resource
