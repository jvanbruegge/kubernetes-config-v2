let kube = (../packages.dhall).kubernetes

let Roles =
      { serviceAccount : Text
      , createAccount : Bool
      , name : Text
      , namespace : Text
      , clusterRules : List kube.PolicyRule.Type
      , createClusterBinding : Optional Bool
      , rules : List kube.PolicyRule.Type
      , createRoleBinding : Optional Bool
      , clusterRoleRefName : Optional Text
      , roleRefName : Optional Text
      }

let default =
      { createAccount = True
      , clusterRules = [] : List kube.PolicyRule.Type
      , rules = [] : List kube.PolicyRule.Type
      , createClusterBinding = None Bool
      , createRoleBinding = None Bool
      , clusterRoleRefName = None Text
      , roleRefName = None Text
      }

in  { Type = Roles, default = default }
