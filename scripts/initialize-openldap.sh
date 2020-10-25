#!/bin/bash

./applyDir.sh ldap

echo "Waiting for OpenLDAP to start, this will take a while"
kubectl wait --namespace=ldap --for=condition=ready --timeout=3000s pods openldap-0
{ kubectl logs --namespace=ldap -f openldap-0 & } | sed -n '/First start is done.../q'
{ kubectl logs --namespace=ldap -f openldap-0 & } | sed -n '/slapd starting/q'

sleep 2

adminSHA=$(slappasswd -h '{SSHA}' -s "$(sed -n '1p' < ldap_keys.txt)")
configSHA=$(slappasswd -h '{SSHA}' -s "$(sed -n '2p' < ldap_keys.txt)")

chPassLdif=$(echo "./ldap/ldif/chPassword.ldif.dhall \"$adminSHA\" \"$configSHA\"" | dhall text)
chTreeLdif=$(echo "./ldap/ldif/chTreePassword.ldif.dhall \"$adminSHA\"" | dhall text)

# First seed the DIT
kubectl exec --namespace=ldap -t openldap-0 -- \
    bash -c "echo \"$(< ldap/ldif/objectclasses.ldif)\" | ldapadd -Y EXTERNAL -H ldapi://"

sleep 4

kubectl exec --namespace=ldap -t openldap-0 -- \
    bash -c "echo \"$(< ldap/ldif/memberOf.ldif)\" | ldapadd -Y EXTERNAL -H ldapi://"

sleep 4

kubectl exec --namespace=ldap -t openldap-0 -- \
    bash -c "echo \"$(< ldap/ldif/refint.ldif)\" | ldapadd -Y EXTERNAL -H ldapi://"

sleep 4

kubectl exec --namespace=ldap -t openldap-0 -- \
    bash -c "echo \"$(< ldap/ldif/refint.ldif)\" | ldapadd -Y EXTERNAL -H ldapi://"

sleep 4

kubectl exec --namespace=ldap -it openldap-0 -- \
    bash -c "echo \"$(< ldap/ldif/dit.ldif)\" | ldapadd -H ldaps://ldap.cerberus-systems.de -D 'cn=admin,dc=cerberus-systems,dc=de' -x -w admin"

sleep 4

# Then change the passwords
kubectl exec --namespace=ldap -it openldap-0 -- \
    bash -c "echo \"$chPassLdif\" | ldapmodify -Y EXTERNAL -H ldapi://"

sleep 4

kubectl exec --namespace=ldap -it openldap-0 -- \
    bash -c "echo \"$chTreeLdif\" | ldapmodify -H ldaps://ldap.cerberus-systems.de -D 'cn=admin,dc=cerberus-systems,dc=de' -x -w admin"

rm ldap_keys.txt

echo "Deploying phpldapadmin"
./applyDir.sh phpldapadmin
