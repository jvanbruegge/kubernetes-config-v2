let openssl = (../packages.dhall).openssl

let utils = ../utils.dhall

let settings = ../settings.dhall

in    λ(subdomain : Text)
    → let urls =
            utils.NonEmpty.map
              Text
              Text
              (utils.Text.prepend "${subdomain}.")
              settings.hosts

      in  openssl.mkConfig
            openssl.Config::{
            , distinguishedName = openssl.DistinguishedName::{
              , commonName = urls.head
              }
            , altNames = urls.tail
            }
