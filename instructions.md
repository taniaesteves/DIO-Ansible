
## TAGS
    - deploy_cataio
    - delete_cataio

## ENV
    - run_all (boolean)


## Create Cataio from scratch

```
$ ansible-playbook -u gsd deploy_cataio_playbook.yml --tags deploy_cataio -e run_all=true
```

## Just start Cataio

```
$ ansible-playbook -u gsd deploy_cataio_playbook.yml --tags deploy_cataio
```

## Just stop Cataio

```
$ ansible-playbook -u gsd deploy_cataio_playbook.yml --tags delete_cataio
```

## Delete completely Cataio

```
$ ansible-playbook -u gsd deploy_cataio_playbook.yml --tags delete_cataio -e run_all=true
```
