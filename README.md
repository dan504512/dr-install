# dr-install

## install steps

sudo pacman -Syu

sudo pacman -S git

git clone https://github.com/drobe504/dr-install.git

cd dr-install

./drbs.sh <user-name> <password>

su - <user-name>

./dr-install -a dr-etc.zip -b develop

./dr-install -a dr-dotfiles.zip -b develop

# tips

make sure user/pass exist in system configuration
