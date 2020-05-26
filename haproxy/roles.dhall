let api = ../api.dhall

let kube = (../packages.dhall).kubernetes

let clusterRules =
      [ kube.PolicyRule::{
        , verbs = [ "list", "watch" ]
        , resources = [ "configmaps", "endpoints", "nodes", "pods", "secrets" ]
        , apiGroups = [ "" ]
        }
      , kube.PolicyRule::{
        , verbs = [ "get" ]
        , resources = [ "nodes" ]
        , apiGroups = [ "" ]
        }
      , kube.PolicyRule::{
        , verbs = [ "get", "list", "watch" ]
        , resources = [ "services" ]
        , apiGroups = [ "" ]
        }
      , kube.PolicyRule::{
        , verbs = [ "create", "patch" ]
        , resources = [ "events" ]
        , apiGroups = [ "" ]
        }
      , kube.PolicyRule::{
        , verbs = [ "get", "list", "watch" ]
        , resources = [ "ingresses" ]
        , apiGroups = [ "extensions" ]
        }
      , kube.PolicyRule::{
        , verbs = [ "update" ]
        , resources = [ "ingresses/status" ]
        , apiGroups = [ "extensions" ]
        }
      ]

let rules =
      [ kube.PolicyRule::{
        , verbs = [ "get" ]
        , resources = [ "configmaps", "pods", "secrets", "namespaces" ]
        , apiGroups = [ "" ]
        }
      , kube.PolicyRule::{
        , verbs = [ "get", "update", "create" ]
        , resources = [ "configmaps", "endpoints" ]
        , apiGroups = [ "" ]
        }
      ]

in    λ(input : ./Settings.dhall)
    → api.mkRoles
        api.Roles::{
        , name = input.serviceAccount
        , clusterRules = clusterRules
        , rules = rules
        , namespace = input.namespace
        , serviceAccount = input.serviceAccount
        }
