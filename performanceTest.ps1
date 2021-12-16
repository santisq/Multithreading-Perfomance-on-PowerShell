$ErrorActionPreference = 'SilentlyContinue'

# Define Init Variables
$initialDirectory = '/home/user/'
$directories = Get-ChildItem $initialDirectory -Directory -Recurse
$TestForEachObject = $true # => Set to $false if not on PS COre
$TestThreadJob = $true # => Set to $false if no ThreadJob Module
$numberOfThreads = 10
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

    if($TestThreadJob)
    {
        $threadJobMeasure = Measure-Command {
            # ThreadJob Test

            $groupSize = [math]::Ceiling($directories.Count / $numberOfThreads)
            $counter = [pscustomobject]@{ Value = 0 }
            $groups = $directories | Group-Object -Property {
                [math]::Floor($counter.Value++ / $groupSize)
            }

            $jobs = foreach($group in $groups)
            {
                Start-ThreadJob {
                    foreach($chunk in $args)
                    {
                        [pscustomobject]@{
                            DirectoryFullName = $chunk.FullName
                            NumberOfFiles = (Get-ChildItem $chunk.fullName -File).count
                        }
                    }
                } -ArgumentList $group.Group
            }
            
            $resultThreadJob = $jobs | Receive-Job -Wait -AutoRemoveJob
        }

        [pscustomobject]@{
            TestRun = $_
            Test = 'Start-ThreadJob'
            TotalSeconds = $threadJobMeasure.TotalSeconds
            NumberOfFolders = $resultThreadJob.Count
            NumberOfFiles = ($resultThreadJob.numberOfFiles | Measure-Object -Sum).Sum
        }
    }

    $PSJobMeasure = Measure-Command {
        # Start-Job Test

        $groupSize = [math]::Ceiling($directories.Count / $numberOfThreads)
        $counter = [pscustomobject]@{ Value = 0 }
        $groups = $directories | Group-Object -Property {
            [math]::Floor($counter.Value++ / $groupSize)
        }

        $jobs = foreach($group in $groups)
        {
            Start-Job {
                foreach($chunk in $args)
                {
                    [pscustomobject]@{
                        DirectoryFullName = $chunk.FullName
                        NumberOfFiles = (Get-ChildItem $chunk.fullName -File).count
                    }
                }
            } -ArgumentList $group.Group
        }
        
        $resultPSJob = $jobs | Receive-Job -Wait -AutoRemoveJob
    }

    [pscustomobject]@{
        TestRun = $_
        Test = 'Start-Job'
        TotalSeconds = $PSJobMeasure.TotalSeconds
        NumberOfFolders = $resultPSJob.Count
        NumberOfFiles = ($resultPSJob.numberOfFiles | Measure-Object -Sum).Sum
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
                Handle = $PSInstance.BeginInvoke()
            }
        }

        while($runspaces.Handle.IsCompleted -contains $false)
        {
            Start-Sleep -Milliseconds 50
        }

        $resultRunspace = $Runspaces | ForEach-Object {
            foreach($item in $_.Instance.EndInvoke($_.Handle))
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

    if($TestForEachObject)
    {
        $foreachParallel = Measure-Command {
            # ForEach-Object -Parallel Test

            $groupSize = [math]::Ceiling($directories.Count / $numberOfThreads)
            $counter = [pscustomobject]@{ Value = 0 }
            $groups = $directories | Group-Object -Property {
                [math]::Floor($counter.Value++ / $groupSize)
            }

            $resultForEachParallel = foreach($group in $groups)
            {
                $group.Group | ForEach-Object -Parallel {
                    [pscustomobject]@{
                        DirectoryFullName = $_.FullName
                        NumberOfFiles = (Get-ChildItem $_.FullName -File).count
                    }
                }
            }
        }

        [pscustomobject]@{
            TestRun = $_
            Test = 'ForEach-Object -Parallel'
            TotalSeconds = $foreachParallel.TotalSeconds
            NumberOfFolders = $resultForEachParallel.Count
            NumberOfFiles = ($resultForEachParallel.numberOfFiles | Measure-Object -Sum).Sum
        }
    }

    Get-Variable | Remove-Variable
}

1..$numberOfTestRuns | ForEach-Object {
    & $testBlock
} | Sort-Object TotalSeconds | Format-Table -AutoSize
