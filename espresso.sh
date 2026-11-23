#!/usr/bin/env bash
# Interactive scaffolder for an Express.js project with feature folders.
# Usage: ./setup-express-mvc.sh [project-name]
set -euo pipefail

DEFAULT_DIRS=(config views public middleware utils services)
DEFAULT_PACKAGES=(express ejs express-validator nodemon dotenv cors)

# ---------- Project name ----------
APP_NAME="${1:-}"
if [[ -z "$APP_NAME" ]]; then
  read -rp "Project name: " APP_NAME
fi
[[ -n "$APP_NAME" ]] || { echo "Error: project name is required."; exit 1; }
[[ ! -e "$APP_NAME" ]] || { echo "Error: '$APP_NAME' already exists."; exit 1; }

for cmd in node npm; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Error: $cmd is not installed."; exit 1; }
done

mkdir -p "$APP_NAME"
cd "$APP_NAME"

# ---------- 1. npm init ----------
echo "==> Running npm init -y"
npm init -y >/dev/null
npm pkg set name="$APP_NAME" main="src/server.js" \
  scripts.start="node src/server.js" \
  scripts.dev="nodemon src/server.js" >/dev/null

# ---------- 2. Git, .gitignore, .env ----------
if command -v git >/dev/null 2>&1; then
  echo "==> Git found, running git init"
  git init -q
else
  echo "==> Git not found, skipping git init"
fi

cat > .gitignore <<'EOF'
node_modules/
.env
npm-debug.log*
.DS_Store
EOF

cat > .env <<'EOF'
PORT=3000
NODE_ENV=development
EOF
echo "==> Created .gitignore and .env"

# ---------- 3. Default folders (inside src) ----------
echo "==> Creating default folders inside src/"
for dir in "${DEFAULT_DIRS[@]}"; do
  mkdir -p "src/$dir"
done
mkdir -p src/features

# ---------- 4. Feature folders ----------
echo ""
echo "Enter feature folders to create (e.g. auth payments users)."
read -rp "Features (space-separated, blank for none): " -a FEATURES_INPUT || true

FEATURES=()
for f in "${FEATURES_INPUT[@]:-}"; do
  [[ -z "$f" ]] && continue
  name="$(echo "$f" | tr '[:upper:]' '[:lower:]')"
  if [[ ! "$name" =~ ^[a-z][a-z0-9_-]*$ ]]; then
    echo "   Skipping invalid name: '$f'"
    continue
  fi
  FEATURES+=("$name")
done

for feature in "${FEATURES[@]:-}"; do
  [[ -z "$feature" ]] && continue
  dir="src/features/$feature"
  mkdir -p "$dir"

  cat > "$dir/$feature.routes.js" <<EOF
const express = require('express');
const controller = require('./$feature.controller');

const router = express.Router();

router.get('/', controller.index);

module.exports = router;
EOF

  cat > "$dir/$feature.controller.js" <<EOF
const service = require('./$feature.service');

exports.index = async (req, res, next) => {
  try {
    res.json(await service.getAll());
  } catch (err) {
    next(err);
  }
};
EOF

  cat > "$dir/$feature.service.js" <<EOF
exports.getAll = async () => {
  return { feature: '$feature', message: 'Hello from $feature' };
};
EOF

  echo "   Created feature: $feature"
done

# ---------- 5. Packages ----------
echo ""
echo "Default packages: ${DEFAULT_PACKAGES[*]}"
echo "Press Enter to use the defaults, or type your own full list (space-separated)."
read -rp "Packages: " -a PKG_INPUT || true

if [[ ${#PKG_INPUT[@]} -eq 0 ]]; then
  PACKAGES=("${DEFAULT_PACKAGES[@]}")
else
  PACKAGES=("${PKG_INPUT[@]}")
fi

PROD_PKGS=()
DEV_PKGS=()
for p in "${PACKAGES[@]}"; do
  case "$p" in
    nodemon|jest|supertest|eslint|prettier) DEV_PKGS+=("$p") ;;
    *) PROD_PKGS+=("$p") ;;
  esac
done

if [[ ${#PROD_PKGS[@]} -gt 0 ]]; then
  echo "==> Installing: ${PROD_PKGS[*]}"
  npm install "${PROD_PKGS[@]}"
fi
if [[ ${#DEV_PKGS[@]} -gt 0 ]]; then
  echo "==> Installing dev dependencies: ${DEV_PKGS[*]}"
  npm install --save-dev "${DEV_PKGS[@]}"
fi

# ---------- 6. Core files ----------
cat > src/config/index.js <<'EOF'
try { require('dotenv').config(); } catch (e) { /* dotenv not installed */ }

module.exports = {
  port: process.env.PORT || 3000,
  env: process.env.NODE_ENV || 'development',
};
EOF

cat > src/server.js <<'EOF'
const app = require('./app');
const { port, env } = require('./config');

app.listen(port, () => {
  console.log(`Server running in ${env} mode on http://localhost:${port}`);
});
EOF

cat > src/app.js <<'EOF'
const fs = require('fs');
const path = require('path');
const express = require('express');
const { notFound, errorHandler } = require('./middleware/errorHandler');

const app = express();

const has = (mod) => {
  try { require.resolve(mod); return true; } catch (e) { return false; }
};

// Optional packages
if (has('cors')) app.use(require('cors')());
if (has('ejs')) {
  app.set('view engine', 'ejs');
  app.set('views', path.join(__dirname, 'views'));
}

// Core middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

// Home
app.get('/', (req, res) => {
  if (app.get('view engine')) return res.render('index', { title: 'Home' });
  res.json({ message: 'API is running' });
});

// Auto-mount every feature folder at /<feature>
const featuresDir = path.join(__dirname, 'features');
if (fs.existsSync(featuresDir)) {
  fs.readdirSync(featuresDir, { withFileTypes: true })
    .filter((d) => d.isDirectory())
    .forEach((d) => {
      const routeFile = path.join(featuresDir, d.name, `${d.name}.routes.js`);
      if (fs.existsSync(routeFile)) app.use(`/${d.name}`, require(routeFile));
    });
}

app.use(notFound);
app.use(errorHandler);

module.exports = app;
EOF

cat > src/middleware/errorHandler.js <<'EOF'
exports.notFound = (req, res, next) => {
  const err = new Error(`Not Found - ${req.originalUrl}`);
  err.status = 404;
  next(err);
};

exports.errorHandler = (err, req, res, next) => { // eslint-disable-line no-unused-vars
  res.status(err.status || 500).json({ error: err.message });
};
EOF

cat > src/views/index.ejs <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title><%= title %></title>
  <link rel="stylesheet" href="/css/style.css">
</head>
<body>
  <h1>Your Express app is running!</h1>
</body>
</html>
EOF

mkdir -p src/public/css src/public/js
echo "body { font-family: system-ui, sans-serif; margin: 2rem; }" > src/public/css/style.css
echo "console.log('Client JS loaded');" > src/public/js/main.js

echo "# Helper functions go here" > src/utils/README.md
echo "# Business logic shared across features goes here" > src/services/README.md

# ---------- Done ----------
echo ""
echo "Done! Next steps:"
echo "  cd $APP_NAME"
echo "  npm run dev"
if [[ ${#FEATURES[@]} -gt 0 ]]; then
  echo "Feature routes mounted at: $(printf '/%s ' "${FEATURES[@]}")"
fi
