defmodule Helpers do

  def fill_template(converted_requests, postman_id, collection_name, description) do
    %{
      collection: %{
        info: %{
          _postman_id: postman_id,
          name: collection_name,
          description: description,
          schema: "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
        },
        item: converted_requests
      }
    }
  end

  def load_specs(filename) do
    filename
    |> File.read!()
    |> Poison.decode!()
  end

end
