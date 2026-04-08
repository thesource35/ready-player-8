import fs from 'node:fs';
import http from 'node:http';
import https from 'node:https';

const targetHost = '127.0.0.1';
const targetPort = 3000;
const domain = 'constructionos.world';
const certPath = '/tmp/constructionos-local-proxy/cert.pem';
const keyPath = '/tmp/constructionos-local-proxy/key.pem';

function proxyRequest(req, res) {
  const options = {
    hostname: targetHost,
    port: targetPort,
    path: req.url,
    method: req.method,
    headers: {
      ...req.headers,
      host: `${targetHost}:${targetPort}`,
      'x-forwarded-host': req.headers.host || domain,
      'x-forwarded-proto': 'https',
    },
  };

  const upstream = http.request(options, (upstreamRes) => {
    res.writeHead(upstreamRes.statusCode || 502, upstreamRes.headers);
    upstreamRes.pipe(res);
  });

  upstream.on('error', (error) => {
    res.writeHead(502, { 'content-type': 'text/plain; charset=utf-8' });
    res.end(`Local proxy error: ${error.message}`);
  });

  req.pipe(upstream);
}

const httpsServer = https.createServer(
  {
    key: fs.readFileSync(keyPath),
    cert: fs.readFileSync(certPath),
  },
  proxyRequest,
);

const httpServer = http.createServer((req, res) => {
  const host = (req.headers.host || domain).replace(/:\d+$/, '');
  const location = `https://${host}${req.url || '/'}`;
  res.writeHead(301, { location });
  res.end();
});

httpsServer.listen(443, '0.0.0.0', () => {
  console.log('HTTPS proxy listening on https://constructionos.world');
});

httpServer.listen(80, '0.0.0.0', () => {
  console.log('HTTP redirect listening on http://constructionos.world');
});
