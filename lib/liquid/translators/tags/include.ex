defmodule Liquid.Translators.Tags.Include do
  alias Liquid.{Tag, Include}
  alias Liquid.Translators.Markup

  def translate([snippet]), do: parse("'#{Markup.literal(snippet)}'")

  def translate([snippet, rest]), do: parse("'#{Markup.literal(snippet)}' #{Markup.literal(rest)}")

  def parse(markup) do
    Include.parse(%Tag{markup: markup, name: :include})
  end
end
