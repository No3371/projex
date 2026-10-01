# Read-only Parent lineage tree for one projex document: follows the target's Parent chain to its
# root, then prints every current-corpus descendant of that root as a box-drawing tree.
# Usage: projex-tree.ps1 <repo-root> <filename>
# Exit: 0 tree on stdout | 2 usage, repo, or target error | 3 lineage errors | 4 unreadable or non-UTF-8 document.
# Error lines on stderr: "projex-tree: <code>: <locator>: <detail>". All output is UTF-8 with LF line ends.
#
# No param block and no [CmdletBinding()]: the parameter binder would reject extra arguments with its own
# error (exit 1) and silently bind -Verbose / -- as common parameters before the usage check could run.
# Every name and header comparison is ordinal: -eq / -match / Sort-Object / StartsWith(string) compare
# case-insensitively or by culture (culture StartsWith matches "> **Parent:**" against the same text with a soft hyphen after ">").
$ErrorActionPreference = 'Stop'

# Code-point order: UTF-8 bytes compared lexicographically. String.CompareOrdinal compares UTF-16 units,
# which puts U+FF01 after U+1F600 (surrogate pair 0xD83D < 0xFF01).
class Utf8Order : System.Collections.Generic.IComparer[string] {
    static [Text.Encoding] $Encoding = [Text.UTF8Encoding]::new($false)
    [int] Compare([string]$A, [string]$B) {
        $X = [Utf8Order]::Encoding.GetBytes($A)
        $Y = [Utf8Order]::Encoding.GetBytes($B)
        $N = [Math]::Min($X.Length, $Y.Length)
        for ($I = 0; $I -lt $N; $I++) { if ($X[$I] -ne $Y[$I]) { return [int]$X[$I] - [int]$Y[$I] } }
        return $X.Length - $Y.Length
    }
}

$Utf8 = [Text.UTF8Encoding]::new($false)
$StrictUtf8 = [Text.UTF8Encoding]::new($false, $true)
$Ordinal = [StringComparison]::Ordinal
$Order = [Utf8Order]::new()

# Writes raw UTF-8 bytes: [Console]::Error.WriteLine and Write-Output would use the console encoding
# and the platform newline (CRLF on Windows). The bytes bypass the PowerShell pipeline, so an in-process
# caller (& projex-tree.ps1) can neither capture nor redirect them; capture by running "pwsh -File" as a child.
function Emit([string]$Text, [int]$Code, [bool]$ToStderr) {
    $Bytes = $Utf8.GetBytes($Text)
    $Stream = if ($ToStderr) { [Console]::OpenStandardError() } else { [Console]::OpenStandardOutput() }
    $Stream.Write($Bytes, 0, $Bytes.Length)
    $Stream.Flush()
    exit $Code
}
function Fail([string]$Line, [int]$Code) { Emit "projex-tree: $Line`n" $Code $true }
function Same([string]$A, [string]$B) { return [string]::Equals($A, $B, $Ordinal) }

if ($args.Count -ne 2) { Fail 'E_USAGE: invocation: expected <repo-root> <filename>' 2 }
$RepoRoot = [string]$args[0]
$Filename = [string]$args[1]

# Literal-string directory test (Test-Path / Resolve-Path would also accept non-filesystem PowerShell drives such as Env:); the root must also be listable.
# A relative root is joined to the session's FileSystem location: the one-argument GetFullPath and Directory.Exists
# use the process working directory, which Set-Location does not move, so an in-process call would read another directory.
$Root = $null
if ($RepoRoot.Length -gt 0) {
    try {
        $Full = [IO.Path]::GetFullPath($RepoRoot, (Get-Location -PSProvider FileSystem).ProviderPath)
        if ([IO.Directory]::Exists($Full)) {
            $Info = [IO.DirectoryInfo]::new($Full)
            $null = [IO.Directory]::GetFileSystemEntries($Info.FullName)
            $Root = $Info
        }
    } catch { $Root = $null }
}
if ($null -eq $Root) { Fail "E_REPO: ${RepoRoot}: repository root not found" 2 }
if ($Filename.Length -eq 0) { Fail 'E_TARGET_NAME: <empty>: filename basename required' 2 }
if ($Filename.IndexOfAny([char[]]('/', '\', ':')) -ge 0) { Fail "E_TARGET_NAME: ${Filename}: filename basename required" 2 }

# Header whitespace: 09-0D, 1C-20 and the Unicode space separators; String.Trim() alone misses 1C-1F
$Space = [char[]](@(0x09..0x0D) + @(0x1C..0x20) + @(0x85, 0xA0, 0x1680) + @(0x2000..0x200A) + @(0x2028, 0x2029, 0x202F, 0x205F, 0x3000))
$LineBreak = '\r\n|[\n\r\v\f\x1c\x1d\x1e\x85' + [char]0x2028 + [char]0x2029 + ']'
$NamePattern = '^[0-9]{10}-[a-z0-9][a-z0-9-]*-[a-z0-9][a-z0-9-]*\.md$'

$Docs = [Collections.Generic.List[object]]::new()
function ReadDoc([IO.FileInfo]$File, [string]$Rel) {
    try { $Raw = [IO.File]::ReadAllBytes($File.FullName) } catch { Fail "E_IO: ${Rel}: read failed" 4 }
    # exactly one BOM: TrimStart([char]0xFEFF) would also strip a second, content BOM
    $Skip = 0
    if ($Raw.Length -ge 3 -and $Raw[0] -eq 0xEF -and $Raw[1] -eq 0xBB -and $Raw[2] -eq 0xBF) { $Skip = 3 }
    try { $Text = $StrictUtf8.GetString($Raw, $Skip, $Raw.Length - $Skip) } catch { Fail "E_IO: ${Rel}: invalid UTF-8" 4 }
    $Parents = [Collections.Generic.List[string]]::new()
    $Started = $false
    $Index = 0
    foreach ($Line in [regex]::Split($Text, $LineBreak)) {
        if ($Index++ -eq 0 -and $Line.StartsWith('#', $Ordinal)) { $Started = $true; continue }
        $Stripped = $Line.Trim($Space)
        if (Same $Stripped '---') { break }
        if ($Line.StartsWith('> ', $Ordinal)) {
            $Started = $true
            if ($Line.StartsWith('> **Parent:**', $Ordinal)) { $Parents.Add($Line.Substring(13).Trim($Space)) }
            continue
        }
        if ($Stripped.Length -eq 0) { continue }
        if ($Started) { break }
    }
    $Docs.Add([pscustomobject]@{ Name = $File.Name; Rel = $Rel; Parents = $Parents })
}

# Pre-order walk: a directory's files, then its subdirectories, each in code-point order.
# Skips .git, .projexwt, links (LinkTarget, not ReparsePoint: cloud placeholders are reparse points but not
# links), and any directory below the root holding a .git entry (checked by exact name in this listing;
# Test-Path is case-insensitive on NTFS). Unlistable directories are skipped silently.
function Walk([IO.DirectoryInfo]$Dir, [string]$Prefix, [bool]$InProjex, [bool]$IsRoot) {
    # materialized inside try: enumeration is lazy and throws on the first MoveNext
    try { $Entries = @($Dir.EnumerateFileSystemInfos()) } catch { return }
    if (-not $IsRoot) { foreach ($Entry in $Entries) { if (Same $Entry.Name '.git') { return } } }
    $Files = [Collections.Generic.Dictionary[string, object]]::new([StringComparer]::Ordinal)
    $Subs = [Collections.Generic.Dictionary[string, object]]::new([StringComparer]::Ordinal)
    foreach ($Entry in $Entries) {
        if ($null -ne $Entry.LinkTarget) { continue }
        if ($Entry -is [IO.DirectoryInfo]) {
            if (-not (Same $Entry.Name '.git') -and -not (Same $Entry.Name '.projexwt')) { $Subs[$Entry.Name] = $Entry }
        } elseif ($Entry.Name.EndsWith('.md', $Ordinal)) {
            $Files[$Entry.Name] = $Entry
        }
    }
    if ($InProjex) {
        $Names = [Collections.Generic.List[string]]::new($Files.Keys)
        $Names.Sort($Order)
        foreach ($Name in $Names) { ReadDoc $Files[$Name] ($Prefix + $Name) }
    }
    $Names = [Collections.Generic.List[string]]::new($Subs.Keys)
    $Names.Sort($Order)
    foreach ($Name in $Names) { Walk $Subs[$Name] ($Prefix + $Name + '/') ($InProjex -or (Same $Name '.projex')) $false }
}
# A repository root that is itself a .projex directory makes every .md below it a document
$RootName = $Root.Name
$Resolved = $Root.ResolveLinkTarget($true)
if ($null -ne $Resolved) { $RootName = $Resolved.Name }
Walk $Root '' (Same $RootName '.projex') $true

$ByName = [Collections.Generic.Dictionary[string, object]]::new([StringComparer]::Ordinal)
foreach ($Doc in $Docs) {
    if (-not $ByName.ContainsKey($Doc.Name)) { $ByName[$Doc.Name] = [Collections.Generic.List[object]]::new() }
    $ByName[$Doc.Name].Add($Doc)
}
if (-not $ByName.ContainsKey($Filename)) { Fail "E_TARGET_NOT_FOUND: ${Filename}: document not found" 2 }
if ($ByName[$Filename].Count -ne 1) { Fail "E_TARGET_AMBIGUOUS: ${Filename}: filename resolves to multiple documents" 2 }

$Errors = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
function AddError([string]$Code, [string]$Loc, [string]$Detail) { $null = $Errors.Add("$Code`0$Loc`0$Detail") }
# NUL-joined (code, locator, detail) compared bytewise = tuple order: NUL sorts before every name byte,
# and only the last field (detail) may itself hold NUL
function EmitErrors {
    $Sorted = [Collections.Generic.List[string]]::new($Errors)
    $Sorted.Sort($Order)
    $Text = [Text.StringBuilder]::new()
    foreach ($Record in $Sorted) {
        $Fields = $Record.Split([char[]]@([char]0), 3)
        $null = $Text.Append("projex-tree: $($Fields[0]): $($Fields[1]): $($Fields[2])`n")
    }
    Emit $Text.ToString() 3 $true
}
function IsRootParent([string]$Parent) { return (Same $Parent 'User') -or (Same $Parent 'Orchestrator') }
function IsName([string]$Parent) { return [regex]::IsMatch($Parent, $NamePattern) }

$Chain = [Collections.Generic.List[object]]::new()
$Seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$Current = $ByName[$Filename][0]
while ($true) {
    $Name = $Current.Name
    if (-not $Seen.Add($Name)) { AddError 'E_CYCLE' $Current.Rel 'Parent chain cycles'; break }
    $Chain.Add($Current)
    if ($Current.Parents.Count -gt 1) { AddError 'E_PARENT_DUPLICATE' $Current.Rel 'multiple Parent headers'; break }
    if ($Current.Parents.Count -eq 0) { break }
    $Parent = $Current.Parents[0]
    if (IsRootParent $Parent) { break }
    if (-not (IsName $Parent)) { AddError 'E_PARENT_MALFORMED' $Current.Rel "Parent is not a projex filename: $Parent"; break }
    if (Same $Parent $Name) { AddError 'E_PARENT_SELF' $Current.Rel 'Parent names the document itself'; break }
    if (-not $ByName.ContainsKey($Parent)) { AddError 'E_PARENT_DANGLING' $Current.Rel "Parent not discovered: $Parent"; break }
    if ($ByName[$Parent].Count -ne 1) { AddError 'E_IDENTITY_DUPLICATE' $Parent 'Parent identity resolves to multiple documents'; break }
    $Current = $ByName[$Parent][0]
}
if ($Errors.Count -gt 0) { EmitErrors }

# Members admitted below each holder have exactly one well-formed Parent and enter once, so the member set
# is a tree: a descendant cycle check or a member multi-Parent re-scan after this loop could never fire,
# so neither exists.
$Members = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$Children = [Collections.Generic.Dictionary[string, object]]::new([StringComparer]::Ordinal)
function AddChild([string]$Holder, [string]$Child) {
    if (-not $Children.ContainsKey($Holder)) { $Children[$Holder] = [Collections.Generic.List[string]]::new() }
    $Children[$Holder].Add($Child)
}
foreach ($Doc in $Chain) { $null = $Members.Add($Doc.Name) }
for ($I = 0; $I -lt $Chain.Count - 1; $I++) { AddChild $Chain[$I + 1].Name $Chain[$I].Name }
$Queue = [Collections.Generic.Queue[string]]::new()
for ($I = $Chain.Count - 1; $I -ge 0; $I--) { $Queue.Enqueue($Chain[$I].Name) }
while ($Queue.Count -gt 0) {
    $Holder = $Queue.Dequeue()
    foreach ($Doc in $Docs) {
        if ($Doc.Parents.Count -gt 1) {
            foreach ($Parent in $Doc.Parents) { if (Same $Parent $Holder) { AddError 'E_PARENT_DUPLICATE' $Doc.Rel 'multiple Parent headers'; break } }
            continue
        }
        if ($Doc.Parents.Count -ne 1) { continue }
        $Parent = $Doc.Parents[0]
        if (-not (Same $Parent $Holder) -or (IsRootParent $Parent) -or -not (IsName $Parent)) { continue }
        if ($ByName[$Doc.Name].Count -ne 1) { AddError 'E_IDENTITY_DUPLICATE' $Doc.Name 'child identity resolves to multiple documents'; continue }
        if (-not $Members.Add($Doc.Name)) { continue }
        AddChild $Holder $Doc.Name
        $Queue.Enqueue($Doc.Name)
    }
}
if ($Errors.Count -gt 0) { EmitErrors }

$Tee = [string][char]0x251C + [char]0x2500 + [char]0x2500 + ' '
$Elbow = [string][char]0x2514 + [char]0x2500 + [char]0x2500 + ' '
$Pipe = [string][char]0x2502 + '   '
$Out = [Text.StringBuilder]::new()
function Render([string]$Holder, [string]$Prefix) {
    if (-not $Children.ContainsKey($Holder)) { return }
    $Kids = [Collections.Generic.List[string]]::new($Children[$Holder])
    $Kids.Sort($Order)
    for ($I = 0; $I -lt $Kids.Count; $I++) {
        $Last = $I -eq $Kids.Count - 1
        $null = $Out.Append($Prefix + $(if ($Last) { $Elbow } else { $Tee }) + $Kids[$I] + "`n")
        Render $Kids[$I] ($Prefix + $(if ($Last) { '    ' } else { $Pipe }))
    }
}
$RootDoc = $Chain[$Chain.Count - 1].Name
$null = $Out.Append($RootDoc + "`n")
Render $RootDoc ''
Emit $Out.ToString() 0 $false
