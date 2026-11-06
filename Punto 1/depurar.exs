# Validación recursiva
# Recibe [{n_linea, texto, {:ok, %Conexion{}} | {:error, _}}]
# Devuelve {[{n_linea, %Conexion{}}] conservadas, [mensajes de depuración]}
defmodule Depurar do
  def depurar(lista), do: depurar(lista, [], [])

  defp depurar([], ok, msgs), do: {ok, msgs}
  defp depurar([{_, _, {:error, _}} | r], ok, msgs), do: depurar(r, ok, msgs)

  defp depurar([{i, l, {:ok, c}} | r], ok, msgs) do
    case revisar(c, buscar(ok, c)) do
      :ok -> depurar(r, ok ++ [{i, c}], msgs)
      motivo -> depurar(r, ok, msgs ++ ["Línea #{i}: #{l} -> #{motivo}"])
    end
  end

  defp revisar(%{origen: o, destino: o}, _), do: "conecta una ciudad consigo misma; se descarta"
  defp revisar(_, nil), do: :ok
  defp revisar(%{distancia: d}, {j, %{distancia: d}}), do: "repetida (línea #{j}); se descarta"

  defp revisar(_, {j, k}),
    do: "distancia distinta a la de la línea #{j} (#{k.distancia}); se conserva la de la línea #{j}"

  # Busca una conexión ya conservada entre el mismo par (en cualquier sentido)
  defp buscar([], _), do: nil

  defp buscar([{j, k} | r], c) do
    if {k.origen, k.destino} in [{c.origen, c.destino}, {c.destino, c.origen}],
      do: {j, k},
      else: buscar(r, c)
  end
end
