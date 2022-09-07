# ExApiSpecConverter

Elixir Based API Spec Converter that can be used with [phoenix_swagger](https://hexdocs.pm/phoenix_swagger/getting-started.html) to generate Postman collections for your API. You can also use it to extract in-line documentation to host on [Postman](https://learning.postman.com/docs/publishing-your-api/documenting-your-api/). :)

## Installation
The package can be installed by adding `ex_api_spec_converter` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_api_spec_converter, "~> 0.1.0"}
  ]
end
```

**Usage**
Convert your specs like so:
``` elixir
   ExApiSpecConverter.convert(filepath, doc_id, coll_name, coll_descr)
```
Output will be Postman V2 Collection specs.

**Assumptions**:
1. You're using [phoenix_swagger](https://hexdocs.pm/phoenix_swagger/getting-started.html) to generate your swagger 2 API specs and in-line documentation like so in your controllers:

``` elixir
def swagger_definitions do
    %{
      Book: swagger_schema do
        title "Book"
        description "Book"
        PhoenixSwagger.Schema.properties do
          genre [:string, "null"], "genre of book", example: "Fantasy", required: true
          name :string, "Name of book", example: "Harry Potter and the Chamber of Secrets", required: true
          author :string, "Author of book", example: "JK Rowling", required: true
        end
      end
    }
  end

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> :index >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  swagger_path :show do
    get "/books/:id"
    summary "Get All Books"
    produces "application/json"
    operation_id "Books"
    description(
"Returns all books.
#### Required Params
|       Field        |    Type    |                Description                 |
| ------------------ | ---------- | ------------------------------------------ |
| **id**             | String     | Book ID.                                   |

#### Optional URL Filters
|       Field        |    Type    |                Description                 |
| ------------------ | ---------- | ------------------------------------------ |
| **author**         | String     | Book Author                                |
| **genre**          | String     | Book genre  (ex: "fantasy", "youngadult"   |")
    response 200, "OK", Schema.ref(:Book)
    response 401, "Unauthorized - Unauthorized", Schema.ref(:Error)
    response 500, "Internal server error - Internal server error", Schema.ref(:Error)
  end
```


**Note on `phoenix_swagger`**
1. Postman collection folders should be defined in `swagger_path` > `operation_id`
2. Postman request description is defined in `swagger_path` > `description`
3. Postman request name is defined in `swagger_path` > `summary`
