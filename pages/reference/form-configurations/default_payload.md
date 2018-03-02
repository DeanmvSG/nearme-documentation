---
title: Form Configuration - Default Payload
permalink: /reference/form-configurations-static/default_payload
---

## General Information

Form Configuration `default_payload` option allows to provide default request parameters
as JSON. Provided data and request parameters are joined together
before validation. All attributes passed this way must be defined in form configuration.

## Variables

 Liquid Tempalte syntax can be used, there are three additonal objects available:
* form
* params
* current_user

## Example

```
---
name: book_service_form
base_form: ReservationForm
configuration:
  properties:
    validation:
      presence: true
    abandoned_cart_timestamp:
      validation:
        presence: true
default_payload: |-
  {%- assign date_now = 'now' | date: '%d-%m-%Y %H:%M:%S' -%}
  {
    "properties_attributes": {
      "abandoned_cart_timestamp": "{{ date_now }}"
    }
  }
---
```


## Custom Model Example

```
---
name: new_blog_post
base_form: CustomizationForm
configuration:
  properties:
    title:
      validation:
        presence: true
    slug:
      validation:
        presence: true
default_payload: |-
  {
    "properties_attributes": {
      "slug": "{% raw %}{{ params.properties_attributes.title | default: '' | slugify }}{% endraw %}"
    }
  }
---
```
