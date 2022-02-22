# Contribute

Contributions are welcome!

# Development

## Setup

Add permission to the script:

```shell
chmod +x docker-compose-manager.*.sh
```

## Installation

```shell
./install.sh --debug
bash <(cat install.sh) --debug
# or
bash <(cat install.sh) ps3 --debug
```

## Uninstallation

```shell
rm /usr/local/bin/dcm
rm -r /usr/local/lib/docker-compose-manager/
```

## Testing

```shell
./docker-compose-manager.ps3.sh <optional path to directory where we look for docker-compose files>
# current directory is default
./docker-compose-manager.ps3.sh
# or with full_path
./docker-compose-manager.ps3.sh /
# or with full_path
./docker-compose-manager.ps3.sh ./tests
```