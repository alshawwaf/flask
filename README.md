# Deploy a flask website with a TLS certificate

* The server is running on port 5000
* Conver the certificate to p12
* openssl pkcs12 -export -out flask_ubuntu_certificate.p12 -inkey key.pem -in cert.pem
* * Export to server
  * scp flask_ubuntu_certificate.p12  admin@10.0.3.11:/home/admin/flask_ubuntu_certificate.p12
