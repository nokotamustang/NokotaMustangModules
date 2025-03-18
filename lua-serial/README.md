# Vignette

**Title**:
lua-serial

**Version**:
1.0

**Description**:
Lua based table data serializer and deserializer.

**Authors**:
Charles Mallah

**Copyright**:
(c) 2025 Charles Mallah

**License**:
MIT license (mit-license.org)

**Sample**:
Input data is a table such as:

    local testData = {
      a = "text",
      b = 10,
      c = {
        d = "nested",
        e = nil
     }
    }

Serialized output for this sample is a string:

    {"b":10,"a":"hello","c":{"d":"nested"}}

The reverse would apply for the deserialized case.

**Example**:
Serialize your table to a string directly:

    local serial = require("serial")
    local stringOut = serial.serialize(testData)

Deserialize a string to a table directly:

    local tableOut = serial.deserialize(stringOut)

# API

**serialize** (data) : serialized

> Serialize a table and return the string  
> &rarr; **data** (table) <_required_>  
> &larr; **serialized** (string)

**deserialize(serialized) return expect_object** (serialized) : data

> Deserialize a string and return the table  
> &rarr; **serialized** (string) <_required_>  
> &larr; **data** (table)

# Project

-   [Back to root](../README.md)
