import json
import os
import subprocess

def update_metadata():
    # 1. Read existing metadata
    with open("current_hasura_metadata.json", "r") as f:
        metadata = json.load(f)

    # 2. Define New Custom Types
    new_input_objects = [
        {
            "name": "CreateShopTypeInput",
            "fields": [
                {"name": "name", "type": "String!"},
                {"name": "description", "type": "String"},
                {"name": "image", "type": "String"}
            ]
        },
        {
            "name": "UpdateShopTypeInput",
            "fields": [
                {"name": "_id", "type": "String!"},
                {"name": "name", "type": "String"},
                {"name": "description", "type": "String"},
                {"name": "image", "type": "String"},
                {"name": "isActive", "type": "Boolean"}
            ]
        },
        {
            "name": "CuisineInput",
            "fields": [
                {"name": "_id", "type": "String"},
                {"name": "name", "type": "String!"},
                {"name": "description", "type": "String"},
                {"name": "image", "type": "String"},
                {"name": "shopTypeId", "type": "String"},
                {"name": "shopType", "type": "String"},
                {"name": "isActive", "type": "Boolean"}
            ]
        },
        {
            "name": "PaginationInput",
            "fields": [
                {"name": "page", "type": "Int"},
                {"name": "size", "type": "Int"},
                {"name": "limit", "type": "Int"},
                {"name": "rows", "type": "Int"}
            ]
        },
         {
            "name": "FetchShopTypeFilter",
            "fields": [
                {"name": "search", "type": "String"},
                {"name": "isActive", "type": "Boolean"},
                {"name": "global", "type": "String"}
            ]
        },
        {
            "name": "CoordinatesInput",
            "fields": [
                {"name": "latitude", "type": "Float!"},
                {"name": "longitude", "type": "Float!"}
            ]
        },
        {
            "name": "CircleBoundsInput",
            "fields": [
                {"name": "radius", "type": "Float!"}
            ]
        },
        {
            "name": "RestaurantInputCustom",
            "fields": [
                {"name": "_id", "type": "String"},
                {"name": "name", "type": "String"},
                {"name": "address", "type": "String"},
                {"name": "image", "type": "String"},
                {"name": "logo", "type": "String"},
                {"name": "phone", "type": "String"},
                {"name": "deliveryTime", "type": "Int"},
                {"name": "minimumOrder", "type": "Float"},
                {"name": "tax", "type": "Float"},
                {"name": "slug", "type": "String"},
                {"name": "username", "type": "String"},
                {"name": "password", "type": "String"},
                {"name": "shopType", "type": "String"},
                {"name": "cuisines", "type": "[String!]"},
                {"name": "openingTimes", "type": "[OpeningTimeInput!]"}
            ]
        }
    ]

    new_objects = [
        {
            "name": "ShopType",
            "fields": [
                {"name": "_id", "type": "String!"},
                {"name": "name", "type": "String!"},
                {"name": "image", "type": "String"},
                {"name": "isActive", "type": "Boolean!"}
            ]
        },
        {
            "name": "Cuisine",
            "fields": [
                {"name": "_id", "type": "String!"},
                {"name": "name", "type": "String!"},
                {"name": "description", "type": "String"},
                {"name": "image", "type": "String"},
                {"name": "isActive", "type": "Boolean!"},
                {"name": "shopTypeId", "type": "String"},
                {"name": "shopType", "type": "String"}
            ]
        },
        {
            "name": "FetchShopTypesResponse",
            "fields": [
                {"name": "data", "type": "[ShopType!]!"},
                {"name": "total", "type": "Int!"},
                {"name": "page", "type": "Int!"},
                {"name": "pageSize", "type": "Int!"},
                {"name": "totalPages", "type": "Int!"},
                {"name": "hasNextPage", "type": "Boolean!"},
                {"name": "hasPrevPage", "type": "Boolean!"}
            ]
        },
        {
            "name": "LocationType",
             "fields": [
                {"name": "coordinates", "type": "[Float!]"}
            ]
        },
        {
            "name": "DeliveryBoundsType",
             "fields": [
                {"name": "coordinates", "type": "[[[Float!]]]"}
            ]
        },
        {
            "name": "UpdateDeliveryBoundsAndLocationData",
            "fields": [
                {"name": "_id", "type": "String"},
                {"name": "location", "type": "LocationType"},
                {"name": "deliveryBounds", "type": "DeliveryBoundsType"}
            ]
        },
        {
             "name": "UpdateDeliveryBoundsAndLocationResponse",
             "fields": [
                 {"name": "success", "type": "Boolean!"},
                 {"name": "message", "type": "String"},
                 {"name": "data", "type": "UpdateDeliveryBoundsAndLocationData"}
             ]
        }
    ]

    # Append new types, checking for duplicates by name
    current_input_objects = metadata.get("custom_types", {}).get("input_objects", [])
    existing_input_names = {io["name"] for io in current_input_objects}
    for io in new_input_objects:
        # Update if exists, or append
        if io["name"] in existing_input_names:
             # Find and replace for update
             for idx, existing_io in enumerate(current_input_objects):
                 if existing_io["name"] == io["name"]:
                     current_input_objects[idx] = io
                     break
        else:
            current_input_objects.append(io)
    
    current_objects = metadata.get("custom_types", {}).get("objects", [])
    existing_object_names = {o["name"] for o in current_objects}
    for o in new_objects:
         if o["name"] in existing_object_names:
             for idx, existing_o in enumerate(current_objects):
                 if existing_o["name"] == o["name"]:
                     current_objects[idx] = o
                     break
         else:
            current_objects.append(o)
            
    # Update metadata types
    if "custom_types" not in metadata:
        metadata["custom_types"] = {}
    metadata["custom_types"]["input_objects"] = current_input_objects
    metadata["custom_types"]["objects"] = current_objects


    # 3. Track Tables
    if "sources" not in metadata:
        metadata["sources"] = []
    
    # Ensure default source exists
    default_source = next((s for s in metadata["sources"] if s["name"] == "default"), None)
    if not default_source:
        default_source = {
            "name": "default",
            "kind": "postgres",
            "tables": [],
            "configuration": {
                "connection_info": {
                    "database_url": {"from_env": "HASURA_GRAPHQL_DATABASE_URL"},
                    "isolation_level": "read-committed",
                    "use_prepared_statements": False
                }
            }
        }
        metadata["sources"].append(default_source)
    
    current_tables = default_source.get("tables", [])
    
    # Define table configurations
    cuisines_table = {
        "table": {"schema": "public", "name": "cuisines"},
        "select_permissions": [
            {
                "role": "public",
                "permission": {
                    "columns": "*",
                    "filter": {},
                    "allow_aggregations": True
                }
            }
        ]
    }
    
    # Add or update cuisines table
    existing_table_names = {t["table"]["name"] for t in current_tables}
    if "cuisines" not in existing_table_names:
        current_tables.append(cuisines_table)
    else:
        for idx, t in enumerate(current_tables):
            if t["table"]["name"] == "cuisines":
                current_tables[idx] = cuisines_table
                break
                
    default_source["tables"] = current_tables

    # 4. Define New Actions
    new_actions = [
        {
            "name": "fetchShopTypes",
            "definition": {
                "handler": "http://fastapi-service:8000/fetchShopTypes",
                "output_type": "FetchShopTypesResponse",
                "arguments": [
                    {"name": "filter", "type": "FetchShopTypeFilter"},
                    {"name": "pagination", "type": "PaginationInput"}
                ],
                "type": "query",
                "kind": "synchronous"
            }
        },
        {
            "name": "createShopType",
            "definition": {
                "handler": "http://fastapi-service:8000/createShopType",
                "output_type": "ShopType",
                "arguments": [
                    {"name": "dto", "type": "CreateShopTypeInput!"}
                ],
                "type": "mutation",
                "kind": "synchronous"
            }
        },
        {
            "name": "updateShopType",
            "definition": {
                "handler": "http://fastapi-service:8000/updateShopType",
                "output_type": "ShopType",
                "arguments": [
                    {"name": "dto", "type": "UpdateShopTypeInput!"}
                ],
                "type": "mutation",
                "kind": "synchronous"
            }
        },
        {
            "name": "deleteShopType",
            "definition": {
                "handler": "http://fastapi-service:8000/deleteShopType",
                "output_type": "ShopType",
                "arguments": [
                    {"name": "id", "type": "String!"}
                ],
                "type": "mutation",
                "kind": "synchronous"
            }
        },
        {
            "name": "fetchCuisines",
            "definition": {
                "handler": "http://fastapi-service:8000/fetchCuisines",
                "output_type": "[Cuisine!]!",
                "arguments": [
                    {"name": "shopType", "type": "String"},
                    {"name": "isActive", "type": "Boolean"}
                ],
                "type": "query",
                "kind": "synchronous"
            }
        },
        {
            "name": "createCuisine",
            "definition": {
                "handler": "http://fastapi-service:8000/createCuisine",
                "output_type": "Cuisine",
                "arguments": [
                    {"name": "cuisineInput", "type": "CuisineInput!"}
                ],
                "type": "mutation",
                "kind": "synchronous"
            }
        },
        {
            "name": "editCuisine",
             "definition": {
                "handler": "http://fastapi-service:8000/editCuisine",
                "output_type": "Cuisine",
                "arguments": [
                    {"name": "cuisineInput", "type": "CuisineInput!"}
                ],
                "type": "mutation",
                "kind": "synchronous"
            }
        },
        {
            "name": "deleteCuisine",
             "definition": {
                "handler": "http://fastapi-service:8000/deleteCuisine",
                "output_type": "Cuisine",
                "arguments": [
                    {"name": "id", "type": "String!"}
                ],
                "type": "mutation",
                "kind": "synchronous"
            }
        },
        {
            "name": "updateDeliveryBoundsAndLocation",
            "definition": {
                "handler": "http://fastapi-service:8000/updateDeliveryBoundsAndLocation",
                "output_type": "UpdateDeliveryBoundsAndLocationResponse",
                "arguments": [
                    {"name": "id", "type": "ID!"},
                    {"name": "location", "type": "CoordinatesInput!"},
                    {"name": "boundType", "type": "String!"},
                    {"name": "address", "type": "String"},
                    {"name": "bounds", "type": "[[[Float!]]]"},
                    {"name": "circleBounds", "type": "CircleBoundsInput"}
                ],
                "type": "mutation",
                "kind": "synchronous"
            }
        }
    ]

    current_actions = metadata.get("actions", [])
    existing_action_names = {a["name"] for a in current_actions}
    for a in new_actions:
        if a["name"] in existing_action_names:
            # Replace
             for idx, existing_a in enumerate(current_actions):
                 if existing_a["name"] == a["name"]:
                     current_actions[idx] = a
                     break
        else:
            current_actions.append(a)
    
    metadata["actions"] = current_actions

    # 4. Prepare Replace Metadata Payload
    payload = {
        "type": "replace_metadata",
        "version": 2,
        "args": {
            "metadata": metadata,
            "allow_inconsistent_metadata": True
        }
    }

    # 5. Save payload to file
    with open("metadata_payload.json", "w") as f:
        json.dump(payload, f, indent=2)

    print("Metadata payload created. Applying using curl...")
    
    # 6. Execute curl
    try:
        cmd = [
            "curl",
            "-X", "POST",
            "http://localhost:8080/v1/metadata",
            "-H", "Content-Type: application/json",
            "-d", "@metadata_payload.json"
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        print("Response:", result.stdout)
        print("Error:", result.stderr)
    except Exception as e:
        print(f"Error executing curl: {e}")

if __name__ == "__main__":
    update_metadata()
