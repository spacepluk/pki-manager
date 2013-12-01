pki-manager
===========

Commandline tool for managing your own PKI infrastructure.


This tool is based on the tutorial on http://pki-tutorial.readthedocs.org. At this point a big thanks to Stefan H. Holek wgo wrote the tutorial. I learned a lot about managing a PKI with OpenSSL. Also he helped me out when I had some questions and emailed him. Thanks Stefan! :)

I tried to keep the logic very simple and modular. The wrapper scripts are just there to set some important vars and then run every step through for building a CA or certificate where normaly a couple of commands where needed.

Folder structure:
 - bin - scripts for managing the PKI
 - ca - CAs will be saved in subdirectorys including CSR, CRT, Key, Pem and a ca-chain Pem file
 - certs - TLS certificates storeing place, includes CSR, CRT, Key and PEM file
 - crl - revokation lists store
 - doc - sample configuration files and additional imformations
 - etc - config dir
 - public - CA files in DER format which are ready for publishing

Manage your PKI
---------------

 - Create a root-ca

cp doc/configs/root-ca.cfg etc/sample.cfg

bash bin/build-ca.sh --root-ca sample

 - Create your intermediate-ca

mkdir etc/sample-bu

cp doc/configs/intermediate-ca etc/sample-bu/sample-bu.cfg

bash bin/build-ca.sh --sign-with sample --intermediate-ca sample-bu

 - Create a signing-ca

cp doc/configs/signing-ca.cfg etc/sample-bu/tls-ca.cfg

bash bin/build-ca.sh --sign-with sample-bu --signing-ca tls-ca

 - Create a TLS certificate (eg web server)

cp doc/configs/tls-server.cfg etc/tls-server.cfg

bash bin/generate-certificate.sh --server --dn www.sample.org --sign-with tls-ca sample.org

 - Revoke a certificate

bash bin/revoke.sh --cert --signed-with tls-ca www.sample.org

Important notes
---------------

 - config files for a root-ca are stored in etc/
 - subfolders in etc/ are keeping intermediate-cas and signing-cas
 - the subfolder and the intermediate-ca have to be named the same
 - don't use dots in file names eg sample.org.cfg (OpenSSL doesn't like that)
