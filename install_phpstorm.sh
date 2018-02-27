#!/usr/bin/env bash
### Helper functions
function get_phpstorm_last_eap_version()
{
  # Parse PhpStorm EAP page to get the last EAP version
  phpstorm_last_eap_version=`curl https://www.jetbrains.com/phpstorm/eap/ 2>/dev/null | grep "PhpStorm-EAP" | grep "tar.gz" | sed -ne "s/^.*PhpStorm-EAP-\([0-9\.]\+\)\.tar\.gz.*$/\1/p" `
}

function get_phpstorm_last_stable_version()
{
    # Parse jetbrains releases API return to get the last PhpStorm version
  phpstorm_last_stable_version=`curl https://data.services.jetbrains.com/products/releases?code=PS 2>/dev/null | grep "\"version\"" | sed -ne "s/^.*\"version\":\"\([^\"]\+\)\".*$/\1/p" `
}

### Main script

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Use sudo." 1>&2
   exit 1
fi

# PhpStorm will be extracted in this folder
INSTALL_ROOT="/opt"
# bin folder to use (allow to launch phpstorm as a single command)
BIN_ROOT="/usr/local/bin"

CURRENT_USER=`who am i | awk '{print $1}'`
CURRENT_USER_GROUP=`stat -c "%G" "/home/$CURRENT_USER"`
if [ -z $CURRENT_USER_GROUP ]; then
  CURRENT_USER_GROUP=$CURRENT_USER
fi

confirmation_step=true

# Parse arguments
while [[ $# > 0 ]]
do
key="$1"

case $key in
    --eap)
    EAP=true
    ;;
    -V|--version)
    phpstorm_version="$2"
    shift # past argument
    ;;
    -y)
    confirmation_step=false
    ;;
    *) # unknown option
    echo "Unknown parameter: $1"
    exit 1
    ;;
esac
shift # past argument or value
done



if [ -n "$phpstorm_version" ]; then
  echo 'Asked PhpStorm Version: '$phpstorm_version
elif [ -n "$EAP" ]; then
  get_phpstorm_last_eap_version
  phpstorm_version=$phpstorm_last_eap_version;
  echo 'Last PhpStorm EAP Version: '$phpstorm_version
else
  get_phpstorm_last_stable_version
  phpstorm_version=$phpstorm_last_stable_version;
  echo 'Last PhpStorm Version: '$phpstorm_version
fi

version_checked=$(echo $phpstorm_version | sed -e '/^[0-9\.]*$/d')
if [ -z "$phpstorm_version" ] || [ -n "$version_checked" ]; then
    echo 'Sorry, the PhpStorm Version format is incorrect.'
    exit 1
fi

while $confirmation_step; do
    read -p "Do you wish to install this version? (Y/n) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) break;;
    esac
done

if [ -n "$EAP" ]; then
  phpstorm_archive="PhpStorm-EAP-$phpstorm_version.tar.gz"
else
  phpstorm_archive="PhpStorm-$phpstorm_version.tar.gz"
fi

phpstorm_download_link="http://download.jetbrains.com/webide/$phpstorm_archive"

# TODO Check archive existence:
# wget --spider -q $phpstorm_download_link && exists=true || exists=false


if [ -d "$INSTALL_ROOT/PhpStorm-$phpstorm_version" ]; then
  echo "PhpStorm Version already installed"
  if [ -h "$INSTALL_ROOT/PhpStorm" ] && [ "$(readlink $INSTALL_ROOT/PhpStorm)" != "$INSTALL_ROOT/PhpStorm-$phpstorm_version" ]; then
    ask_for_symlink=true
  else
    hide_ending_message=true
  fi

else
  echo "Intalling PhpStorm..."
  wget  -O "$INSTALL_ROOT/$phpstorm_archive" $phpstorm_download_link
  echo "Downloaded PhpStorm..."
  tar -xzf "$INSTALL_ROOT/$phpstorm_archive" -C "$INSTALL_ROOT"
  INSTALL_DIR=`tar tzf "$INSTALL_ROOT/$phpstorm_archive" | head -1 | sed -e 's/\/.*//'`
  rm -f "$INSTALL_ROOT/$phpstorm_archive"
  if [ "$INSTALL_DIR" != "PhpStorm-$phpstorm_version" ]; then
    mv "$INSTALL_ROOT/$INSTALL_DIR" "$INSTALL_ROOT/PhpStorm-$phpstorm_version"
  fi
  chown $CURRENT_USER:$CURRENT_USER_GROUP -R "$INSTALL_ROOT/PhpStorm-$phpstorm_version"

  ask_for_symlink=true
fi

if [ -h "$INSTALL_ROOT/PhpStorm" ] && [ "$ask_for_symlink" = true ]; then
  update_symlink=true;
  while $confirmation_step; do
      read -p "Do you want to update symlink? (Y/n) " yn
      case $yn in
          [Yy]* ) break;;
          [Nn]* ) update_symlink=false; break;;
          * ) break;;
      esac
  done
fi

if [ -h "$INSTALL_ROOT/PhpStorm" ] && [ "$update_symlink" = true ]; then
  echo "Updating symlink..."
  rm -f "$INSTALL_ROOT/PhpStorm"
fi

if [ ! -h "$INSTALL_ROOT/PhpStorm" ]; then
  echo "Creating symlink..."
  ln -s "$INSTALL_ROOT/PhpStorm-$phpstorm_version" "$INSTALL_ROOT/PhpStorm"
  chown $CURRENT_USER:$CURRENT_USER_GROUP -R "$INSTALL_ROOT/PhpStorm"
fi

if [ -n "$BIN_ROOT" ] && [ "$(readlink $BIN_ROOT/phpstorm)" != "$INSTALL_ROOT/PhpStorm/bin/phpstorm.sh" ]; then
  echo "Updating bin..."
  rm -f "$BIN_ROOT/phpstorm"
  ln -s "$INSTALL_ROOT/PhpStorm/bin/phpstorm.sh" "$BIN_ROOT/phpstorm"
fi

#TODO ask to remove old install

if [ "$hide_ending_message" != true ]; then
  echo "PhpStorm installation finished"
fi
