$adServers = @("exemple.com", "example2.com", "example3.com")

function Find-ADGroupAcrossServers {
    param([string]$groupName)
    
    foreach ($server in $adServers) {
        try {
            $group = Get-ADGroup -Identity $groupName -Server $server -Properties DistinguishedName -ErrorAction Stop
            return $group, $server
        }
        catch {
            continue
        }
    }
    throw "Группа $groupName не найдена ни на одном из серверов"
}

function Find-ADUserAcrossServers {
    param([string]$login)
    
    foreach ($server in $adServers) {
        try {
            $user = Get-ADUser -Identity $login -Server $server -Properties DistinguishedName -ErrorAction Stop
            return $user, $server
        }
        catch {
            continue
        }
    }
    throw "Пользователь $login не найден ни на одном из серверов"
}

while($true)
{
    Write-Host
    Write-Host "Menu" -BackgroundColor White -ForegroundColor Red
    Write-Host

    Write-Host "1. Добавить пользователя в группу AD" -ForegroundColor Green
    Write-Host "2. Удалить пользователя из группы AD" -ForegroundColor Green
    Write-Host "3. Вывести список участников группы AD" -ForegroundColor Green
    Write-Host "4. Выход" -ForegroundColor Green
    Write-Host
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $choice = Read-Host "Введите номер пункта меню"

    if ($choice -in 1,2) {
        $group = Read-Host "Введите имя группы"
        #$server_group = Read-Host "Введите сервер группы"
        $login = Read-Host "Введите логин пользователя"
        #$server_user = Read-Host "Введите сервер пользователя"
        try {
            $userObj, $server_user = Find-ADUserAcrossServers -login $login
            $groupObj, $server_group = Find-ADGroupAcrossServers -group $group
            $user = Get-ADUser -Identity $userObj.DistinguishedName -Server $server_user

            Write-Host "Cервер группы: $server_group" -ForegroundColor Green
            Write-Host "Cервер пользователя: $server_user" -ForegroundColor Green

            if (-not $server_group) {
                Write-Host "Не удалось определить сервер для группы" -ForegroundColor Red
                continue
            }
            if (-not $server_user) {
                Write-Host "Не удалось определить сервер для пользователя" -ForegroundColor Red
                continue
            }
        }
        catch {
            Write-Host "Объект не найден: $_" -ForegroundColor Red
            continue
        }
        if ([string]::IsNullOrWhiteSpace($group) -or [string]::IsNullOrWhiteSpace($login)) {
            Write-Host "Имя группы и логин обязательны." -ForegroundColor Red
            continue
        }
    }

    Switch($choice){
      1{
        try {
            Write-Host "Подождите, скрипт выполняется" -ForegroundColor Green
            Add-ADGroupMember -Identity $group -Server $server_group -Members $user -Confirm:$false
            Write-Host "Пользователь $login добавлен в группу $group" -ForegroundColor Green
        }
        catch {
                Write-Host "Ошибка: $_" -ForegroundColor Red
        }
      }
      2{
        try {
            Write-Host "Подождите, скрипт выполняется" -ForegroundColor Green
            Remove-ADGroupMember -Identity $group -Server $server_group -Members $user -Confirm:$false
            Write-Host "Пользователь $login удален из группы $group." -ForegroundColor Green
        }
        catch {
                Write-Host "Ошибка: $_" -ForegroundColor Red
        }
      }
      3{
        $group = Read-Host "Введите имя группы"
        try {
            $groupObj, $server_group = Find-ADGroupAcrossServers -groupName $group
            Write-Host "Подождите, скрипт выполняется" -ForegroundColor Green
            $members = Get-ADGroupMember -Identity $group -Recursive -Server $server_group
            $members.SamAccountName | Out-File -FilePath "$env:USERPROFILE\Desktop\$group-$timestamp.txt"
            Write-Host "Список участников сохранён в $group-$timestamp.txt на рабочем столе" -ForegroundColor Green
        }
        catch {
            Write-Host "Группа не найдена или нет доступа" -ForegroundColor Red
        }
      }
      4{Write-Host "Выход"; exit}
      default {Write-Host "Нет такого пункта, попробуйте снова" -ForegroundColor Red}
    }
}
