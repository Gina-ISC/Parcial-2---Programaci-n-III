defmodule Buscador do
  @dirs [{0, 1, "derecha"}, {0, -1, "izquierda"}, {1, 0, "abajo"}, {-1, 0, "arriba"},
         {1, 1, "abajo-derecha"}, {1, -1, "abajo-izquierda"},
         {-1, 1, "arriba-derecha"}, {-1, -1, "arriba-izquierda"}]

  #sopa, lista de filas
  def mapa([], _, m), do: m
  def mapa([fila | resto], f, m), do: mapa(resto, f + 1, columnas(fila, f, 0, m))

  defp columnas([], _, _, m), do: m
  defp columnas([l | r], f, c, m), do: columnas(r, f, c + 1, Map.put(m, {f, c}, l))

  #validación previa + búsqueda
  def resolver(m, palabra) do
    letras = String.graphemes(palabra)

    case faltan(Map.to_list(contar(letras, %{})), contar(Map.values(m), %{})) do
      {[], []} ->
        case filas(m, letras, 0) do
          [] -> {:error, "no aparece en la sopa"}
          formas -> {:ok, formas}
        end

      {sin, poca} ->
        {:error, "descartada: " <> motivo(sin, poca)}
    end
  end

  defp contar([], acc), do: acc
  defp contar([l | r], acc), do: contar(r, Map.update(acc, l, 1, &(&1 + 1)))

  #letras que la sopa no tiene, letras que la sopa tiene en cantidad insuficiente
  defp faltan([], _), do: {[], []}

  defp faltan([{l, n} | r], sopa) do
    {sin, poca} = faltan(r, sopa)

    case Map.get(sopa, l, 0) do
      d when d >= n -> {sin, poca}
      0 -> {[l | sin], poca}
      d -> {sin, ["necesita #{n} #{l} y la sopa solo tiene #{d}" | poca]}
    end
  end

  defp motivo([], poca), do: unir(poca)
  defp motivo(sin, []), do: "la sopa no tiene " <> unir(sin)
  defp motivo(sin, poca), do: "la sopa no tiene " <> unir(sin) <> "; " <> unir(poca)

  defp unir([x]), do: x
  defp unir([x | r]), do: x <> ", " <> unir(r)

  #nivel 1: filas
  defp filas(m, letras, f) do
    if Map.has_key?(m, {f, 0}),
      do: cols(m, letras, f, 0) ++ filas(m, letras, f + 1),
      else: []
  end

  #nivel 2: columnas de la fila
  defp cols(m, letras, f, c) do
    if Map.has_key?(m, {f, c}),
      do: dirs(m, letras, {f, c}, @dirs) ++ cols(m, letras, f, c + 1),
      else: []
  end

  #nivel 3, las 8 direcciones desde cada inicio
  defp dirs(_, _, _, []), do: []

  defp dirs(m, letras, pos, [{df, dc, nombre} | resto]) do
    otras = dirs(m, letras, pos, resto)

    case coincide(m, letras, pos, {df, dc}) do
      nil -> otras
      coords -> [{coords, nombre} | otras]
    end
  end

  #nivel 4, letra por letra; devuelve las coordenadas o nil
  defp coincide(_, [], _, _), do: []

  defp coincide(m, [l | r], {f, c}, {df, dc} = d) do
    if Map.get(m, {f, c}) == l do
      case coincide(m, r, {f + df, c + dc}, d) do
        nil -> nil
        cola -> [{f, c} | cola]
      end
    end
  end
end
