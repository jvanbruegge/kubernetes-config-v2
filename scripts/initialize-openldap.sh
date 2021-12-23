#!/usr/bin/env bash

set -euo pipefail

source ./scripts/vault-connection.sh

echo "Generating ldap admin passwords"
adminPass="$(tr -dc _A-Za-z-0-9 < /dev/urandom | head -c32; echo)"
configPass="$(tr -dc _A-Za-z-0-9 < /dev/urandom | head -c32; echo)"

echo "Saving ldap admin passwords in vault"
curlCmd -XPOST --data "{ \"admin\": \"$adminPass\", \"config-admin\": \"$configPass\" }" "$VAULT_ADDR/v1/kv/ldap"

./applyDir.sh ldap

echo "Waiting for OpenLDAP to start, this will take a while"
kubectl wait --namespace=ldap --for=condition=ready --timeout=3000s pods openldap-0
{ kubectl logs --namespace=ldap -f openldap-0 -c openldap & } | sed -n '/First start is done.../q'
{ kubectl logs --namespace=ldap -f openldap-0 -c openldap & } | sed -n '/slapd starting/q'

sleep 2

adminSHA=$(slappasswd -h '{SSHA}' -s "$adminPass")
configSHA=$(slappasswd -h '{SSHA}' -s "$configPass")

chPassLdif=$(echo "./ldap/ldif/chPassword.ldif.dhall \"$adminSHA\" \"$configSHA\"" | dhall text)
chTreeLdif=$(echo "./ldap/ldif/chTreePassword.ldif.dhall \"$adminSHA\"" | dhall text)

# First seed the DIT
kubectl exec --namespace=ldap -t openldap-0 -c openldap -- \
    bash -c "echo \"$(< ldap/ldif/objectclasses.ldif)\" | ldapadd -Y EXTERNAL -H ldapi://"

sleep 4

kubectl exec --namespace=ldap -t openldap-0 -c openldap -- \
    bash -c "echo \"$(< ldap/ldif/memberOf.ldif)\" | ldapadd -Y EXTERNAL -H ldapi://"

sleep 4

kubectl exec --namespace=ldap -t openldap-0 -c openldap -- \
    bash -c "echo \"$(< ldap/ldif/refint.ldif)\" | ldapadd -Y EXTERNAL -H ldapi://"

sleep 4

kubectl exec --namespace=ldap -t openldap-0 -c openldap -- \
  ldapadd -Y EXTERNAL -H ldapi:// -f /etc/ldap/schema/ppolicy.ldif
sleep 4

kubectl exec --namespace=ldap -t openldap-0 -c openldap -- \
    bash -c "echo \"$(< ldap/ldif/passwordPolicy.ldif)\" | ldapadd -Y EXTERNAL -H ldapi://"

sleep 4

kubectl exec --namespace=ldap -it openldap-0 -c openldap -- \
    bash -c "echo \"$(< ldap/ldif/defaultPolicy.ldif)\" | ldapadd -H ldaps://ldap.cerberus-systems.de -D 'cn=admin,dc=cerberus-systems,dc=de' -x -w admin"

sleep 4

kubectl exec --namespace=ldap -it openldap-0 -c openldap -- \
    bash -c "echo \"$(< ldap/ldif/dit.ldif)\" | ldapadd -H ldaps://ldap.cerberus-systems.de -D 'cn=admin,dc=cerberus-systems,dc=de' -x -w admin"

sleep 4

# Then change the passwords
kubectl exec --namespace=ldap -it openldap-0 -c openldap -- \
    bash -c "echo \"$chPassLdif\" | ldapmodify -Y EXTERNAL -H ldapi://"

sleep 4

kubectl exec --namespace=ldap -it openldap-0 -c openldap -- \
    bash -c "echo \"$chTreeLdif\" | ldapmodify -H ldaps://ldap.cerberus-systems.de -D 'cn=admin,dc=cerberus-systems,dc=de' -x -w admin"

echo "Deploying phpldapadmin"
./applyDir.sh phpldapadmin
