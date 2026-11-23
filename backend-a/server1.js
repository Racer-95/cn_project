const http = require("http");

const PORT = 3001;

const server = http.createServer((req, res) => {
  res.writeHead(200, {
    "Content-Type": "application/json",
    "Cache-Control": "public, max-age=10"
  });

  const response = {
    message: "Hello from Backend A",
    server: "Backend A",
    ip: "10.7.23.156",
    port: PORT,
    path: req.url,
    timestamp: new Date().toISOString()
  };

  res.end(JSON.stringify(response, null, 2));
});

server.listen(PORT, "0.0.0.0", () => {
  console.log("Backend A running on port 3001");
});
