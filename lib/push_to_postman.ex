defmodule PushToPostman do
  @moduledoc """
  Postman Integration to maintain Tests collection data upon deployment.

  PushToPostman.push("/Users/fatimamohamed/Projects/ex_api_spec_converter/test/resources/swagger.json", "test converter", "testing converter", "
  6330228-0219bd9a-b33d-41ad-b3dc-aeeb68585477", "63173c61-edcf-4aea-9433-2379b3cb3f20", "test_converter", "PMAK-6303088fb0f30e5304789fb1-c0c2ed23188066
  9bc3171e9016b1d256f4")

  """

  import ExApiSpecConverter
  import Helpers

  @postman_api_host "https://api.getpostman.com"

  def push(filepath, coll_name, coll_descr, coll_uid, coll_id, env_name, api_key) do
    environment_template(env_name)
    # get current environment variables
    {:ok, current_env} = request("get", "environments", coll_uid, api_key)
    updated_env =
      current_env
      |> replace_schema
      |> fill_template(environment_template(env_name))
      |> Poison.encode!

    # updated current test environment variables to include generated schema
    request("put", "environments", coll_uid, api_key, updated_env, request_headers())

    # update documentation collection
    doc_collection =
      filepath
      |> ExApiSpecConverter.convert(coll_id, coll_name, coll_descr)
      |> Poison.encode!

    request("put", "collections", coll_uid, api_key, doc_collection, request_headers())
  end

  defp replace_schema(current_env) do
    current_env["values"]
      |> Kernel.update_in([Access.filter(&(&1["key"] == "schema_defs")), "value"],
        fn _ -> Poison.encode!(Helpers.schema_map())
      end)
  end

  defp fill_template(updated_values, env_template) do
    env_template[:environment][:values]
      |> Kernel.update_in(fn _ -> updated_values end)
  end

  defp request(method, resource, opts, api_key, body \\ [], headers \\ []) do
    resource
    |> build_url(opts, api_key)
    |> crud_action(method, body, headers)
    |> parse_response(resource |> String.slice(0..-2))
  end

  defp crud_action(endpoint, "get", body, headers),
    do: HTTPoison.get(endpoint, body, headers)
  defp crud_action(endpoint, "put", body, headers),
    do: HTTPoison.request("put", endpoint, body, headers, [recv_timeout: 90_000, timeout: 90_000])

  defp build_url(page, opts, api_key) do
    "#{@postman_api_host}/#{page}/#{opts}?apikey=#{api_key}"
  end

  def environment_template(env_name), do: %{ "environment": %{ "name": env_name, "values": []}}
  defp request_headers, do: [{"Content-Type", "application/json"}]

end
