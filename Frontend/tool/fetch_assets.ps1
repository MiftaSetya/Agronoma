$ErrorActionPreference = 'Stop'

$Root     = 'C:\Project\Agronoma\Frontend'
$Base     = 'http://127.0.0.1:3845/assets/'
$IconDir  = Join-Path $Root 'assets\icons'
$ImageDir = Join-Path $Root 'assets\images'
New-Item -ItemType Directory -Force -Path $IconDir, $ImageDir | Out-Null

$svgs = @(
'a0a7f93bd94de47b5b65ca2e78b7106ffce27179.svg','8637549cd036f77b062483c5cb4d60910a8c92ab.svg',
'9a842c4b65e2591f55bfb50fa02c42b6ad7af785.svg','6a70a53d996b3f923a1d490f9aab3b2896b9e220.svg',
'ba991d7e479e4e44ea62a2b9766eecee92c0ca66.svg','0f266937dbc7f47ae09ead6161676490e57424f2.svg',
'94bcff3fff34c3ecd002a0cd551cf71f7bbef393.svg','e17f53b79a44ac5f5579d798ed031741559f1057.svg',
'232621d7fc41d275216ae4958c8a51d19a457a3a.svg','89e633c0b7f09b64d85d3fe221bf884c6a28e687.svg',
'2681f967727b559d12b95a177cb34563fa88c3c2.svg','8bcc67bdd8ea6bacf5302fbd05a5ad2f1f2926cb.svg',
'901b8b3d55a5ad056e7fa6f658f50a50f0b7cd88.svg','02130f480c80f906befa3baa5ab1fdf6d327fd82.svg',
'69cd7a79cb4172c2d6b85e732ff94aea63378d4c.svg','374e1449c0e2a79c1133cb271726b8629001c3e6.svg',
'efadcb3d07316ca86a8ff994b2bcfc744865280a.svg','dcf9c6b62c5cb236e611a7732c2bbd8fa12cde37.svg',
'6f62cf306191c3a4566cde0b8c08a2c2bff60a80.svg','284d83d1607bcf4841f417f1e61535a592d60489.svg',
'582a8ddb04f1242063e58741fe02c93560b55cc5.svg','4398fe693c8dac56de10c52c50bbbaa7e9b2a207.svg',
'dee016e42fc6a7eec95851cfbdbe0624c0b041af.svg','1633b862dd265c0272284a2162ca7f0f56104f4c.svg',
'fe532cf4fc291f9c9007ee4aeaa5f0055d0def3a.svg','e3efd504eaf63201af35fdce0d696bb38c53395f.svg',
'8463a5d6644c3e3287755842d99620b29794033c.svg','b572431490cf3ccf3fb165bb477a21fafcdc703f.svg',
'58a5d2eac5ce61ecdcbfacb0c870c71abac51886.svg','200d5ec8666be0da1473ff5b003f26fdc460de58.svg',
'9e3e7ad618d45456e1f259c40703d756bea890aa.svg','0984935e8e6fa6f64e8c91c02ba3643a23e05f35.svg',
'2c51ffd1bf8dcd5ac3b37960817784fcdbffac42.svg','93dee2dbdbb548c6edee280137d0d6248f66edd2.svg',
'9d0d832e994ea5410e308af8f604666e8a837a1c.svg','d73e86bc3385251b71e62c490f2a0ad3ad443285.svg',
'd886046b2c60058e6f92f3b67da61fd8fc3a83e1.svg','39e90148463a205633460bcfcba12bf6f83db64a.svg',
'2e6408ac1b3fac5f48f1b88828bb3fac7f8c00fc.svg','f1f021666ca3890cc161dc24b3d319afd9542150.svg',
'2fa8343d259af84d9bf2691f0331c1677b703040.svg','b209a8b63b014c4a955c74fbaa5044b471c1dfcb.svg',
'9b5154c0a340bbf8b66fab07d8b56c81d033d19e.svg','ae9c38a8ef9c9b218f15df152c1da515082ce4e1.svg',
'6336823ca0e4785e6d79804711688087b86e6289.svg','091d3ab263f91469af9789033f53ae49543eb966.svg',
'a7ce4d8f5b3d6d8e199c650a5675b1ebd8ae3c7b.svg','94312fbfd7eb7a516ff388c59c4dafa9851503ba.svg',
'61e410580a1154c9d0e46fe0bbc09d055ca75034.svg','e49bbb9c2a7503b4c030f0694067d5cd2cf5e81a.svg',
'3fc8a3bedb27a05d125fe5010a63fd9bd0783b43.svg','bb146b370aba54db44c73f219625c5fb514167c3.svg',
'f03253ccd9c730f318a31e8d54c5718364947c47.svg','1422e538c2c6069584f2be50ff8d8a1df87507c0.svg',
'83fa194c6dbe83a4361e999218ba218625294047.svg','515651936e1841aad38808d964faa4c98b8bba0a.svg',
'0c97f46d4f8317ec513f81177c282912226141c2.svg','17ff6b81d5a4ce835ab648a932a53a492539509c.svg',
'756880f66dbb2c1c46a221bcb89b919fa395b4fc.svg','fd34997884e8aad2a5b3c926d0676dc5d1935bbc.svg',
'3de30bfd240ec309374535a8edd16a2e24b08f07.svg','82c379a7225b48bf2a156b5e7cbf7cfc3287e792.svg',
'3cc16617bca9652e3982eef86d8e3df2ab4a2ec2.svg','eff00ba59f89a0c385d0f2080e5e5bf852888f81.svg',
'86fcf6188b602b790546f60663c6049b287264fd.svg','6e06a745ee1bbc9b5d3db70ee27cadf1535ef3a6.svg',
'd4923294986d45c05f568a95865b2104835b6f1a.svg','b41322841d9cc5ec959151cb36809d1d452fd03d.svg',
'b2af88a34e62691e1ab0d1c509b60cca02a24810.svg','e865fadf07013f42b665c39486e5928bc7f26d2d.svg',
'dd67902a30301086456de678d952b12db558ff3c.svg','b29cf6263f25e6b7d930eb277ced477bb23100db.svg',
'3484631a58aeb12eb4b1ca0859c14cdee65a5991.svg','3ab2a16f06867678af0e9bf237ad440ece3141fa.svg',
'47969e0c2ecbd2885404bd8cbd67767533d2a3c3.svg','38f7dd194df12f703e8c2bcd87e4e6c39201801a.svg',
'57920ea7ee9109763b28b8e8b35d87a1dbfdce4c.svg','064950e4ba668408d3433650bac624cf05a0c626.svg',
'f8be6d49ce2aaac578242cfb78d0cef318955acc.svg','b0edba78cbc793858bc2a5725e002e56704df17b.svg',
'042357eb72843fcc732cf87814a881f75d3a8aba.svg','63bd523e40fe86456993c5dc397b57c50ddaf3a7.svg',
'88bffc6ff73d42552309c4499e67fb62a125610e.svg','d9987165e4f0b5809476e0b4c33f2f47af4c161b.svg',
'b4c075c20e5454ae81cb78880782db187c0e912c.svg','d8af34bfcf27bd9d8f46b92286b1939e790bc1c7.svg',
'31a2dc7cf9b51123d1fe48f4b7791761038cc104.svg','7360fdf6fcb97da9a8596989f80c5862221146cd.svg',
'cc68dec2da50f29b52a52705b3d1089e62b6e816.svg','13655dc5f4f5c913570be0285f420059a4df9167.svg',
'fce7e399a8278f3f99643b151ac4f22372d87c6b.svg','1bc17606b2180b12291e17a8b9239ccfe9282fc7.svg',
'e25b7a487deb3f597644a23437d85ddb9bb17d9a.svg','3c4a16316f4fc77064326da38a9e6111d77f1a01.svg',
'7c1bfeeab8abbce777d4a8167432ac79152b568f.svg','746c5a179d5139b05592888c60dde480e03891fd.svg',
'98832cea57af00afa1ed2540a2499464115251f3.svg','a6f91e88e5d5585c53aff52712cabf3d40a75bc2.svg',
'9b2be4d4fe2969ff3fb5aaeaf1ae7f2900e84c7a.svg','69aded8418e740d6bda9f92bfeef8d864a84fe7f.svg',
'8832c9f72a47e02a3bbffc64b85f1ff410274900.svg','795eded994b37bb1d12d3d5d792ee7fa0bd116cb.svg',
'277e53b539780ab8332228aed88ed415049ceba2.svg','ef737f2fd5f77ee8b2373bcd192ef31ba14d492b.svg',
'5aaaa51f244abcfb56f8da61543bb79b2144f90a.svg','b3045c453da252dd1ffdbc2320190e60977f8149.svg',
'b632715990d9673b171c047e16807cf288ad1b35.svg','3e8fa98f234a1d513786c84bc4a1e15dc1feaea6.svg',
'770a02f455cd831c886a3cb47071494d7a089a40.svg','6fe50b8e12b3491cb364b67205a8656d1e9fc141.svg',
'bd5068fb86e5bb40e6d92e9ff619fc668f52e7a9.svg','bd49f2e97f904542a18c894beae4631902b5b775.svg',
'c6991985d9ffa3d6fee95dd7897c9b90ecb93fc5.svg','b818387941d0611786f8a41b0e7a9506b43535a9.svg',
'e49f39185afb4a5f6ab2b994b1a046aefb686511.svg','16e0c83d12c6c41291f02c27fd2cd0019740595f.svg',
'8936dfb0c38474f79a77cfbfcb81277f53fb701e.svg'
)

$pngs = @(
'10c13ac1a228a365cb98a0064b1d5afbc84887b2.png','a1d9f55fba0c922f702df6312dfc730d481d9c46.png',
'83fcae546fbfaec4e5b6e7980bb5365d0cf4c9e4.png','e1c380d0fe338c6467944659e846a0f9c64879df.png',
'5fd926b61cce8291149523be00289d78b3b7b5d2.png','e1af5d24963f1de953445cc053705d89d49130fd.png',
'0b2e0f5be47ba56050c9b3b67807a7ad737bcc8e.png','1f81b734e8934189c58e15c350cf1556b1cf3ad0.png',
'680c6f3c54087f01bbcdf6f9bafbe5ef3ef0d457.png','ece298d0ec2c16f10310d45724b276a6035cb503.png',
'8bffd86102f472123f3e7fe0cfccb0b1e275a15e.png','916ce803e52a4c51b4d9c8f4994668da852dcff1.png',
'5a06f9d9aeec8929dfbecc58242370ade180d192.png','4ea7e0d87f3073adabcb4d15aeeedd740cd07643.png',
'23f81969f628ad06296438584f978298573d10b8.png','be6aadfe318be2836140ef486475976009e32a34.png',
'615dabecf180b9cddab902d35ca29700fd9d4c40.png','ad9f407e510c9863d23e9f4536be7df515b3bed2.png',
'5aee898294f2a3a69c294ff46e01c96c14261f84.png','d41d5e0848924bc81706be83a6c9fe6a1e60c0e8.png'
)

$ok = 0; $skip = 0; $fail = @()

foreach ($f in $svgs) {
  $dest = Join-Path $IconDir $f
  if (Test-Path $dest) { $skip++; continue }
  try {
    Invoke-WebRequest -Uri ($Base + $f) -OutFile $dest -UseBasicParsing
    $txt = Get-Content -Raw -Path $dest -ErrorAction Stop
    if ($txt -notmatch '<svg') { throw "bukan SVG valid" }
    $ok++
  } catch { $fail += @{ f = $f; e = $_.Exception.Message }; Remove-Item $dest -ErrorAction SilentlyContinue }
}

foreach ($f in $pngs) {
  $dest = Join-Path $ImageDir $f
  if (Test-Path $dest) { $skip++; continue }
  try {
    Invoke-WebRequest -Uri ($Base + $f) -OutFile $dest -UseBasicParsing
    $b = [System.IO.File]::ReadAllBytes($dest)
    if ($b.Length -lt 8 -or $b[0] -ne 0x89 -or $b[1] -ne 0x50 -or $b[2] -ne 0x4E -or $b[3] -ne 0x47) { throw "bukan PNG valid" }
    $ok++
  } catch { $fail += @{ f = $f; e = $_.Exception.Message }; Remove-Item $dest -ErrorAction SilentlyContinue }
}

Write-Host "=== HASIL UNDUHAN ==="
Write-Host "Berhasil : $ok"
Write-Host "Dilewati : $skip"
Write-Host "Gagal    : $($fail.Count)"
foreach ($x in $fail) { Write-Host ("  GAGAL " + $x.f + " -> " + $x.e) }
Write-Host ""
Write-Host ("SVG di assets/icons : " + (Get-ChildItem $IconDir -Filter *.svg).Count)
Write-Host ("PNG di assets/images: " + (Get-ChildItem $ImageDir -Filter *.png).Count)
Write-Host ("Total ukuran         : " + [math]::Round((Get-ChildItem $IconDir,$ImageDir -File | Measure-Object Length -Sum).Sum / 1KB, 1) + " KB")
