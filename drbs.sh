#!/bin/sh
# DR Boostrapping Script
# by Dan <drobe504@gmail.com>
# License: GNU GPLv3

aurhelper="yay"
name="drbs"
pass1="password"

### FUNCTIONS ###
error() { clear; printf "ERROR:\\n%s\\n" "$1"; exit; }
installpkg(){ pacman --noconfirm --needed -S "$1" >/dev/null 2>&1 ;}
aurinstall() { sudo -u "$name" yay -S --noconfirm "$1" >/dev/null 2>&1 ;}

refreshkeys() { \
  case "$(readlink -f /sbin/init)" in
      *systemd* )
          pacman --noconfirm -S archlinux-keyring >/dev/null 2>&1
          ;;
      *)
          pacman --noconfirm --needed -S artix-keyring artix-archlinux-support >/dev/null 2>&1
          for repo in extra community; do
              grep -q "^\[$repo\]" /etc/pacman.conf ||
                  echo "[$repo]
Include = /etc/pacman.d/mirrorlist-arch" >> /etc/pacman.conf
          done
          pacman -Sy >/dev/null 2>&1
          pacman-key --populate archlinux >/dev/null 2>&1
          ;;
  esac ;}

gitmakeinstall() {
  dir=$(mktemp -d)
  git clone --depth 1 "$1" "$dir" >/dev/null 2>&1
  cd "$dir" || exit
  make >/dev/null 2>&1
  make install >/dev/null 2>&1
  cd /tmp || return ;}

manualinstall() { # Installs $1 manually if not installed. Used only for AUR helper here.
  [ -f "/usr/bin/$1" ] || (
      cd /tmp || exit
      rm -rf /tmp/"$1"*
      curl -sO https://aur.archlinux.org/cgit/aur.git/snapshot/"$1".tar.gz &&
          sudo -u "$name" tar -xvf "$1".tar.gz >/dev/null 2>&1 &&
          cd "$1" &&
          sudo -u "$name" makepkg --noconfirm -si >/dev/null 2>&1
      cd /tmp || return) ;}

putgitrepo() { # Downloads a gitrepo $1 and places the files in $2 only overwriting conflicts
    [ -z "$3" ] && branch="master" || branch="$3"
    dir=$(mktemp -d)
    [ ! -d "$2" ] && mkdir -p "$2"
    git clone --recursive -b "$branch" --depth 1 --recurse-submodules "$1" "$dir" #>/dev/null 2>&1
    sudo cp -rfT "$dir" "$2" ;}

adduserandpass() { \
  # Adds user `$name` with password $pass1.
  useradd -m -g wheel -s /bin/bash "$name" >/dev/null 2>&1 ||
  usermod -a -G wheel "$name" && mkdir -p /home/"$name" && chown "$name":wheel /home/"$name"
  echo "$name:$pass1" | chpasswd
  unset pass1 pass2 ;}

newperms() { # Set special sudoers settings for install (or after).
    sed -i "/#DRBS/d" /etc/sudoers
    echo "$* #DRBS" >> /etc/sudoers ;}

# install core packages
pacman -Syu --noconfirm
installpkg base-devel

refreshkeys || error "Error automatically refreshing Arch keyring. Consider doing so manually."
for x in curl ca-certificates git ntp zsh vim zip unzip; do
    installpkg "$x"
done

ntpdate 0.us.pool.ntp.org >/dev/null 2>&1

adduserandpass || error "Error adding username and/or password."
[ -f /etc/sudoers.pacnew ] && cp /etc/sudoers.pacnew /etc/sudoers # Just in case

# Allow user to run sudo without password. Since AUR programs must be installed
# in a fakeroot environment, this is required for all builds with AUR.
newperms "%wheel ALL=(ALL) NOPASSWD: ALL"

# Use all cores for compilation TODO: update aconfmgr etc config with this depending on machine
sed -i "s/-j2/-j$(nproc)/;/^#MAKEFLAGS/s/^#//" /etc/makepkg.conf

manualinstall yay || error "Failed to install AUR helper."
for x in aconfmgr-git git-secret; do
  aurinstall "$x"
done
