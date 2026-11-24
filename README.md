# init

> One command to turn a fresh Ubuntu server into a ready-to-deploy Node.js + Nginx box.

![Shell](https://img.shields.io/badge/shell-bash-4EAA25?logo=gnubash&logoColor=white)
![Ubuntu](https://img.shields.io/badge/os-Ubuntu-E95420?logo=ubuntu&logoColor=white)
[![ShellCheck](https://github.com/lihourchhin/init/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/lihourchhin/init/actions/workflows/shellcheck.yml)

## Quick start

```sh
curl -fsSL https://raw.githubusercontent.com/lihourchhin/init/master/run.sh | bash
```

Run it as a sudo-capable user (or as root) on a fresh Ubuntu server. The script is non-interactive and safe to re-run.

> **Tip:** read scripts before piping them into a shell:
> ```sh
> curl -fsSL https://raw.githubusercontent.com/lihourchhin/init/master/run.sh -o run.sh
> less run.sh && bash run.sh
> ```

## What it installs

| Area        | What you get                                                        |
| ----------- | ------------------------------------------------------------------- |
| System      | Full `apt` update/upgrade, `git`, `curl`, `wget`, `build-essential`, `htop`, `neofetch`, `bpytop` |
| Web server  | Nginx (enabled on boot) + Certbot with the Nginx plugin             |
| Node.js     | Current LTS from NodeSource, plus `yarn`, `pnpm` and `pm2` globally |
| Shell       | Zsh + Oh My Zsh + `zsh-autosuggestions`, set as your default shell  |
| Workspace   | `~/projects`, `~/temps`, `~/uploads`                                |

## Options

Set any of these before `bash` to customise the run:

| Variable       | Default | Effect                                   |
| -------------- | ------- | ---------------------------------------- |
| `SKIP_NGINX=1` | –       | Skip Nginx and Certbot                    |
| `SKIP_NODE=1`  | –       | Skip Node.js and global npm packages      |
| `SKIP_ZSH=1`   | –       | Skip Zsh / Oh My Zsh                      |
| `NODE_MAJOR`   | LTS     | Pin a Node.js major version, e.g. `22`   |

```sh
curl -fsSL https://raw.githubusercontent.com/lihourchhin/init/master/run.sh | NODE_MAJOR=22 SKIP_ZSH=1 bash
```

## After it finishes

```sh
exec zsh                              # start your new shell
sudo certbot --nginx -d example.com   # get an HTTPS certificate
pm2 startup                           # make pm2 apps survive reboots
```

## Requirements

- Ubuntu (other distributions are rejected)
- Root, or a user with `sudo`
- Internet access

## Development

Lint the script before committing:

```sh
shellcheck run.sh
```
