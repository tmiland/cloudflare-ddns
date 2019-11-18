# cloudflare-ddns
Scripts for updating the Cloudflare DDNS Api on [DigitalOcean](https://m.do.co/c/f1f2b475fca0) Droplets.

forked and heavily modified from [jonegerton/cloudflare-ddns](https://github.com/jonegerton/cloudflare-ddns)

#### cf-ddns.sh:

Updates CloudFlare for DDNS

#### Usage:

Rename example conf (Fill out cfuser,cfkey,cfzonekey,cf_wan_host and cf_private_host before next step)
```bash
$ cp -rp cf-ddns_example.conf cf-ddns.conf
```
Get ID of the wan host entry (will be automatically added to cf-ddns.conf)
```bash
$ cf-ddns.sh -rw 
```
Get ID of the private host entry (will be automatically added to cf-ddns.conf)
```bash
$ cf-ddns.sh -rp
```
Update WAN IP
```bash
$ cf-ddns.sh -w
```

Update Private IP
```bash
$ cf-ddns.sh -p
```

Update both WAN and Private IPs
```bash
$ cf-ddns.sh -c
```

Show help screen
```bash
$ cf-ddns.sh -h
```
