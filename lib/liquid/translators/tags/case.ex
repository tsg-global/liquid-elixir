defmodule Liquid.Translators.Tags.Case do
  @moduledoc """
  Translate new AST to old AST for the Case tag.
  """
  alias Liquid.Translators.Markup
  alias Liquid.Combinators.Tags.Case
  alias Liquid.{NimbleTranslator, Block, Variable, Case}

  @doc """
  Takes the markup of the new AST, creates a `Liquid.Block` struct (old AST) and fill the keys needed to render a Case tag.
  """
  @spec translate(Case.markup()) :: Block.t()
  def translate([condition, {:body, _} | when_list]) do
    to_case_block(Markup.literal(condition), Enum.flat_map(when_list, &process_clauses/1))
  end

  defp process_clauses({:when, [condition, body: values]}) do
    tag = %Liquid.Tag{
      name: :when,
      markup: Markup.literal(condition)
    }

    result = NimbleTranslator.process_node(values)
    [tag, result]
  end

  defp process_clauses({:else, [body: values]}) do
    process_list = NimbleTranslator.process_node(values)

    else_liquid_tag = %Liquid.Tag{name: :else}

    if is_list(process_list) do
      [else_liquid_tag | process_list]
    else
      [else_liquid_tag, process_list]
    end
  end

  defp create_block_for_case(markup, when_alone) do
    nodelist = Enum.flat_map(when_alone, &when_to_nodelist/1)
    to_case_block(markup, nodelist)
  end

  defp create_block_for_case(markup, when_tag, else_tag_values) when is_list(when_tag) do
    nodelist = Enum.flat_map(when_tag, &when_to_nodelist/1)
    nodelist_plus_else = List.flatten([nodelist | else_tag(else_tag_values)])
    to_case_block(markup, nodelist_plus_else)
  end

  defp create_block_for_case(markup, literal, when_tag) do
    nodelist_when = Enum.flat_map(when_tag, &when_to_nodelist/1)
    full_list = List.flatten([literal | nodelist_when])
    to_case_block(markup, full_list)
  end

  defp create_block_for_case(markup, literal, when_tag, else_tag_values) do
    nodelist_when = Enum.flat_map(when_tag, &when_to_nodelist/1)
    nodelist_plus_else = [nodelist_when | else_tag(else_tag_values)]
    full_list = List.flatten([literal | nodelist_plus_else])
    to_case_block(markup, full_list)
  end

  defp create_block_for_case_else(markup, else_tag_values) do
    nodelist = else_tag(else_tag_values)
    to_case_block(markup, nodelist)
  end

  defp create_block_for_case_else(markup, literal, else_tag_values) do
    nodelist_plus_else = else_tag(else_tag_values)
    full_list = List.flatten([literal | nodelist_plus_else])
    to_case_block(markup, full_list)
  end

  defp to_case_block(markup, nodelist) do
    [[_, name]] = Regex.scan(Case.syntax(), markup)
    Case.split(Variable.create(name), nodelist)
  end
end
