const http = require("http");
const { URL } = require("url");

const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || "127.0.0.1";

const sendJson = (res, statusCode, payload) => {
  res.writeHead(statusCode, { "Content-Type": "application/json" });
  res.end(JSON.stringify(payload));
};

// Simulated health checks (in production, connect to real DB/Redis)
const checkDatabase = async () => {
  // Simulate DB connection check
  return { status: "connected", latency_ms: Math.floor(Math.random() * 10) };
};

const checkRedis = async () => {
  // Simulate Redis connection check
  return { status: "connected", latency_ms: Math.floor(Math.random() * 5) };
};

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);

  if (req.method === "GET" && url.pathname === "/") {
    const env = process.env.ENVIRONMENT || 'development';
    const version = process.env.VERSION || 'unknown';
    const gitSha = process.env.GIT_SHA || 'unknown';
    return sendJson(res, 200, {
      message: `Simple Node.js backend service is running in ${env} environment`,
      version: version,
      git_sha: gitSha
    });
  }

  if (req.method === "GET" && url.pathname === "/health") {
    // Run async health checks
    const [dbHealth, redisHealth] = await Promise.all([
      checkDatabase(),
      checkRedis()
    ]);
    
    const overallStatus = dbHealth.status === "connected" && redisHealth.status === "connected"
      ? "ok"
      : "degraded";
    
    return sendJson(res, 200, {
      status: overallStatus,
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
      dependencies: {
        database: dbHealth,
        redis: redisHealth
      },
      version: process.env.VERSION || 'unknown'
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
  console.log(`Environment: ${process.env.ENVIRONMENT || 'development'}`);
  console.log(`Version: ${process.env.VERSION || 'unknown'}`);
});
