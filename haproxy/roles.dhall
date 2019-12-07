let api = ../api.dhall

let kube = ../kubernetes.dhall

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

in    λ(input : { serviceAccount : Text, namespace : Text })
    → api.mkRoles
        (   { createAccount = True
            , name = "ingresses-controller"
            , clusterRules = clusterRules
            , rules = rules
            }
          ⫽ input
        )
