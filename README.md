# Linear Loops vs ThreadJob vs Runspace

This script is meant to mainly test how good does the `ThreadJob Module` performs vs `Runspace` when looping through local directories.

### Requirements
- PowerShell v5.1
- [ThreadJob Module](https://docs.microsoft.com/en-us/powershell/module/threadjob/start-threadjob?view=powershell-7.1&viewFallbackFrom=powershell-5.1)

### Init Variables

- `$numberOfThreads` Normally we use `((Get-CimInstance win32_processor).NumberOfLogicalProcessors | Measure-Object -Sum).Sum`, however this number can be tweaked to get better results.
- `$numberOfTestRuns` The number of Test Cases we want to perform, by default its set to **5**

### Results

- By default, results are sorted by `TotalSeconds`:

```
TestRun Test      TotalSeconds NumberOfFolders NumberOfFiles
------- ----      ------------ --------------- -------------
      3 ThreadJob    4.8891603            3709        142367
      2 ThreadJob    4.9398637            3709        142367
      4 ThreadJob     4.943194            3709        142367
      5 ThreadJob    4.9602689            3709        142367
      1 ThreadJob    4.9841981            3709        142367
      1 RunSpace     5.2052934            3709        142367
      5 RunSpace     5.2290481            3709        142367
      3 RunSpace     5.2677655            3709        142367
      2 RunSpace      5.359765            3709        142367
      4 RunSpace     5.5090859            3709        142367
      4 Linear       6.8770682            3709        142367
      2 Linear       6.9006135            3709        142367
      5 Linear       7.1451586            3709        142367
      1 Linear       7.1719337            3709        142367
      3 Linear       7.2723745            3709        142367
```

### Credits

All credits on the `Runspace` code goes to Mathias R. Jessen and his awesome answer on StackOverflow [here](https://stackoverflow.com/a/41797153/15339544).
