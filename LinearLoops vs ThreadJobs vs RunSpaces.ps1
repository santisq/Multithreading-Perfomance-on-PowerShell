# requires -Modules ThreadJob

$directories = Get-ChildItem $home -Directory -Recurse -EA SilentlyContinue

$measures = @(

Measure-Command{
    # Linear Test
    
    $resultLinear = foreach($directory in $directories)
    {
        [pscustomobject]@{
            DirectoryFullName = $directory.FullName
            NumberOfFiles = (Get-ChildItem $directory.FullName -File).count
        }
    }
}

Measure-Command{
    # ThreadJob Test

    $groupSize = [math]::Ceiling($directories.Count/10)
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
        } -ThrottleLimit 10 -ArgumentList $group.Group
    }
        
    $resultThread = Get-Job | Receive-Job -Wait
    Get-Job | Remove-Job
}

Measure-Command{
    #RunSpace Test

    $RunspacePool = [runspacefactory]::CreateRunspacePool(1,10)
    $RunspacePool.Open()

    $groupSize = [math]::Ceiling($directories.Count/10)
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
})

@(
[pscustomobject]@{
    Test = 'Linear'
    TotalSeconds = $measures[0].TotalSeconds
    NumberOfFolders = $resultLinear.Count
    NumberOfFiles = $(
        $i=0
        $resultLinear.numberOfFiles.foreach({
            $i = $i+$_
        })
        $i
    )
}

[pscustomobject]@{
    Test = 'ThreadJob'
    TotalSeconds = $measures[1].TotalSeconds
    NumberOfFolders = $resultThread.Count
    NumberOfFiles = $(
        $i=0
        $resultLinear.numberOfFiles.foreach({
            $i = $i+$_
        })
        $i
    )
}

[pscustomobject]@{
    Test = 'RunSpace'
    TotalSeconds = $measures[2].TotalSeconds
    NumberOfFolders = $resultRunspace.Count
    NumberOfFiles = $(
        $i=0
        $resultLinear.numberOfFiles.foreach({
            $i = $i+$_
        })
        $i
    )
}) | Format-Table -AutoSize

Get-Variable | Remove-Variable -EA SilentlyContinue
