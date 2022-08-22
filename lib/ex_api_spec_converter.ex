defmodule ExApiSpecConverter do
  import Helpers

  @moduledoc """
  Documentation for `ExApiSpecConverter`.
  """

  def convert(filename, doc_id, coll_name, coll_descr) do
    filename
    |> load_specs
    |> prepare_specs
    |> fill_template(doc_id, coll_name, coll_descr)
  end

  defp prepare_specs(specs) do
    {paths, schema_defs} =
      specs
      |> extract_data

    schema_defs
    |> convert_schemas
    |> convert_requests(paths)
    |> alphabetize_requests()
    |> convert_folders
  end

  def convert_schemas(schemas) do
    {objs, ref_objs, arrays} = order_schemas(schemas)

    objs
    |> prepare_schemas
    |> prepare_schemas(ref_objs)
    |> prepare_schemas(arrays)
  end

  def prepare_schemas(completed \\ %{}, schemas)

  def prepare_schemas(completed, [{name, body} | t]) do
    cond do
      body["type"] == "object" ->
        with {schema_name, body} <- build_response(name, body["properties"], completed) do
          completed
          |> Map.put(schema_name, body)
          |> prepare_schemas(t)
        end

      body["type"] == "array" ->
        if Map.has_key?(body["items"], "$ref") do
          ref_name = schema_name(body["items"]["$ref"])

          completed
          |> Map.put(body["title"], [completed[ref_name]])
          |> prepare_schemas(t)
        else
          completed
          |> Map.put(body["title"], body["example"])
          |> prepare_schemas(t)
        end
    end
  end

  def prepare_schemas(completed, []), do: completed

  def build_response(name, properties, completed) do
    prop_names = Map.keys(properties)

    {body, _refs} = populate_properties(name, properties, prop_names, completed)

    {name, body}
  end

  def order_schemas(schemas, objs \\ [], ref_objs \\ [], arrays \\ [])

  def order_schemas([{_name, body} = h | t], objs, ref_objs, arrays) do
    cond do
      body["type"] == "object" and !has_ref?(body["properties"]) ->
        order_schemas(t, [h | objs], ref_objs, arrays)

      body["type"] == "object" and has_ref?(body["properties"]) ->
        order_schemas(t, objs, [h | ref_objs], arrays)

      body["type"] == "array" ->
        order_schemas(t, objs, ref_objs, [h | arrays])
    end
  end

  def order_schemas([], objs, ref_objs, arrays) do
    {objs, ref_objs, arrays}
  end

  def populate_properties(name, schema, prop_names, completed, refs \\ %{}, body \\ %{})

  def populate_properties(name, schema, [h | t], completed, refs, body) do
    if Map.has_key?(schema[h], "$ref") do
      schema_name = schema_name(schema[h]["$ref"])

      if Map.has_key?(completed, schema_name) do
        updated_body = Map.put(body, h, completed[schema_name])
        populate_properties(h, schema, t, completed, refs, updated_body)
      else
        updated_refs = Map.put(refs, h, schema_name(schema[h]["$ref"]))
        populate_properties(name, schema, t, completed, updated_refs, body)
      end
    else
      updated_body = Map.put(body, h, schema[h]["example"])
      populate_properties(name, schema, t, completed, refs, updated_body)
    end
  end

  def populate_properties(_name, _schema, [], _completed, refs, body) do
    {body, refs}
  end

  defp convert_requests(responses, requests, converted_requests \\ %{})

  defp convert_requests(responses, [{path_str, raw_requests} | tail], converted_requests) do
    updated_requests =
      path_str
      |> map_request(raw_requests, responses)
      |> add_to_folder(get_folder_name(raw_requests), converted_requests)

    convert_requests(responses, tail, updated_requests)
  end

  defp convert_requests(_responses, [], converted_requests), do: converted_requests

  defp convert_folders(converted_requests) do
    Enum.map(converted_requests, fn {folder_name, requests} ->
      create_folder(requests, folder_name)
    end)
  end

  defp map_request(path, request_map, responses) do
    request_map
    |> Stream.map(fn {method, request_body} ->
      build_request(responses, path, method, request_body)
    end)
    |> Enum.to_list()
  end

  defp get_folder_name(request_map) do
    {_method, request} = Enum.random(request_map)
    request["operationId"]
  end

  defp add_to_folder(request_list, folder_name, converted_requests) do
    case Map.has_key?(converted_requests, folder_name) do
      true ->
        Map.put(converted_requests, folder_name, request_list ++ converted_requests[folder_name])

      false ->
        Map.put(converted_requests, folder_name, request_list)
    end
  end

  def has_ref?(body) do
    Enum.any?(body, fn {_property, body} -> Map.has_key?(body, "$ref") end)
  end

  def alphabetize_requests(converted_requests) do
    converted_requests
    |> Enum.reduce(%{}, fn {controller, routes}, acc ->
      sorted_routes = Enum.sort_by(routes, &String.downcase(&1.name), &(&1 < &2))
      Map.put(acc, controller, sorted_routes)
    end)
    |> Enum.sort(fn {first_key, _routes}, {second_key, _sec_routes} ->
      first_key < second_key
    end)
  end
end
