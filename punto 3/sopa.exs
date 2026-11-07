Code.require_file("buscador.exs", __DIR__)

defmodule Sopa do
  def main do
    [sopa, pals, salida] =
      Enum.map(["sopa.txt", "palabras.txt", "resultado_sopa.txt"], &Path.join(__DIR__, &1))

    case Enum.reject([sopa, pals], &File.exists?/1) do
      [] -> ejecutar(sopa, pals, salida)
      faltan -> IO.puts("Error: no existe el archivo " <> Enum.map_join(faltan, ", ", &Path.basename/1))
    end
  end


  defp leer(ruta) do
    ruta
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Stream.reject(&(&1 == "" or String.starts_with?(&1, "#")))
    |> Stream.map(&String.upcase/1)
  end

  defp ejecutar(sopa, pals, salida) do
    mapa = sopa |> leer() |> Stream.map(&String.graphemes/1) |> Enum.to_list() |> Buscador.mapa(0, %{})
    res = pals |> leer() |> Enum.uniq() |> Enum.map(&{&1, Buscador.resolver(mapa, &1)})
    total = Enum.count(res, &match?({_, {:ok, _}}, &1))


    res
    |> Stream.flat_map(&bloque/1)
    |> Stream.concat(["Palabras encontradas: #{total} de #{length(res)}\n"])
    |> Stream.each(&IO.write/1)
    |> Enum.into(File.stream!(salida))
  end

  defp bloque({p, {:ok, formas}}) do
    n = length(formas)
    ["Palabra: #{p}\n", "Encontrada: Sí (#{n} #{if n == 1, do: "forma", else: "formas"})\n"] ++
      formas(formas, 1) ++ ["\n"]
  end

  defp bloque({p, {:error, motivo}}), do: ["Palabra: #{p}\n", "Encontrada: No (#{motivo})\n", "\n"]

  defp formas([], _), do: []

  defp formas([{coords, dir} | resto], n) do
    {f1, c1} = hd(coords)
    {f2, c2} = List.last(coords)
    camino = Enum.map_join(coords, " -> ", fn {f, c} -> "{#{f},#{c}}" end)

    ["Forma #{n}: comienza en {#{f1},#{c1}}, termina en {#{f2},#{c2}}, dirección #{dir}\n",
     camino <> "\n" | formas(resto, n + 1)]
  end
end

Sopa.main()
