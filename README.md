# Print your GitHub commit history within organisation

**Prerequisite**

- script uses `jq` (to install on macOS `brew install jq`)
- script needs a github organisation name as the first argument
- script requires a Github token as the second argument [https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/)

*Usage*

- clone the repo, then
- running `./main.sh myorgname 09709a87d098d7as90fa8s709d87a0s9d87 ivar 2019-02-18`
- generates `tmp/history.log`

```
---------------------------------------------------------------
https://260eecf91e51f1afc867ac86af159409d5c39@github.com/myorgname/hello-world.git
---------------------------------------------------------------
Fri, 22 Feb 2019 18:56:51 +0000 3 days ago, branch:  (HEAD -> master, tag: 10.5.0, origin/master, origin/HEAD) message: #2 fix typo on homepage
Tue, 19 Feb 2019 12:55:01 +0000 6 days ago, branch:  message: initial commit

---------------------------------------------------------------
https://260eecf91e51f1afc867ac86af159409d5c39@github.com/myorgname/awesome-product.git
---------------------------------------------------------------
Wed, 20 Feb 2019 11:31:30 +0000 5 days ago, branch:  message: readme [ci skip]
Wed, 20 Feb 2019 11:22:49 +0000 5 days ago, branch:  message: improve stability of functional tests
```

**Run without cloning**

```
curl -o- https://raw.githubusercontent.com/ivarprudnikov/my_commit_history/master/main.sh | bash -s -- myorgname 09709a87d098d7as90fa8s709d87a0s9d87 ivar 2021-02-22
```
