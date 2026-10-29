
# Tolis Achievement System - Fable: The Lost Chapters
# Corrected version with categories, achievements, game detection and playtime.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$ErrorActionPreference = 'Stop'
$DataDirectory = Join-Path $env:APPDATA 'TolisAchievementSystem'
$DataFile = Join-Path $DataDirectory 'FableTLC.json'
$PlaytimeFile = Join-Path $DataDirectory 'FableTLC_Playtime.json'
$GameProcessName = 'Fable'

$script:TotalPlaySeconds = 0L
$script:LastPlayed = $null
$script:GameSessionStart = $null
$script:LastPlaytimeSave = Get-Date

# Load saved playtime without touching achievement progress.
if (Test-Path -LiteralPath $PlaytimeFile) {
    try {
        $playData = Get-Content -LiteralPath $PlaytimeFile -Raw -Encoding UTF8 |
            ConvertFrom-Json

        if ($null -ne $playData.TotalSeconds) {
            $script:TotalPlaySeconds = [long][math]::Max(
                0, [long]$playData.TotalSeconds
            )
        }

        $script:LastPlayed = $playData.LastPlayed
    }
    catch {
        $script:TotalPlaySeconds = 0L
        $script:LastPlayed = $null
    }
}

# Default achievements.
$DefaultAchievements = @(
    [pscustomobject]@{ Id='first_steps'; Title='First Steps'; Description='Complete your first quest.'; Category='Story'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='a_customer'; Title='A Customer'; Description='Buy your first item.'; Category='Exploration'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='first_blood'; Title='First Blood'; Description='Win your first battle.'; Category='Combat'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='key_collector'; Title='Key Collector'; Description='Find your first Silver Key.'; Category='Collectibles'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='open_sesame'; Title='Open Sesame'; Description='Open a Demon Door.'; Category='Exploration'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='legendary'; Title='Legendary'; Description='Obtain a legendary weapon.'; Category='Collectibles'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='a_true_hero'; Title='A True Hero'; Description='Become a renowned hero.'; Category='Story'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='final_battle'; Title='The Final Battle'; Description='Defeat Jack of Blades.'; Category='Combat'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='hero_of_albion'; Title='Hero of Albion'; Description='Complete the main story.'; Category='Story'; Unlocked=$false; UnlockDate=$null },

    [pscustomobject]@{ Id='guild_graduate'; Title='🎓 Guild Graduate'; Description='Complete your training at the Heroes Guild.'; Category='Story'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='arena_champion'; Title='🏆 Arena Champion'; Description='Complete the Arena.'; Category='Combat'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='silver_hoarder'; Title='🥈 Silver Hoarder'; Description='Collect 10 Silver Keys.'; Category='Collectibles'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='treasure_hunter'; Title='💎 Treasure Hunter'; Description='Open a chest using Silver Keys.'; Category='Exploration'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='fishing_hero'; Title='🎣 Fishing Hero'; Description='Catch your first fish.'; Category='Exploration'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='master_fisher'; Title='🏅 Master Fisher'; Description='Catch 10 fish.'; Category='Collectibles'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='property_owner'; Title='🏠 Property Owner'; Description='Purchase your first property.'; Category='Exploration'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='wealthy_hero'; Title='💰 Wealthy Hero'; Description='Accumulate 100,000 gold.'; Category='Collectibles'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='demon_door_master'; Title='🚪 Demon Door Master'; Description='Open 5 Demon Doors.'; Category='Exploration'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='combat_veteran'; Title='⚔️ Combat Veteran'; Description='Win 100 battles.'; Category='Combat'; Unlocked=$false; UnlockDate=$null },

    [pscustomobject]@{ Id='archmage'; Title='🪄 Archmage'; Description='Cast every type of spell at least once.'; Category='Combat'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='spell_slinger'; Title='✨ Spell Slinger'; Description='Cast 100 spells.'; Category='Combat'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='will_master'; Title='🔮 Will Master'; Description='Reach a high level of Will.'; Category='Combat'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='bow_expert'; Title='🏹 Bow Expert'; Description='Defeat 25 enemies with a bow.'; Category='Combat'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='blade_master'; Title='⚔️ Blade Master'; Description='Defeat 50 enemies with melee weapons.'; Category='Combat'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='unarmed_fighter'; Title='🥊 Unarmed Fighter'; Description='Win a battle without using a weapon.'; Category='Combat'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='fashion_hero'; Title='👑 Fashion Hero'; Description='Collect 5 different clothing items.'; Category='Collectibles'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='doll_collector'; Title='🧸 Doll Collector'; Description='Collect a Hero doll.'; Category='Collectibles'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='silver_key_hunter'; Title='🗝️ Silver Key Hunter'; Description='Collect 25 Silver Keys.'; Category='Collectibles'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='demon_door_seeker'; Title='🚪 Door Seeker'; Description='Discover 3 Demon Doors.'; Category='Exploration'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='map_explorer'; Title='🗺️ Map Explorer'; Description='Visit 10 different regions.'; Category='Exploration'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='fishing_fanatic'; Title='🎣 Fishing Fanatic'; Description='Catch 25 fish.'; Category='Collectibles'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='digging_deep'; Title='⛏️ Digging Deep'; Description='Dig up 10 buried items.'; Category='Exploration'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='big_spender'; Title='💸 Big Spender'; Description='Spend 10,000 gold in shops.'; Category='Exploration'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='millionaire_in_spirit'; Title='💰 Money Maker'; Description='Accumulate 250,000 gold.'; Category='Collectibles'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='good_samaritan'; Title='❤️ Good Samaritan'; Description='Complete 10 quests for others.'; Category='Story'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='fearless_hero'; Title='🛡️ Fearless Hero'; Description='Defeat a powerful enemy without fleeing.'; Category='Combat'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='renowned_hero'; Title='🌟 Renowned Hero'; Description='Reach a high renown level.'; Category='Story'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='married_life'; Title='💍 Married Life'; Description='Get married.'; Category='Exploration'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='hero_of_many_talents'; Title='🏅 Hero of Many Talents'; Description='Improve Strength, Skill and Will.'; Category='Story'; Unlocked=$false; UnlockDate=$null },

    [pscustomobject]@{ Id='assassin_strike'; Title='🗡️ Assassin Strike'; Description='Successfully perform a Sneak Attack.'; Category='Combat'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='perfect_guard'; Title='🛡️ Perfect Guard'; Description='Defeat an enemy without taking damage.'; Category='Combat'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='undead_slayer'; Title='💀 Undead Slayer'; Description='Defeat 25 undead enemies.'; Category='Combat'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='troll_hunter'; Title='🪨 Troll Hunter'; Description='Defeat a Troll.'; Category='Combat'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='fashion_icon'; Title='👗 Fashion Icon'; Description='Own 10 different clothing items.'; Category='Collectibles'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='silver_key_master'; Title='🔑 Key Master'; Description='Collect 30 Silver Keys.'; Category='Collectibles'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='demon_door_whisperer'; Title='🚪 Door Whisperer'; Description='Open 10 Demon Doors.'; Category='Exploration'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='world_traveler'; Title='🌍 World Traveler'; Description='Explore every major region of Albion.'; Category='Exploration'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='charismatic_hero'; Title='❤️ Charismatic Hero'; Description='Make someone fall in love with you.'; Category='Exploration'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='master_trader'; Title='💎 Master Trader'; Description='Earn gold by selling items to merchants.'; Category='Collectibles'; Unlocked=$false; UnlockDate=$null },
    [pscustomobject]@{ Id='legend_of_albion'; Title='🌟 Legend of Albion'; Description='Complete the main story and become a legend.'; Category='Story'; Unlocked=$false; UnlockDate=$null }
)

function Get-PropertyValue {
    param($Object, [string[]]$Names, $Default = $null)

    foreach ($name in $Names) {
        if ($null -ne $Object -and $null -ne $Object.PSObject.Properties[$name]) {
            return $Object.PSObject.Properties[$name].Value
        }
    }

    return $Default
}

function Get-InferredCategory {
    param($Achievement)

    $title = [string](Get-PropertyValue $Achievement @('Title','Name','Achievement','title','name') '')
    $id = [string](Get-PropertyValue $Achievement @('Id','ID','id') '')

    foreach ($default in $DefaultAchievements) {
        if ($id -eq $default.Id -or $title -eq $default.Title) {
            return $default.Category
        }
    }

    $combined = ($title + ' ' + $id).ToLowerInvariant()

    if ($combined -match 'quest|story|albion|hero|ending') { return 'Story' }
    if ($combined -match 'battle|combat|blood|kill|fight|enemy|defeat') { return 'Combat' }
    if ($combined -match 'key|collect|weapon|item|silver|legendary') { return 'Collectibles' }
    if ($combined -match 'door|explor|customer|buy|shop|discover') { return 'Exploration' }

    return 'Custom'
}

function Save-Achievements {
    try {
        if (-not (Test-Path -LiteralPath $DataDirectory)) {
            New-Item -ItemType Directory -Path $DataDirectory -Force | Out-Null
        }

        $Achievements | ConvertTo-Json -Depth 8 |
            Set-Content -LiteralPath $DataFile -Encoding UTF8

        if ($null -ne $saveStatusLabel) {
            $saveStatusLabel.Text = 'Progress saved'
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Could not save achievements:`r`n$($_.Exception.Message)",
            'Save Error',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
}

function Get-CurrentPlaySeconds {
    $seconds = [long]$script:TotalPlaySeconds

    if ($null -ne $script:GameSessionStart) {
        $elapsed = (Get-Date) - $script:GameSessionStart
        $seconds += [long][math]::Floor($elapsed.TotalSeconds)
    }

    return $seconds
}

function Save-Playtime {
    try {
        if (-not (Test-Path -LiteralPath $DataDirectory)) {
            New-Item -ItemType Directory -Path $DataDirectory -Force | Out-Null
        }

        $playData = [pscustomobject]@{
            TotalSeconds = (Get-CurrentPlaySeconds)
            LastPlayed   = $script:LastPlayed
        }

        $playData | ConvertTo-Json |
            Set-Content -LiteralPath $PlaytimeFile -Encoding UTF8

        $script:LastPlaytimeSave = Get-Date
    }
    catch {
        # Do not interrupt the timer if a temporary save error occurs.
    }
}

function Refresh-PlaytimeDisplay {
    $seconds = [long](Get-CurrentPlaySeconds)
    $hours = [long][math]::Floor($seconds / 3600)
    $minutes = [int][math]::Floor(($seconds % 3600) / 60)

    # Cast minutes to an integer before using the D2 format specifier.
    $totalPlaytimeLabel.Text = 'Total Playtime: {0}h {1:D2}m' -f $hours, $minutes

    if ($script:LastPlayed) {
        try {
            $date = [datetime]$script:LastPlayed
            $lastPlayedLabel.Text = 'Last Played: ' + $date.ToString('dd/MM/yyyy HH:mm')
        }
        catch {
            $lastPlayedLabel.Text = 'Last Played: Unknown'
        }
    }
    else {
        $lastPlayedLabel.Text = 'Last Played: Never'
    }
}

function Load-Achievements {
    $loaded = @()

    if (Test-Path -LiteralPath $DataFile) {
        try {
            $raw = Get-Content -LiteralPath $DataFile -Raw -Encoding UTF8

            if (-not [string]::IsNullOrWhiteSpace($raw)) {
                $parsed = ConvertFrom-Json -InputObject $raw
                if ($null -ne $parsed) {
                    $loaded = @($parsed)
                }
            }
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show(
                "The existing save file could not be read. It has not been deleted.`r`n$($_.Exception.Message)",
                'Load Warning',
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
        }
    }

    if ($loaded.Count -eq 0) {
        return @(
            $DefaultAchievements | ForEach-Object {
                [pscustomobject]@{
                    Id          = $_.Id
                    Title       = $_.Title
                    Description = $_.Description
                    Category    = $_.Category
                    Unlocked    = $_.Unlocked
                    UnlockDate  = $_.UnlockDate
                }
            }
        )
    }

    $normalized = @()

    foreach ($item in $loaded) {
        $title = [string](Get-PropertyValue $item @('Title','Name','Achievement','title','name') 'Untitled Achievement')
        $description = [string](Get-PropertyValue $item @('Description','Details','description','details') '')
        $id = [string](Get-PropertyValue $item @('Id','ID','id') '')

        if ([string]::IsNullOrWhiteSpace($id)) {
            $id = ($title -replace '[^a-zA-Z0-9]+','_').Trim('_').ToLowerInvariant()
        }

        $unlockedValue = Get-PropertyValue $item @('Unlocked','IsUnlocked','unlocked','isUnlocked') $false
        $unlocked = $false

        if ($unlockedValue -is [bool]) {
            $unlocked = $unlockedValue
        }
        elseif ($null -ne $unlockedValue) {
            $unlocked = ([string]$unlockedValue -match '^(true|1|yes)$')
        }

        $unlockDate = Get-PropertyValue $item @('UnlockDate','DateUnlocked','unlockDate','dateUnlocked') $null
        $category = [string](Get-PropertyValue $item @('Category','category') '')

        if ($category -notin @('Story','Combat','Exploration','Collectibles','Custom')) {
            $category = Get-InferredCategory $item
        }

        $normalized += [pscustomobject]@{
            Id          = $id
            Title       = $title
            Description = $description
            Category    = $category
            Unlocked    = $unlocked
            UnlockDate  = $unlockDate
        }
    }

    foreach ($default in $DefaultAchievements) {
        $found = $false

        foreach ($item in $normalized) {
            if ($item.Id -eq $default.Id -or $item.Title -eq $default.Title) {
                $found = $true
                break
            }
        }

        if (-not $found) {
            $normalized += [pscustomobject]@{
                Id          = $default.Id
                Title       = $default.Title
                Description = $default.Description
                Category    = $default.Category
                Unlocked    = $false
                UnlockDate  = $null
            }
        }
    }

    return $normalized
}

$Achievements = @(Load-Achievements)

# Main window.
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Tolis Achievement System - Fable: The Lost Chapters'
$form.Size = New-Object System.Drawing.Size(790, 610)
$form.MinimumSize = New-Object System.Drawing.Size(790, 610)
$form.StartPosition = 'CenterScreen'
$form.BackColor = [System.Drawing.Color]::FromArgb(28, 30, 36)
$form.ForeColor = [System.Drawing.Color]::White
$form.Font = New-Object System.Drawing.Font('Segoe UI', 9)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = 'FABLE: THE LOST CHAPTERS'
$titleLabel.Location = New-Object System.Drawing.Point(20, 15)
$titleLabel.Size = New-Object System.Drawing.Size(500, 32)
$titleLabel.Font = New-Object System.Drawing.Font('Segoe UI', 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(240, 190, 85)
$form.Controls.Add($titleLabel)

$gameStatusLabel = New-Object System.Windows.Forms.Label
$gameStatusLabel.Text = '● GAME NOT RUNNING'
$gameStatusLabel.Location = New-Object System.Drawing.Point(510, 22)
$gameStatusLabel.Size = New-Object System.Drawing.Size(250, 24)
$gameStatusLabel.ForeColor = [System.Drawing.Color]::FromArgb(230, 100, 100)
$gameStatusLabel.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($gameStatusLabel)

$totalPlaytimeLabel = New-Object System.Windows.Forms.Label
$totalPlaytimeLabel.Text = 'Total Playtime: 0h 00m'
$totalPlaytimeLabel.Location = New-Object System.Drawing.Point(510, 48)
$totalPlaytimeLabel.Size = New-Object System.Drawing.Size(250, 22)
$totalPlaytimeLabel.ForeColor = [System.Drawing.Color]::FromArgb(210, 210, 220)
$form.Controls.Add($totalPlaytimeLabel)

$lastPlayedLabel = New-Object System.Windows.Forms.Label
$lastPlayedLabel.Text = 'Last Played: Never'
$lastPlayedLabel.Location = New-Object System.Drawing.Point(510, 72)
$lastPlayedLabel.Size = New-Object System.Drawing.Size(260, 35)
$lastPlayedLabel.ForeColor = [System.Drawing.Color]::FromArgb(210, 210, 220)
$form.Controls.Add($lastPlayedLabel)

$progressLabel = New-Object System.Windows.Forms.Label
$progressLabel.Location = New-Object System.Drawing.Point(22, 55)
$progressLabel.Size = New-Object System.Drawing.Size(400, 22)
$progressLabel.Text = '0 / 0 achievements unlocked (0%)'
$form.Controls.Add($progressLabel)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(22, 80)
$progressBar.Size = New-Object System.Drawing.Size(730, 18)
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$form.Controls.Add($progressBar)

$filterLabel = New-Object System.Windows.Forms.Label
$filterLabel.Text = 'Category:'
$filterLabel.Location = New-Object System.Drawing.Point(22, 112)
$filterLabel.Size = New-Object System.Drawing.Size(65, 24)
$form.Controls.Add($filterLabel)

$categoryFilter = New-Object System.Windows.Forms.ComboBox
$categoryFilter.Location = New-Object System.Drawing.Point(88, 108)
$categoryFilter.Size = New-Object System.Drawing.Size(190, 28)
$categoryFilter.DropDownStyle = 'DropDownList'
[void]$categoryFilter.Items.AddRange(
    [object[]]@('All Categories','Story','Combat','Exploration','Collectibles','Custom')
)
$categoryFilter.SelectedIndex = 0
$form.Controls.Add($categoryFilter)

$listView = New-Object System.Windows.Forms.ListView
$listView.Location = New-Object System.Drawing.Point(22, 145)
$listView.Size = New-Object System.Drawing.Size(730, 285)
$listView.View = [System.Windows.Forms.View]::Details
$listView.FullRowSelect = $true
$listView.MultiSelect = $false
$listView.HideSelection = $false
$listView.BackColor = [System.Drawing.Color]::FromArgb(39, 42, 50)
$listView.ForeColor = [System.Drawing.Color]::White
$listView.BorderStyle = 'FixedSingle'
[void]$listView.Columns.Add('Achievement', 245)
[void]$listView.Columns.Add('Category', 130)
[void]$listView.Columns.Add('Status', 125)
[void]$listView.Columns.Add('Unlocked On', 190)
$form.Controls.Add($listView)

$unlockButton = New-Object System.Windows.Forms.Button
$unlockButton.Text = 'Unlock'
$unlockButton.Location = New-Object System.Drawing.Point(22, 455)
$unlockButton.Size = New-Object System.Drawing.Size(105, 34)
$unlockButton.FlatStyle = 'Flat'
$unlockButton.BackColor = [System.Drawing.Color]::FromArgb(60, 130, 80)
$unlockButton.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($unlockButton)

$lockButton = New-Object System.Windows.Forms.Button
$lockButton.Text = 'Lock Again'
$lockButton.Location = New-Object System.Drawing.Point(135, 455)
$lockButton.Size = New-Object System.Drawing.Size(105, 34)
$lockButton.FlatStyle = 'Flat'
$lockButton.BackColor = [System.Drawing.Color]::FromArgb(130, 75, 75)
$lockButton.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($lockButton)

$addButton = New-Object System.Windows.Forms.Button
$addButton.Text = 'Add Achievement'
$addButton.Location = New-Object System.Drawing.Point(248, 455)
$addButton.Size = New-Object System.Drawing.Size(135, 34)
$addButton.FlatStyle = 'Flat'
$addButton.BackColor = [System.Drawing.Color]::FromArgb(65, 85, 130)
$addButton.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($addButton)

$detailsButton = New-Object System.Windows.Forms.Button
$detailsButton.Text = 'View Details'
$detailsButton.Location = New-Object System.Drawing.Point(391, 455)
$detailsButton.Size = New-Object System.Drawing.Size(115, 34)
$detailsButton.FlatStyle = 'Flat'
$detailsButton.BackColor = [System.Drawing.Color]::FromArgb(70, 75, 88)
$detailsButton.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($detailsButton)

$saveStatusLabel = New-Object System.Windows.Forms.Label
$saveStatusLabel.Text = 'Ready'
$saveStatusLabel.Location = New-Object System.Drawing.Point(22, 510)
$saveStatusLabel.Size = New-Object System.Drawing.Size(300, 22)
$saveStatusLabel.ForeColor = [System.Drawing.Color]::FromArgb(160, 190, 160)
$form.Controls.Add($saveStatusLabel)

function Refresh-AchievementList {
    $listView.BeginUpdate()
    try {
        $listView.Items.Clear()

        $visible = @(
            $Achievements | Where-Object {
                $categoryFilter.SelectedItem -eq 'All Categories' -or
                $_.Category -eq [string]$categoryFilter.SelectedItem
            }
        )

        foreach ($achievement in $visible) {
            $status = if ($achievement.Unlocked) { 'UNLOCKED' } else { 'LOCKED' }
            $dateText = ''

            if ($achievement.Unlocked -and $achievement.UnlockDate) {
                $dateText = [string]$achievement.UnlockDate
            }

            $row = New-Object System.Windows.Forms.ListViewItem([string]$achievement.Title)
            [void]$row.SubItems.Add([string]$achievement.Category)
            [void]$row.SubItems.Add($status)
            [void]$row.SubItems.Add($dateText)
            $row.Tag = $achievement.Id

            if ($achievement.Unlocked) {
                $row.ForeColor = [System.Drawing.Color]::FromArgb(150, 225, 160)
            }
            else {
                $row.ForeColor = [System.Drawing.Color]::FromArgb(225, 225, 230)
            }

            [void]$listView.Items.Add($row)
        }
    }
    finally {
        $listView.EndUpdate()
    }

    $total = $Achievements.Count
    $unlockedCount = @($Achievements | Where-Object { $_.Unlocked }).Count
    $percent = if ($total -gt 0) {
        [int][math]::Round(($unlockedCount / $total) * 100)
    }
    else {
        0
    }

    $progressLabel.Text = "$unlockedCount / $total achievements unlocked ($percent%)"
    $progressBar.Value = [math]::Max(0, [math]::Min(100, $percent))
}

function Get-SelectedAchievement {
    if ($listView.SelectedItems.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            'Select an achievement from the list first.',
            'No Achievement Selected',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        return $null
    }

    $id = [string]$listView.SelectedItems[0].Tag
    foreach ($achievement in $Achievements) {
        if ($achievement.Id -eq $id) { return $achievement }
    }

    return $null
}

$unlockButton.Add_Click({
    $achievement = Get-SelectedAchievement
    if ($null -eq $achievement) { return }

    if (-not $achievement.Unlocked) {
        $achievement.Unlocked = $true
        $achievement.UnlockDate = Get-Date -Format 'yyyy-MM-dd HH:mm'
        Save-Achievements
        Refresh-AchievementList

        [System.Windows.Forms.MessageBox]::Show(
            "Achievement Unlocked!`r`n`r`n$($achievement.Title)`r`n$($achievement.Description)",
            'Achievement Unlocked',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
    }
})

$lockButton.Add_Click({
    $achievement = Get-SelectedAchievement
    if ($null -eq $achievement) { return }

    $achievement.Unlocked = $false
    $achievement.UnlockDate = $null
    Save-Achievements
    Refresh-AchievementList
})

$detailsButton.Add_Click({
    $achievement = Get-SelectedAchievement
    if ($null -eq $achievement) { return }

    $status = if ($achievement.Unlocked) {
        "Unlocked on: $($achievement.UnlockDate)"
    }
    else {
        'Status: Locked'
    }

    [System.Windows.Forms.MessageBox]::Show(
        "Achievement: $($achievement.Title)`r`nCategory: $($achievement.Category)`r`n`r`n$($achievement.Description)`r`n`r`n$status",
        'Achievement Details',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
})

$addButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = 'Add Achievement'
    $dialog.Size = New-Object System.Drawing.Size(430, 330)
    $dialog.StartPosition = 'CenterParent'
    $dialog.FormBorderStyle = 'FixedDialog'
    $dialog.MaximizeBox = $false
    $dialog.MinimizeBox = $false
    $dialog.BackColor = [System.Drawing.Color]::FromArgb(28, 30, 36)
    $dialog.ForeColor = [System.Drawing.Color]::White
    $dialog.Font = New-Object System.Drawing.Font('Segoe UI', 9)

    $nameLabel = New-Object System.Windows.Forms.Label
    $nameLabel.Text = 'Achievement name:'
    $nameLabel.Location = New-Object System.Drawing.Point(18, 18)
    $nameLabel.Size = New-Object System.Drawing.Size(150, 22)
    $dialog.Controls.Add($nameLabel)

    $nameBox = New-Object System.Windows.Forms.TextBox
    $nameBox.Location = New-Object System.Drawing.Point(18, 42)
    $nameBox.Size = New-Object System.Drawing.Size(375, 25)
    $dialog.Controls.Add($nameBox)

    $descLabel = New-Object System.Windows.Forms.Label
    $descLabel.Text = 'Description:'
    $descLabel.Location = New-Object System.Drawing.Point(18, 78)
    $descLabel.Size = New-Object System.Drawing.Size(150, 22)
    $dialog.Controls.Add($descLabel)

    $descBox = New-Object System.Windows.Forms.TextBox
    $descBox.Location = New-Object System.Drawing.Point(18, 102)
    $descBox.Size = New-Object System.Drawing.Size(375, 52)
    $descBox.Multiline = $true
    $dialog.Controls.Add($descBox)

    $catLabel = New-Object System.Windows.Forms.Label
    $catLabel.Text = 'Category:'
    $catLabel.Location = New-Object System.Drawing.Point(18, 166)
    $catLabel.Size = New-Object System.Drawing.Size(100, 22)
    $dialog.Controls.Add($catLabel)

    $catBox = New-Object System.Windows.Forms.ComboBox
    $catBox.Location = New-Object System.Drawing.Point(18, 190)
    $catBox.Size = New-Object System.Drawing.Size(220, 26)
    $catBox.DropDownStyle = 'DropDownList'
    [void]$catBox.Items.AddRange(
        [object[]]@('Story','Combat','Exploration','Collectibles','Custom')
    )
    $catBox.SelectedItem = 'Custom'
    $dialog.Controls.Add($catBox)

    $cancel = New-Object System.Windows.Forms.Button
    $cancel.Text = 'Cancel'
    $cancel.Location = New-Object System.Drawing.Point(205, 240)
    $cancel.Size = New-Object System.Drawing.Size(88, 32)
    $cancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $dialog.Controls.Add($cancel)

    $create = New-Object System.Windows.Forms.Button
    $create.Text = 'Create'
    $create.Location = New-Object System.Drawing.Point(305, 240)
    $create.Size = New-Object System.Drawing.Size(88, 32)
    $dialog.Controls.Add($create)

    $dialog.AcceptButton = $create
    $dialog.CancelButton = $cancel

    $create.Add_Click({
        $newTitle = $nameBox.Text.Trim()
        $newDescription = $descBox.Text.Trim()

        if ([string]::IsNullOrWhiteSpace($newTitle)) {
            [System.Windows.Forms.MessageBox]::Show(
                'Enter an achievement name.',
                'Missing Name'
            ) | Out-Null
            return
        }

        foreach ($existing in $Achievements) {
            if ($existing.Title -ieq $newTitle) {
                [System.Windows.Forms.MessageBox]::Show(
                    'An achievement with this name already exists.',
                    'Duplicate Achievement'
                ) | Out-Null
                return
            }
        }

        $newId = ($newTitle -replace '[^a-zA-Z0-9]+','_').Trim('_').ToLowerInvariant()
        if ([string]::IsNullOrWhiteSpace($newId)) {
            $newId = 'custom_' + [guid]::NewGuid().ToString('N').Substring(0,8)
        }

        $idExists = @($Achievements | Where-Object { $_.Id -eq $newId }).Count -gt 0
        if ($idExists) {
            $newId += '_' + [guid]::NewGuid().ToString('N').Substring(0,6)
        }

        $script:Achievements += [pscustomobject]@{
            Id          = $newId
            Title       = $newTitle
            Description = $newDescription
            Category    = [string]$catBox.SelectedItem
            Unlocked    = $false
            UnlockDate  = $null
        }

        Save-Achievements
        Refresh-AchievementList
        $dialog.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $dialog.Close()
    })

    [void]$dialog.ShowDialog($form)
})

$categoryFilter.Add_SelectedIndexChanged({
    Refresh-AchievementList
})

# Game detection and playtime tracking.
$gameTimer = New-Object System.Windows.Forms.Timer
$gameTimer.Interval = 2000

$gameTimer.Add_Tick({
    try {
        $process = Get-Process -Name $GameProcessName -ErrorAction SilentlyContinue |
            Select-Object -First 1
        $isRunning = ($null -ne $process)
    }
    catch {
        $isRunning = $false
    }

    if ($isRunning) {
        $gameStatusLabel.Text = '● GAME RUNNING'
        $gameStatusLabel.ForeColor = [System.Drawing.Color]::FromArgb(100, 220, 130)

        if ($null -eq $script:GameSessionStart) {
            $script:GameSessionStart = Get-Date
            $script:LastPlayed = $script:GameSessionStart.ToString('o')
            Save-Playtime
        }

        if (((Get-Date) - $script:LastPlaytimeSave).TotalSeconds -ge 60) {
            Save-Playtime
        }
    }
    else {
        $gameStatusLabel.Text = '● GAME NOT RUNNING'
        $gameStatusLabel.ForeColor = [System.Drawing.Color]::FromArgb(230, 100, 100)

        if ($null -ne $script:GameSessionStart) {
            $elapsed = (Get-Date) - $script:GameSessionStart
            $script:TotalPlaySeconds += [long][math]::Floor($elapsed.TotalSeconds)
            $script:GameSessionStart = $null
            Save-Playtime
        }
    }

    Refresh-PlaytimeDisplay
})

# Start the timer only once.
$gameTimer.Start()
Refresh-PlaytimeDisplay

# Save final playtime and achievement progress when the window closes.
$form.Add_FormClosing({
    $gameTimer.Stop()

    if ($null -ne $script:GameSessionStart) {
        $elapsed = (Get-Date) - $script:GameSessionStart
        $script:TotalPlaySeconds += [long][math]::Floor($elapsed.TotalSeconds)
        $script:GameSessionStart = $null
    }

    Save-Playtime
    Save-Achievements
})

Refresh-AchievementList
[void]$form.ShowDialog()
