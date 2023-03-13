Function New-SSLCertificateCA {
    param (
		[parameter(Mandatory=$true, Position=0)][string]$Name,
		[parameter(Mandatory=$true, Position=1)][string]$FriendlyName,
		[parameter(Mandatory=$true, Position=2)][string]$Company,
		[parameter(Mandatory=$true, Position=3)][string]$DnsName,
		[parameter(Mandatory=$true, Position=4)][string]$CN,
		[parameter(Mandatory=$true, Position=5)][string]$OU,
		[parameter(Mandatory=$true, Position=6)][string]$L,
		[parameter(Mandatory=$true, Position=7)][string]$S,
		[parameter(Mandatory=$true, Position=8)][string]$C,
		[parameter(Mandatory=$true, Position=9)][string]$Password,
		[parameter(Mandatory=$true, Position=10)][int]$NotAfterYears
	)
    Write-Host "New SSL Certificate Started"
    $paramsCA = @{
        FriendlyName = $FriendlyName
        Subject = "CN=$($CN),O=$($Company),OU=$($OU),L=$($L),S=$($S),C=$($C)"
        KeyLength = 4096
        HashAlgorithm = 'SHA256'
        KeyExportPolicy = 'Exportable'
        CertStoreLocation = 'Cert:\LocalMachine\My'
        KeyUsage = 'CertSign','CRLSign', 'KeyEncipherment', 'DataEncipherment' #fixes invalid cert error
        TextExtension = @("2.5.29.19 ={critical}{text}CA=1&pathlength=3")
        NotAfter = (Get-Date).AddYears($NotAfterYears)
    }
    $rootCA = New-SelfSignedCertificate @paramsCA
    Write-Host "ƒобавление корневого сертификата удостовер€ющего центра в хранилище текущего клиента"
    Export-Certificate -Cert $rootCA -FilePath ".\certs\ca\rootCA.crt" | Out-Null
    Import-Certificate -CertStoreLocation 'Cert:\LocalMachine\Root' -FilePath ".\certs\ca\rootCA.crt" | Out-Null

    Write-Host "Ёкспорт сертификатов в файл pfx дл€ дальнейшего использовани€"
    Export-PfxCertificate -Cert $rootCA -FilePath ".\certs\ca\ca.pfx" -Password (ConvertTo-SecureString -AsPlainText $Password -Force) | Out-Null

    openssl pkcs12 -in ".\certs\ca\ca.pfx" -clcerts -nokeys -out ".\certs\ca\ca.crt" -passin pass:$($Password)
    openssl pkcs12 -in ".\certs\ca\ca.pfx" -nocerts -nodes -out ".\certs\ca\ca.key" -passin pass:$($Password)
}


Function New-SSLIntermidiate {
    param (
		[parameter(Mandatory=$true, Position=0)][string]$Name,
		[parameter(Mandatory=$true, Position=1)][string]$FriendlyName,
		[parameter(Mandatory=$true, Position=2)][string]$Company,
		[parameter(Mandatory=$true, Position=3)][string]$DnsName,
		[parameter(Mandatory=$true, Position=4)][string]$CN,
		[parameter(Mandatory=$true, Position=5)][string]$OU,
		[parameter(Mandatory=$true, Position=6)][string]$L,
		[parameter(Mandatory=$true, Position=7)][string]$S,
		[parameter(Mandatory=$true, Position=8)][string]$C,
		[parameter(Mandatory=$true, Position=9)][string]$Password,
		[parameter(Mandatory=$true, Position=10)][int]$NotAfterYears,
		[parameter(Mandatory=$true, Position=11)][string]$SignerSubject

	)
    Write-Host "New SSL Intermediate Certificate Started"
    $Signer = Get-ChildItem Cert:\LocalMachine\My | where Subject -eq $SignerSubject

    $params = @{
        Subject = "CN=$($CN),O=$($Company),OU=$($OU),L=$($L),S=$($S),C=$($C)"
        FriendlyName = $FriendlyName
        Signer = $Signer[0]
        KeyLength = 4096
        HashAlgorithm = 'SHA256'
        KeyExportPolicy = 'Exportable'
        CertStoreLocation = 'Cert:\LocalMachine\My'
        KeyUsage = 'KeyEncipherment', 'DataEncipherment', 'CertSign'
        KeyUsageProperty = 'Sign'
        TextExtension = @("2.5.29.19 ={critical}{text}CA=1&pathlength=0")
        NotAfter = (Get-date).AddYears($NotAfterYears)
    }
    $intermediateCert = New-SelfSignedCertificate @params

    Write-Host "Ёкспорт сертификата дочернего удостовер€ющего центра"
    Export-Certificate -Cert $intermediateCert -FilePath ".\certs\intermediate\$($name)Cert.crt" | Out-Null
    Import-Certificate -CertStoreLocation 'Cert:\LocalMachine\Root' -FilePath ".\certs\intermediate\$($name)Cert.crt" | Out-Null

    Write-Host "Ёкспорт сертификатов в файл pfx дл€ дальнейшего использовани€"
    Export-PfxCertificate -Cert $intermediateCert -FilePath ".\certs\intermediate\$($name).pfx" -Password (ConvertTo-SecureString -AsPlainText $Password -Force) | Out-Null

    openssl pkcs12 -in ".\certs/intermediate/$($name).pfx" -clcerts -nokeys -out ".\certs/intermediate/$($name).crt"  -passin pass:$($Password)
    openssl pkcs12 -in ".\certs/intermediate/$($name).pfx" -nocerts -nodes  -out ".\certs/intermediate/$($name).key"  -passin pass:$($Password)

}




Function New-SSLDomain {
    param (
		[parameter(Mandatory=$true, Position=0)][string]$Name,
		[parameter(Mandatory=$true, Position=1)][string]$Subject,
		[parameter(Mandatory=$true, Position=2)][string]$Company,
		[parameter(Mandatory=$true, Position=3)][string]$DnsName,
		[parameter(Mandatory=$true, Position=4)][string]$CN,
		[parameter(Mandatory=$true, Position=5)][string]$OU,
		[parameter(Mandatory=$true, Position=6)][string]$L,
		[parameter(Mandatory=$true, Position=7)][string]$S,
		[parameter(Mandatory=$true, Position=8)][string]$C,
		[parameter(Mandatory=$true, Position=9)][string]$Password,
		[parameter(Mandatory=$true, Position=10)][int]$NotAfterYears,
		[parameter(Mandatory=$true, Position=11)][string]$SignerSubject,
		[parameter(Mandatory=$true, Position=12)][string]$IntermediateCert,


	)
    Write-Host "New SSL Intermediate Certificate Started"
    $Signer = Get-ChildItem Cert:\LocalMachine\My | where Subject -eq $SignerSubject

    $params = @{
        Subject = "CN=$($CN),O=$($Company),OU=$($OU),L=$($L),S=$($S),C=$($C)"
        FriendlyName = $FriendlyName
        Signer = $Signer[0]
        KeyLength = 4096
        HashAlgorithm = 'SHA256'
        KeyExportPolicy = 'Exportable'
        CertStoreLocation = 'Cert:\LocalMachine\My'
        KeyUsage = 'KeyEncipherment', 'DataEncipherment', 'CertSign'
        KeyUsageProperty = 'Sign'
        TextExtension = @("2.5.29.19 ={critical}{text}CA=1&pathlength=0")
        NotAfter = (Get-date).AddYears($NotAfterYears)
    }
    $intermediateCert = New-SelfSignedCertificate @params

    Write-Host "Ёкспорт сертификата дочернего удостовер€ющего центра"
    Export-Certificate -Cert $intermediateCert -FilePath ".\certs\intermediate\$($name)Cert.crt" | Out-Null
    Import-Certificate -CertStoreLocation 'Cert:\LocalMachine\Root' -FilePath ".\certs\intermediate\$($name)Cert.crt" | Out-Null

    Write-Host "Ёкспорт сертификатов в файл pfx дл€ дальнейшего использовани€"
    Export-PfxCertificate -Cert $intermediateCert -FilePath ".\certs\intermediate\$($name).pfx" -Password (ConvertTo-SecureString -AsPlainText $Password -Force) | Out-Null

    openssl pkcs12 -in ".\certs/intermediate/$($name).pfx" -clcerts -nokeys -out ".\certs/intermediate/$($name).crt"  -passin pass:$($Password)
    openssl pkcs12 -in ".\certs/intermediate/$($name).pfx" -nocerts -nodes  -out ".\certs/intermediate/$($name).key"  -passin pass:$($Password)

}