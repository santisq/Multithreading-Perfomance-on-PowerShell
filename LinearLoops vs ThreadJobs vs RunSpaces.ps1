# requires -Modules ThreadJob
$ErrorActionPreference = 'SilentlyContinue'

$directories = Get-ChildItem C:\ -Directory -Recurse
$numberOfThreads = ((Get-CimInstance win32_processor).NumberOfLogicalProcessors | Measure-Object -Sum).Sum
# $numberOfThreads = 10
$numberOfTestRuns = 5

$testBlock = {

    $linearMeasure = Measure-Command {
    # Linear Test
    
        $resultLinear = foreach($directory in $directories)
        {
            [pscustomobject]@{
                DirectoryFullName = $directory.FullName
                NumberOfFiles = (Get-ChildItem $directory.FullName -File).count
            }
        }
    }

    [pscustomobject]@{
        TestRun = $_
        Test = 'Linear'
        TotalSeconds = $linearMeasure.TotalSeconds
        NumberOfFolders = $resultLinear.Count
        NumberOfFiles = ($resultLinear.numberOfFiles | Measure-Object -Sum).Sum
    }

    $threadJobMeasure = Measure-Command {
        # ThreadJob Test

        $groupSize = [math]::Ceiling($directories.Count / $numberOfThreads)
        $counter = [pscustomobject]@{ Value = 0 }
        $groups = $directories | Group-Object -Property {
            [math]::Floor($counter.Value++ / $groupSize)
        }

        foreach($group in $groups)
        {
            Start-ThreadJob{
                foreach($chunk in $args)
                {
                    [pscustomobject]@{
                        DirectoryFullName = $chunk.FullName
                        NumberOfFiles = (Get-ChildItem $chunk.fullName -File).count
                    }
                }
            } -ThrottleLimit $numberOfThreads -ArgumentList $group.Group
        }
        
        $resultThreadJob = Get-Job | Receive-Job -Wait
        Get-Job | Remove-Job
    }

    [pscustomobject]@{
        TestRun = $_
        Test = 'ThreadJob'
        TotalSeconds = $threadJobMeasure.TotalSeconds
        NumberOfFolders = $resultThreadJob.Count
        NumberOfFiles = ($resultThreadJob.numberOfFiles | Measure-Object -Sum).Sum
    }

    $runSpaceMeasure = Measure-Command {
        #RunSpace Test

        $RunspacePool = [runspacefactory]::CreateRunspacePool(1, $numberOfThreads)
        $RunspacePool.Open()

        $groupSize = [math]::Ceiling($directories.Count / $numberOfThreads)
        $counter = [pscustomobject]@{ Value = 0 }
        $groups = $directories | Group-Object -Property {
            [math]::Floor($counter.Value++ / $groupSize)
        }

        $runspaces = foreach($group in $groups)
        {
            $PSInstance = [powershell]::Create().AddScript({
                param($chunks)

                foreach($chunk in $chunks)
                {
                    [pscustomobject]@{
                        DirectoryFullName = $chunk.FullName
                        NumberOfFiles = (Get-ChildItem $chunk.fullName -File).count
                    }
                }
            }).AddParameter('chunks',$group.group)

            $PSInstance.RunspacePool = $RunspacePool

            [pscustomobject]@{
                Instance = $PSInstance
                IAResult = $PSInstance.BeginInvoke()
            }
        }

        while($runspaces | Where-Object {-not $_.IAResult.IsCompleted})
        {
            Start-Sleep -Milliseconds 50
        }

        $resultRunspace = $Runspaces | ForEach-Object {
            foreach($item in $_.Instance.EndInvoke($_.IAResult))
            {
                [pscustomobject]@{
                    DirectoryFullName = $item.DirectoryFullName
                    NumberOfFiles = $item.NumberOfFiles
                }
            }
        }

        $RunspacePool.Dispose()
    }

    [pscustomobject]@{
        TestRun = $_
        Test = 'RunSpace'
        TotalSeconds = $runSpaceMeasure.TotalSeconds
        NumberOfFolders = $resultRunSpace.Count
        NumberOfFiles = ($resultRunSpace.numberOfFiles | Measure-Object -Sum).Sum
    }

    Get-Variable | Remove-Variable
}

1..$numberOfTestRuns | ForEach-Object {
    & $testBlock
} | Sort-Object TotalSeconds | Format-Table -AutoSize
