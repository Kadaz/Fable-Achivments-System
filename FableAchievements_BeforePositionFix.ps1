# Tolis Achievement System - Fable: The Lost Chapters
# Windows PowerShell + Windows Forms. No extra modules required.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

$ErrorActionPreference = "Stop"

$appDir = Join-Path $env:APPDATA "TolisAchievementSystem"
$dataFile = Join-Path $appDir "FableTLC.json"

if (-not (Test-Path $appDir)) {
    New-Item -ItemType Directory -Path $appDir -Force | Out-Null
}

$defaults = @(
    @{ Id="first-quest"; Name="First Steps"; Description="Complete your first quest." },
    @{ Id="first-purchase"; Name="A Customer"; Description="Buy your first item." },
    @{ Id="first-victory"; Name="First Blood"; Description="Win your first battle." },
    @{ Id="silver-key"; Name="Key Collector"; Description="Find your first Silver Key." },
    @{ Id="demon-door"; Name="Open Sesame"; Description="Open a Demon Door." },
    @{ Id="legendary-weapon"; Name="Legendary"; Description="Obtain a legendary weapon." },
    @{ Id="hero-status"; Name="A True Hero"; Description="Become a renowned hero." },
    @{ Id="jack"; Name="The Final Battle"; Description="Defeat Jack of Blades." },
    @{ Id="main-story"; Name="Hero of Albion"; Description="Complete the main story." }
)

function Save-Data {
    $script:achievements |
        ConvertTo-Json -Depth 5 |
        Set-Content -LiteralPath $script:dataFile -Encoding UTF8
}

function Load-Data {
    if (Test-Path -LiteralPath $script:dataFile) {
        try {
            $loaded = @(Get-Content -LiteralPath $script:dataFile -Raw |
                ConvertFrom-Json)

            if ($loaded.Count -gt 0) {
                return @($loaded)
            }
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show(
                "The progress file could not be read. The existing file will not be overwritten automatically.`n`n$($_.Exception.Message)",
                "Save file error",
                "OK",
                "Warning"
            ) | Out-Null
            throw
        }
    }

    $result = @()
    foreach ($item in $script:defaults) {
        $result += [PSCustomObject]@{
            Id = $item.Id
            Name = $item.Name
            Description = $item.Description
            Unlocked = $false
            UnlockedDate = ""
        }
    }
    return $result
}

function Refresh-List {
    $script:listBox.BeginUpdate()
    $script:listBox.Items.Clear()

    foreach ($item in $script:achievements) {
        if ($item.Unlocked) {
            $line = "[UNLOCKED] " + $item.Name
        } else {
            $line = "[LOCKED]   " + $item.Name
        }
        [void]$script:listBox.Items.Add($line)
    }

    $script:listBox.EndUpdate()

    $total = $script:achievements.Count
    $unlocked = @($script:achievements | Where-Object { $_.Unlocked }).Count

    $script:stats.Text = "Unlocked: $unlocked / $total"
    $percent = 0
    if ($total -gt 0) {
        $percent = [int][Math]::Round(($unlocked / $total) * 100)
    }

    $script:progress.Value = $percent
    $script:percentLabel.Text = "$percent% complete"

    if ($script:listBox.Items.Count -gt 0 -and
        $script:listBox.SelectedIndex -lt 0) {
        $script:listBox.SelectedIndex = 0
    }

    Update-Details
}

function Update-Details {
    $index = $script:listBox.SelectedIndex

    if ($index -lt 0 -or $index -ge $script:achievements.Count) {
        $script:details.Text = "Select an achievement to view its details."
        $script:unlockButton.Enabled = $false
        $script:lockButton.Enabled = $false
        return
    }

    $item = $script:achievements[$index]
    $status = if ($item.Unlocked) { "UNLOCKED" } else { "LOCKED" }

    $dateText = ""
    if ($item.UnlockedDate) {
        $dateText = "`r`nUnlocked on: $($item.UnlockedDate)"
    }

    $script:details.Text = "$($item.Name)`r`n`r`n$($item.Description)`r`n`r`nStatus: $status$dateText"
    $script:unlockButton.Enabled = -not [bool]$item.Unlocked
    $script:lockButton.Enabled = [bool]$item.Unlocked
}

function Show-AddDialog {
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = "Add Achievement"
    $dialog.Size = New-Object System.Drawing.Size(440, 310)
    $dialog.StartPosition = "CenterParent"
    $dialog.FormBorderStyle = "FixedDialog"
    $dialog.MaximizeBox = $false
    $dialog.MinimizeBox = $false

    $nameLabel = New-Object System.Windows.Forms.Label
    $nameLabel.Text = "Achievement name:"
    $nameLabel.Location = New-Object System.Drawing.Point(15, 18)
    $nameLabel.AutoSize = $true
    $dialog.Controls.Add($nameLabel)

    $nameBox = New-Object System.Windows.Forms.TextBox
    $nameBox.Location = New-Object System.Drawing.Point(15, 42)
    $nameBox.Size = New-Object System.Drawing.Size(390, 25)
    $dialog.Controls.Add($nameBox)

    $descLabel = New-Object System.Windows.Forms.Label
    $descLabel.Text = "Description:"
    $descLabel.Location = New-Object System.Drawing.Point(15, 80)
    $descLabel.AutoSize = $true
    $dialog.Controls.Add($descLabel)

    $descBox = New-Object System.Windows.Forms.TextBox
    $descBox.Location = New-Object System.Drawing.Point(15, 104)
    $descBox.Size = New-Object System.Drawing.Size(390, 55)
    $descBox.Multiline = $true
    $dialog.Controls.Add($descBox)

    $ok = New-Object System.Windows.Forms.Button
    $ok.Text = "Create"
    $ok.Location = New-Object System.Drawing.Point(220, 205)
    $ok.Size = New-Object System.Drawing.Size(85, 32)
    $ok.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $dialog.Controls.Add($ok)

    $cancel = New-Object System.Windows.Forms.Button
    $cancel.Text = "Cancel"
    $cancel.Location = New-Object System.Drawing.Point(320, 205)
    $cancel.Size = New-Object System.Drawing.Size(85, 32)
    $cancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $dialog.Controls.Add($cancel)

    $dialog.AcceptButton = $ok
    $dialog.CancelButton = $cancel

    if ($dialog.ShowDialog($script:form) -eq
        [System.Windows.Forms.DialogResult]::OK) {

        $newName = $nameBox.Text.Trim()
        $newDesc = $descBox.Text.Trim()

        if ([string]::IsNullOrWhiteSpace($newName)) {
            [System.Windows.Forms.MessageBox]::Show(
                "Enter an achievement name.",
                "Missing name"
            ) | Out-Null
        } else {
            $newItem = [PSCustomObject]@{
                Id = [Guid]::NewGuid().ToString()
                Name = $newName
                Description = $newDesc
                Unlocked = $false
                UnlockedDate = ""
            }

            $script:achievements = @($script:achievements) + @($newItem)
            Save-Data
            Refresh-List
            $script:listBox.SelectedIndex = $script:achievements.Count - 1
        }
    }

    $dialog.Dispose()
}

$script:defaults = $defaults
$script:achievements = @(Load-Data)

$form = New-Object System.Windows.Forms.Form
$script:form = $form
$form.Text = "Tolis Achievement System - Fable"
$form.Size = New-Object System.Drawing.Size(820, 590)
$form.MinimumSize = New-Object System.Drawing.Size(700, 500)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(27, 30, 38)
$form.ForeColor = [System.Drawing.Color]::White
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

$header = New-Object System.Windows.Forms.Label
$header.Text = "FABLE: THE LOST CHAPTERS"
$header.Font = New-Object System.Drawing.Font("Segoe UI", 17, [System.Drawing.FontStyle]::Bold)
$header.ForeColor = [System.Drawing.Color]::Gold
$header.Location = New-Object System.Drawing.Point(20, 15)
$header.Size = New-Object System.Drawing.Size(760, 35)
$form.Controls.Add($header)

$subheader = New-Object System.Windows.Forms.Label
$subheader.Text = "Tolis Achievement System  |  Personal achievements"
$subheader.Location = New-Object System.Drawing.Point(22, 52)
$subheader.Size = New-Object System.Drawing.Size(750, 25)
$subheader.ForeColor = [System.Drawing.Color]::LightGray
$form.Controls.Add($subheader)

# Automatic Fable process detection
$script:gameStatus = New-Object System.Windows.Forms.Label
$script:gameStatus.Location = New-Object System.Drawing.Point(400, 55)
$script:gameStatus.Size = New-Object System.Drawing.Size(360, 28)
$script:gameStatus.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$script:gameStatus.Text = "CHECKING GAME STATUS..."
$script:gameStatus.ForeColor = [System.Drawing.Color]::Khaki
$form.Controls.Add($script:gameStatus)

function Update-GameStatus {
    $game = Get-Process -Name "Fable" -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if ($null -ne $game) {
        $script:gameStatus.Text = "● GAME RUNNING"
        $script:gameStatus.ForeColor = [System.Drawing.Color]::LightGreen
    } else {
        $script:gameStatus.Text = "● GAME NOT RUNNING"
        $script:gameStatus.ForeColor = [System.Drawing.Color]::Salmon
    }
}

$script:gameTimer = New-Object System.Windows.Forms.Timer
$script:gameTimer.Interval = 2000
$script:gameTimer.Add_Tick({ Update-GameStatus })
$script:gameTimer.Start()

$listLabel = New-Object System.Windows.Forms.Label
$listLabel.Text = "ACHIEVEMENTS"
$listLabel.Location = New-Object System.Drawing.Point(22, 95)
$listLabel.Size = New-Object System.Drawing.Size(340, 25)
$form.Controls.Add($listLabel)

$script:listBox = New-Object System.Windows.Forms.ListBox
$script:listBox.Location = New-Object System.Drawing.Point(22, 125)
$script:listBox.Size = New-Object System.Drawing.Size(355, 310)
$script:listBox.BackColor = [System.Drawing.Color]::FromArgb(39, 43, 53)
$script:listBox.ForeColor = [System.Drawing.Color]::White
$script:listBox.BorderStyle = "FixedSingle"
$script:listBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$form.Controls.Add($script:listBox)

$detailLabel = New-Object System.Windows.Forms.Label
$detailLabel.Text = "DETAILS"
$detailLabel.Location = New-Object System.Drawing.Point(400, 95)
$detailLabel.Size = New-Object System.Drawing.Size(350, 25)
$form.Controls.Add($detailLabel)

$script:details = New-Object System.Windows.Forms.TextBox
$script:details.Location = New-Object System.Drawing.Point(400, 125)
$script:details.Size = New-Object System.Drawing.Size(375, 145)
$script:details.Multiline = $true
$script:details.ReadOnly = $true
$script:details.BackColor = [System.Drawing.Color]::FromArgb(39, 43, 53)
$script:details.ForeColor = [System.Drawing.Color]::White
$script:details.BorderStyle = "FixedSingle"
$script:details.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$form.Controls.Add($script:details)

$script:stats = New-Object System.Windows.Forms.Label
$script:stats.Location = New-Object System.Drawing.Point(400, 290)
$script:stats.Size = New-Object System.Drawing.Size(360, 25)
$form.Controls.Add($script:stats)

$script:progress = New-Object System.Windows.Forms.ProgressBar
$script:progress.Location = New-Object System.Drawing.Point(400, 320)
$script:progress.Size = New-Object System.Drawing.Size(375, 24)
$script:progress.Minimum = 0
$script:progress.Maximum = 100
$form.Controls.Add($script:progress)

$script:percentLabel = New-Object System.Windows.Forms.Label
$script:percentLabel.Location = New-Object System.Drawing.Point(400, 350)
$script:percentLabel.Size = New-Object System.Drawing.Size(350, 25)
$form.Controls.Add($script:percentLabel)

$script:unlockButton = New-Object System.Windows.Forms.Button
$script:unlockButton.Text = "Unlock"
$script:unlockButton.Location = New-Object System.Drawing.Point(400, 390)
$script:unlockButton.Size = New-Object System.Drawing.Size(115, 38)
$script:unlockButton.BackColor = [System.Drawing.Color]::FromArgb(65, 115, 75)
$script:unlockButton.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($script:unlockButton)

$script:lockButton = New-Object System.Windows.Forms.Button
$script:lockButton.Text = "Lock Again"
$script:lockButton.Location = New-Object System.Drawing.Point(525, 390)
$script:lockButton.Size = New-Object System.Drawing.Size(115, 38)
$script:lockButton.BackColor = [System.Drawing.Color]::FromArgb(95, 75, 65)
$script:lockButton.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($script:lockButton)

$addButton = New-Object System.Windows.Forms.Button
$addButton.Text = "+ Add Achievement"
$addButton.Location = New-Object System.Drawing.Point(22, 450)
$addButton.Size = New-Object System.Drawing.Size(180, 38)
$addButton.BackColor = [System.Drawing.Color]::FromArgb(55, 80, 125)
$addButton.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($addButton)

$footer = New-Object System.Windows.Forms.Label
$footer.Text = "Progress is stored locally in your Windows AppData folder."
$footer.Location = New-Object System.Drawing.Point(22, 510)
$footer.Size = New-Object System.Drawing.Size(750, 25)
$footer.ForeColor = [System.Drawing.Color]::LightGray
$form.Controls.Add($footer)

$script:listBox.Add_SelectedIndexChanged({ Update-Details })

$script:unlockButton.Add_Click({
    $i = $script:listBox.SelectedIndex
    if ($i -ge 0) {
        $item = $script:achievements[$i]
        if (-not $item.Unlocked) {
            $item.Unlocked = $true
            $item.UnlockedDate = Get-Date -Format "yyyy-MM-dd HH:mm"
            Save-Data
            Refresh-List
            $script:listBox.SelectedIndex = $i

            [System.Windows.Forms.MessageBox]::Show(
                "Achievement Unlocked!`n`n$($item.Name)",
                "Achievement Unlocked",
                "OK",
                "Information"
            ) | Out-Null
        }
    }
})

$script:lockButton.Add_Click({
    $i = $script:listBox.SelectedIndex
    if ($i -ge 0) {
        $script:achievements[$i].Unlocked = $false
        $script:achievements[$i].UnlockedDate = ""
        Save-Data
        Refresh-List
        $script:listBox.SelectedIndex = $i
    }
})

$addButton.Add_Click({ Show-AddDialog })

$form.Add_FormClosing({
    if ($null -ne $script:gameTimer) {
        $script:gameTimer.Stop()
        $script:gameTimer.Dispose()
    }
})

$form.Add_Shown({
    Update-GameStatus
    Refresh-List
})

[void]$form.ShowDialog()
