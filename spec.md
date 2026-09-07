Configure this Ubuntu Oracle Compute instance to host three independent GitHub repositories behind one Nginx reverse proxy.

Domains:

* trade.longwarp.com → palakons/alpha-trader-v2
* toll.longwarp.com → palakons/thai_unified_toll_map
* shabu.longwarp.com → palakons/shabu_nub_nub

Architecture requirements:

* One system-level Nginx instance listening on ports 80/443.
* Each application runs as its own non-root process on localhost only.
* alpha-trader-v2 has a Python backend and Node frontend. Assign separate localhost ports, e.g. frontend 3000, backend 8000.
* thai_unified_toll_map runs on 127.0.0.1:3001.
* shabu_nub_nub runs on 127.0.0.1:3002.
* Do not expose application ports publicly.
* Create separate systemd services for each long-running application process.
* Configure Nginx virtual hosts by hostname.
* Configure HTTPS using Let’s Encrypt/Certbot after DNS resolves.
* Preserve SSH access.
* Only ports 22, 80 and 443 should need public ingress.
* Do not modify application source code unless necessary for production configuration.
* Before making changes, inspect each repo’s package.json, Python entry points, environment variables, build commands, and existing deployment configuration. Do not assume all Node projects use the same framework.
* Show me the proposed ports, systemd units, Nginx configuration, and commands before making destructive or security-sensitive changes.

Security:

* trade.longwarp.com is private/sensitive and must require authentication. Nginx Basic Auth over HTTPS
* toll.longwarp.com and shabu.longwarp.com may be publicly accessible.
* Do not use application-port security as authentication.
* Recommend and implement an appropriate authentication layer for trade.longwarp.com.
* Keep secrets outside Git and use environment files with restricted permissions.

Suggested Structurje:

oracle-app-server/
├── nginx/
│   ├── trade.longwarp.com.conf
│   ├── toll.longwarp.com.conf
│   └── shabu.longwarp.com.conf
├── systemd/
│   ├── alpha-trader-api.service
│   ├── alpha-trader-web.service
│   ├── toll-map.service
│   └── shabu.service
└── README.md