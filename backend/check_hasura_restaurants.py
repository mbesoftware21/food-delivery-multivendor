import requests
import json

url = "http://localhost:8080/v1/graphql"
query = """
query {
  restaurantsPaginated(args: {page: 1, limit: 10}) {
    data
    totalCount
  }
}
"""

try:
    response = requests.post(url, json={"query": query})
    print(json.dumps(response.json(), indent=2))
except Exception as e:
    print(f"Error: {e}")
