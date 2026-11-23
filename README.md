# espresso ☕

A Bash script that scaffolds an Express.js project in seconds. It sets up the folder structure, creates your feature folders, initialises git, and installs your packages, all interactively.

## Features

- Runs `npm init -y` and sets up `start` and `dev` scripts
- Runs `git init` if git is installed (skipped otherwise)
- Creates `.gitignore` and `.env`
- Creates the default folders inside `src/`: `config`, `views`, `public`, `middleware`, `utils`, `services`
- Lets you name your own **feature folders** (e.g. `auth`, `payments`), each with a route, controller and service file
- Lets you choose which **npm packages** to install, with sensible defaults
- Auto-mounts every feature at `/<feature>`, so there's no need to edit `app.js`

## Requirements

- Bash 4+
- Node.js and npm
- Git (optional)

## Installation

Make the script executable:

```bash
chmod +x espresso
```

Optionally, put it on your PATH so you can run it from anywhere:

```bash
sudo mv espresso /usr/local/bin/espresso
```

## Usage

```bash
espresso [project-name]
```

If you leave out the project name, espresso will ask for it.

### Example session

```text
$ espresso my-api
==> Running npm init -y
==> Git found, running git init
==> Created .gitignore and .env
==> Creating default folders inside src/

Enter feature folders to create (e.g. auth payments users).
Features (space-separated, blank for none): auth payments users
   Created feature: auth
   Created feature: payments
   Created feature: users

Default packages: express ejs express-validator nodemon dotenv cors
Press Enter to use the defaults, or type your own full list (space-separated).
Packages:
==> Installing: express ejs express-validator dotenv cors
==> Installing dev dependencies: nodemon

Done! Next steps:
  cd my-api
  npm run dev
```

### The two prompts

**Features**: type feature names separated by spaces. Names are lowercased, and invalid names (anything that isn't letters, numbers, `-` or `_`, or that doesn't start with a letter) are skipped. Press Enter to create none.

**Packages**: press Enter to install the defaults, or type your own list.

> ⚠️ A custom list **replaces** the defaults entirely. If you type `express mongoose`, you get only those two. Include `express` (and anything else you need) in your list.

`nodemon`, `jest`, `supertest`, `eslint` and `prettier` are installed as dev dependencies. Everything else is installed as a regular dependency.

## What gets generated

```text
my-api/
├── .env
├── .gitignore
├── package.json
└── src/
    ├── app.js
    ├── server.js
    ├── config/
    │   └── index.js
    ├── middleware/
    │   └── errorHandler.js
    ├── public/
    │   ├── css/style.css
    │   └── js/main.js
    ├── services/
    ├── utils/
    ├── views/
    │   └── index.ejs
    └── features/
        ├── auth/
        │   ├── auth.routes.js
        │   ├── auth.controller.js
        │   └── auth.service.js
        └── payments/
            └── ...
```

## Running your project

```bash
cd my-api
npm run dev     # development, with auto-reload (nodemon)
npm start       # production
```

Then visit:

- `http://localhost:3000/`: home page
- `http://localhost:3000/auth`: example response from the `auth` feature

The port and environment are set in `.env`.

## Adding a feature later

Create a folder in `src/features/` with a `<name>.routes.js` file that exports an Express router, for example `src/features/orders/orders.routes.js`. It is mounted automatically at `/orders` the next time the server starts.

## Notes

- espresso exits with an error if the project folder already exists, so it never overwrites existing work.
- `cors` and `ejs` are wired up only if they were installed, so you can skip them with a custom package list.
- The `.env` file is listed in `.gitignore`, so your secrets stay out of version control.

## License

MIT
