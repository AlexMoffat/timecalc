
#!/bin/bash

#  nth-commit.sh
#  Usage: `nth-commit.sh n [branch]`

branch=${2:-'master'}
SHA1=$(git rev-list $branch | tail -n $1 | head -n 1)
git checkout $SHA1
