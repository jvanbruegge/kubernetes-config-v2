let api = ../api.dhall

let kube = (../packages.dhall).kubernetes

let secrets =
      kube.PolicyRule::{
      , verbs = [ "get", "list", "watch", "create", "update", "delete" ]
      , resources = Some [ "secrets" ]
      , apiGroups = Some [ "" ]
      }

let events =
      kube.PolicyRule::{
      , verbs = [ "create", "patch" ]
      , resources = Some [ "events" ]
      , apiGroups = Some [ "" ]
      }

let mkLeaderElection =
        λ(input : ./Settings.dhall)
      → let rules =
              [ kube.PolicyRule::{
                , verbs = [ "get", "create", "update", "patch" ]
                , resources = Some [ "configmaps" ]
                , apiGroups = Some [ "" ]
                }
              ]

        in  api.mkRoles
              api.Roles::{
              , name = "cert-manager:leaderelection"
              , rules = rules
              , namespace = input.namespace
              , serviceAccount = input.serviceAccount
              }

let mkClusterRole =
        λ(name : Text)
      → λ(clusterRules : List kube.PolicyRule.Type)
      → λ(input : ./Settings.dhall)
      → api.mkRoles
          api.Roles::{
          , name = name
          , clusterRules = clusterRules
          , namespace = input.namespace
          , serviceAccount = input.serviceAccount
          , createAccount = False
          }

let mkIssuerController =
      let clusterRules =
            [ kube.PolicyRule::{
              , verbs = [ "update" ]
              , resources = Some [ "issuers", "issuers/status" ]
              , apiGroups = Some [ "cert-manager.io" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "get", "list", "watch" ]
              , resources = Some [ "issuers" ]
              , apiGroups = Some [ "cert-manager.io" ]
              }
            , secrets
            , events
            ]

      in  mkClusterRole "cert-manager-controller-issuers" clusterRules

let mkClusterIssuerController =
      let clusterRules =
            [ kube.PolicyRule::{
              , verbs = [ "update" ]
              , resources = Some [ "clusterissuers", "clusterissuers/status" ]
              , apiGroups = Some [ "cert-manager.io" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "get", "list", "watch" ]
              , resources = Some [ "clusterissuers" ]
              , apiGroups = Some [ "cert-manager.io" ]
              }
            , secrets
            , events
            ]

      in  mkClusterRole "cert-manager-controller-clusterissuers" clusterRules

let mkCertificateController =
      let clusterRules =
            [ kube.PolicyRule::{
              , verbs = [ "update" ]
              , resources = Some
                  [ "certificates"
                  , "certificates/status"
                  , "certificaterequests"
                  , "certificaterequests/status"
                  ]
              , apiGroups = Some [ "cert-manager.io" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "get", "list", "watch" ]
              , resources = Some
                  [ "certificates"
                  , "certificaterequests"
                  , "clusterissuers"
                  , "issuers"
                  ]
              , apiGroups = Some [ "cert-manager.io" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "update" ]
              , resources = Some
                  [ "certificates/finalizers"
                  , "certificaterequests/finalizers"
                  ]
              , apiGroups = Some [ "cert-manager.io" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "create", "delete", "get", "list", "watch" ]
              , resources = Some [ "orders" ]
              , apiGroups = Some [ "acme.cert-manager.io" ]
              }
            , secrets
            , events
            ]

      in  mkClusterRole "cert-manager-controller-certificates" clusterRules

let mkOrdersController =
      let clusterRules =
            [ kube.PolicyRule::{
              , verbs = [ "update" ]
              , resources = Some [ "orders", "orders/status" ]
              , apiGroups = Some [ "acme.cert-manager.io" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "get", "list", "watch" ]
              , resources = Some [ "orders", "challenges" ]
              , apiGroups = Some [ "acme.cert-manager.io" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "get", "list", "watch" ]
              , resources = Some [ "clusterissuers", "issuers" ]
              , apiGroups = Some [ "cert-manager.io" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "create", "delete" ]
              , resources = Some [ "challenges", "challenges" ]
              , apiGroups = Some [ "acme.cert-manager.io" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "update" ]
              , resources = Some [ "orders/finalizers" ]
              , apiGroups = Some [ "acme.cert-manager.io" ]
              }
            , secrets
            , events
            ]

      in  mkClusterRole "cert-manager-controller-orders" clusterRules

let mkChallengeController =
      let clusterRules =
            [ kube.PolicyRule::{
              , verbs = [ "update" ]
              , resources = Some [ "challenges", "challenges/status" ]
              , apiGroups = Some [ "acme.cert-manager.io" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "get", "list", "watch" ]
              , resources = Some [ "challenges" ]
              , apiGroups = Some [ "acme.cert-manager.io" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "get", "list", "watch" ]
              , resources = Some [ "clusterissuers", "issuers" ]
              , apiGroups = Some [ "cert-manager.io" ]
              }
            , secrets
            , events
            , kube.PolicyRule::{
              , verbs = [ "get", "list", "watch", "create", "delete" ]
              , resources = Some [ "pods", "services" ]
              , apiGroups = Some [ "" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "get", "list", "watch", "create", "delete", "update" ]
              , resources = Some [ "ingresses" ]
              , apiGroups = Some [ "extensions" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "update" ]
              , resources = Some [ "challenges/finalizers" ]
              , apiGroups = Some [ "acme.cert-manager.io" ]
              }
            , secrets
            ]

      in  mkClusterRole "cert-manager-controller-challenges" clusterRules

let mkIngressShimController =
      let clusterRules =
            [ kube.PolicyRule::{
              , verbs = [ "create", "update", "delete" ]
              , resources = Some [ "certificates", "certificaterequests" ]
              , apiGroups = Some [ "cert-manager.io" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "get", "list", "watch" ]
              , resources = Some
                  [ "certificates"
                  , "certificaterequests"
                  , "issuers"
                  , "clusterissuers"
                  ]
              , apiGroups = Some [ "cert-manager.io" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "get", "list", "watch" ]
              , resources = Some [ "ingresses" ]
              , apiGroups = Some [ "extensions" ]
              }
            , kube.PolicyRule::{
              , verbs = [ "update" ]
              , resources = Some [ "ingresses/finalizers" ]
              , apiGroups = Some [ "extensions" ]
              }
            , events
            ]

      in  mkClusterRole "cert-manager-controller-ingress-shim" clusterRules

in    λ(input : ./Settings.dhall)
    →   mkLeaderElection input
      # mkIssuerController input
      # mkClusterIssuerController input
      # mkCertificateController input
      # mkOrdersController input
      # mkChallengeController input
      # mkIngressShimController input
