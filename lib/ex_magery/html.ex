defmodule ExMagery.Html do
  @boolean_attributes ~w(
    allowfullscreen
    async
    autofocus
    autoplay
    capture
    checked
    controls
    default
    defer
    disabled
    formnovalidate
    hidden
    itemscope
    loop
    multiple
    muted
    novalidate
    open
    readonly
    reversed
    required
    selected
  )

  @spec boolean_attribute?(string) :: boolean
  def boolean_attribute?(attribute_name) do
    Enum.member?(@boolean_attributes, attribute_name)
  end
end
