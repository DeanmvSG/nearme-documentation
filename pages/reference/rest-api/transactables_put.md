---
title: Create a Transactable
permalink: /reference/rest-api/transactables_put
---
To update a transactable, send a PUT request to /api/user/transactables/:transactable_id

**HTTP request**

PUT /api/user/transactables/:transactable_id

**Parameters**

| Parameter | Type | Description | Required | Notes |
|---------------------|--------------------------------------------------------------------|-------------------------------------------------------------|------------------------|---------------------------------------------|
| form_configuration_name | String | Name of the form configuration | Required ||
| form | TransactableForm | TransactableForm parameters that corresponds with FormConfiguration configuration | Required | |

**Transactable Parameters**

{% include resources/TransactableForm.html %}

**Example request**

```
"authorization: Token token=192a8aee2e9c3bbd20e4e207506926c0"
"accept: application/json"
"content-type: application/json"
```
```
{
  "form_configuration_name": "reference_rest_api_update_transactable",
  "form": {
    "name": "Super boat"
  }
}
```

| Element | Type | Description | Required? |
|------------------------------------|--------------------------------------------|----------------------------------------------------------------------------------------------------|------------------------|
| form_configuration_name | String | Name of the defined FormConfiguration | Required |
| form | TransactableForm | Attributes for user, should match configuration defined in corresponding FormConfiguration | Required |

**Example response**

```
HTTP/1.1 204 No Content
Content-Type: application/vnd.api+json
```
```
{}
```

| Element | Type | Description |
|-------------------------------------|--------------------------------------------|----------------------------------------------------------------|
| [Element as it appears in response] | [Array, Object, String, Integer, or Float] | [Brief description of what information the element represents] |
| […] | […] | […] |

{% include reference/error_and_status_codes_put.md %}
