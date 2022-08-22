defmodule ExApiSpecConverterTest do
  use ExUnit.Case

  doctest ExApiSpecConverter

  @api_specs_path Path.join(~w(. test swagger.json))

  @postman_id "1"
  @coll_name "Hi, this is the name"
  @coll_descr "Yo, this is a description"

  test "ensure swagger2 is converted to postman specs properly" do
    converted = ExApiSpecConverter.convert(@api_specs_path, @postman_id, @coll_name, @coll_descr)

    assert converted.collection.info._postman_id === @postman_id
    assert converted.collection.info.name === @coll_name
    assert converted.collection.info.description === @coll_descr

    assert converted.collection.info.schema ===
             "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"

    assert Enum.count(converted.collection.item) === 1

    unit_item = hd(converted.collection.item)
    assert unit_item.name === "Units"
    assert unit_item.description === "Folder for Units"

    assert Enum.count(unit_item.item) === 1

    endpoint = hd(unit_item.item)
    assert endpoint.name === "Send Confirmation Email"
    assert endpoint.request.body === %{mode: "raw"}

    assert endpoint.request.description =~
             "Sends the activation email to all residents in the unit"

    assert endpoint.request.method === "POST"

    assert endpoint.request.url.raw ===
             "https://api-stage.zego.io/api/units/{unit_id}/send-confirmation"

    assert Enum.count(endpoint.response) === 4
  end

  test "Make sure sorting docs alphabetically works properly" do
    input = %{
      "The Killers" => [
        %{name: "Mr. Brigtside"},
        %{name: "Somebody Told Me"},
        %{name: "Midnight Show"}
      ],
      "Jackson Five" => [%{name: "abc"}, %{name: "easy as 123"}],
      "Bob Esponga" => [%{name: "Sandy"}, %{name: "Patrick"}, %{name: "Krabs"}, %{name: "Gary"}]
    }

    output = ExApiSpecConverter.alphabetize_requests(input)
    {"Bob Esponga", first_inners} = Enum.at(output, 0)
    {"Jackson Five", second_inners} = Enum.at(output, 1)
    {"The Killers", third_inners} = Enum.at(output, 2)

    assert Enum.at(first_inners, 0).name === "Gary"
    assert Enum.at(first_inners, 1).name === "Krabs"
    assert Enum.at(first_inners, 2).name === "Patrick"
    assert Enum.at(first_inners, 3).name === "Sandy"
    assert Enum.at(second_inners, 0).name === "abc"
    assert Enum.at(second_inners, 1).name === "easy as 123"
    assert Enum.at(third_inners, 0).name === "Midnight Show"
    assert Enum.at(third_inners, 1).name === "Mr. Brigtside"
    assert Enum.at(third_inners, 2).name === "Somebody Told Me"
  end
end
