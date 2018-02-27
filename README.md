# install-phpstorm-ubuntu-sh

### How to use:

Download and make it executable:
```sh
wget https://raw.githubusercontent.com/clfer/install-phpstorm-ubuntu-sh/master/install_phpstorm.sh
chmod +x install_phpstorm.sh
```
Run it:

```sh
#install last stable release
sudo ./install_phpstorm.sh
```

```sh
#install last eap release
sudo ./install_phpstorm.sh --eap
```

```sh
#install specific stable release
sudo ./install_phpstorm.sh -V 2017.3.4
```

```sh
#install specific eap release
sudo ./install_phpstorm.sh -V EAP-141.1412 #old EAP format
sudo ./install_phpstorm.sh -V 181.3870.19
```

Launch PhpStorm:
```sh
phpstorm

```
