zn-proxy
--------
A simple docker container that runs squid and socks5 proxies with stunnel encryption and authentication.

Building
--------
```bash
docker build -t zincio/zn-proxy:latest .
```

Running
-------
```bash
docker run -d --rm \
    --restart=always \
    --name zn-proxy \
    -p 8443:8443 \
    -p 5088:5088 \
    -e PROXY_USERNAME=znprx \
    -e PROXY_PASSWORD=long-secure-password-goes-here \
    zincio/zn-proxy:latest
```
Run once without `-d` or use `docker logs zn-proxy` to see the connection strings generated.

BYOP
----
Supply this proxy to the Zinc API by following the [BYOP docs](https://docs.zincapi.com/#configure-zincapi-for-your-own-proxy-byop). Use the socks5+stunnel connection string if possible.
