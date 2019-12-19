let kube = ../kubernetes.dhall

let api = ../api.dhall

let utils = ../utils.dhall

let globalSettings = ../settings.dhall

let volumeName = "ldap-data"

let ldapContainer =
      kube.Container::{
      , name = "openldap"
      , image = Some "registry.hub.docker.com/osixia/openldap:1.3.0"
      , env =
          [ kube.EnvVar::{
            , name = "LDAP_ORGANISATION"
            , value = Some globalSettings.organizationName
            }
          , kube.EnvVar::{
            , name = "LDAP_DOMAIN"
            , value = Some (utils.NonEmpty.head Text globalSettings.hosts)
            }
          , kube.EnvVar::{ name = "LDAP_TLS_ENFORCE", value = Some "true" }
          ]
      , ports =
          [ kube.ContainerPort::{ containerPort = 636, name = Some "ldaps" } ]
      , volumeMounts =
          [ kube.VolumeMount::{
            , mountPath = "/var/lib/ldap"
            , name = volumeName
            , subPath = Some "data"
            }
          , kube.VolumeMount::{
            , mountPath = "/etc/ldap/slapd.d"
            , name = volumeName
            , subPath = Some "config"
            }
          ]
      }

in    λ(input : ./Settings.dhall)
    → let config =
            api.SimpleDeployment::{
            , name = "openldap"
            , namespace = input.namespace
            , containers = [ ldapContainer ]
            , ingress = api.noIngress
            , volumes =
                [ kube.Volume::{
                  , name = volumeName
                  , persistentVolumeClaim =
                      Some { claimName = input.claimName, readOnly = None Bool }
                  }
                ]
            }

      in  api.mkStatefulSet config
