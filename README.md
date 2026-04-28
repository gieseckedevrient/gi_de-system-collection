# Ansible Collection - gi_de.system

Documentation for the collection.

## Unit tests

install testing framework

```shell
 sudo -H pip3.11 install --upgrade pytest
 sudo -H pip3.11 install --upgrade pytest-ansible
```

### Run from terminal

place terminal to root folder:
`[system]$`

Run from command line :
`[user@machine system]$pytest tests`

sample output :

```shell
Test session starts (platform: linux, Python 3.11.11, pytest 8.4.1, pytest-sugar 1.1.0)
ansible: 2.16.14
rootdir: REDACTED
plugins: xdist-3.8.0, sugar-1.1.0, plus-0.8.1, ansible-25.6.3
collected 7 items

 tests/unit/plugins/filter/test_to_dlln.py ✓✓✓✓✓✓✓                                                                                                            100% ██████████

Results (0.02s):
       7 passed
```

### Run using ansible-test

Not working yet, too much dependant on ``quay.io`` with no override option, when using the `--docker` option

Neither working when running using the `--local` option, because of effective location of the collection on the file system and the ansible cfg
