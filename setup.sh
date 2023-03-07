#!/bin/bash
set -ex

# Ensure repositories are enabled
sudo add-apt-repository universe
sudo add-apt-repository multiverse
sudo add-apt-repository restricted

# Add dell drivers for focal fossa XPS 13

sudo sh -c 'cat > /etc/apt/sources.list.d/focal-dell.list << EOF
deb http://dell.archive.canonical.com/updates/ focal-dell public
# deb-src http://dell.archive.canonical.com/updates/ focal-dell public

deb http://dell.archive.canonical.com/updates/ focal-oem public
# deb-src http://dell.archive.canonical.com/updates/ focal-oem public

deb http://dell.archive.canonical.com/updates/ focal-somerville public
# deb-src http://dell.archive.canonical.com/updates/ focal-somerville public

deb http://dell.archive.canonical.com/updates/ focal-somerville-melisa public
# deb-src http://dell.archive.canonical.com/updates focal-somerville-melisa public
EOF'

sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F9FDA6BED73CDC22

sudo apt update -qq

# Install general utilities
sudo apt install git curl htop net-tools \
  vlc gnome-tweaks ubuntu-restricted-extras \
  synaptic -y -qq

# Install drivers
sudo apt install oem-somerville-melisa-meta libfprint-2-tod1-goodix oem-somerville-meta tlp-config -y

# Install fusuma for handling gestures

sudo gpasswd -a $USER input
sudo apt install libinput-tools xdotool ruby -y -qq
sudo gem install --silent fusuma

# Install Howdy for facial recognition
while true; do
  read -p "Facial recognition with Howdy (y/n)?" choice
  case "$choice" in 
    y|Y ) 
    echo "Installing Howdy"
    sudo add-apt-repository ppa:boltgolt/howdy -y > /dev/null 2>&1
    sudo apt update -qq
    sudo apt install howdy -y; break;;
    n|N ) 
    echo "Skipping Install of Howdy"; break;;
    * ) echo "invalid";;
  esac
done

# Remove packages:

sudo apt remove rhythmbox -y -q

# Install Icon Theme
[[ -d /tmp/tela-icon-theme ]] && rm -rf /tmp/tela-icon-theme
git clone https://github.com/vinceliuice/Tela-icon-theme.git /tmp/tela-icon-theme > /dev/null 2>&1
/tmp/tela-icon-theme/install.sh -a

gsettings set org.gnome.desktop.interface icon-theme 'Tela-grey-dark'

# Add Plata-theme
sudo add-apt-repository ppa:tista/plata-theme -y > /dev/null 2>&1
sudo apt update -qq && sudo apt install plata-theme -y

gsettings set org.gnome.desktop.interface gtk-theme "Plata-Noir"
gsettings set org.gnome.desktop.wm.preferences theme "Plata-Noir"

# Enable Shell Theme

sudo apt install gnome-shell-extensions -y
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com
gsettings set org.gnome.shell.extensions.user-theme name "Plata-Noir"

# Install fonts
sudo apt install fonts-firacode fonts-open-sans -y -qq

gsettings set org.gnome.desktop.interface font-name 'Open Sans 12'
gsettings set org.gnome.desktop.interface monospace-font-name 'Fira Code 13'

wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf -O /tmp/MesloLGS_NF_Regular.ttf
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf -O /tmp/MesloLGS_NF_Bold.ttf
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf -O /tmp/MesloLGS_NF_Italic.ttf
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf -O /tmp/MesloLGS_NF_Bold_Italic.ttf

sudo cp /tmp/MesloLGS_NF_Regular.ttf /usr/local/share/fonts/MesloLGS_NF_Regular.ttf
sudo cp /tmp/MesloLGS_NF_Bold.ttf /usr/local/share/fonts/MesloLGS_NF_Bold.ttf
sudo cp /tmp/MesloLGS_NF_Italic.ttf /usr/local/share/fonts/MesloLGS_NF_Italic.ttf
sudo cp /tmp/MesloLGS_NF_Bold_Italic.ttf /usr/local/share/fonts/MesloLGS_NF_Bold_Italic.ttf

# Setup Development tools
## Add build essentials
sudo apt install \
    build-essential \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common -y -q

## Install Go
wget https://go.dev/dl/go1.20.1.linux-amd64.tar.gz -O /tmp/go1.20.1.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf /tmp/go1.20.1.linux-amd64.tar.gz

if ! grep -qF "export PATH=\$PATH:/usr/local/go/bin" /etc/profile; then
  sudo sh -c 'echo "export PATH=\$PATH:/usr/local/go/bin" >> /etc/profile'
fi

## Install dotnet-core sdk + runtime
wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

sudo apt-get update && \
sudo apt-get install -y dotnet-sdk-6.0

## NVM + node ;ts Install
echo "Installing NVM + node lts"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
nvm install --lts

# Setup GNOME material shell (Need Node.js for compilation of the Typescript extension)
git clone -b 3.38 https://github.com/PapyElGringo/material-shell.git ~/material-shell || true
make -C ~/material-shell/ install

# install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install gh

# install zsh + oh-my-zsh + powerlevel10k
sudo apt install zsh -y && \
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && \
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
  
# Gotta reboot now:
sudo apt update -qq && sudo apt upgrade -y && sudo apt autoremove -y

echo $'\n'$"Ready for REBOOT"
