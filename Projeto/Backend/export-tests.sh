#!/bin/bash

# Gera um relatório de testes em arquivo texto formatado
# Opções:
#   -n | --no-run   Não executa os testes, apenas exporta os últimos relatórios
#   -o | --output   Nome do arquivo de saída
#   -h | --help     Mostra ajuda

set -euo pipefail

OUTPUT_FILE="tests-report-$(date +%Y%m%d-%H%M%S).txt"
RUN_TESTS=true

print_help() {
  cat <<EOF
Uso: $0 [opções]

Gera um snapshot textual dos resultados de testes Maven (Surefire) com formatação legível.

Opções:
  -n, --no-run       Não executa testes; exporta o que estiver em target/surefire-reports
  -o, --output ARQ   Define nome do arquivo de saída (default: tests-report-<timestamp>.txt)
  -h, --help         Exibe esta ajuda

Exemplos:
  $0                Executa testes no Docker e exporta
  $0 -n             Apenas exporta os últimos resultados (sem rodar)
  $0 -o saida.txt   Salva em saida.txt
EOF
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--no-run)
      RUN_TESTS=false
      shift
      ;;
    -o|--output)
      OUTPUT_FILE="${2:-}"
      if [[ -z "$OUTPUT_FILE" ]]; then
        echo "Erro: --output requer um nome de arquivo" >&2
        exit 1
      fi
      shift 2
      ;;
    -h|--help)
      print_help
      exit 0
      ;;
    *)
      echo "Opção desconhecida: $1" >&2
      echo "Use --help para ajuda." >&2
      exit 1
      ;;
  esac
done

TEST_EXIT_CODE=0

# Executa testes no Docker (igual ao run-tests.sh), salvando relatórios em target/surefire-reports
if [[ "$RUN_TESTS" == true ]]; then
  echo "🚀 Executando testes no Docker..."
  docker run --rm --network gerenciador-net --env-file .env \
    -v "$(pwd)":/workspace-src:ro \
    -v "$(pwd)/target":/workspace-output \
    maven:3.9.7-eclipse-temurin-21-jammy \
    bash -c '
      mkdir -p /tmp/build
      cp -r /workspace-src/* /tmp/build/ 2>/dev/null || true
      cd /tmp/build
      mvn -q clean test
      TEST_CODE=$?
      mkdir -p /workspace-output/surefire-reports
      cp -r target/surefire-reports/* /workspace-output/surefire-reports/ 2>/dev/null || true
      exit $TEST_CODE
    '
  TEST_EXIT_CODE=$?
fi

{
  echo "╔════════════════════════════════════════════════════════════════╗"
  echo "║                 RELATÓRIO DE TESTES - GERENCIADOR             ║"
  echo "║                  Data: $(date '+%d/%m/%Y %H:%M:%S')                  ║"
  if [[ "$RUN_TESTS" == true ]]; then
    echo "║             (Testes executados antes da exportação)            ║"
  else
    echo "║                (Exportando últimos relatórios locais)          ║"
  fi
  echo "╚════════════════════════════════════════════════════════════════╝"
  echo ""

  if [ -d "target/surefire-reports" ]; then
    TOTAL_TESTS=0
    TOTAL_FAILURES=0
    TOTAL_ERRORS=0
    TOTAL_SKIPPED=0
    TOTAL_TIME=0

    echo "🧪 ═══════════════════ CLASSES DE TESTE ═══════════════════"
    for file in target/surefire-reports/TEST-*.xml; do
      if [ -f "$file" ]; then
        TEST_CLASS=$(basename "$file" .xml | sed 's/TEST-//' | sed 's/com.gerenciador.eventos.//')
        TESTS=$(grep -oP 'tests="\K[0-9]+' "$file" | head -1)
        FAILURES=$(grep -oP 'failures="\K[0-9]+' "$file" | head -1)
        ERRORS=$(grep -oP 'errors="\K[0-9]+' "$file" | head -1)
        SKIPPED=$(grep -oP 'skipped="\K[0-9]+' "$file" | head -1)
        TIME=$(grep -oP 'time="\K[0-9.]+' "$file" | head -1)

        TOTAL_TESTS=$((TOTAL_TESTS + TESTS))
        TOTAL_FAILURES=$((TOTAL_FAILURES + FAILURES))
        TOTAL_ERRORS=$((TOTAL_ERRORS + ERRORS))
        TOTAL_SKIPPED=$((TOTAL_SKIPPED + SKIPPED))
        TIME_CLEAN=$(echo "$TIME" | tr ',' '.')
        TOTAL_TIME=$(echo "$TOTAL_TIME + $TIME_CLEAN" | bc -l)

        if [ "$FAILURES" == "0" ] && [ "$ERRORS" == "0" ]; then
          echo "  ✅ $TEST_CLASS: $TESTS testes (${TIME}s)"
        else
          echo "  ❌ $TEST_CLASS: $TESTS testes - $FAILURES falhas, $ERRORS erros (${TIME}s)"
        fi
      fi
    done

    echo ""
    echo "📊 ═══════════════════ RESUMO ═══════════════════"
    TOTAL_SUCCESS=$((TOTAL_TESTS - TOTAL_FAILURES - TOTAL_ERRORS - TOTAL_SKIPPED))
    echo "  • Testes: $TOTAL_TESTS"
    echo "  • ✅ Sucesso: $TOTAL_SUCCESS"
    if [ $TOTAL_FAILURES -gt 0 ]; then
      echo "  • ❌ Falhas: $TOTAL_FAILURES"
    fi
    if [ $TOTAL_ERRORS -gt 0 ]; then
      echo "  • ⚠️  Erros: $TOTAL_ERRORS"
    fi
    if [ $TOTAL_SKIPPED -gt 0 ]; then
      echo "  • ⊘ Ignorados: $TOTAL_SKIPPED"
    fi
  # Formatar TOTAL_TIME com 3 casas (força locale C e tolera falhas)
  TOTAL_TIME_FMT=$(LC_ALL=C printf '%.3f' "$TOTAL_TIME" 2>/dev/null || echo "$TOTAL_TIME")
    echo "  • ⏱️  Tempo: ${TOTAL_TIME_FMT}s"

    echo ""
    echo "🗂️  Relatórios completos: target/surefire-reports/"
  else
    echo "⚠️  Nenhum relatório de teste encontrado em target/surefire-reports."
    echo "    Execute os testes ou remova a opção --no-run."
  fi

  echo ""
  echo "╔════════════════════════════════════════════════════════════════╗"
  if [ ${TEST_EXIT_CODE:-0} -eq 0 ]; then
    echo "║                RESULTADO: TODOS OS TESTES PASSARAM            ║"
  else
    echo "║                RESULTADO: ALGUNS TESTES FALHARAM              ║"
  fi
  echo "╚════════════════════════════════════════════════════════════════╝"
} > "$OUTPUT_FILE"

echo "✅ Relatório de testes gerado: $OUTPUT_FILE"

# Código de saída reflete o resultado dos testes (se foram executados)
exit ${TEST_EXIT_CODE:-0}
