const fs = require("fs");
const path = require("path");

const rootDir = path.resolve(__dirname, "..");
const srcDir = path.join(rootDir, "src");
const distDir = path.join(rootDir, "dist");

fs.rmSync(distDir, { recursive: true, force: true });
fs.mkdirSync(distDir, { recursive: true });

for (const entry of fs.readdirSync(srcDir)) {
  const sourcePath = path.join(srcDir, entry);
  const outputPath = path.join(distDir, entry);
  fs.copyFileSync(sourcePath, outputPath);
}

console.log("Build completed. Output written to dist/.");
