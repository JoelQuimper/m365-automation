$branch = ""

# Create a new branch
git branch $branch #create new branch
git checkout $branch #switch to new branch

# Stage/Commit
$commitMessage = ""
git add . #stage all changes
git commit -m $commitMessage #commit staged changes with message

# Push
git push --set-upstream origin $branch #the first time
git push #subsequent times

# Create a Pull Request

# Cleanup
git checkout main #switch back to main branch
git fetch --prune #update remote tracking branches to remove origin branches that have been deleted
git pull #update local main branch with the merge Pull Request changes
git branch -D $branch #delete local branch
