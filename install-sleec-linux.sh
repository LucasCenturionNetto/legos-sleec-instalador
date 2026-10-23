#!/usr/bin/env bash
# Instala o LEGOS-SLEEC no Linux: IntelliJ IDEA Community 2021.3.3,
# o plugin Sleec e as dependencias Python, para todos os usuarios da maquina.
#
# Uso: sudo bash install-sleec-linux.sh [caminho/do/plugin.zip]
# Sem argumento, procura o zip na mesma pasta deste script.
set -euo pipefail

IDEA_VERSION="2021.3.3"
IDEA_URL="https://download.jetbrains.com/idea/ideaIC-${IDEA_VERSION}.tar.gz"
IDEA_DIR="/opt/idea-IC-${IDEA_VERSION}"
VENV_DIR="/opt/sleec-venv"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PLUGIN_ZIP="${1:-${SCRIPT_DIR}/SleecLanguageExtension-2.4-SNAPSHOT.zip}"

falha() { echo "ERRO: $*" >&2; exit 1; }

# O plugin precisa de tkinter e idlelib, e o instalador de venv; algumas distros
# vendem essas partes do Python em pacotes separados. O venv e testado criando
# um de verdade, porque no Debian/Ubuntu o modulo existe mas vem desativado.
python_ok() {
    command -v python3 >/dev/null || return 1
    python3 -c "import tkinter, idlelib.colorizer" 2>/dev/null || return 1
    local d r
    d="$(mktemp -d)"
    python3 -m venv "$d/v" >/dev/null 2>&1
    r=$?
    rm -rf "$d"
    return $r
}

[ "$(id -u)" -eq 0 ] || falha "execute com sudo: sudo bash $0"
[ -f "$PLUGIN_ZIP" ] || falha "plugin nao encontrado: $PLUGIN_ZIP"
[ "$(uname -m)" = "x86_64" ] || falha "processador $(uname -m) nao suportado; o IntelliJ ${IDEA_VERSION} para Linux existe so para x86_64 (Intel/AMD de 64 bits)"

# Baixa $1 para $2 com wget ou curl. Internet instavel: desiste de uma
# conexao parada em 30 s e retoma de onde parou.
baixar() {
    if command -v wget >/dev/null; then
        wget --continue --tries=30 --read-timeout=30 --waitretry=5 -O "$2" "$1"
    elif command -v curl >/dev/null; then
        curl -fL --retry 30 --retry-delay 5 --speed-limit 1024 --speed-time 30 -C - -o "$2" "$1"
    else
        falha "nem wget nem curl estao instalados"
    fi
}

instalar_pacotes() {
    if command -v apt-get >/dev/null; then
        # Um repositorio de terceiros quebrado (ex.: VS Code sem chave) nao deve impedir a instalacao.
        apt-get -o DPkg::Lock::Timeout=600 update || echo "    aviso: apt-get update teve erros; seguindo com as listas disponiveis"
        apt-get -o DPkg::Lock::Timeout=600 install -y python3 python3-venv python3-tk idle3
    elif command -v dnf >/dev/null; then
        dnf install -y python3 python3-tkinter python3-idle
    elif command -v pacman >/dev/null; then
        pacman -S --needed --noconfirm python tk
    elif command -v zypper >/dev/null; then
        # No openSUSE os pacotes levam a versao do Python no nome (ex.: python313-tk).
        local v
        v="$(python3 -c 'import sys; print("%d%d" % sys.version_info[:2])' 2>/dev/null || echo 3)"
        zypper --non-interactive install "python${v}" "python${v}-tk" "python${v}-idle"
    else
        falha "gerenciador de pacotes nao reconhecido. Instale o Python 3 com tkinter, idlelib e venv e rode de novo."
    fi
}

echo "==> [1/5] Python do sistema"
if python_ok; then
    echo "    Python ja tem tudo o que o plugin precisa"
else
    echo "    faltam componentes do Python; instalando pelo gerenciador de pacotes"
    instalar_pacotes
    python_ok || falha "o Python ainda nao tem tkinter, idlelib ou venv depois da instalacao"
fi
python3 -c "import sys; assert sys.version_info >= (3, 8)" || falha "o plugin precisa de Python 3.8 ou mais novo; este e $(python3 --version)"

echo "==> [2/5] Ambiente Python em ${VENV_DIR}"
python3 -m venv "$VENV_DIR"
"$VENV_DIR/bin/pip" install --upgrade pip
"$VENV_DIR/bin/pip" install z3-solver pysmt ordered-set textx termcolor

echo "==> [3/5] IntelliJ IDEA ${IDEA_VERSION} em ${IDEA_DIR}"
LOCAL_TAR="${SCRIPT_DIR}/ideaIC-${IDEA_VERSION}.tar.gz"
# Marca gravada so depois de extrair tudo: uma extracao interrompida e refeita.
IDEA_DONE="$IDEA_DIR/.sleec-extracao-completa"
if [ -f "$IDEA_DONE" ]; then
    echo "    ja instalado, pulando o download"
else
    rm -rf "$IDEA_DIR"
    if [ -f "$LOCAL_TAR" ]; then
        # Copia levada junto com a pasta: evita baixar 766 MB em cada maquina.
        echo "    usando $LOCAL_TAR"
        TAR="$LOCAL_TAR"
    else
        TAR="$(mktemp --suffix=.tar.gz)"
        baixar "$IDEA_URL" "$TAR"
    fi
    mkdir -p "$IDEA_DIR"
    tar -xzf "$TAR" -C "$IDEA_DIR" --strip-components=1
    [ "$TAR" = "$LOCAL_TAR" ] || rm -f "$TAR"
    touch "$IDEA_DONE"
fi

echo "==> [4/5] Plugin Sleec"
rm -rf "$IDEA_DIR/plugins/SleecLanguageExtension"
# Descompacta com o proprio Python para nao depender do unzip.
python3 -m zipfile -e "$PLUGIN_ZIP" "$IDEA_DIR/plugins"

echo "==> [5/5] Atalhos"
# O plugin chama "python3" pelo PATH; o lancador poe o venv na frente.
mkdir -p /usr/local/bin /usr/share/applications
cat > /usr/local/bin/sleec-idea <<EOF
#!/bin/sh
PATH="${VENV_DIR}/bin:\$PATH" exec "${IDEA_DIR}/bin/idea.sh" "\$@"
EOF
chmod 755 /usr/local/bin/sleec-idea

cat > /usr/share/applications/sleec-idea.desktop <<EOF
[Desktop Entry]
Type=Application
Name=LEGOS-SLEEC (IntelliJ IDEA)
Comment=IntelliJ IDEA Community ${IDEA_VERSION} com o plugin Sleec
Exec=/usr/local/bin/sleec-idea %f
Icon=${IDEA_DIR}/bin/idea.svg
Terminal=false
Categories=Development;IDE;
StartupWMClass=jetbrains-idea-ce
EOF

echo "==> Verificando as dependencias Python"
"$VENV_DIR/bin/python3" -c "import z3, pysmt, textx, ordered_set, termcolor, idlelib.colorizer; print('Dependencias Python: OK')"

echo
echo "Instalacao concluida. Abra com o comando 'sleec-idea' ou pelo menu de aplicativos."
