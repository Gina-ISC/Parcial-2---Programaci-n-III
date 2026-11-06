Code.require_file("structs.exs", __DIR__)
Code.require_file("depurar.exs", __DIR__)

defmodule Rutas do
  def main do
    faltante = Enum.find(["conexiones.csv", "consultas.txt"], &(!File.exists?(p(&1))))
    if faltante, do: IO.puts("Error: no existe el archivo #{faltante}"), else: correr()
  end

  defp correr do
    todas =
      p("conexiones.csv")
      |> lineas()
      |> Stream.map(fn {i, l} -> {i, l, Conexion.parse(l)} end)
      |> Enum.to_list()

    todas
    |> Stream.filter(&match?({_, _, {:error, _}}, &1))
    |> Stream.map(fn {i, l, {:error, m}} -> "Línea #{i}: #{l} -> #{m}" end)
    |> escribir("errores_conexiones.txt")

    {validas, descartes} = Depurar.depurar(todas)
    escribir(descartes, "depuracion_conexiones.txt")

    grafo =
      Enum.reduce(validas, %{}, fn {_, c}, g ->
        g |> agregar(c.origen, c.destino, c.distancia) |> agregar(c.destino, c.origen, c.distancia)
      end)

    res =
      p("consultas.txt")
      |> lineas()
      |> Stream.map(fn {_, l} -> Enum.map(String.split(l, ","), &String.trim/1) end)
      |> Stream.filter(&match?([_, _], &1))
      |> Enum.map(&resolver(&1, grafo))

    res |> Stream.flat_map(&elem(&1, 0)) |> escribir("alcance.txt")
    res |> Stream.flat_map(&elem(&1, 1)) |> Stream.each(&IO.puts/1) |> escribir("rutas_encontradas.txt")
  end

  defp resolver([o, d], g) do
    cab = "=== #{o} -> #{d} ==="
    faltan = Enum.reject([o, d], &Map.has_key?(g, &1))

    if faltan != [] do
      {[], [cab, "Ciudad inexistente en el grafo: " <> Enum.join(faltan, ", ")]}
    else
      # Stream infinito de conjuntos alcanzables; se consume hasta que un paso repite al anterior
      pares =
        Stream.iterate([o], &expandir(&1, g))
        |> Stream.chunk_every(2, 1)
        |> Stream.take_while(fn [a, b] -> a != b end)
        |> Enum.to_list()

      pasos = Enum.map(pares, &hd/1) ++ [pares |> List.last() |> List.last()]

      alc =
        ["--- Alcance desde #{o} ---"] ++
          (pasos |> Enum.with_index() |> Enum.map(fn {s, i} -> "Paso #{i}: #{Enum.join(s, ", ")}" end)) ++
          ["Se estabiliza en el paso #{length(pasos) - 1}"]

      if d in List.last(pasos),
        do: {alc, [cab | informe(rutas(g, o, d, [o], 0))]},
        else: {alc, [cab, "Sin rutas: #{d} no es alcanzable desde #{o}"]}
    end
  end

  defp expandir(s, g),
    do: s |> Enum.flat_map(fn c -> [c | Enum.map(g[c], &elem(&1, 0))] end) |> Enum.uniq() |> Enum.sort()

  # cam = ciudades visitadas (la actual al frente, en orden inverso)
  defp rutas(_, d, d, cam, dist), do: [%Ruta{ciudades: Enum.reverse(cam), distancia: dist}]

  defp rutas(g, c, d, cam, dist) do
    g[c]
    |> Enum.reject(fn {v, _} -> v in cam end)
    |> Enum.flat_map(fn {v, w} -> rutas(g, v, d, [v | cam], dist + w) end)
  end

  defp informe(rs) do
    (rs |> Enum.with_index(1) |> Enum.map(fn {r, i} -> "Ruta #{i}: #{fmt(r)} (#{length(r.ciudades)} ciudades, #{r.distancia} km)" end)) ++
      ["Número de rutas: #{length(rs)}"] ++
      Enum.map(menor(rs, &length(&1.ciudades)), &"Ruta más corta: #{fmt(&1)}") ++
      Enum.map(menor(rs, & &1.distancia), &"Ruta de menor distancia: #{fmt(&1)} (#{&1.distancia} km)")
  end

  defp menor(rs, f), do: Enum.filter(rs, &(f.(&1) == f.(Enum.min_by(rs, f))))
  defp fmt(r), do: Enum.join(r.ciudades, " -> ")
  defp agregar(g, a, b, d), do: Map.update(g, a, [{b, d}], &(&1 ++ [{b, d}]))
  defp p(nombre), do: Path.join(__DIR__, nombre)

  # Líneas numeradas desde 1, sin vacías ni comentarios, de forma perezosa
  defp lineas(ruta) do
    ruta
    |> File.stream!()
    |> Stream.with_index(1)
    |> Stream.map(fn {l, i} -> {i, String.trim(l)} end)
    |> Stream.reject(fn {_, l} -> l == "" or String.starts_with?(l, "#") end)
  end

  # Escribe línea por línea (reemplaza el archivo si ya existe)
  defp escribir(lineas, nombre) do
    lineas |> Stream.map(&(&1 <> "\n")) |> Stream.into(File.stream!(p(nombre))) |> Stream.run()
  end
end

Rutas.main()
