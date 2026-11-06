defmodule Conexion do
  defstruct [:origen, :destino, :distancia]

  def parse(linea) do
    case linea |> String.split(",") |> Enum.map(&String.trim/1) do
      [a, b, d] ->
        cond do
          a == "" or b == "" ->
            {:error, "campos faltantes (hay un campo vacío)"}

          true ->
            case Integer.parse(d) do
              {n, ""} when n < 0 -> {:error, "distancia negativa (#{n})"}
              {n, ""} -> {:ok, %Conexion{origen: a, destino: b, distancia: n}}
              _ -> {:error, "distancia no numérica (\"#{d}\")"}
            end
        end

      campos when length(campos) < 3 ->
        {:error, "campos faltantes (se esperaban 3 y hay #{length(campos)})"}

      campos ->
        {:error, "campos sobrantes (se esperaban 3 y hay #{length(campos)})"}
    end
  end
end

defmodule Ruta do
  defstruct ciudades: [], distancia: 0
end
