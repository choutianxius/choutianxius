#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

usage() {
    cat <<'EOF'
Usage: ./make.sh [OPTIONS]

Build the resume PDF using pdflatex.

Options:
  --docker    Run the build inside a texlive Docker container
  --clean, -c Remove build artifacts
  --help, -h  Show this help message

Examples:
  ./make.sh              Build the PDF
  ./make.sh --docker     Build using Docker (no local TeX installation needed)
  ./make.sh --clean      Clean build artifacts
EOF
}

if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    usage
    exit 0
fi

if [ "$1" == "--docker" ]; then
    if [ -f /.dockerenv ]; then
        echo "Error: --docker cannot be used inside a container." >&2
        exit 1
    fi
    shift
    docker run --rm -v "$SCRIPT_DIR:/workdir" -w /workdir texlive/texlive:latest ./make.sh "$@"
    exit $?
fi

if [ "$1" == "--clean" ] || [ "$1" == "-c" ]; then
    rm -f "$SCRIPT_DIR"/mycv.{aux,fls,log,out,pdf,synctex.gz,fdb_latexmk}
elif [ $# -eq 0 ]; then
    if ! command -v pdflatex &> /dev/null; then
        echo "Error: pdflatex is not available. Try: ./make.sh --docker" >&2
        exit 1
    fi
    pdflatex -synctex=1 -interaction=nonstopmode -file-line-error -recorder "$SCRIPT_DIR/mycv.tex"
else
    usage >&2
    exit 1
fi
