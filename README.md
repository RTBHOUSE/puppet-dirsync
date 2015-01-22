# puppet-dirsync
Synchronizes directories from puppet with git

### Apache configuration for read only git repo with client certificates authentication

    <IfModule mod_ssl.c>
    Listen 443
    <VirtualHost _default_:443>
            DocumentRoot /path/to/puppet_repo
        
            <Directory />
                    Options FollowSymLinks
                    AllowOverride None
            </Directory>
        
            <Directory /path/to/puppet_repo/>
                    Options Indexes FollowSymLinks MultiViews
                    AllowOverride None
                    Order allow,deny
                    allow from all
            </Directory>
        
            ErrorLog ${APACHE_LOG_DIR}/git_client_cert_error.log
            LogLevel warn
            CustomLog ${APACHE_LOG_DIR}/ssl_git_client_cert_access.log combined
            SSLEngine on
            SSLCertificateFile    /var/lib/puppet/ssl/certs/your_cert.pem
            SSLCertificateKeyFile /var/lib/puppet/ssl/private_keys/your_private_key.pem
            SSLCACertificateFile /var/lib/puppet/ssl/certs/ca.pem
            SSLCARevocationPath /var/lib/puppet/ssl/
            SSLCARevocationFile /var/lib/puppet/ssl/crl.pem
            SSLVerifyClient require
            SSLVerifyDepth  10
    </VirtualHost>
    </IfModule>
