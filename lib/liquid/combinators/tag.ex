defmodule Liquid.Combinators.Tag do
  @moduledoc """
  Helper to create tags
  """
  import NimbleParsec

  @doc """
  Define a block from a tag_name and, optionally, a function to parse tag parameters,
  and a function to parse the body inside the tag
  Both functions must receive a combinator and must return a combinator

  The returned tag is a combinator which expect a start tag `{%` a tag name and a end tag `%}`

  ## Examples

  Tag.define_closed(
  "comment",
  & &1,
  fn combinator ->
  combinator
  |> optional(parsec(:comment_content))
  |> reduce({Markup, :literal, []})
  end,
  ""
  """
  @spec define_closed(String.t(), fun(), fun(), String.t()) :: fun()
  def define_closed(tag_name, combinator_head \\ & &1, combinator_body \\ & &1, separator \\ " ")

  def define_closed(tag_name, combinator_head, combinator_body, separator) do
    tag_name
    |> open_tag(combinator_head, separator)
    |> combinator_body.()
    |> close_tag(tag_name)
    |> tag(String.to_atom(tag_name))
  end

  @doc """
  Define a tag from a tag_name and, optionally, a function to parse tag parameters,
  the tag and a function to parse the body inside the tag
  Both functions must receive a combinator and must return a combinator

  The returned tag is a combinator which expect a start tag `{%` a tag name and a end tag `%}`

  ## Examples

  defmodule MyParser do
  import NimbleParsec
  alias Liquid.Combinators.Tag

  def ignorable, do: Tag.define_closed(
  "ignorable",
  fn combinator -> combinator |> string("T") |> ignore() |> integer(2,2))

  MyParser.ignorable("{% ignorable T12 %}")
  #=> {:ok, {:ignorable, [12]}, "", %{}, {1, 0}, 2}
  """
  @spec define_open(String.t(), fun()) :: fun()
  def define_open(tag_name, combinator_head \\ & &1) do
    tag_name
    |> open_tag(combinator_head)
    |> tag(String.to_atom(tag_name))
  end

  def define_sub_block(tag_name, allowed_tags, combinator \\ & &1) do
    empty()
    |> parsec(:start_tag)
    |> ignore(string(tag_name))
    |> combinator.()
    |> parsec(:end_tag)
    |> tag(String.to_atom(tag_name))
    |> tag(:sub_block)
    |> traverse({__MODULE__, :check_allowed_tags, [allowed_tags]})
  end

  def define_block(tag_name, combinator_head \\ & &1, separator \\ " ")

  def define_block(tag_name, combinator_head, separator) do
    tag_name
    |> open_tag(combinator_head, separator)
    |> tag(String.to_atom(tag_name))
    |> tag(:block)
    |> traverse({__MODULE__, :store_tag_in_context, []})
  end

  def open_tag(tag_name, combinator \\ & &1, separator \\ " ")

  def open_tag(tag_name, combinator, separator) do
    empty()
    |> parsec(:start_tag)
    |> ignore(string(tag_name <> separator))
    |> combinator.()
    |> parsec(:end_tag)
  end

  def close_tag(combinator \\ empty(), tag_name) do
    combinator
    |> parsec(:start_tag)
    |> ignore(string("end" <> tag_name))
    |> parsec(:end_tag)
  end

  def store_tag_in_context(_, [{:block, [{tag_name, _}]}] = acc, %{tags: tags} = context, _, _) do
    {acc, %{context | tags: [to_string(tag_name) | tags]}}
  end

  def check_allowed_tags(_, acc, %{tags: []} = context, _, _, _) do
    tag_name = tag_name(acc)
    {[error: "Unexpected outer '#{tag_name}' tag"], context}
  end

  def check_allowed_tags(_, acc, %{tags: [tag | _]} = context, _, _, allowed_tags) do
    tag_name = tag_name(acc)

    if Enum.member?(allowed_tags, tag) do
      {acc, context}
    else
      {[
         error:
           "#{tag} does not expect #{tag_name} tag. The #{tag_name} tag is valid only inside: #{
             Enum.join(allowed_tags, ", ")
           }"
       ], context}
    end
  end

  defp tag_name([{:sub_block, [{tag, _}]}]), do: tag
  defp tag_name([{:sub_block, [tag]}]), do: tag
end
