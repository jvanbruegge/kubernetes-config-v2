let api = ../api.dhall

in    λ(input : ./Settings.dhall)
    → api.mkRoles
        api.Roles::{
        , name = "tokenreview"
        , createClusterBinding = Some True
        , namespace = input.namespace
        , clusterRoleRefName = Some "system:auth-delegator"
        , serviceAccount = input.serviceAccount
        }
