let kube = ../kubernetes.dhall

let union = ../union.dhall

let api = ../api.dhall

let globalSettings = ../settings.dhall

let helpers = ../api/internal/helpers.dhall

let mkContainer =
        λ ( input
          : { configMapName : Text, tcpConfigMapName : Text, namespace : Text }
          )
      → kube.Container::{
        , name = "haproxy-ingress"
        , image = Some "quay.io/jcmoraisjr/haproxy-ingress:v0.7"
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
            , data = [ { mapKey = "636", mapValue = "ldap/openldap:636" } ]
            }

      let config =
            api.SimpleDeployment::{
            , name = "haproxy"
            , namespace = input.namespace
            , servicePorts = Some ([] : List Natural)
            , containers =
                [ mkContainer
                    { configMapName = configMap.metadata.name
                    , tcpConfigMapName = tcpConfigMap.metadata.name
                    , namespace = input.namespace
                    }
                ]
            , serviceAccount = Some input.serviceAccount
            , externalIPs = globalSettings.serverIPs
            , ingress = api.noIngress
            }

      let mkServicePort =
              λ(port : Natural)
            → λ(name : Text)
            → kube.ServicePort::{
              , port = port
              , name = Some name
              , protocol = Some "TCP"
              , targetPort = Some (< Int : Natural | String : Text >.Int port)
              }

      let service =
            kube.Service::{
            , metadata = helpers.mkMeta config
            , spec =
                Some
                  kube.ServiceSpec::{
                  , ports =
                      [ mkServicePort 80 "http"
                      , mkServicePort 443 "https"
                      , mkServicePort 1936 "stats"
                      , mkServicePort 636 "ldaps"
                      ]
                  , selector = helpers.mkSelector config
                  , externalIPs = config.externalIPs
                  }
            }

      in    [ union.ConfigMap configMap, union.ConfigMap tcpConfigMap ]
          # api.mkDeployment config
          # [ union.Service service ]
