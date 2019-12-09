let kube = ../kubernetes.dhall

let union = ../union.dhall

let api = ../api.dhall

let Deployment = ../api/DeploymentWithService.dhall

let mkContainer =
        λ ( input
          : { configMapName : Text, tcpConfigMapName : Text, namespace : Text }
          )
      → kube.Container::{
        , name = "haproxy-ingress"
        , image = Some "quay.io/quay.io/jcmoraisjr/haproxy-ingress:v0.7.5"
        , imagePullPolicy = Some "IfNotPresent"
        , args =
            [ "--default-backend-service=${input.namespace}/ingress-default-backend"
            , "--configmap=${input.namespace}/${input.configMapName}"
            , "--tcp-services-configmap=${input.namespace}/${input.tcpConfigMapName}"
            , "--reload-strategy=native"
            ]
        , env =
            [ { name = "POD_NAME"
              , value = None Text
              , valueFrom =
                  kube.EnvVarSource::{
                  , fieldRef =
                      Some
                        kube.ObjectFieldSelector::{
                        , fieldPath = "metadata.name"
                        }
                  }
              }
            , { name = "POD_NAMESPACE"
              , value = None Text
              , valueFrom =
                  kube.EnvVarSource::{
                  , fieldRef =
                      Some
                        kube.ObjectFieldSelector::{
                        , fieldPath = "metadata.namespace"
                        }
                  }
              }
            ]
        , ports =
            [ kube.ContainerPort::{
              , containerPort = 80
              , name = Some "http"
              , protocol = Some "TCP"
              }
            , kube.ContainerPort::{
              , containerPort = 443
              , name = Some "https"
              , protocol = Some "TCP"
              }
            , kube.ContainerPort::{
              , containerPort = 1936
              , name = Some "stats"
              , protocol = Some "TCP"
              }
            ]
        }

in    λ(input : ./Settings.dhall)
    → let configMap =
            kube.ConfigMap::{
            , metadata =
                kube.ObjectMeta::{
                , name = "haproxy-config"
                , namespace = Some input.namespace
                }
            , data =
                [ { mapKey = "backend-server-slots-increment", mapValue = "4" }
                , { mapKey = "ssl-dh-default-max-size", mapValue = "2048" }
                ]
            }

      let tcpConfigMap =
            kube.ConfigMap::{
            , metadata =
                kube.ObjectMeta::{
                , name = "haproxy-tcp-config"
                , namespace = Some input.namespace
                }
            }

      let config =
            Deployment::{
            , name = "haproxy"
            , namespace = input.namespace
            , containers =
                [ mkContainer
                    { configMapName = configMap.metadata.name
                    , tcpConfigMapName = tcpConfigMap.metadata.name
                    , namespace = input.namespace
                    }
                ]
            , serviceAccount = Some input.serviceAccount
            }

      in    [ union.ConfigMap configMap, union.ConfigMap tcpConfigMap ]
          # api.mkDeploymentAndService config
