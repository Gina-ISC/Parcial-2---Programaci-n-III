defmodule Conexion do
  defstruct [:origen, :destino, :distancia]

  def parse(linea) do
    case linea |> String.split(",") |> Enum.map(&String.trim/1) do
      [a, b, d] when a != "" and b != "" ->
        case Integer.parse(d) do
          {n, ""} -> {:ok, %Conexion{origen: a, destino: b, distancia: n}}
          _ -> {:error, "distancia no numérica"}
        end

      _ ->
        {:error, "campos faltantes o sobrantes"}
    end
  end
end

defmodule Ruta do
  defstruct ciudades: [], distancia: 0
end
