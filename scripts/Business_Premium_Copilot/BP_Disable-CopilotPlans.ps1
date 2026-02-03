# Paramètres : User Principal Name (UPN) de l'utilisateur et SkuId de la licence
param (
    [Parameter(Mandatory=$true)]
    [string]$UserPrincipalName,
    
    [string]$SkuId = "a6d18b68-a67e-4cbd-ba00-8744bc468faa"  # BUSINESS_PREMIUM_AND_MICROSOFT_365_COPILOT_FOR_BUSINESS
)

# Liste des GUIDs des plans à désactiver
$toDisable = @(
    "89f1c4c8-0878-40f7-804d-869c9128ab5d",  # M365_COPILOT_CONNECTORS
    "3f30311c-6b1e-48a4-ab79-725b469da960", # M365_COPILOT_BUSINESS_CHAT
    "a62f8878-de10-42f3-b68f-6149a25ceb97",  # M365_COPILOT_APPS
    "b95945de-b3bd-46db-8437-f2beb6ea2347", # M365_COPILOT_TEAMS
    "0aedf20c-091d-420b-aadf-30c042609612", # M365_COPILOT_SHAREPOINT
    "931e4a88-a67f-48b5-814f-16a5f1e6028d", # M365_COPILOT_INTELLIGENT_SEARCH
    "82d30987-df9b-4486-b146-198b21d164c7",  # GRAPH_CONNECTORS_COPILOT
    "fe6c28b3-d468-44ea-bbd0-a10a5167435c"   # COPILOT_STUDIO_IN_COPILOT_FOR_M365
)

# Récupérer les détails de la licence pour cet utilisateur et ce SkuId
$license = Get-MgUserLicenseDetail -UserId $UserPrincipalName | Where-Object { $_.SkuId -eq $SkuId }

if (-not $license) {
    Write-Host "L'utilisateur $UserPrincipalName n'a pas la licence $SkuId assignée."
} else {
    # Récupérer les plans actuellement désactivés (statut "Disabled")
    $currentDisabled = @()
    foreach ($plan in $license.ServicePlans) {
        if ($plan.ProvisioningStatus -eq "Disabled") {
            $currentDisabled += $plan.ServicePlanId
        }
    }

    # Ajouter les nouveaux plans à désactiver et dédupliquer
    $disabledPlans = ($currentDisabled + $toDisable) | Select-Object -Unique

    # Préparer les paramètres pour la mise à jour
    $params = @{
        AddLicenses = @(
            @{
                SkuId = $SkuId
                DisabledPlans = $disabledPlans
            }
        )
        RemoveLicenses = @()
    }

    # Mettre à jour la licence
    Set-MgUserLicense -UserId $UserPrincipalName -BodyParameter $params
    Write-Host "Les plans spécifiés ont été désactivés pour l'utilisateur $UserPrincipalName sur la licence $SkuId."
}
