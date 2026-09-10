#!/usr/bin/env bash
#
# Compila as versões em português e em inglês da proposta Precision-AMR (APR/FAPESP).
#
# Uso:
#   ./build.sh              compila as duas versões
#   ./build.sh pt           compila apenas a versão em português
#   ./build.sh en           compila apenas a versão em inglês
#   ./build.sh --keep       mantém os arquivos auxiliares (para depurar erros LaTeX)
#   ./build.sh pt --keep    combina as duas coisas
#
# Os documentos usam a fonte Arial via fontspec, o que exige XeLaTeX (não pdflatex).

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

KEEP_AUX=0
LANGS=()

for arg in "$@"; do
    case "$arg" in
        pt|en)      LANGS+=("$arg") ;;
        --keep)     KEEP_AUX=1 ;;
        -h|--help)  sed -n '3,13p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *)          echo "erro: argumento desconhecido '$arg' (use pt, en ou --keep)" >&2; exit 2 ;;
    esac
done

# Sem idioma explícito, compila os dois.
if [ ${#LANGS[@]} -eq 0 ]; then
    LANGS=(pt en)
fi

command -v latexmk >/dev/null 2>&1 || { echo "erro: latexmk não encontrado no PATH" >&2; exit 1; }
command -v xelatex >/dev/null 2>&1 || { echo "erro: xelatex não encontrado no PATH" >&2; exit 1; }

FAILED=0

for lang in "${LANGS[@]}"; do
    dir="$ROOT/src/$lang"
    job="mixed-precision-amr-$lang"

    if [ ! -f "$dir/$job.tex" ]; then
        echo "erro: $dir/$job.tex não encontrado" >&2
        FAILED=1
        continue
    fi

    echo "==> compilando $lang ($job.tex)"

    # latexmk cuida das múltiplas passadas: xelatex -> bibtex -> xelatex -> xelatex
    if ! (cd "$dir" && latexmk -xelatex -interaction=nonstopmode -halt-on-error "$job.tex" >/dev/null 2>&1); then
        echo "    FALHOU. Últimas linhas do log:" >&2
        [ -f "$dir/$job.log" ] && grep -E "^!|^l\.[0-9]+" "$dir/$job.log" | head -20 >&2
        echo "    log completo em: src/$lang/$job.log (rode com --keep para preservá-lo)" >&2
        FAILED=1
        continue
    fi

    # Citações e referências não resolvidas não quebram a compilação, mas invalidam o PDF.
    if grep -qiE "undefined (citation|reference)|LaTeX Warning: (Citation|Reference)" "$dir/$job.log"; then
        echo "    AVISO: há citações ou referências indefinidas:" >&2
        grep -iE "undefined (citation|reference)|LaTeX Warning: (Citation|Reference)" "$dir/$job.log" | sort -u | head -10 >&2
        FAILED=1
    fi

    pages=""
    if command -v pdfinfo >/dev/null 2>&1; then
        pages="$(pdfinfo "$dir/$job.pdf" 2>/dev/null | awk '/^Pages:/{print $2}')"
    fi
    refs=""
    if [ -f "$dir/$job.bbl" ]; then
        refs="$(grep -c '\\bibitem' "$dir/$job.bbl" 2>/dev/null)"
    fi

    msg="    OK -> src/$lang/$job.pdf"
    [ -n "$pages" ] && msg="$msg (${pages} páginas"
    [ -n "$pages" ] && [ -n "$refs" ] && msg="$msg, ${refs} referências"
    [ -n "$pages" ] && msg="$msg)"
    echo "$msg"

    if [ "$KEEP_AUX" -eq 0 ]; then
        (cd "$dir" && latexmk -c "$job.tex" >/dev/null 2>&1; rm -f "$job.bbl" "$job.xdv")
    fi
done

if [ "$FAILED" -ne 0 ]; then
    echo "==> concluído com problemas" >&2
    exit 1
fi

echo "==> tudo certo"
