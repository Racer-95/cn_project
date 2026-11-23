const http = require("http");

const PORT = 3002;

const server = http.createServer((req, res) => {
  res.writeHead(200, {
    "Content-Type": "application/json",
    "Cache-Control": "public, max-age=10"
  });

  res.end(JSON.stringify({
    message: "Hello from Backend B",
    server: "Backend B",
    ip: "10.7.12.181",
    port: PORT,
    path: req.url,
    timestamp: new Date().toISOString()
  }, null, 2));
});

server.listen(PORT, "0.0.0.0", () => {
  console.log("Backend B running on port 3002");
});
