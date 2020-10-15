[CmdletBinding()]param([switch]$LoadFuncOnly)
function GetGitBranchWhenNotMain {param([Switch]$FailIfBad)
    $local:remoteRepos = $(& git remote | Out-String).Trim()
    if( $remoteRepos -cnotmatch 'upstream' ) {
        if( $FailIfBad ) {
            throw "You are missing a git remote named 'upstream', to create run:
git remote add upstream https://github.com/kobi2294/Course-102020-Varonis-Extreme.Net"
        }
    } else {
        $local:currentBranch = & git rev-parse --abbrev-ref HEAD
        if( -not $currentBranch ) {
            GetGitBranchWhenNotMain -FailIfMain
        }
    
        foreach( $local:mainBranchOption in @('main','master')) {
            if( $currentBranch -eq $mainBranchOption ) {
                $currentBranch = $null
                if( $FailIfBad ) {
                    throw "You should not work on the **$mainBranchOption** branch.
      
To create a new branch named 'working', run:
    git branch working

To switch to the 'working' branch, run:
    git checkout working

After you switched to the other branch, run this script again."
                }
            }
        }
        if( $currentBranch ) { $currentBranch }
    }
}

function performGitOperations {
    $local:currentBranch = GetGitBranchWhenNotMain -FailIfMain
    try {
        $local:stashStatus =  ( git stash list ).Count
        Write-Verbose "git stash # Attempting to stash"
        git stash
        if( $LastExitCode -eq 1 ) { throw "### FAILED: git stash"}
        $stashStatus = ( git stash list ).Count -ne $stashStatus
        If( $stashStatus ) { Write-Verbose "# Stashed changes." } else { Write-Verbose "Nothing to satsh" }
        
        Write-Verbose "git fetch upstream # Fetching from upstream repo"
        git fetch upstream
        if( $LastExitCode -eq 1 ) { throw "FAILED: git fetch upstream"}
        Write-Verbose "git checkout main # switching to main branch"
        git checkout main
        if( $LastExitCode -eq 1 ) { throw "FAILED: git checkout main"}
        Write-Verbose "git rebase upstream/main # rebasing main branch on usptream repo"
        git rebase upstream/main
        if( $LastExitCode -eq 1 ) { throw "FAILED: git rebase upstream/main"}
        Write-Verbose "git push origin main # pushing rebased main to origin repo"
        git push origin main
        if( $LastExitCode -eq 1 ) { throw "FAILED: git push origin main"}
        Write-Verbose "origin repo should be synced now"
    } finally {
        Write-Verbose "git checkout $currentBranch # switching back to $currentBranch working branch"
        git checkout $currentBranch
        if( $LastExitCode -eq 1 ) { throw "FAILED: git checkout gsz"}
        
        Write-Verbose "git pull --rebase=true # rebase and pull from newly synced main version to $currentBranch working branch"
        git pull --rebase=true
        if( $LastExitCode -eq 1 ) { throw "FAILED: git pull --rebase=true"}
        
        Write-Verbose "git push origin # pushing rebased $currentBranch"
        git push origin
        if( $LastExitCode -eq 1 ) { throw "FAILED: git push origin"}
        
        if( $stashStatus ) {
            Write-Verbose "git stash pop # retreiving latest changes that were stashed"
            git stash pop
            if( $LastExitCode -eq 1 ) { throw "FAILED: git stash pop"}
        }
    }
}

if( -not $LoadFuncOnly ) { . performGitOperations }
else {
    
    $local:currentBranch = GetGitBranchWhenNotMain -FailIfBad
    
    $local:remoteURL = $(git remote get-url origin) -replace '//github\.com/','//raw.githubusercontent.com/' -replace '\.git$',"/$currentBranch/_git_update-main-from-upstream.ps1"
    
    "To run this code, please run the following line
Invoke-Expression `"function InlineFunc{`$(Invoke-WebRequest $remoteURL -UseBasicParsing)}; . InlineFunc`""
}

# How to LoadFunc into memory directly from file
# Invoke-Expression "function InlineFunc{$(Get-Content .\_git_update-main-from-upstream.ps1 -raw)}; . InlineFunc -LoadFuncOnly"
#
# How to LoadFunc into memory directly from github fork
# Invoke-WebRequest https://raw.githubusercontent.com/Lockszmith/Course-102020-Varonis-Extreme.Net/gsz/_git_update-main-from-upstream.ps1) | Invoke-Expression
