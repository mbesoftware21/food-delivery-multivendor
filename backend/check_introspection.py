import requests
import json

url = "http://localhost:8080/v1/graphql"
query = """
query {
  __type(name: "query_root") {
    fields(includeDeprecated: true) {
      name
      args {
        name
        type {
          kind
          name
          ofType {
            kind
            name
          }
        }
      }
      type {
        kind
        name
        ofType {
          kind
          name
          ofType {
            kind
            name
            fields {
              name
              type {
                kind
                name
              }
            }
             ofType {
              kind
              name
               fields {
                name
                type {
                  kind
                  name
                }
              }
            }
          }
        }
      }
    }
  }
}
"""

response = requests.post(url, json={"query": query})
data = response.json()
# Filter for restaurantsPaginated
fields = data.get("data", {}).get("__type", {}).get("fields", [])
for f in fields:
    if f["name"] == "restaurantsPaginated":
        # print(json.dumps(f, indent=2))
        print(json.dumps(f["type"], indent=2))

