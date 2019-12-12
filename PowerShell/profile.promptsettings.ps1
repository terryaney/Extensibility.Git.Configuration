# Prompt shape

$global:gitVersion = "0.7.3"
$global:gitVersion = "1.0"

if ( $gitVersion -eq "0.7.3" ) {
    $ScriptRoot = Split-Path $MyInvocation.MyCommand.Path
    Write-Host $ScriptRoot
    Import-Module "$ScriptRoot\posh-git\posh-git"
}
else {
    # Run following in Powershell
    # PowerShellGet\Install-Module posh-git -Scope CurrentUser -AllowPrerelease -Force
    # https://github.com/dahlbyk/posh-git
    Import-Module posh-git
}

class KATPromptSettings {
    [string]$BeforeErrorText     = '  '
    [string]$BeforeVSEnvironmentText     = '  '
    [string]$BeforeKubernetesText     = '  '
    [string]$BeforeAzureText     = '  '
    [string]$BeforeDirectoryText     = '  '    
    [string]$BeforeDirectoryMemoryText     = 'M:'
}

$global:PromptSettings = [KATPromptSettings]::new()

if ( $gitVersion -eq "0.7.3" ) {
    # If Unable to use UbuntuMono NF, can use text
    $PromptSettings.BeforeErrorText = ' ! '
    $PromptSettings.BeforeVSEnvironmentText = ' VS '
    $PromptSettings.BeforeKubernetesText = ' Kn '
    $PromptSettings.BeforeAzureText = ' Az '
    $PromptSettings.BeforeDirectoryText = ' '

    if ( $PromptSettings.BeforeErrorText -eq " ! " ) {
        $GitPromptSettings.BeforeText = " "
        $GitPromptSettings.AfterText = " "
    }
    else {
        $GitPromptSettings.AfterStatus.Text = " "
        $GitPromptSettings.BeforeStatus.Text = "  "
        $GitPromptSettings.BranchAheadStatusSymbol.Text = ""
        $GitPromptSettings.BranchBehindStatusSymbol.Text = ""
        $GitPromptSettings.BranchGoneStatusSymbol.Text = ""
        $GitPromptSettings.BranchBehindAndAheadStatusSymbol.Text = ""
        $GitPromptSettings.BranchIdenticalStatusSymbol.Text = ""
        $GitPromptSettings.BranchUntrackedText = "※ "
        $GitPromptSettings.DelimStatus.Text = " ॥"
        $GitPromptSettings.LocalStagedStatusSymbol.Text = ""
        $GitPromptSettings.LocalWorkingStatusSymbol.Text = ""
    }


    $GitPromptSettings.BranchForegroundColor = [ConsoleColor]::White
    $GitPromptSettings.BeforeForegroundColor = [ConsoleColor]::White
    $GitPromptSettings.AfterForegroundColor = [ConsoleColor]::White    
    $GitPromptSettings.BeforeBackgroundColor = [ConsoleColor]::DarkBlue
    $GitPromptSettings.AfterBackgroundColor = [ConsoleColor]::DarkBlue
    $GitPromptSettings.BranchBackgroundColor = [ConsoleColor]::DarkBlue    
    $GitPromptSettings.BranchAheadBackgroundColor = [ConsoleColor]::DarkBlue
    $GitPromptSettings.BranchBehindBackgroundColor = [ConsoleColor]::DarkBlue
    $GitPromptSettings.BranchBehindAndAheadBackgroundColor = [ConsoleColor]::DarkBlue
    $GitPromptSettings.BeforeIndexBackgroundColor = [ConsoleColor]::DarkBlue
    $GitPromptSettings.IndexBackgroundColor = [ConsoleColor]::DarkBlue
    $GitPromptSettings.WorkingBackgroundColor = [ConsoleColor]::DarkBlue
    $GitPromptSettings.UntrackedBackgroundColor = [ConsoleColor]::DarkBlue
}
else {
    $GitPromptSettings.EnableStashStatus = $false
    $GitPromptSettings.ShowStatusWhenZero = $false

    # Background colors

    $GitPromptSettings.AfterStash.BackgroundColor = [ConsoleColor]::DarkBlue
    $GitPromptSettings.AfterStatus.BackgroundColor = [ConsoleColor]::DarkBlue
    $GitPromptSettings.BeforeIndex.BackgroundColor = [ConsoleColor]::DarkBlue
    $GitPromptSettings.BeforeStash.BackgroundColor = [ConsoleColor]::DarkBlue
    $GitPromptSettings.BeforeStatus.BackgroundColor = [ConsoleColor]::DarkBlue
    $GitPromptSettings.BranchAheadStatusSymbol.BackgroundColor = [ConsoleColor]::DarkBlue
    $GitPromptSettings.BranchBehindAndAheadStatusSymbol.BackgroundColor = [ConsoleColor]::DarkBlue
    $GitPromptSettings.BranchBehindStatusSymbol.BackgroundColor = [ConsoleColor]::DarkBlue
    $GitPromptSettings.BranchColor.BackgroundColor = [ConsoleColor]::DarkBlue
    $GitPromptSettings.BranchGoneStatusSymbol.BackgroundColor = [ConsoleColor]::DarkBlue
    $GitPromptSettings.BranchIdenticalStatusSymbol.BackgroundColor = [ConsoleColor]::DarkBlue
    $GitPromptSettings.DefaultColor.BackgroundColor = [ConsoleColor]::DarkBlue
    $GitPromptSettings.DelimStatus.BackgroundColor = [ConsoleColor]::DarkBlue
    $GitPromptSettings.ErrorColor.BackgroundColor = [ConsoleColor]::DarkBlue
    $GitPromptSettings.IndexColor.BackgroundColor = [ConsoleColor]::DarkBlue
    $GitPromptSettings.LocalDefaultStatusSymbol.BackgroundColor = [ConsoleColor]::DarkBlue
    $GitPromptSettings.LocalStagedStatusSymbol.BackgroundColor = [ConsoleColor]::DarkBlue
    $GitPromptSettings.LocalWorkingStatusSymbol.BackgroundColor = [ConsoleColor]::DarkBlue
    $GitPromptSettings.StashColor.BackgroundColor = [ConsoleColor]::DarkBlue
    $GitPromptSettings.WorkingColor.BackgroundColor = [ConsoleColor]::DarkBlue

    # Foreground colors

    $GitPromptSettings.AfterStatus.ForegroundColor = [ConsoleColor]::Blue
    # $GitPromptSettings.BeforeStatus.ForegroundColor = [ConsoleColor]::Blue
    $GitPromptSettings.BeforeStatus.ForegroundColor = [ConsoleColor]::White
    $GitPromptSettings.BranchColor.ForegroundColor = [ConsoleColor]::White
    $GitPromptSettings.BranchGoneStatusSymbol.ForegroundColor = [ConsoleColor]::Blue
    $GitPromptSettings.BranchIdenticalStatusSymbol.ForegroundColor = [ConsoleColor]::Blue
    $GitPromptSettings.DefaultColor.ForegroundColor = [ConsoleColor]::Gray
    # $GitPromptSettings.DelimStatus.ForegroundColor = [ConsoleColor]::Blue
    $GitPromptSettings.DelimStatus.ForegroundColor = [ConsoleColor]::White
    $GitPromptSettings.IndexColor.ForegroundColor = [ConsoleColor]::Cyan
    $GitPromptSettings.WorkingColor.ForegroundColor = [ConsoleColor]::Yellow

    if ( $PromptSettings.BeforeErrorText -eq " ! " ) {
        $GitPromptSettings.BranchUntrackedText = "※"
        $GitPromptSettings.AfterStatus.Text = " "
        $GitPromptSettings.BeforeStatus.Text = " "
    }
    else {
        $GitPromptSettings.AfterStatus.Text = " "
        $GitPromptSettings.BeforeStatus.Text = "  "
        $GitPromptSettings.BranchAheadStatusSymbol.Text = ""
        $GitPromptSettings.BranchBehindStatusSymbol.Text = ""
        $GitPromptSettings.BranchGoneStatusSymbol.Text = ""
        $GitPromptSettings.BranchBehindAndAheadStatusSymbol.Text = ""
        $GitPromptSettings.BranchIdenticalStatusSymbol.Text = ""
        $GitPromptSettings.BranchUntrackedText = "※ "
        $GitPromptSettings.DelimStatus.Text = " ॥"
        $GitPromptSettings.LocalStagedStatusSymbol.Text = ""
        $GitPromptSettings.LocalWorkingStatusSymbol.Text = ""
    }
}
