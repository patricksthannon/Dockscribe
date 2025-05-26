# Dockscribe
**CLI tool to pull short descriptions of all currently running docker containers**

_As I was using the `brew leaves | xargs brew desc --eval-all`[^1] command for homebrew, which lists short descriptions of all current brew packages, I decided I would like a tool similar to this for Docker. Therefor, **Dockscribe** was born._<br/>

This script will scan for all of your currently running docker containers, source descriptions from dockerhub and github, then output the results. In some cases, if the docker container is a dependency for a parent container (ie as "immich-machine-learning" for immich) it will fallback to the parent base description.

## Dependencies:

Dockscribe will automatically download `jq` by either using apt get, homebrew (mac os), or downloading from the static binary. 

_jq is built around the concept of filters that work over a stream of JSON._

## Install Instructions 
1. Install using scripts below for either Linux or MacOs.
```
# Linux with curl | into default PATH /.local/bin/
curl -L https://raw.githubusercontent.com/patricksthannon/Dockscribe/refs/heads/main/dockscribe.sh -o ~/.local/bin/dockscribe.sh
chmod +x ~/.local/bin/dockscribe.sh

# Linux with wget | into default PATH /.local/bin/
wget -O ~/.local/bin/docksribe.sh "https://raw.githubusercontent.com/patricksthannon/Dockscribe/refs/heads/main/dockscribe.sh" && chmod +x ~/.local/bin/dockscribe.sh

# Mac OS with curl | into default PATH /usr/local/bin/
 curl -L https://raw.githubusercontent.com/patricksthannon/Dockscribe/refs/heads/main/dockscribe.sh -o /usr/local/bin/dockscribe.sh && chmod +x /usr/local/bin/dockscribe.sh

```

2. Test script.

```
dockscribe.sh
```

Output Example:
```
actualbudget/actual-server — Actual server & web app 
binwiederhier/ntfy — Send push notifications to your phone or desktop via PUT/POST
ghcr.io/corentinth/it-tools — Collection of handy online tools for developers, with great UX. 
ghcr.io/gethomepage/homepage — A highly customizable homepage (or startpage / application dashboard) with Docker and service API integrations.
ghcr.io/immich-app/immich-machine-learning — High performance self-hosted photo and video management solution.
gitea/gitea — Gitea: Git with a cup of tea - A painless self-hosted Git service.
jellyfin/jellyfin — The Free Software Media Browser 
lscr.io/linuxserver/plex — A Plex Media Server container, brought to you by LinuxServer.io. 
lscr.io/linuxserver/syncthing — A Syncthing container, brought to you by LinuxServer.io. 
neosmemo/memos — A privacy-first, lightweight note-taking service. Easily capture and share your great thoughts.
postgres — The PostgreSQL object-relational database system provides reliability and data integrity.
redis — Redis is the world’s fastest data platform for caching, vector search, and NoSQL databases.
tensorchord/pgvecto-rs — Scalable Vector Search in Postgres. Revolutionize Vector Search, not Database. pgvector alternative.
vaultwarden/server — Alternative implementation of the Bitwarden server API in Rust, including the Web Vault.

```

[^1]: Reference: https://apple.stackexchange.com/questions/101090/list-of-all-packages-installed-using-homebrew
