defmodule Identicon do
  @moduledoc """
  Generate an ident image icon for a given string, usually a person's name.
  """

  @doc """
  Entry point of module, to provide the name of the person.

  ## Examples

      iex> Identicon.name("richard")

  """
  def main(name) do
    name
    |> hash_input
    |> pick_colour
    |> build_grid
    |> remove_odd_squares
    |> build_pixel_map
    |> draw_image
    |> save_image(name)
  end

  def hash_input(input) do
    hash = :crypto.hash(:md5, input)
    |> :binary.bin_to_list

    %Identicon.Image{seed: hash}
  end

  def pick_colour(%Identicon.Image{seed: [r, g, b | _tail]} = image) do
    %Identicon.Image{image | colour: {r, g, b}}
  end

  def build_grid(%Identicon.Image{seed: seed_list} = image) do
    grid = 
      seed_list
      |> Enum.chunk(3)
      |> Enum.map(&mirror_row/1)
      |> List.flatten
      |> Enum.with_index

    %Identicon.Image{image | grid: grid}
  end

  def mirror_row(row) do
    # [145, 66, 200] becomes
    # [145, 66, 200, 66, 145]
    [_rev_head | rev_tail] = Enum.reverse(row)
    row ++ rev_tail
  end

  def remove_odd_squares(%Identicon.Image{grid: grid} = image) do
    new_grid = 
      Enum.filter grid, fn({code, _index}) -> 
        rem(code, 2) == 0
      end

    %Identicon.Image{image | grid: new_grid}
  end

  def build_pixel_map(%Identicon.Image{grid: grid} = image) do
    pixel_map = 
      Enum.map grid, fn({_code, index}) ->
        x = rem(index, 5) * 50
        y = div(index, 5) * 50
        top_left = {x, y}
        bottom_right = {x + 50, y + 50}
        {top_left, bottom_right}
      end

    %Identicon.Image{image | pixel_map: pixel_map}
  end

  def draw_image(%Identicon.Image{colour: colour, pixel_map: pixel_map}) do
    image = :egd.create(250, 250)
    fill = :egd.color(colour)

    Enum.each pixel_map, fn({start, stop}) ->
      :egd.filledRectangle(image, start, stop, fill)
    end

    :egd.render(image)
  end

  def save_image(image, name) do
    File.write("#{name}.png", image)
  end
  
end
