#!/bin/sh
# dr-install
# by Dan <drobe504@gmail.com>
# License: GNU GPLv3

### OPTIONS AND VARIABLES ###
while getopts ":a:b:" o; do case "${o}" in
  h) printf "Optional arguments for custom use:\\n  -a: encrypted archive containing config and gpg key pair\\n  -b: git repo branch\\n  -h: Show this message\\n" && exit ;;
  a) archive=${OPTARG} ;;
  b) branch=${OPTARG} ;;
  *) printf "Invalid option: -%s\\n" "$OPTARG" && exit ;;
esac done

# DEFAULTS:
[ -z "$archive" ] && exit
[ -z "$branch" ] && branch="main"

# extract archive
gitdir=$(mktemp -d)
gpgdir=$(mktemp -d)
cp "$archive" "$gpgdir/archive.zip"
cd "$gpgdir"
unzip "archive.zip"

# import gpg key pair for git-secret
gpg --homedir "$gpgdir" --import public.key
gpg --homedir "$gpgdir" --allow-secret-key-import --import secret.key

# read config
git_remote_with_creds="$(sed -n '1p' config)"
git_remote="$(sed -n '2p' config)"

# set up repo
cd "$gitdir"
git clone --recursive -b "$branch" --depth 1 --recurse-submodules "${git_remote_with_creds}" "$gitdir" >/dev/null 2>&1
git-secret reveal -d "$gpgdir"
git remote set-url origin "$git_remote"

# run install
make install

# cleanup
rm -rf "$gitdir"
rm -rf "$gpgdir"
