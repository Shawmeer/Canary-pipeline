const http = require("http");
const { URL } = require("url");

const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || "127.0.0.1";

const sendJson = (res, statusCode, payload) => {
  res.writeHead(statusCode, { "Content-Type": "application/json" });
  res.end(JSON.stringify(payload));
};

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);

  if (req.method === "GET" && url.pathname === "/") {
    return sendJson(res, 200, {
      message: "Simple Node.js backend service is running"
    });
  }

  if (req.method === "GET" && url.pathname === "/health") {
    return sendJson(res, 200, {
      status: "ok",
      uptime: process.uptime(),
      timestamp: new Date().toISOString()
    });
  }

  if (req.method === "GET" && url.pathname === "/api/greet") {
    const name = url.searchParams.get("name") || "World";

    return sendJson(res, 200, {
      message: `Hello, ${name}!`
    });
  }

  return sendJson(res, 404, {
    error: "Route not found"
  });
});

server.listen(PORT, HOST, () => {
  console.log(`Server is running on http://${HOST}:${PORT}`);
});
