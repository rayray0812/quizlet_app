const fs = require("fs");
const path = require("path");
const http = require("http");
const { spawn } = require("child_process");

const port = Number(process.argv[2] || process.env.PORT || 47831);
const siteRoot = path.join(__dirname, "site");
const host = "127.0.0.1";
const origin = `http://${host}:${port}`;

const mimeTypes = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".png": "image/png",
  ".svg": "image/svg+xml"
};

function openBrowser(url) {
  const detached = { detached: true, stdio: "ignore" };
  const commands = [
    ["cmd", ["/c", "start", "", url]],
    ["powershell", ["-NoProfile", "-Command", `Start-Process '${url}'`]]
  ];

  for (const [command, args] of commands) {
    try {
      const child = spawn(command, args, detached);
      child.unref();
      return;
    } catch (error) {}
  }
}

const server = http.createServer((request, response) => {
  const requestUrl = new URL(request.url, origin);
  let pathname = decodeURIComponent(requestUrl.pathname);
  if (pathname === "/") pathname = "/index.html";

  const resolvedPath = path.resolve(siteRoot, "." + pathname);
  if (!resolvedPath.startsWith(siteRoot)) {
    response.writeHead(403, { "Content-Type": "text/plain; charset=utf-8" });
    response.end("Forbidden");
    return;
  }

  fs.stat(resolvedPath, (statError, stats) => {
    if (statError || !stats.isFile()) {
      response.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
      response.end("Not Found");
      return;
    }

    const extension = path.extname(resolvedPath).toLowerCase();
    response.writeHead(200, {
      "Content-Type": mimeTypes[extension] || "application/octet-stream",
      "Cache-Control": "no-store"
    });
    fs.createReadStream(resolvedPath).pipe(response);
  });
});

server.listen(port, host, () => {
  console.log(`Quizlet Batch Importer running at ${origin}/`);
  openBrowser(`${origin}/`);
});
