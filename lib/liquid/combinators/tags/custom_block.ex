defmodule Liquid.Combinators.Tags.CustomBlock do
  @moduledoc """
  Implementation of custom tag. "Blocks" are tags that take  a markup and have the a special characteristic, they have a closing tag and perform a transformation of the content between the two.
  To create a new tag, Use Liquid.Register module and register your tag with Liquid.Register.register/3.
  The register tag  takes three arguments: the user-facing name of the tag, the module where code of parsing/rendering is located
  and the type that implements it (tag or block).
  ```
   {% MyCustomTag anything here %}code submitted to transformation{% endMyCustomTag%}
  ```
  """
  import NimbleParsec
  alias Liquid.Combinators.Tags.CustomTag

  @type t :: [custom_block: CustomBlock.markup()]

  @type markup :: [
          custom_name: String.t(),
          custom_markup: String.t(),
          body: Liquid.NimbleParser.t()
        ]

  @doc """
  Parses a Custom tag of type block, creates a Keyword list where the key is `:custom_block`
  and the value is another keyword list which have a name, markup, body and end name.
  """
  @spec block() :: NimbleParsec.t()
  def block do
    opener_custom_tag()
    |> optional(parsec(:__parse__) |> tag(:body))
    |> concat(closer_custom_tag())
    |> traverse({Liquid.Combinators.Tags.CustomBlock, :check_close_tag, []})
    |> tag(:custom_block)
  end

  @doc """
  Checks if the closed tag name correspond to the opened tag name.
  """
  @spec check_close_tag(String.t(), list(), map(), tuple(), tuple()) :: tuple()
  def check_close_tag(_rest, args, context, _line, _offset) do
    tags_name = Keyword.get_values(args, :custom_name)
    [opened_name, closed_name] = tags_name

    case opened_name == "end" <> closed_name do
      true -> {fix_parse(args), context}
      false -> {:error, "#{opened_name} can be closed by  #{closed_name}"}
    end
  end

  @doc """
  Checks if the name parsed is a `Liquid` tag.
  """
  @spec check_string_closed(String.t(), list(), map(), tuple(), tuple()) :: tuple()
  def check_string_closed(_rest, args, context, _line, _offset) do
    case liquid_tags_without_customs?(args) do
      true -> {:error, "Invalid tag name"}
      false -> {args, context}
    end
  end

  defp end_name do
    valid_end_name()
    |> unwrap_and_tag(:custom_name)
  end

  defp opener_custom_tag do
    parsec(:start_tag)
    |> concat(end_name())
    |> optional(markup())
    |> parsec(:end_tag)
  end

  defp closer_custom_tag do
    parsec(:start_tag)
    |> concat(end_name())
    |> parsec(:end_tag)
  end

  defp markup do
    empty()
    |> parsec(:ignore_whitespaces)
    |> concat(valid_markup())
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:custom_markup)
  end

  defp valid_markup() do
    repeat_until(utf8_char([]), [string("{%"), string("%}"), string("{{"), string("}}")])
  end

  defp valid_end_name() do
    CustomTag.string_name()
    |> traverse({Liquid.Combinators.Tags.CustomBlock, :check_string_closed, []})
  end

  defp fix_parse(
         custom_name: _endname,
         body: body,
         custom_markup: markup,
         custom_name: name
       ),
       do: [body: body, custom_markup: markup, custom_name: name]

  defp fix_parse(custom_name: _endname, custom_markup: markup, custom_name: name),
    do: [custom_markup: markup, custom_name: name]

  defp liquid_tags_without_customs?([string])
       when string in [
              "case",
              "endcase",
              "assign",
              "decrement",
              "increment",
              "when",
              "if",
              "endif",
              "unless",
              "endunless",
              "capture",
              "endcapture",
              "raw",
              "endraw",
              "for",
              "endfor",
              "break",
              "continue",
              "ifchanged",
              "endifchanged",
              "else",
              "comment",
              "endcomment",
              "tablerow",
              "endtablerow",
              "elsif",
              ""
            ],
       do: true

  defp liquid_tags_without_customs?([_]), do: false
end
