function performGitOperations {
    try {
        git stash
        if( $LastExitCode -eq 1 ) { throw "FAILED: git stash"}
        
        git fetch upstream
        if( $LastExitCode -eq 1 ) { throw "FAILED: git fetch upstream"}
        git checkout main
        if( $LastExitCode -eq 1 ) { throw "FAILED: git checkout main"}
        git rebase upstream/main
        if( $LastExitCode -eq 1 ) { throw "FAILED: git rebase upstream/main"}
        git push origin main
        if( $LastExitCode -eq 1 ) { throw "FAILED: git push origin main"}
    } finally {
        git checkout gsz
        if( $LastExitCode -eq 1 ) { throw "FAILED: git checkout gsz"}
        
        git stash pop
        if( $LastExitCode -eq 1 ) { throw "FAILED: git stash pop"}
    }
}

performGitOperations