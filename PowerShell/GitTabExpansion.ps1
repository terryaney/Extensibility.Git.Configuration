# Initial implementation by Jeremy Skinner
# http://www.jeremyskinner.co.uk/2010/03/07/using-git-with-windows-powershell/

$Global:GitTabSettings = New-Object PSObject -Property @{
    AllCommands = $false
}

$subcommands = @{
    bisect = 'start bad good skip reset visualize replay log run'
    notes = 'edit show'
    reflog = 'expire delete show'
    remote = 'add rename rm set-head show prune update'
    stash = 'list show drop pop apply branch save clear create'
    submodule = 'add status init update summary foreach sync'
    svn = 'init fetch clone rebase dcommit branch tag log blame find-rev set-tree create-ignore show-ignore mkdirs commit-diff info proplist propget show-externals gc reset'
    tfs = 'bootstrap checkin checkintool ct cleanup cleanup-workspaces clone diagnostics fetch help init pull quick-clone rcheckin shelve shelve-list unshelve verify'
    flow = 'init feature release hotfix'
}

$gitflowsubcommands = @{
    feature = 'list start finish publish track diff rebase checkout pull delete'
    release = 'list start finish publish track delete'
    hotfix = 'list start finish publish delete'
}

function script:gitCmdOperations($commands, $command, $filter) {
    $commands.$command -split ' ' |
        where { $_ -like "$filter*" }
}


$script:someCommands = @('add','am','annotate','archive','bisect','blame','branch','bundle','checkout','cherry','cherry-pick','citool','clean','clone','commit','config','describe','diff','difftool','fetch','format-patch','gc','grep','gui','help','init','instaweb','log','merge','mergetool','mv','notes','prune','pull','push','rebase','reflog','remote','rerere','reset','revert','rm','shortlog','show','stash','status','submodule','svn','tag','whatchanged')
try {
  if ((git help -a 2>&1 | Select-String flow) -ne $null) {
      $script:someCommands += 'flow'
  }
}
catch {
}

function script:gitCommands($filter, $includeAliases) {
    $cmdList = @()
    if (-not $global:GitTabSettings.AllCommands) {
        $cmdList += $someCommands -like "$filter*"
    } else {
        $cmdList += git help --all |
            where { $_ -match '^  \S.*' } |
            foreach { $_.Split(' ', [StringSplitOptions]::RemoveEmptyEntries) } |
            where { $_ -like "$filter*" }
    }

    if ($includeAliases) {
        $cmdList += gitAliases $filter
    }
    $cmdList | sort
}

function script:gitRemotes($filter) {
    git remote |
        where { $_ -like "$filter*" }
}

function script:gitBranches($filter, $includeHEAD = $false) {
    $prefix = $null
    if ($filter -match "^(?<from>\S*\.{2,3})(?<to>.*)") {
        $prefix = $matches['from']
        $filter = $matches['to']
    }
    $branches = @(git branch --no-color | foreach { if($_ -match "^\*?\s*(?<ref>.*)") { $matches['ref'] } }) +
                @(git branch --no-color -r | foreach { if($_ -match "^  (?<ref>\S+)(?: -> .+)?") { $matches['ref'] } }) +
                @(if ($includeHEAD) { 'HEAD','FETCH_HEAD','ORIG_HEAD','MERGE_HEAD' })
    $branches |
        where { $_ -ne '(no branch)' -and $_ -like "$filter*" } |
        foreach { $prefix + $_ }
}

function script:gitTags($filter) {
    git tag |
        where { $_ -like "$filter*" }
}

function script:gitFeatures($filter, $command){
	$featurePrefix = git config --local --get "gitflow.prefix.$command"
    $branches = @(git branch --no-color | foreach { if($_ -match "^\*?\s*$featurePrefix(?<ref>.*)") { $matches['ref'] } })
    $branches |
        where { $_ -ne '(no branch)' -and $_ -like "$filter*" } |
        foreach { $prefix + $_ }
}

function script:gitRemoteBranches($remote, $ref, $filter) {
    git branch --no-color -r |
        where { $_ -like "  $remote/$filter*" } |
        foreach { $ref + ($_ -replace "  $remote/","") }
}

function script:gitStashes($filter) {
    (git stash list) -replace ':.*','' |
        where { $_ -like "$filter*" } |
        foreach { "'$_'" }
}

function script:gitTfsShelvesets($filter) {
    (git tfs shelve-list) |
        where { $_ -like "$filter*" } |
        foreach { "'$_'" }
}

function script:gitFiles($filter, $files) {
    $files | sort |
        where { $_ -like "$filter*" } |
        foreach { if($_ -like '* *') { "'$_'" } else { $_ } }
}

function script:gitIndex($filter) {
    gitFiles $filter $GitStatus.Index
}

function script:gitAddFiles($filter) {
    gitFiles $filter (@($GitStatus.Working.Unmerged) + @($GitStatus.Working.Modified) + @($GitStatus.Working.Added))
}

function script:gitCheckoutFiles($filter) {
    gitFiles $filter (@($GitStatus.Working.Unmerged) + @($GitStatus.Working.Modified) + @($GitStatus.Working.Deleted))
}

function script:gitDiffFiles($filter, $staged) {
    if ($staged) {
        gitFiles $filter $GitStatus.Index.Modified
    } else {
        gitFiles $filter (@($GitStatus.Working.Unmerged) + @($GitStatus.Working.Modified) + @($GitStatus.Index.Modified))
    }
}

function script:gitMergeFiles($filter) {
    gitFiles $filter $GitStatus.Working.Unmerged
}

function script:gitDeleted($filter) {
    gitFiles $filter $GitStatus.Working.Deleted
}

function script:gitAliases($filter) {
    git config --get-regexp ^alias\. | foreach {
        if($_ -match "^alias\.(?<alias>\S+) .*") {
            $alias = $Matches['alias']
            if($alias -like "$filter*") {
                $alias
            }
        }
    } | Sort
}

function script:expandGitAlias($cmd, $rest) {
    if((git config --get-regexp "^alias\.$cmd`$") -match "^alias\.$cmd (?<cmd>[^!].*)`$") {
        return "git $($Matches['cmd'])$rest"
    } else {
        return "git $cmd$rest"
    }
}

function GitTabExpansion($lastBlock) {

    if($lastBlock -match "^$(Get-AliasPattern git) (?<cmd>\S+)(?<args> .*)$") {
        $lastBlock = expandGitAlias $Matches['cmd'] $Matches['args']
    }

    # Handles tgit <command> (tortoisegit)
    if($lastBlock -match "^$(Get-AliasPattern tgit) (?<cmd>\S*)$") {
            # Need return statement to prevent fall-through.
            return $tortoiseGitCommands | where { $_ -like "$($matches['cmd'])*" }
    }

    # Handles gitk
    if($lastBlock -match "^$(Get-AliasPattern gitk).* (?<ref>\S*)$"){
        return gitBranches $matches['ref'] $true
    }

    switch -regex ($lastBlock -replace "^$(Get-AliasPattern git) ","") {

        # Handles git <cmd> <op>
        "^(?<cmd>$($subcommands.Keys -join '|'))\s+(?<op>\S*)$" {
            gitCmdOperations $subcommands $matches['cmd'] $matches['op']
        }


        # Handles git flow <cmd> <op>
        "^flow (?<cmd>$($gitflowsubcommands.Keys -join '|'))\s+(?<op>\S*)$" {
            gitCmdOperations $gitflowsubcommands $matches['cmd'] $matches['op']
        }

		# Handles git flow <command> <op> <name>
        "^flow (?<command>\S*)\s+(?<op>\S*)\s+(?<name>\S*)$" {
			gitFeatures $matches['name'] $matches['command']
        }

        # Handles git remote (rename|rm|set-head|set-branches|set-url|show|prune) <stash>
        "^remote.* (?:rename|rm|set-head|set-branches|set-url|show|prune).* (?<remote>\S*)$" {
            gitRemotes $matches['remote']
        }

        # Handles git stash (show|apply|drop|pop|branch) <stash>
        "^stash (?:show|apply|drop|pop|branch).* (?<stash>\S*)$" {
            gitStashes $matches['stash']
        }

        # Handles git bisect (bad|good|reset|skip) <ref>
        "^bisect (?:bad|good|reset|skip).* (?<ref>\S*)$" {
            gitBranches $matches['ref'] $true
        }

        # Handles git tfs unshelve <shelveset>
        "^tfs +unshelve.* (?<shelveset>\S*)$" {
            gitTfsShelvesets $matches['shelveset']
        }

        # Handles git branch -d|-D|-m|-M <branch name>
        # Handles git branch <branch name> <start-point>
        "^branch.* (?<branch>\S*)$" {
            gitBranches $matches['branch']
        }

        # Handles git <cmd> (commands & aliases)
        "^(?<cmd>\S*)$" {
            gitCommands $matches['cmd'] $TRUE
        }

        # Handles git help <cmd> (commands only)
        "^help (?<cmd>\S*)$" {
            gitCommands $matches['cmd'] $FALSE
        }

        # Handles git push remote <ref>:<branch>
        "^push.* (?<remote>\S+) (?<ref>[^\s\:]*\:)(?<branch>\S*)$" {
            gitRemoteBranches $matches['remote'] $matches['ref'] $matches['branch']
        }

        # Handles git push remote <branch>
        # Handles git pull remote <branch>
        "^(?:push|pull).* (?:\S+) (?<branch>[^\s\:]*)$" {
            gitBranches $matches['branch']
        }

        # Handles git pull <remote>
        # Handles git push <remote>
        # Handles git fetch <remote>
        "^(?:push|pull|fetch).* (?<remote>\S*)$" {
            gitRemotes $matches['remote']
        }

        # Handles git reset HEAD <path>
        # Handles git reset HEAD -- <path>
        "^reset.* HEAD(?:\s+--)? (?<path>\S*)$" {
            gitIndex $matches['path']
        }

        # Handles git <cmd> <ref>
        "^commit.*-C\s+(?<ref>\S*)$" {
            gitBranches $matches['ref'] $true
        }

        # Handles git add <path>
        "^add.* (?<files>\S*)$" {
            gitAddFiles $matches['files']
        }

        # Handles git checkout -- <path>
        "^checkout.* -- (?<files>\S*)$" {
            gitCheckoutFiles $matches['files']
        }

        # Handles git rm <path>
        "^rm.* (?<index>\S*)$" {
            gitDeleted $matches['index']
        }

        # Handles git diff/difftool <path>
        "^(?:diff|difftool)(?:.* (?<staged>(?:--cached|--staged))|.*) (?<files>\S*)$" {
            gitDiffFiles $matches['files'] $matches['staged']
        }

        # Handles git merge/mergetool <path>
        "^(?:merge|mergetool).* (?<files>\S*)$" {
            gitMergeFiles $matches['files']
        }

        # Handles git <cmd> <ref>
        "^(?:checkout|cherry|cherry-pick|diff|difftool|log|merge|rebase|reflog\s+show|reset|revert|show).* (?<ref>\S*)$" {
            gitBranches $matches['ref'] $true
            gitTags $matches['ref']
        }

        # Custom KAT Handlers
        # For debug:     $Host.UI.RawUI.WindowTitle = "  > $lastBlock <  "

        # Handles git dt/undo <path>
        "^(?:.*undo|dt|.*z-dt) (?<files>\S*)$" {
            # gitDiffFiles returns Index.Modified no matter what.  I don't want that in my list
            # gitDiffFiles $GitStatus $matches['files'] $matches['staged']
            gitFiles $matches['files'] (@($GitStatus.Working.Unmerged) + @($GitStatus.Working.Modified))
        }

        # Handles git del-rb/co-rb remote <branch>
        "^(?:.*del-rb|.*co-rb)${ignoreGitParams}\s+(?<remote>[^\s-]\S*).*\s+(?<branch>[^\s\:]*)$" {
            gitBranches $matches['branch'] $true
        }
        # Handles git del-rb/co-rb <remote>
        "^(?:.*del-rb|.*co-rb)${ignoreGitParams}\s+(?<remote>\S*)$" {
            gitRemotes $matches['remote']
        }

        # Handles git ch-b branch1 <branch2>
        "^(?:.*ch-b)\s+(?<branch1>\S*)\s+(?<branch2>\S*)$" {
            gitBranches $matches['branch2'] $true
        }

        # Handles git ch-b <branch1>
        "^(?:.*ch-b)\s+(?<branch1>\S*)$" {
            gitBranches $matches['branch1'] $true
        }

        # Handles git dt-s <files>
        "^(?:.*dt-s)\s+(?<files>\S*)$" {
            gitFiles $matches['files'] $GitStatus.Index.Modified
        }

        # Handles git dt-w <files>
        "^(?:.*dt-w)\s+(?<files>\S*)$" {
            gitFiles $matches['files'] (@($GitStatus.Working.Unmerged) + @($GitStatus.Working.Modified))
        }

        # Handles git prev/previous <ref>
        "^(?:.*previous|.*prev)${ignoreGitParams}\s+(?<ref>\S*)$" {
            gitRefHints 0
        }

        # Posted a issue in posh-git asking if I was even close to doing this right.
        # https://github.com/dahlbyk/posh-git/issues/667
        
        # Handles git dt-c ref1 ref2 <path>
        "^(?:.*dt-c)\s+(?<ref1>\S*)\s*(?<ref2>\S*)?\s*(?<files>\S*)?$" {
            if ( "$($matches['ref2'])" -ne "" )
            {            
                # If typed in a 'file filter' and hit tab, only returned tracked files matching
                gitTracked $matches['files']
            }
            elseif ( "$($matches['ref1'])" -ne "" )
            {            
                # If only first ref is filled in and they tab, return hints + all tracked files
                @(gitRefHints 1) + @(gitTracked $matches['ref2'])
            }
            else
            {
                # If tabbing immediately after the dt-c, just return hints
                gitRefHints 0
            }
        }

        # Handles git set-origin|clone-btr type <ref>
        "^(?:.*set-origin|.*clone-btr)${ignoreGitParams}\s+(?<remote>[^\s-]\S*).*\s+(?<ref>[^\s\:]*)$" {
            $cmdList = @()
            $cmdList += "<ClientName>"
            $cmdList
        }

        # Handles git set-origin|clone-btr <type>
        "^(?:.*set-origin|.*clone-btr)${ignoreGitParams}\s+(?<remote>\S*)$" {
            $cmdList = @()
            $cmdList += "ESS"
            $cmdList += "ESS.4.1"
            $cmdList += "Admin"
            $cmdList += "Admin.4.5"
            $cmdList += "Tahiti"
            $cmdList += "Shared.Bootstrap"
            $cmdList += "Shared.Severance"
            $cmdList += "Shared.Bootstrap.Admin"
            $cmdList += "Shared.Bootstrap.Core"
            $cmdList
        }
        # Handles git undelete <path>
        "^(?:.*undelete)${ignoreGitParams}\s+$" {
            $cmdList = @()
            $cmdList += "<FileName>"
            $cmdList
        }
        # Handles git unstage-all - no params allowed
        "^(?:.*unstage-all|.*pull-all|.*fetch-all)${ignoreGitParams}\s+$" {
            $cmdList = @()
            $cmdList += ""
            $cmdList
        }
    }
}

function script:gitRefHints($offset) {
    $refHints = New-Object System.Collections.Generic.List[string]

    if ( $offset -eq 0)
    {
        $refHints.Add("HEAD~")
    }
    $refHints.Add("HEAD~~")
    if ( $offset -eq 1)
    {
        $refHints.Add("HEAD~~")
    }
    $refHints.Add("HEAD~N")
    $refHints
}

function script:gitTracked($filter) {
    
    if ( $global:gitVersion -eq "0.7.3" ) 
    {
        $git = git ls-files | Where-Object { $_ -like "$filter*" }
    }
    else 
    {
        $git = Invoke-Utf8ConsoleCommand { (git ls-files) } |
            Where-Object { $_ -like "$filter*" } |
            quoteStringWithSpecialChars
    }    

    return $git
}

$PowerTab_RegisterTabExpansion = if (Get-Module -Name powertab) { Get-Command Register-TabExpansion -Module powertab -ErrorAction SilentlyContinue }
if ($PowerTab_RegisterTabExpansion)
{
    & $PowerTab_RegisterTabExpansion "git.exe" -Type Command {
        param($Context, [ref]$TabExpansionHasOutput, [ref]$QuoteSpaces)  # 1:

        $line = $Context.Line
        $lastBlock = [regex]::Split($line, '[|;]')[-1].TrimStart()
        $TabExpansionHasOutput.Value = $true
        GitTabExpansion $lastBlock
    }
    return
}

if (Test-Path Function:\TabExpansion) {
    Rename-Item Function:\TabExpansion TabExpansionBackup
}

function TabExpansion($line, $lastWord) {
    $lastBlock = [regex]::Split($line, '[|;]')[-1].TrimStart()

    switch -regex ($lastBlock) {
        # Execute git tab completion for all git-related commands
        "^$(Get-AliasPattern git) (.*)" { GitTabExpansion $lastBlock }
        "^$(Get-AliasPattern tgit) (.*)" { GitTabExpansion $lastBlock }
        "^$(Get-AliasPattern gitk) (.*)" { GitTabExpansion $lastBlock }

        # Fall back on existing tab expansion
        default { if (Test-Path Function:\TabExpansionBackup) { TabExpansionBackup $line $lastWord } }
    }
}
