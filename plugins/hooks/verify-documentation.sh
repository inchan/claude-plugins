#!/bin/bash
# verify-documentation.sh - 문서 및 설정 파일 검증 스크립트

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Documentation & Configuration Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check_file() {
    local file=$1
    local description=$2
    
    if [ -f "$file" ]; then
        local size=$(du -h "$file" | awk '{print $1}')
        echo "✅ $description ($size)"
        return 0
    else
        echo "❌ $description - NOT FOUND"
        return 1
    fi
}

check_executable() {
    local file=$1
    local description=$2
    
    if [ -x "$file" ]; then
        echo "✅ $description (executable)"
        return 0
    else
        echo "⚠️  $description (not executable)"
        return 1
    fi
}

echo "📚 Documentation Files:"
check_file "INDEX.md" "INDEX.md"
check_file "QUICKSTART.md" "QUICKSTART.md"
check_file "INSTALLATION.md" "INSTALLATION.md"
check_file "ARCHITECTURE.md" "ARCHITECTURE.md"
check_file "PERFORMANCE.md" "PERFORMANCE.md"
check_file "README.md" "README.md"
echo ""

echo "🔧 Installation Scripts:"
check_file "install-dependencies.sh" "install-dependencies.sh"
check_executable "install-dependencies.sh" "install-dependencies.sh"
echo ""

echo "⚙️ Configuration Files:"
check_file "config/matcher-config.json" "matcher-config.json"
check_file "config/synonyms.json" "synonyms.json"
echo ""

echo "🛠️ Core Scripts:"
check_file "skill-activation-hook.sh" "skill-activation-hook.sh"
check_executable "skill-activation-hook.sh" "skill-activation-hook.sh"
echo ""

echo "📦 Library Files:"
check_file "lib/cache-manager.sh" "cache-manager.sh"
check_file "lib/metadata-parser.sh" "metadata-parser.sh"
check_file "lib/plugin-discovery.sh" "plugin-discovery.sh"
echo ""

echo "🎯 Matcher Files:"
check_file "matchers/tfidf-matcher.js" "tfidf-matcher.js"
check_file "matchers/semantic-matcher.py" "semantic-matcher.py"
check_file "matchers/package.json" "package.json"
check_file "matchers/requirements.txt" "requirements.txt"
echo ""

echo "📂 Directory Structure:"
[ -d "cache" ] && echo "✅ cache/" || echo "❌ cache/ NOT FOUND"
[ -d "config" ] && echo "✅ config/" || echo "❌ config/ NOT FOUND"
[ -d "lib" ] && echo "✅ lib/" || echo "❌ lib/ NOT FOUND"
[ -d "matchers" ] && echo "✅ matchers/" || echo "❌ matchers/ NOT FOUND"
[ -d "tests" ] && echo "✅ tests/" || echo "❌ tests/ NOT FOUND"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Summary:"
echo ""
echo "Documentation: 6 files"
echo "Installation: 1 script"
echo "Configuration: 2 files"
echo "Core Scripts: 1 file"
echo "Libraries: 3 files"
echo "Matchers: 4 files"
echo ""
echo "Total: 17 files + 5 directories"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
