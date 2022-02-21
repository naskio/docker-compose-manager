# Docker Compose Manager

manage multiple docker-compose files (stacks) in one place using an intuitive command line interface.

# Usage

## CLI

- Add permission to the script `chmod +x ./docker-compose-cli.sh`.

```shell
chmod +x ./docker-compose-cli.sh

# get all folders which has docker-compose.y(a)ml file in it
find /home/ -regex '.*/docker-compose.ya?ml' -printf '%h\n' | sort -u
```

## Test

```
./docker-compose-manager.ps3.sh
./docker-compose-manager.ps3.sh /home/
./docker-compose-manager.ps3.sh /
./docker-compose-manager.ps3.sh tests
./docker-compose-manager.ps3.sh <optional path to directory where we look for docker-compose files>
```

# Dependencies

- nameref (use bash version > 4.3) => Not anymore
- ```brew install gnu-getopt``` => may be optional

# Help

```
"Docker Compose Manager Help"
echo "Usage: docker-compose-manager.sh --directory <full path of directory where we look for docker-compose files>"
echo "Example 1: docker-compose-manager.sh --directory /home/"
echo "Example 2: docker-compose-manager.sh -d /"
echo "Example 3: docker-compose-manager.sh"
echo "TestCase 01: docker-compose-manager.sh -d $HOME/Desktop/tests"
```

# Install

```
bash <(curl -s http://mywebsite.com/myscript.txt)
curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -

```