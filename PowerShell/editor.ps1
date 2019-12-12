# Just a seperate file for an edit function that'll be mapped to alias 'e'.
# Wanted it seperate in case other BTR developers wanted to use a different editor
# they could grab all my files in WindowsPowershell except this.

function edit {
  &'C:\Program Files\Sublime Text 3\sublime_text.exe' $args
}

function vs2017 {
  &'C:\Users\terry.aney\Documents\WindowsPowerShell\vs2017.ps1'
}

function vs2019 {
  &'C:\Users\terry.aney\Documents\WindowsPowerShell\vs2019.ps1'
}