defmodule Liquid.Variable do
  @moduledoc """
    Module to create and lookup for Variables
  """

  defstruct name: nil, literal: nil, filters: [], parts: []
  alias Liquid.{Appointer, Filters, Variable, Context}

  @doc """
    resolves data from `Liquid.Variable.parse/1` and creates a variable struct
  """
  def create(markup) when is_binary(markup) do
    [name | filters] = markup |> parse()
    name = String.trim(name)
    variable = %Liquid.Variable{name: name, filters: filters}
    parsed = Appointer.parse_name(name)
    Map.merge(variable, parsed)
  end

  @doc """
  Assigns context to variable and than applies all filters
  """
  def lookup(%Variable{} = v, %Context{} = context) do
    {ret, filters} = Appointer.assign(v, context)
    try do
      filters |> Filters.filter(ret) |> apply_global_filter(context)
    rescue
      e in UndefinedFunctionError -> e.reason
      e in ArgumentError -> e.message
      e in ArithmeticError -> "Liquid error: #{e.message}"
    end
  end

  defp apply_global_filter(input, %Context{global_filter: nil}), do: input
  defp apply_global_filter(input, %Context{global_filter: global_filter}), do: global_filter.(input)

  @doc """
  Parses the markup to a list of filters
  """
  def parse(markup) when is_binary(markup) do
    parsed_variable = if markup != "" do
      Liquid.filter_parser()
        |> Regex.scan(markup)
        |> List.flatten()
        |> Enum.map(&String.trim/1)
    else
      [""]
    end

    if hd(parsed_variable) == "|" or hd(Enum.reverse(parsed_variable)) == "!" do
      raise Liquid.SyntaxError, message: "You cannot use an empty filter"
    end

    [name | filters] = Enum.filter(parsed_variable, &(&1 != "|"))

    filters = parse_filters(filters)
    [name | filters]
  end

  defp parse_filters(filters) do
    for markup <- filters do
      [_, filter] = ~r/\s*(\w+)/ |> Regex.scan(markup) |> hd()
      args = Liquid.filter_arguments()
      |> Regex.scan(markup)
      |> List.flatten()
      |> Liquid.List.even_elements()

      [String.to_atom(filter), args]
    end
  end
end
