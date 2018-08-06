defimpl String.Chars, for: Tuple do
  def to_string(elem), do: to_markup(elem)

  defp to_markup({:parts, value}) do
    value |> Enum.join(".") |> String.replace(".[", "[")
  end

  defp to_markup({:params, value}), do: ": " <> Enum.join(value, ", ")

  defp to_markup({predicate, value}) when predicate in [:for, :with],
    do: "#{predicate} #{Enum.join(value)}"

  defp to_markup({_, nil}), do: "null"

  defp to_markup({_, value}) when is_list(value), do: Enum.join(value)

  defp to_markup({_, value}), do: "#{value}"
end
