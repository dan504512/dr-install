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
dir=$(mktemp -d)
homedir=$(mktemp -d)
echo "$homedir"
cp "$archive" "$dir/archive.zip"
cd "$dir"
unzip "archive.zip"

# import gpg key pair for git-secret
gpg --homedir "$homedir" --import public.key
gpg --homedir "$homedir" --allow-secret-key-import --import secret.key

# read config
git_remote_with_creds="$(sed -n '1p' config)"
git_remote="$(sed -n '2p' config)"

# cleanup
rm archive.zip public.key secret.key config

# set up repo
git clone --recursive -b "$branch" --depth 1 --recurse-submodules "${git_remote_with_creds}" "$dir" #>/dev/null 2>&1
git-secret reveal -d "$homedir"
git remote set-url origin "$git_remote"

#rm -rf $dir"
