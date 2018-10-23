author_email=$(git log -1 --pretty=format:'%ae')
author_name=$(git log -1 --pretty=format:'%an')
sha=$(git rev-parse HEAD)
branch=$(git symbolic-ref -q HEAD || git name-rev --name-only --no-undefined --always HEAD)
branch=${branch#refs/heads/}
branch=${branch#tags/}

echo "author_email ${author_email}"
echo "author_name ${author_name}"
echo "sha ${sha}"
echo "branch ${branch}"
