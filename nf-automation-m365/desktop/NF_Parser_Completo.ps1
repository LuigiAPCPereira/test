$ErrorActionPreference = "Stop"

function Empty-Result([string]$status, [string]$erro) {
    return [ordered]@{
        StatusParser = $status
        TipoDocumento = "DESCONHECIDO"
        NumeroNF = ""
        NumeroNFNormalizado = ""
        Serie = ""
        DataEmissao = ""
        DataEmissaoISO = ""
        EmpresaPrestadora = ""
        CNPJPrestadora = ""
        CNPJPrestadoraNormalizado = ""
        EmpresaTomadora = ""
        ValorLiquido = ""
        ValorLiquidoNumero = ""
        CamposAusentes = ""
        TextoExtraidoCaracteres = 0
        Erro = $erro
    }
}

try {
    $text = @'
%ExtractedPDFText%
'@
    if ([string]::IsNullOrWhiteSpace($text)) {
        (Empty-Result "ERRO" "O PDF não retornou texto extraível.") | ConvertTo-Json -Compress
        exit
    }

    $text = $text -replace "`r`n", "`n"
    $text = $text -replace [char]0xA0, " "
    $rxOptions = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Multiline

    function First-Group([string[]]$patterns, [int]$group = 1) {
        foreach ($pattern in $patterns) {
            $m = [regex]::Match($text, $pattern, $rxOptions)
            if ($m.Success -and $m.Groups.Count -gt $group) {
                return (($m.Groups[$group].Value -replace "\s+", " ").Trim())
            }
        }
        return ""
    }

    function Clean-Company([string]$value) {
        if ([string]::IsNullOrWhiteSpace($value)) { return "" }
        $v = ($value -replace "\s+", " ").Trim([char[]]" -:")
        $v = $v -replace "\s+(CPF|CNPJ|NIF)\s*$", ""
        return $v.Trim()
    }

    function Normalize-Digits([string]$value) {
        if ([string]::IsNullOrWhiteSpace($value)) { return "" }
        return ($value -replace "\D", "")
    }

    function Date-ToIso([string]$value) {
        if ([string]::IsNullOrWhiteSpace($value)) { return "" }
        $dt = [datetime]::MinValue
        if ([datetime]::TryParseExact($value, "dd/MM/yyyy", [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$dt)) {
            return $dt.ToString("yyyy-MM-dd")
        }
        return ""
    }

    function Money-ToInvariant([string]$value) {
        if ([string]::IsNullOrWhiteSpace($value)) { return "" }
        $normalized = ($value -replace "\.", "") -replace ",", "."
        $number = 0D
        if ([decimal]::TryParse($normalized, [Globalization.NumberStyles]::Number, [Globalization.CultureInfo]::InvariantCulture, [ref]$number)) {
            return $number.ToString("0.00", [Globalization.CultureInfo]::InvariantCulture)
        }
        return ""
    }

    function Cnpj-NearCompany([string]$company) {
        if ([string]::IsNullOrWhiteSpace($company)) { return "" }
        $companyHits = [regex]::Matches($text, [regex]::Escape($company), [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        $cnpjHits = [regex]::Matches($text, "\b\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}\b")
        $best = ""
        $bestDistance = [int]::MaxValue
        foreach ($companyHit in $companyHits) {
            foreach ($cnpjHit in $cnpjHits) {
                $distance = [Math]::Abs($cnpjHit.Index - ($companyHit.Index + $companyHit.Length))
                if ($distance -le 220 -and $distance -lt $bestDistance) {
                    $bestDistance = $distance
                    $best = $cnpjHit.Value
                }
            }
        }
        return $best
    }

    function Max-MoneyAfter([string]$labelPattern, [int]$window = 350) {
        $label = [regex]::Match($text, $labelPattern, $rxOptions)
        if (-not $label.Success) { return "" }
        $start = $label.Index
        $length = [Math]::Min($window, $text.Length - $start)
        $section = $text.Substring($start, $length)
        $moneyHits = [regex]::Matches($section, "(?<!\d)(?:\d{1,3}(?:\.\d{3})+|\d+),\d{2}(?!\d)")
        if ($moneyHits.Count -eq 0) { return "" }
        $bestRaw = ""
        $bestValue = -1D
        foreach ($hit in $moneyHits) {
            $normalized = ($hit.Value -replace "\.", "") -replace ",", "."
            $number = 0D
            if ([decimal]::TryParse($normalized, [Globalization.NumberStyles]::Number, [Globalization.CultureInfo]::InvariantCulture, [ref]$number)) {
                if ($number -gt $bestValue) {
                    $bestValue = $number
                    $bestRaw = $hit.Value
                }
            }
        }
        return $bestRaw
    }

    $TipoDocumento = "DESCONHECIDO"
    if ($text -match "(?i)NFS-?E|NFSE|NOTA FISCAL DE SERVI[CÇ]OS ELETR[ÔO]NICA") {
        $TipoDocumento = "NFSE"
    } elseif ($text -match "(?i)DANFE|DOCUMENTO AUXILIAR.*NOTA FISCAL.*ELETR[ÔO]NICA|CHAVE DE ACESSO") {
        $TipoDocumento = "NFE"
    }

    $NumeroNF = ""
    $Serie = ""
    $DataEmissao = ""
    $EmpresaPrestadora = ""
    $CNPJPrestadora = ""
    $EmpresaTomadora = ""
    $ValorLiquido = ""

    if ($TipoDocumento -eq "NFSE") {
        $numeroSerie = [regex]::Match($text, "N[ÚU]MERO\s*/\s*S[ÉE]RIE\s*[:\-]?\s*([0-9.]+)\s*/\s*([A-Z0-9.\-]+)", $rxOptions)
        if ($numeroSerie.Success) {
            $NumeroNF = $numeroSerie.Groups[1].Value.Trim()
            $Serie = $numeroSerie.Groups[2].Value.Trim()
        }
        if (-not $NumeroNF) {
            $NumeroNF = First-Group @(
                "N[ÚU]MERO\s+(?:DA\s+)?(?:NFS-?E|NFSE|NF)\s*[:\-]?\s*([0-9.]+)",
                "N[ÚU]MERO\s*[:\-]\s*([0-9.]+)"
            )
        }
        if (-not $Serie) {
            $Serie = First-Group @("^\s*S[ÉE]RIE\s*[:\-]?\s*([A-Z0-9.\-]+)\s*$")
        }
        $DataEmissao = First-Group @(
            "DATA\s+(?:E\s+HORA\s+)?DE\s+EMISS[AÃ]O\s*[:\-]?\s*([0-3]\d/[01]\d/\d{4})",
            "EMISS[AÃ]O[\s\S]{0,80}?([0-3]\d/[01]\d/\d{4})"
        )
        $EmpresaPrestadora = Clean-Company (First-Group @(
            "EMITENTE\s+PRESTADOR(?:\s+DO\s+SERVI[CÇ]O)?[\s\S]{0,700}?NOME\s*/\s*NOME\s+EMPRESARIAL\s*[\r\n ]+([^\r\n]+)",
            "PRESTADOR\s+DO\s+SERVI[CÇ]O[\s\S]{0,500}?NOME\s*/\s*NOME\s+EMPRESARIAL\s*[\r\n ]+([^\r\n]+)"
        ))
        $CNPJPrestadora = First-Group @(
            "EMITENTE\s+PRESTADOR[\s\S]{0,500}?(?:CPF\s*/\s*CNPJ\s*/\s*NIF|CNPJ)\s*[:\-]?\s*(\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2})"
        )
        if (-not $CNPJPrestadora) { $CNPJPrestadora = Cnpj-NearCompany $EmpresaPrestadora }

        $EmpresaTomadora = Clean-Company (First-Group @(
            "TOMADOR\s+DO\s+SERVI[CÇ]O[\s\S]{0,700}?NOME\s*/\s*NOME\s+EMPRESARIAL\s*[\r\n ]+([^\r\n]+)",
            "TOMADOR[\s\S]{0,500}?NOME\s*/\s*NOME\s+EMPRESARIAL\s*[\r\n ]+([^\r\n]+)"
        ))
        $ValorLiquido = First-Group @(
            "VALOR\s+L[ÍI]QUIDO\s+DA\s+NFS-?E\s*(?:\(R\$\))?\s*[:\-]?\s*((?:\d{1,3}(?:\.\d{3})+|\d+),\d{2})",
            "VALOR\s+L[ÍI]QUIDO[\s\S]{0,80}?((?:\d{1,3}(?:\.\d{3})+|\d+),\d{2})"
        )
    }
    else {
        $NumeroNF = First-Group @(
            "^\s*N[º°O]\s*[:\-]?\s*([0-9]{1,3}(?:\.[0-9]{3})+|[0-9]{3,})\s*$",
            "\bN[º°O]\s*[:\-]?\s*([0-9]{1,3}(?:\.[0-9]{3})+|[0-9]{3,})\b"
        )
        $Serie = First-Group @(
            "^\s*S[ÉE]RIE\s*[:\-]?\s*([A-Z0-9.\-]+)\s*$",
            "S[ÉE]RIE\s*[:\-]?\s*([A-Z0-9.\-]+)"
        )
        $DataEmissao = First-Group @(
            "DATA\s+DA\s+EMISS[AÃ]O[\s\S]{0,400}?([0-3]\d/[01]\d/\d{4})",
            "PROTOCOLO\s+DE\s+AUTORIZA[CÇ][AÃ]O[\s\S]{0,180}?([0-3]\d/[01]\d/\d{4})"
        )
        $EmpresaPrestadora = Clean-Company (First-Group @(
            "^\s*RECEBEMOS\s+DE\s+(.+?)\s+OS\s+PRODUTOS/SERVI[CÇ]OS",
            "RECEBEMOS\s+DE\s+(.+?)\s+OS\s+PRODUTOS/SERVI[CÇ]OS"
        ))
        $CNPJPrestadora = Cnpj-NearCompany $EmpresaPrestadora
        if (-not $CNPJPrestadora) {
            $CNPJPrestadora = First-Group @(
                "(?:CNPJ|CNPJ/CPF)\s*[:\-]?\s*(\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2})"
            )
        }
        $EmpresaTomadora = Clean-Company (First-Group @(
            "IDENTIFICA[CÇ][AÃ]O\s+E\s+ASSINATURA\s+DO\s+RECEBEDOR:\s*([^\r\n]+?)(?:\s+ME)?\s*-\s*CNPJ",
            "DESTINAT[ÁA]RIO/REMETENTE[\s\S]{0,650}?NOME/RAZ[AÃ]O\s+SOCIAL[\s\S]{0,180}?([A-Z][A-Z0-9 .&/\-]{4,})"
        ))
        $ValorLiquido = Max-MoneyAfter "VALOR\s+TOTAL\s+DA\s+NOTA" 420
        if (-not $ValorLiquido) {
            $ValorLiquido = First-Group @(
                "VALOR\s+L[ÍI]QUIDO[\s\S]{0,100}?((?:\d{1,3}(?:\.\d{3})+|\d+),\d{2})"
            )
        }
    }

    if (-not $CNPJPrestadora -and $EmpresaPrestadora) { $CNPJPrestadora = Cnpj-NearCompany $EmpresaPrestadora }
    if (-not $DataEmissao) {
        $DataEmissao = First-Group @("\b([0-3]\d/[01]\d/\d{4})\b")
    }

    $NumeroNFNormalizado = Normalize-Digits $NumeroNF
    $CNPJPrestadoraNormalizado = Normalize-Digits $CNPJPrestadora
    $DataEmissaoISO = Date-ToIso $DataEmissao
    $ValorLiquidoNumero = Money-ToInvariant $ValorLiquido

    $missing = New-Object System.Collections.Generic.List[string]
    if (-not $NumeroNF) { $missing.Add("NumeroNF") }
    if (-not $Serie) { $missing.Add("Serie") }
    if (-not $DataEmissao) { $missing.Add("DataEmissao") }
    if (-not $EmpresaPrestadora) { $missing.Add("EmpresaPrestadora") }
    if (-not $CNPJPrestadora) { $missing.Add("CNPJPrestadora") }
    if (-not $EmpresaTomadora) { $missing.Add("EmpresaTomadora") }
    if (-not $ValorLiquido) { $missing.Add("ValorLiquido") }

    if ($missing.Count -eq 0) { $StatusParser = "OK" }
    elseif ($missing.Count -le 2) { $StatusParser = "REVISAR" }
    else { $StatusParser = "FALHA_PARCIAL" }

    [ordered]@{
        StatusParser = $StatusParser
        TipoDocumento = $TipoDocumento
        NumeroNF = $NumeroNF
        NumeroNFNormalizado = $NumeroNFNormalizado
        Serie = $Serie
        DataEmissao = $DataEmissao
        DataEmissaoISO = $DataEmissaoISO
        EmpresaPrestadora = $EmpresaPrestadora
        CNPJPrestadora = $CNPJPrestadora
        CNPJPrestadoraNormalizado = $CNPJPrestadoraNormalizado
        EmpresaTomadora = $EmpresaTomadora
        ValorLiquido = $ValorLiquido
        ValorLiquidoNumero = $ValorLiquidoNumero
        CamposAusentes = ($missing -join ", ")
        TextoExtraidoCaracteres = $text.Length
        Erro = ""
    } | ConvertTo-Json -Compress
}
catch {
    (Empty-Result "ERRO" $_.Exception.Message) | ConvertTo-Json -Compress
}
