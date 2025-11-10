server {
    listen 80 ;
    listen [::]:80 ;

    server_name web.example.com;
    #root /root/UmbracoCMS/publish/wwwroot;

    client_max_body_size 100M;

    # Proxy settings for Umbraco
    location / {
        proxy_pass http://localhost:30080;
        proxy_set_header Host $host;
      	#proxy_set_header Origin $http_origin;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_redirect off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }


    # Deny access to sensitive files
    location ~ /\. {
        deny all;
    }

}

server {
    server_name web.example.com; # managed by Certbot
    #root /root/UmbracoCMS/publish/wwwroot;

    client_max_body_size 100M;

    # Proxy settings for Umbraco
    location / {
        proxy_pass https://localhost:30443;
        proxy_set_header Host $host;
	#proxy_set_header Origin $http_origin;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_redirect off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }


    # Deny access to sensitive files
    location ~ /\. {
        deny all;
    }



    listen [::]:443 ssl; # managed by Certbot
    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/web.example.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/web.example.com/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

}server {
    if ($host = web.example.com) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    listen 80 ;
    listen [::]:80 ;
    server_name web.example.com;
    return 404; # managed by Certbot
}
