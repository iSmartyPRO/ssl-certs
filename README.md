## Load script
```
. .\index.ps1
```

## Create Self Signed CA Certificate 

```
$paramsCA = @{
    Name = "iSmarty"
    FriendlyName = "iSmarty Certificate Authority"
    Company = "iSmarty Pro"
    DnsName = "iSmarty Certificate Authority"
    CN = "iSmarty Certificate Authority"
    OU = "IT"
    L = "Global"
    S = "Msk"
    C = "RU"
    Password = "Sup3rPassword"
    NotAfterYears = 20

}

New-SSLCertificateCA @paramsCA

```


## Create Intermediate Certificate 

You have to get certificate subject of issuer:
```
Get-ChildItem 'Cert:\LocalMachine\CA' | select Subject
```

Params and generate intermediate certificate :
```
$paramsIntermediate = @{
    Name = "iSmarty"
    FriendlyName = "iSmarty IT Authority"
    Company = "IT iSmarty Pro"
    DnsName = "iSmarty IT Authority"
    CN = "iSmarty IT Authority"
    OU = "IT"
    L = "Global"
    S = "Msk"
    C = "RU"
    Password = "Sup3rIntPassword"
    NotAfterYears = 15
    SignerSubject = "CN=iSmarty Certificate Authority, O=iSmarty Pro, OU=IT, L=Global, S=Msk, C=RU"

}

New-SSLIntermidiate @paramsIntermediate

```



# Misc

## Вспомогательные команды

### Создание fullchain сертификата для вебсервера #>

#### Windows Commands
```
mkdir webserver
Get-Content techexpert.crt, itDepartmentCert.crt, ca.crt  | Set-Content webserver\techexpert.crt
Copy-Item techexpert.key webserver
```

#### Linux Command
```
cat  techexpert.crt itDepartmentCert.crt ca.crt  > webserver\techexpert.crt
```

### Проверка файлов
```
openssl x509 -noout -modulus -in webserver\techexpert.crt | openssl md5
openssl rsa -noout -modulus -in webserver\techexpert.key | openssl md5

openssl x509 -noout -modulus -in techexpert.crt | openssl md5
openssl rsa -noout -modulus -in techexpert-rsa.key | openssl md5
```