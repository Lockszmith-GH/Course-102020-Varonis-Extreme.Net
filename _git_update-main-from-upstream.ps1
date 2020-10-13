param([switch]$LoadFuncOnly)
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