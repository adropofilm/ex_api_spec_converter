defmodule Helpers do
  def get_paths(%{"paths" => paths}), do: paths |> Enum.into([])

  def extract_data(%{"paths" => paths, "definitions" => defs}) do
    {paths |> Enum.into([]), defs |> Enum.into([])}
  end

  def create_folder(requests, folder_name) do
    %{
      name: "#{folder_name}",
      item: requests,
      description: "Folder for #{folder_name}",
      _postman_isSubFolder: true
    }
  end

  def build_request(responses, path, method, %{
        "description" => descr,
        "summary" => name,
        "responses" => resp
      }) do
    %{
      name: name,
      request: %{
        method: String.upcase(method),
        header: [],
        body: %{
          mode: "raw"
        },
        url: %{
          raw: "https://api-stage.zego.io/api#{path}",
          protocol: "https",
          host: [
            "api-stage",
            "zego",
            "io"
          ],
          path: create_path(path)
        },
        description: descr
      },
      response: generate_resp(Enum.into(resp, []), responses)
    }
  end

  def create_response(body, status, code) do
    %{
      name: "#{code}-#{status}",
      status: status,
      code: code,
      _postman_previewlanguage: "json",
      header: [],
      cookie: [],
      body: body |> Poison.encode!()
    }
  end

  def fill_template(converted_requests, postman_id, coll_name, coll_descr) do
    %{
      collection: %{
        info: %{
          _postman_id: postman_id,
          name: coll_name,
          description: coll_descr,
          schema: "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
        },
        item: converted_requests
      }
    }
  end

  defp generate_resp(request_list, responses, response_list \\ [])
  defp generate_resp([], _responses, response_list), do: response_list

  defp generate_resp([{code, body} | tail], responses, response_list) do
    code_int = code |> String.to_integer()

    if has_body?(body) do
      if code_int in 300..599 do
        # TODO add schema key in future
        %{"description" => descr} = body

        response =
          descr
          |> get_msg
          |> build_err_schema
          |> create_response(descr, code_int)

        generate_resp(tail, responses, [response | response_list])
      else
        %{"description" => descr, "schema" => %{"$ref" => ref}} = body

        response = create_response(responses[schema_name(ref)], descr, code_int)

        generate_resp(tail, responses, [response | response_list])
      end
    else
      response = create_response(%{}, "No content", code_int)

      generate_resp(tail, responses, [response | response_list])
    end
  end

  def schema_name(schema) do
    schema
    |> String.split("#/definitions/")
    |> Enum.at(1)
  end

  def has_body?(response) do
    Map.has_key?(response, "schema")
  end

  def response_schema(%{"schema" => %{"$ref" => schema}}, responses) do
    schema_name = schema_name(schema)
    responses[schema_name]
  end

  defp create_path(path) do
    [_slash | tail] = String.split(path, "/")
    ["api" | tail]
  end

  # TODO remove after maps used for response descriptions
  defp get_msg(msg) do
    [_status | tail] = String.split(msg, " - ")
    List.to_string(tail)
  end

  defp build_err_schema(msg) do
    %{
      success: false,
      errors: %{
        details: "#{msg}"
      }
    }
  end

  def load_specs(filename) do
    filename
    |> File.read!()
    |> Poison.decode!()
  end

  def parse_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}, resource) do
    %{^resource => resource} = Poison.decode!(body)
    {:ok, resource}
  end

  def parse_response({:ok, %HTTPoison.Response{body: body, status_code: 400..599}}, _resource) do
    %{"error" => msg} = Poison.decode!(body)
    {:error, msg}
  end

  def parse_response({:ok, %HTTPoison.Response{body: body}}) do
    {:error, Poison.decode!(body)}
  end

  def parse_response({:error, %HTTPoison.Error{reason: reason}}) do
    {:error, reason}
  end
end
