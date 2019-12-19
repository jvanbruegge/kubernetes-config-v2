  λ(adminSHA : Text)
→ ''
  dn: cn=admin,dc=cerberus-systems,dc=de
  changetype: modify
  replace: userPassword
  userPassword: ${adminSHA}
  ''
