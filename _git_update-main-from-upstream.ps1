function performGitOperations {
    git fetch upstream
    git checkout main
    git rebase upstream/main
    git push origin main
    git checkout gsz
}

performGitOperations