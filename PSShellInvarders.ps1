$ErrorActionPreference = 'Stop'
$RawUI = $Host.UI.RawUI
$RawUI.BufferSize = [System.Management.Automation.Host.Size]::new(120, 30)
$RawUI.WindowSize = [System.Management.Automation.Host.Size]::new(120, 30)

$PlayerGraphics = New-Object -TypeName 'char[,]' 3, 2
$PlayerGraphics[0, 0] = ' '
$PlayerGraphics[0, 1] = '█'
$PlayerGraphics[1, 0] = '▲'
$PlayerGraphics[1, 1] = '█'
$PlayerGraphics[2, 0] = ' '
$PlayerGraphics[2, 1] = '█'

$script:KeyCodes = @{
    "Left"  = 37
    "Up"    = 38
    "Right" = 39
    "Down"  = 40
}

class GameObject {
    [float]$X
    [float]$Y
    [int]$Width
    [int]$Height
    [int]$Speed
    [char[, ]]$Graphics
    [bool]$IsActive


    GameObject([int]$x, [int]$y, [int]$speed, [char[, ]]$graphics, [bool]$isActive) {
        $this.X = [float]$x
        $this.Y = [float]$y
        $this.Speed = $speed
        $this.Graphics = $graphics
        $this.Width = $graphics.GetLength(0)
        $this.Height = $graphics.GetLength(1)
        $this.IsActive = $isActive
       
    }

    GameObject([int]$x, [int]$y, [int]$speed, [char[, ]]$graphics) {
        $this.X = [float]$x
        $this.Y = [float]$y
        $this.Speed = $speed
        $this.Graphics = $graphics
        $this.Width = $graphics.GetLength(0)
        $this.Height = $graphics.GetLength(1)
        $this.IsActive = $true
    }

    GameObject([int]$x, [int]$y, [int]$speed) {
        $this.X = [float]$x
        $this.Y = [float]$y
        $this.Speed = $speed
        $this.IsActive = $true
    }

    GameObject([int]$x, [int]$y) {
        $this.X = [float]$x
        $this.Y = [float]$y
        $this.IsActive = $true
    }

    [void]SetX([int]$x) {
        $this.X = $x
    }

    [void]SetY([int]$y) {
        $this.Y = $y
    }

    [int]GetX() {
        return $this.X
    }

    [int]GetY() {
        return $this.Y
    }


    [void]MoveLeft([float]$DeltaTime) {
        $this.X -= $this.Speed
    }

    [void]MoveUp([float]$DeltaTime) {
        $this.Y -= $this.Speed
    }

    [void]MoveRight([float]$DeltaTime) {
        $this.X += $this.Speed
    }

    [void]MoveDown([float]$DeltaTime) {
        $this.Y += $this.Speed
    }

    [char[, ]]getGraphics() {
        return $this.Graphics
    }

    [void]Update([float]$DeltaTime, [Scene]$Scene) {
        return
    }

    [void]Collide([GameObject]$GameObject) {
        return
    }
}

class Rocket : GameObject {
    [bool]$InFlight

    Rocket([int]$x, [int]$y) : base($x, $y) {
        $this.X = [float]$x
        $this.Y = [float]$y
        $this.Speed = 1

        $Graphics = New-Object -TypeName 'char[,]' 1, 1
        $Graphics[0, 0] = '|'
        $this.Width = 1
        $this.Height = 1

        $this.Graphics = $Graphics
        $this.InFlight = $false
        $this.IsActive = $false
    }

    [void]Update([float]$DeltaTime, [Scene]$Scene) {
        if ($this.InFlight) {
            $this.MoveUp($DeltaTime)
            $CollidingGameObjects = $Scene.CheckProjectileCollision($this, $this.GetX(), $this.GetY())
            if ($CollidingGameObjects) {
                $this.IsActive = $false
                $this.InFlight = $false
                foreach ($GameObject in $CollidingGameObjects) {
                    $GameObject.Collide($this)
                }
            }
        }

        if ($this.Y -le 0) {
            $this.InFlight = $false
            $this.IsActive = $false
            $this.X = [float]0
            $this.Y = [float]0
        }
    }

    [void]Launch([int]$x, [int]$y) {
        $this.InFlight = $true
        $this.IsActive = $true
        $this.X = [float]$x
        $this.Y = [float]$y
    }
}

class Player : GameObject {
    [Rocket]$Rocket

    Player([int]$x, [int]$y, [int]$speed, [char[, ]]$graphics, [Rocket]$rocket) : base($x, $y, $speed, $graphics) {
        $this.X = [float]$x
        $this.Y = [float]$y
        $this.Speed = $speed
        $this.Graphics = $graphics
        $this.Rocket = $rocket
    }

    [void]ShootRocket() {
        if (-not $this.Rocket.InFlight) {
            $this.Rocket.Launch($this.X + 1, $this.Y - 1)
        }
        
    }
}

class SmallInvader : GameObject {
    [int]$Direction #+1 = Right, -1 = Left
    [HiveMind]$HiveMind

    SmallInvader([int]$x, [int]$y, [int]$speed, [int]$direction, [HiveMind]$hiveMind) : base($x, $y, $speed) {
        $this.X = [float]$x
        $this.Y = [float]$y
        $this.Speed = $speed
        $this.Direction = $direction
        $this.HiveMind = $hiveMind

        $Graphics = New-Object -TypeName 'char[,]' 2, 2
        $Graphics[0, 0] = '■'
        $Graphics[0, 1] = '╝'
        $Graphics[1, 0] = '■'
        $Graphics[1, 1] = '╚'

        $this.Width = 2
        $this.Height = 2


        $this.Graphics = $graphics
    }

    [void]MoveHorizontal([float]$DeltaTime, [Scene]$Scene) {
        if ($this.IsActive) {
            $NewX = $this.X + ($this.Speed * $this.Direction * $DeltaTime)

            if ($NewX + $this.Graphics.getLength(0) -ge $Scene.Width) {
                $this.HiveMind.SignalWall()
            }
            elseif ($NewX -le 0) {
                $this.HiveMind.SignalWall()
            }
            else {
                $this.X = $NewX
            }
        }
    }

    [void]MoveDown([float]$DeltaTime, [Scene]$Scene) {
        if ($this.Y + 1 -ge $Scene.Height - 3) {
            $Scene.GameOver()
        }
        else {
            $this.Y += 1
            $this.Direction *= -1
        }
        
    }

    [void]Update([float]$DeltaTime, [Scene]$Scene) {
        $this.MoveHorizontal($DeltaTime, $Scene)
    }

    [void]Collide([GameObject]$GameObject) {
        if ($GameObject.GetType() -eq [Rocket]) {
            # Explode
            $this.IsActive = $false
        }
    }
}

class HiveMind {
    [Scene]$Scene
    [System.Collections.ArrayList]$Invaders
    [int]$Columns
    [int]$Rows
    [int]$XDistance
    [int]$YDistance
    [bool]$MoveDownPending

    HiveMind([Scene]$scene) {
        $this.Scene = $scene
        $this.Columns = 12
        $this.Rows = 5
        $this.XDistance = 8
        $this.YDistance = 3
        $this.MoveDownPending = $false
        
        $this.Invaders = New-Object System.Collections.ArrayList
    }

    [void]PrepareInvasion() {
        for ($y = 0; $y -lt $this.Rows; $y += 1) {
            for ($x = 0; $x -lt $this.Columns; $x += 1) {
                $InvaderX = $x * $this.XDistance
                $InvaderY = $y * $this.YDistance

                $Invader = [SmallInvader]::new($InvaderX, $InvaderY, 2, 1, $this)
                $Null = $this.Invaders.Add($Invader)
                $Null = $this.Scene.NonPlayerObjects.Add($Invader)
            }
        }
    }

    [void]SignalWall() {
        $this.MoveDownPending = $true
    }

    [void]Advance([float]$DeltaTime, [Scene]$Scene) {
        if ($this.MoveDownPending) {
            foreach ($Invader in $this.Invaders) {
                $Invader.MoveDown($DeltaTime, $Scene)
            }
            $this.MoveDownPending = $false
        }
        
    }
}

class Scene {
    [Player]$Player
    [int]$Width
    [int]$Height
    [System.Management.Automation.Host.PSHostRawUserInterface]$RawUI
    [object[, ]]$World
    [System.Collections.ArrayList]$NonPlayerObjects
    [bool]$IsRunning


    Scene([Player]$player, [System.Management.Automation.Host.PSHostRawUserInterface]$rawUI) {
        $this.Player = $player
        $this.Width = $rawUI.BufferSize.Width
        $this.Height = $rawUI.BufferSize.Height
        $this.RawUI = $rawUI
        $this.World = New-Object 'object[,]' $rawUI.BufferSize.Width, $rawUI.BufferSize.Height
        $this.NonPlayerObjects = New-Object System.Collections.ArrayList
        $this.InitializeWorld()
        $this.IsRunning = $true
    }

    [void]InitializeWorld() {
        $this.Player.SetY($this.Height - 2)
        $this.Player.SetX($this.Width / 2)

        for ($x = 0; $x -lt $this.Width; $x++) {
            for ($y = 0; $y -lt $this.Height; $y++) {
                $this.World[$x, $y] = ' '
            }
        }
    }

    [System.Management.Automation.Host.BufferCell[, ]]GetBuffer() {
        $BackgroundBuffer = New-Object 'System.Management.Automation.Host.BufferCell[,]' $this.Height, $this.Width
        $ForegroundColor = $this.RawUI.BackgroundColor
        $BackgroundColor = $this.RawUI.BackgroundColor
        $BufferCellType = [System.Management.Automation.Host.BufferCellType]::Complete

        $PlayerGraphics = $this.Player.getGraphics()
        $PlayerHeight = $PlayerGraphics.GetLength(1)
        $PlayerWidth = $PlayerGraphics.GetLength(0)

        $PlayerColor = [System.ConsoleColor]::Gray

        
        # Draw background
        for ($x = 0; $x -lt $this.Width; $x++) {
            for ($y = 0; $y -lt $this.Height; $y++) {
                $BackgroundBuffer[$y, $x] = New-Object 'System.Management.Automation.Host.BufferCell' ($this.World[$x, $y], $ForegroundColor, $BackgroundColor, $BufferCellType)
            }
        }


        # Draw player
        for ($x = 0; $x -lt $PlayerWidth; $x++) {
            for ($y = 0; $y -lt $PlayerHeight; $y++) {
                $AbsX = $this.Player.GetX() + $x
                $AbsY = $this.Player.GetY() + $y
                $BackgroundBuffer[$AbsY, $AbsX] = New-Object 'System.Management.Automation.Host.BufferCell' ($PlayerGraphics[$x, $y], $PlayerColor, $BackgroundColor, $BufferCellType)
            }
        }

        foreach ($GameObject in $this.NonPlayerObjects) {
            if ($GameObject.IsActive) {
                for ($x = 0; $x -lt $GameObject.Graphics.GetLength(0); $x++) {
                    for ($y = 0; $y -lt $GameObject.Graphics.GetLength(1); $y++) {
                        $AbsX = $GameObject.GetX() + $x
                        $AbsY = $GameObject.GetY() + $y
                        $BackgroundBuffer[$AbsY, $AbsX] = New-Object 'System.Management.Automation.Host.BufferCell' ($GameObject.getGraphics()[$x, $y], $PlayerColor, $BackgroundColor, $BufferCellType)
                    }
                }
            }
        }
        
        return $BackgroundBuffer
    }

    [void]Update([float]$DeltaTime, [Scene]$Scene) {
        foreach ($GameObject in $this.NonPlayerObjects) {
            $GameObject.Update($DeltaTime, $Scene)
        }

        # Handle input
        if ($this.RawUI.KeyAvailable) {
            $key = $this.RawUI.ReadKey("NoEcho,IncludeKeyUp,IncludeKeyDown")
    
            # Left
            if ($key.VirtualKeyCode -eq $script:KeyCodes["Left"] -and $key.KeyDown) {
                $this.Player.MoveLeft($DeltaTime)
            }

            # Right
            if ($key.VirtualKeyCode -eq $script:KeyCodes["Right"] -and $key.KeyDown) {
                $this.Player.MoveRight($DeltaTime)
            }

            # Up (Shoot)
            if ($key.VirtualKeyCode -eq $script:KeyCodes["Up"] -and $key.KeyDown) {
                $this.Player.ShootRocket()
            }
    
            # ESCape key
            if ($key.VirtualKeyCode -eq 27 ) { 
                Write-Host "Game ended by User"
                $this.IsRunning = $false
            }
        }
    }

    [GameObject[]]CheckProjectileCollision([GameObject]$Self, [int]$X, [int]$Y) {
        # Thankfully the projectiles are just 1 wide and 1 high, so we can factor out width and height
        $CollidingGameObjects = $this.NonPlayerObjects.Where({ 
            ($_.GetX() -le $X -and ($_.GetX() + $_.Width) -ge $X) -and 
            ($_.GetY() -le $Y -and ($_.GetY() + $_.Height) -ge $Y) -and
                $_.IsActive -and
                $_ -ne $Self
            })
        return $CollidingGameObjects
    }

    [void]GameOver() {
        [System.Console]::Beep(2000, 2000)
        Write-Host "Game Over"
        $this.IsRunning = $false
    }

}





$Rocket = [Rocket]::new(0, 0)
$Player = [Player]::new(5, 5, 1, $PlayerGraphics, $Rocket)
$Scene = [Scene]::new($Player, $RawUI)

$HiveMind = [HiveMind]::new($Scene)
$Scene.NonPlayerObjects.Add($Rocket)

$HiveMind.PrepareInvasion()








$Timer = [System.Diagnostics.Stopwatch]::StartNew()
$LastTimestamp = $Timer.ElapsedMilliseconds

#Clear-Host

while ( $Scene.IsRunning ) {
    $NewTimeStamp = $Timer.ElapsedMilliseconds
    $DeltaTime = ($NewTimeStamp - $LastTimestamp) / 1000
    $LastTimestamp = $NewTimeStamp


    
    $Scene.Update($DeltaTime, $Scene)
    $HiveMind.Advance($DeltaTime, $Scene)
    $SceneBuffer = $Scene.GetBuffer()
    $RawUI.SetBufferContents( @{X = 0; Y = 0 }, $SceneBuffer)
   
}