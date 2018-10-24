author_email=$(git log -1 --pretty=format:'%ae')
author_name=$(git log -1 --pretty=format:'%an')
author_date=$(git log -1 --pretty=format:'%aI')
committer_email=$(git log -1 --pretty=format:'%ce')
committer_name=$(git log -1 --pretty=format:'%cn')
committer_date=$(git log -1 --pretty=format:'%cI')
sha=$(git log -1 --pretty=format:'%H')
message=$(git log -1 --pretty=format:'%s')
branch=$(git symbolic-ref -q HEAD || git name-rev --name-only --no-undefined --always HEAD)
branch=${branch#refs/heads/}
branch=${branch#tags/}

echo "author_email ${author_email}"
echo "author_name ${author_name}"
echo "author_date ${author_name}"
echo "committer_email ${committer_email}"
echo "committer_name ${committer_name}"
echo "committer_date ${committer_date}"
echo "sha ${sha}"
echo "branch ${branch}"
