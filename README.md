# Instalador do LEGOS-SLEEC para Linux

Instala o [LEGOS-SLEEC](https://github.com/Kevin-Kolyakov/sleec-intellij-plugin), uma ferramenta para escrever e analisar regras normativas SLEEC, em computadores Linux. Um único comando instala tudo, para todos os usuários da máquina:

- IntelliJ IDEA Community 2021.3.3 (a versão compatível com o plugin)
- o plugin Sleec
- o Python e as bibliotecas que o plugin usa para as análises (Z3, PySMT, textX)
- o comando `sleec-idea` e um atalho no menu de aplicativos

## Antes de começar

Você precisa de:

- **um Linux de 64 bits para Intel/AMD** (`x86_64`), com interface gráfica. Não funciona em processadores ARM, como Raspberry Pi.
- **uma conta com permissão de administrador**, ou seja, que consegue usar `sudo` com a própria senha
- **internet**: o instalador baixa cerca de 900 MB, a maior parte do IntelliJ
- **3 GB livres** em disco

Distribuições:

| Distribuição | Situação |
|---|---|
| Ubuntu 24.04 | testado em 5 máquinas |
| Ubuntu 22.04, Debian 12, Linux Mint, Pop!_OS, Zorin OS | deve funcionar (mesma família do Ubuntu) |
| Fedora | deve funcionar (usa `dnf`) |
| Arch Linux, Manjaro, EndeavourOS | deve funcionar (usa `pacman`) |
| openSUSE Tumbleweed | deve funcionar (usa `zypper`) |
| openSUSE Leap, CentOS 7 e outras com Python anterior ao 3.8 | não funciona: o Python do sistema é antigo demais |

O instalador descobre sozinho qual é a distribuição. Ele só instala pacotes do sistema se faltar alguma parte do Python que o plugin usa (`tkinter`, `idlelib` ou `venv`).

## Instalação

**1.** Abra o Terminal. No Ubuntu e no Mint, use `Ctrl+Alt+T`. Nas outras distribuições, procure "Terminal" no menu de aplicativos.

**2.** Copie o comando abaixo, cole no terminal (normalmente com `Ctrl+Shift+V`) e aperte `Enter`:

```bash
cd ~ && { curl -fsSL https://github.com/LucasCenturionNetto/legos-sleec-instalador/archive/refs/heads/main.tar.gz || wget -qO- https://github.com/LucasCenturionNetto/legos-sleec-instalador/archive/refs/heads/main.tar.gz; } | tar -xz && sudo bash ~/legos-sleec-instalador-main/install-sleec-linux.sh
```

O comando usa o `curl` ou o `wget`, o que existir na máquina. Se aparecer `curl: comando não encontrado`, ignore: ele passa para o `wget` sozinho.

**3.** Digite a sua senha quando pedir. Os caracteres não aparecem na tela enquanto você digita; isso é normal.

**4.** Espere. Leva de 5 a 20 minutos, dependendo da internet. O instalador mostra 5 etapas, de `[1/5]` a `[5/5]`. Durante o download do IntelliJ aparece o progresso, como linhas de pontos ou uma barra com porcentagem.

A instalação deu certo quando as últimas linhas forem:

```
Dependencias Python: OK

Instalacao concluida. Abra com o comando 'sleec-idea' ou pelo menu de aplicativos.
```

Se aparecer qualquer outra coisa no final, veja [Problemas comuns](#problemas-comuns).

## Primeiro uso

Cada usuário faz isto uma vez.

1. Abra o **LEGOS-SLEEC** pelo menu de aplicativos, ou digite `sleec-idea` no terminal.
2. Aceite o *User Agreement* e escolha se quer enviar estatísticas.
3. Na tela inicial, clique em **New Project**, escolha **Sleec Templates** e clique em **Next**.
4. Dê um nome ao projeto (por exemplo `sleec-demo`) e aperte `Enter`, ou clique em **Finish**.

Os exemplos ficam na pasta `LEGOs-master/Evaluation` do projeto: `ALMI`, `ASPEN`, `BSN` e `SAFESCADE`.

Abra sempre pelo menu ou pelo comando `sleec-idea`. O atalho é o que liga o IntelliJ ao Python das análises.

## Teste rápido

1. Na barra superior, à esquerda de **Add Configuration...**, clique no ícone **≡** (*Checks for Redundancies in Sleec Files*).
2. Selecione `LEGOs-master/Evaluation/ASPEN.sleec` e clique em **OK**.
3. Espere alguns segundos. A janela fica sem responder enquanto a análise roda.
4. O resultado aparece no painel **SleecToolWindow**, na parte de baixo. No final dele deve estar:

```
Redundant SLEEC rule:
R14 when DeployDrone and {damages} then InformKeeper
Because of the following SLEEC rule:
R14_1 when DeployDrone and {damages} then GroundDrone
R11_cont_1 when GroundDrone then InformKeeper
```

Se apareceu, está tudo funcionando.

## Como usar

O plugin tem cinco análises, nos ícones da barra superior, da esquerda para a direita:

| Ícone | Análise | O que procura |
|---|---|---|
| símbolo com alerta laranja | Situational Conflicts | um cenário em que duas regras se contradizem |
| lista com interrogação | Purpose | se os propósitos declarados são atendidos |
| exclamação vermelha | Conflicts | regras que não podem ser cumpridas juntas |
| três linhas (≡) | Redundancies | regras que já decorrem de outras |
| triângulo amarelo | Concerns | situações indesejadas que as regras permitem |

Ao clicar, o plugin pede o arquivo `.sleec`; ele não usa o arquivo aberto no editor.

Para ler o resultado, vá direto ao **final da saída**. O começo traz avisos (`UserWarning`) e o rascunho do solver (`find trace`, `vol: 5`), que podem ser ignorados. As palavras destacadas em amarelo são os trechos das regras envolvidos no problema.

## Problemas comuns

| Sintoma | O que fazer |
|---|---|
| `Falha temporária resolvendo...`, `Could not resolve host` ou `Name or service not known` | A máquina está sem internet. Confira a conexão (cabo ou Wi-Fi) e rode o comando de instalação de novo. |
| O comando de instalação termina logo com erro de `gzip` ou `tar` | O download do instalador falhou, quase sempre por falta de internet. Confira a conexão e rode de novo. |
| `não está no arquivo sudoers`, `is not in the sudoers file` ou `sudo: comando não encontrado` | Sua conta não é administradora. Peça a quem administra a máquina para rodar a instalação. No Debian sem `sudo`, quem tem a senha de root pode rodar, depois do comando de instalação: `su -c "bash $HOME/legos-sleec-instalador-main/install-sleec-linux.sh"` |
| `ERRO: processador ... nao suportado` | A máquina não é Intel/AMD de 64 bits (por exemplo, é ARM). O IntelliJ 2021.3.3 não existe para ela. |
| `ERRO: o plugin precisa de Python 3.8 ou mais novo` | A distribuição é antiga demais (por exemplo, openSUSE Leap 15 ou CentOS 7). Use uma versão mais nova da distribuição. |
| `ERRO: gerenciador de pacotes nao reconhecido` | A distribuição não usa `apt`, `dnf`, `pacman` nem `zypper`. Instale pelo gerenciador dela o Python 3 com `tkinter`, `idlelib` e `venv` e rode o comando de novo. |
| Aviso de repositório "não está assinado" ou "NO_PUBKEY" (VS Code, Docker etc.) | Pode ignorar: o instalador avisa e continua. Só acontece em Ubuntu/Debian. |
| A instalação fica parada em `[1/5]` por vários minutos | Outra atualização do sistema está rodando (por exemplo, o "Atualizador de programas" do Ubuntu). No Ubuntu/Debian o instalador espera até 10 minutos; feche o atualizador para acelerar. |
| O download do IntelliJ para de avançar | Se a internet oscilar, o instalador retoma sozinho em até 1 minuto. Se cair de vez, rode o comando de instalação de novo. |
| Diálogo "Python Not Found" ou `ModuleNotFoundError` no painel | O IntelliJ foi aberto sem o atalho. Feche e abra pelo menu ou com `sleec-idea`. |
| "Sleec Templates" não aparece em New Project | Rode o comando de instalação de novo. |
| Os ícones não aparecem na barra | Menu **View → Appearance → Toolbar**. |
| Balão vermelho "IDE error occurred" ao criar o projeto | Pode fechar: é um aviso interno do IntelliJ 2021.3, sem relação com o plugin. |
| O IntelliJ oferece atualização | Recuse. O plugin só funciona nas versões 2021.3 a 2024.3. |

Rodar o comando de instalação de novo é seguro em qualquer caso: ele reaproveita o que já foi instalado e completa o que faltou.

Para testar o Python das análises fora da IDE:

```bash
/opt/sleec-venv/bin/python3 -c "import z3, pysmt, textx, ordered_set, termcolor, idlelib.colorizer; print('OK')"
```

## Internet lenta ou várias máquinas

Para não baixar o IntelliJ (766 MB) em cada máquina:

1. Baixe uma vez `https://download.jetbrains.com/idea/ideaIC-2021.3.3.tar.gz`.
2. Baixe este repositório (botão **Code → Download ZIP** no GitHub) e descompacte.
3. Coloque o `ideaIC-2021.3.3.tar.gz` dentro da pasta descompactada, ao lado do `install-sleec-linux.sh`.
4. Leve a pasta para cada máquina (pendrive ou pasta de rede) e rode dentro dela:

```bash
sudo bash install-sleec-linux.sh
```

Com o arquivo junto, cada máquina baixa da internet só cerca de 100 MB.

## Desinstalar

```bash
sudo rm -rf /opt/idea-IC-2021.3.3 /opt/sleec-venv /usr/local/bin/sleec-idea /usr/share/applications/sleec-idea.desktop
```

As configurações e projetos de cada usuário ficam em `~/.config/JetBrains`, `~/.local/share/JetBrains`, `~/.cache/JetBrains` e `~/IdeaProjects`.

## Para quem mantém este instalador

- `SleecLanguageExtension-2.4-SNAPSHOT.zip` é o plugin compilado a partir de [Kevin-Kolyakov/sleec-intellij-plugin](https://github.com/Kevin-Kolyakov/sleec-intellij-plugin) (commit `9fd7a24`).
- Para gerar uma versão nova do plugin, no repositório do plugin, com JDK 11:

```bash
./gradlew buildPlugin
```

  O zip sai em `build/distributions/`. Substitua o arquivo deste repositório e ajuste o nome em `install-sleec-linux.sh` se a versão mudar.

O LEGOS-SLEEC foi desenvolvido por Kevin Kolyakov, Lina Marsso, Nick Feng, Junwei Quan e Marsha Chechik ([artigo](https://arxiv.org/abs/2501.12544)).
