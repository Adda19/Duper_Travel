#!/usr/bin/env bash
# Gate de Flutter + Hive: protege los datos guardados en el teléfono de los usuarios.
#
# Hive guarda cada campo por su índice (@HiveField(N)) y cada modelo por su typeId. Si un agente reusa o
# renumera un índice, o edita el adaptador generado (*.g.dart) sin cambiar el modelo, la app compila y los
# tests pasan, pero los viajes que la gente ya tenía guardados se leen mal o se pierden. Este gate lo frena:
#   1. Un *.g.dart cambió pero su modelo no: el adaptador se editó a mano.
#   2. Un modelo cambió sus @HiveField pero su *.g.dart no: el adaptador quedó desactualizado.
#   3. Un índice @HiveField que ya existía en main desapareció o pasó a otro campo.
#   4. Un índice @HiveField repetido dentro del mismo modelo.
#   5. Un typeId de @HiveType repetido entre modelos.
set -uo pipefail

base="${FACTORY_BASE:-HEAD}"
changed="${FACTORY_CHANGED:-}"
problems=()

has_changed() { grep -qxF -- "$1" <<<"$changed"; }

# "N campo" por cada @HiveField(N) seguido de su declaración, de un archivo (stdin).
fields_of() {
  awk '
    match($0, /@HiveField\(([0-9]+)/) { s = substr($0, RSTART + 11); sub(/[^0-9].*/, "", s); idx = s; next }
    idx != "" && NF { line = $0; sub(/[;=].*/, "", line); n = split(line, w, " "); print idx, w[n]; idx = "" }
  '
}

while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$f" in
    *.g.dart)
      model="${f%.g.dart}.dart"
      if [ -f "$f" ] && ! has_changed "$model"; then
        problems+=("$f cambió pero $model no: los adaptadores de Hive se generan con build_runner, no se editan a mano.")
      fi
      ;;
    *.dart)
      [ -f "$f" ] && grep -q '@HiveType' "$f" || continue
      gen="${f%.dart}.g.dart"
      old_fields="$(git show "$base:$f" 2>/dev/null | fields_of | sort)"
      new_fields="$(fields_of <"$f" | sort)"
      if [ "$old_fields" != "$new_fields" ] && [ -f "$gen" ] && ! has_changed "$gen"; then
        problems+=("$f cambió sus @HiveField pero $gen no se actualizó: el adaptador quedó desactualizado.")
      fi
      # 3: cada índice viejo debe seguir existiendo con el mismo nombre de campo.
      while read -r idx name; do
        [ -n "$idx" ] || continue
        now="$(awk -v i="$idx" '$1 == i { print $2 }' <<<"$new_fields")"
        if [ -z "$now" ]; then
          problems+=("$f: el índice @HiveField($idx) ($name) desapareció. Los datos guardados con ese índice se pierden; márcalo como obsoleto en vez de borrarlo.")
        elif [ "$now" != "$name" ]; then
          problems+=("$f: @HiveField($idx) era '$name' y ahora es '$now'. Nunca reuses un índice: usa el siguiente libre.")
        fi
      done <<<"$old_fields"
      # 4: índices repetidos.
      dups="$(awk '{ print $1 }' <<<"$new_fields" | sort | uniq -d | tr '\n' ' ')"
      [ -z "$dups" ] || problems+=("$f: @HiveField repetido: $dups")
      ;;
  esac
done <<<"$changed"

# 5: typeId únicos en toda la app.
dup_types="$(grep -rhoE '@HiveType\(typeId: *[0-9]+' lib --include='*.dart' 2>/dev/null | grep -oE '[0-9]+$' | sort | uniq -d | tr '\n' ' ')"
[ -z "$dup_types" ] || problems+=("typeId de @HiveType repetido entre modelos: $dup_types")

if [ ${#problems[@]} -gt 0 ]; then
  echo "Gate Hive: este cambio puede corromper los datos que los usuarios ya tienen guardados."
  printf -- '- %s\n' "${problems[@]}"
  exit 1
fi
echo "Gate Hive: ok (índices y adaptadores consistentes)."
