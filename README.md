# ciph-tunnel-server
Backend connector for clients

## Useage

```
npm install && npm build
```

For API useage:
```
const Tunnel = require('ciph-tunnel-server');
```

For CLI useage:
```
npm start -- [options]
```

Options:
- **-h, --help** — Output usage information;
- **-V, --version** — Output the version number;
- **-H, --host [host]** — Host of server (default: 8080);
- **-P, --port [number]** — Port of server (default: 0.0.0.0);
- **-t, --timeout [time]** — Connection and request timeout (default: 2000);
