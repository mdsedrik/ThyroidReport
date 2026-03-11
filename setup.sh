#!/bin/bash

# ================================================================
# Tiroid Rapor - Xcode Proje Kurulum Scripti
# Bu script Mac'inizde çalıştırılmalıdır.
# ================================================================

set -e

echo "╔══════════════════════════════════════════╗"
echo "║     Tiroid Rapor - Proje Kurulumu        ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Homebrew kontrolü
if ! command -v brew &> /dev/null; then
    echo "📦 Homebrew yükleniyor..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "✅ Homebrew mevcut."
fi

# XcodeGen kontrolü
if ! command -v xcodegen &> /dev/null; then
    echo "📦 XcodeGen yükleniyor..."
    brew install xcodegen
else
    echo "✅ XcodeGen mevcut."
fi

# Proje dizinine git
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo ""
echo "🔨 Xcode projesi oluşturuluyor..."
xcodegen generate

echo ""
echo "✅ ThyroidReport.xcodeproj başarıyla oluşturuldu!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Sonraki adımlar:"
echo "  1. ThyroidReport.xcodeproj dosyasını Xcode ile açın"
echo "  2. Sol üstten 'ThyroidReport' hedefini seçin"
echo "  3. 'Signing & Capabilities' sekmesinde Apple ID'nizi seçin"
echo "  4. iPhone'unuzu Mac'e bağlayın"
echo "  5. Product > Archive menüsünden uygulamayı derleyin"
echo "  6. Distribute App > TestFlight ile yükleyin"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
