# Linear Loops vs ThreadJob vs Runspace

This script is meant to mainly test how good does the `ThreadJob Module` performs vs `Runspace` when looping through local directories.

### Requirements
- PowerShell v5.1
- [ThreadJob Module](https://docs.microsoft.com/en-us/powershell/module/threadjob/start-threadjob?view=powershell-7.1&viewFallbackFrom=powershell-5.1)

### How to start test cases

Here is an example of the script running 5 test cases:

```
Clear-Host

$i = 1

while($i -lt 6)
{
    "[############# TEST RUN [$i] #############]"
    & "X:\path\to\downloadedScript\LinearLoops vs ThreadJobs vs RunSpaces.ps1"
    $i++
}
```

### Results

![results](https://i.stack.imgur.com/wZ3Mw.png?raw=true)

### Credits

All credits on the `Runspace` code goes to Mathias R. Jessen and his awesome answer on StackOverflow [here](https://stackoverflow.com/a/41797153/15339544).
