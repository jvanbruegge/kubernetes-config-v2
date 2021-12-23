let kube = (../packages.dhall).kubernetes

let api = ../api.dhall

let globalSettings = ../settings.dhall

let helpers = ../api/internal/helpers.dhall

let mkContainer =
      λ ( input
        : { configMapName : Text, tcpConfigMapName : Text, namespace : Text }
        ) →
        kube.Container::{
        , name = "haproxy-ingress"
        , image = Some "quay.io/jcmoraisjr/haproxy-ingress:v0.13.4"
        , imagePullPolicy = Some "IfNotPresent"
        , args = Some
          [ "--configmap=${input.namespace}/${input.configMapName}"
          , "--tcp-services-configmap=${input.namespace}/${input.tcpConfigMapName}"
          , "--reload-strategy=native"
          , "--watch-ingress-without-class"
          ]
        , env = Some
          [ { name = "POD_NAME"
            , value = None Text
            , valueFrom = Some kube.EnvVarSource::{
              , fieldRef = Some kube.ObjectFieldSelector::{
                , fieldPath = "metadata.name"
                }
              }
            }
          , { name = "POD_NAMESPACE"
            , value = None Text
            , valueFrom = Some kube.EnvVarSource::{
              , fieldRef = Some kube.ObjectFieldSelector::{
                , fieldPath = "metadata.namespace"
                }
              }
            }
          ]
        , ports = Some
          [ kube.ContainerPort::{
            , containerPort = +80
            , name = Some "http"
            , protocol = Some "TCP"
            }
          , kube.ContainerPort::{
            , containerPort = +443
            , name = Some "https"
            , protocol = Some "TCP"
            }
          , kube.ContainerPort::{
            , containerPort = +1936
            , name = Some "stats"
            , protocol = Some "TCP"
            }
          ]
        }

in  λ(input : ./Settings.dhall) →
      let configMap =
            kube.ConfigMap::{
            , metadata = kube.ObjectMeta::{
              , name = Some "haproxy-config"
              , namespace = Some input.namespace
              }
            , data = Some
              [ { mapKey = "backend-server-slots-increment", mapValue = "4" }
              , { mapKey = "ssl-dh-default-max-size", mapValue = "2048" }
              ]
            }

      let tcpConfigMap =
            kube.ConfigMap::{
            , metadata = kube.ObjectMeta::{
              , name = Some "haproxy-tcp-config"
              , namespace = Some input.namespace
              }
            , data = Some
              [ { mapKey = "636", mapValue = "ldap/openldap:636" }
              , { mapKey = "25565", mapValue = "minecraft/minecraft:25565" }
              ]
            }

      let config =
            api.SimpleDeployment::{
            , name = "haproxy"
            , namespace = input.namespace
            , servicePorts = Some ([] : List Integer)
            , containers =
              [ mkContainer
                  { configMapName = "haproxy-config"
                  , tcpConfigMapName = "haproxy-tcp-config"
                  , namespace = input.namespace
                  }
              ]
            , serviceAccount = Some input.serviceAccount
            , externalIPs = globalSettings.serverIPs
            , ingress = api.noIngress
            }

      let mkServicePort =
            λ(port : Integer) →
            λ(name : Text) →
              kube.ServicePort::{
              , port
              , name = Some name
              , protocol = Some "TCP"
              , targetPort = Some (< Int : Integer | String : Text >.Int port)
              }

      let service =
            kube.Service::{
            , metadata = helpers.mkMeta config
            , spec = Some kube.ServiceSpec::{
              , ports = Some
                [ mkServicePort +80 "http"
                , mkServicePort +443 "https"
                , mkServicePort +1936 "stats"
                , mkServicePort +636 "ldaps"
                , mkServicePort +25565 "minecraft"
                ]
              , selector = Some (helpers.mkSelector config)
              , externalIPs = Some config.externalIPs
              }
            }

      in    [ kube.Resource.ConfigMap configMap
            , kube.Resource.ConfigMap tcpConfigMap
            ]
          # api.mkDeployment config
          # [ kube.Resource.Service service ]
