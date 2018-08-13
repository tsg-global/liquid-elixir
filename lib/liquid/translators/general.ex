defmodule Liquid.Translators.General do
  @moduledoc false
  alias Liquid.Translators.Markup

  @doc """
  Returns a corresponding type value:

  Simple Value Type:
  {variable: [parts: [part: "i"]]} -> "i"
  {variable: [parts: [part: "products", part: "tittle"]]} -> "product.tittle"
  {variable: [parts: [part: "product", part: "tittle", index: 0]]} -> "product.tittle[0]"
   "string_value" -> "'string_value'"
    2 -> "2"

  Complex Value Type: {:range, [start: "any_simple_type", end: "any_simple_type"]} -> "(any_simple_type..any_simple_type)"
  """
  @spec variable_in_parts(Liquid.Combinators.LexicalToken.variable_value()) :: String.t()
  def variable_in_parts(variable) do
    Enum.map(variable, fn {key, value} ->
      case key do
        :part -> value |>  Markup.literal() |> String.replace("?", "")
        :index -> "[#{Markup.literal(value)}]"
        _ -> "[#{Markup.literal(value)}]"
      end
    end)
  end

  @doc """
  Returns true when a tuple is an Else/Elseif tag
  """
  @spec else?(tuple()) :: boolean()
  def else?({:else, _}), do: true
  def else?({:elsif, _}), do: true
  def else?(_), do: false

  @doc """
  Returns true when a tuple is and If tag
  """
  @spec not_open_if(tuple()) :: boolean()
  def not_open_if({:evaluation, _}), do: false
  def not_open_if({:else, _}), do: false
  def not_open_if({:elsif, _}), do: false
  def not_open_if(_), do: true

  @doc """
  When element is a list, returns the first value in, else returns element
  """
  @spec types_no_list(List.t()) :: String.t() | Number.t()
  def types_no_list([]), do: []

  def types_no_list(element) do
    if is_list(element), do: hd(element), else: element
  end

  def types_only_list(element) do
    if is_list(element), do: element, else: [element]
  end
end
