# Multithreading Perfomance on PowerShell

These series of tests are meant to understand how well do Linear Loops (`foreach`) perform against the different multithreading options we have on PowerShell.<br>
The tests consist on first gathering all directories (recursive) from a starting folder (`$initialDirectory`) and looping through each folder to get the count of all the files.<br>

### Tests
- [`foreach`](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_foreach?view=powershell-7.2)
- [`Start-Job`](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/start-job?view=powershell-7.2)
- [`Start-ThreadJob`](https://docs.microsoft.com/en-us/powershell/module/threadjob/start-threadjob?view=powershell-7.2)
- [`Runspace`](https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.runspaces.runspace?view=powershellsdk-7.0.0)
- [`ForEach-Object -Parallel`](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/foreach-object?view=powershell-7.2)

### Requirements
- PowerShell v5.1+

### Init Variables

- __`$initialDirectory`__ The initial directory to begin the test, i.e.: `C:\user\Documents`.
- __`$numberOfThreads`__ By default is set to __10__, this number can be tweaked to get better results.
- __`$numberOfTestRuns`__ The number of Test Cases we want to perform, by default its set to __5__.
- __`$TestForEachObject`__ By default is set to `$true`, set to `$false` if not on PowerShell Core.
- __`$TestThreadJob`__ By default is set to `$true`, set to `$false` if the `ThreadJob` module is not installed.

### Results

- By default, results are sorted by `TotalSeconds`:

```
TestRun Test                     TotalSeconds NumberOfFolders NumberOfFiles
------- ----                     ------------ --------------- -------------
      5 RunSpace                    1.4467082            1109         14142
      4 RunSpace                    1.4536342            1109         14142
      3 RunSpace                    1.4733609            1109         14142
      5 Start-ThreadJob             1.4939372            1109         14142
      1 Start-ThreadJob             1.5183739            1109         14142
      2 Start-ThreadJob             1.5588786            1109         14142
      2 RunSpace                    1.5638541            1109         14142
      3 Start-ThreadJob             1.5780027            1109         14142
      4 Start-ThreadJob             1.7246104            1109         14142
      1 RunSpace                    1.8515854            1109         14142
      2 Linear                      1.9031116            1109         14142
      3 Linear                      1.9369417            1109         14142
      5 Linear                      1.9748949            1109         14142
      1 Linear                       2.016238            1109         14142
      4 Linear                      2.6118708            1109         14142
      1 ForEach-Object -Parallel    3.7749827            1109         14142
      4 ForEach-Object -Parallel    3.8035109            1109         14142
      5 ForEach-Object -Parallel    3.8591055            1109         14142
      2 ForEach-Object -Parallel    3.9026964            1109         14142
      3 ForEach-Object -Parallel    4.7344062            1109         14142
      5 Start-Job                   5.0805633            1109         14142
      4 Start-Job                   5.3252725            1109         14142
      3 Start-Job                   5.4109967            1109         14142
      2 Start-Job                    7.038974            1109         14142
      1 Start-Job                   8.5424708            1109         14142
```
